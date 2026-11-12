#!/usr/bin/env python3
"""
Sweep fmatmul over (M, N, P) on AraXL and collect HW cycles + utilization.

For every M it writes TWO matrices (rows = N, columns = P):
    matrix_hwcycles_M<M>.csv   -> [hw-cycles]
    matrix_util_M<M>.csv       -> utilization in %

Usage (from anywhere):
    python3 sweep_fmatmul.py              # run the sweep (resumes if results.csv exists)
    python3 sweep_fmatmul.py --report     # only rebuild the matrices from results.csv
    python3 sweep_fmatmul.py --dry-run    # print what would run

Each run takes ~5 min, so run it in tmux/screen or with nohup.
"""
import argparse
import csv
import math
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

# =============================== PARAMETERS ===============================
ARA_ROOT    = Path("/scratch/msc26h14/AraXL")
NR_CLUSTERS = 4
CONFIG      = "4_lanes"          # lanes per cluster, "<n>_lanes"
APP         = "fmatmul"

M_VALUES = [16,32]              # one pair of matrices per M
N_VALUES = [16,32,64,128,256]         # rows of each matrix
P_VALUES = [64,128,256,512,1024]       # columns of each matrix

# "printed": utilization as printed by the app (based on "execution took X cycles")
# "hw"     : 2*M*N*P / hw-cycles / (2*total lanes)  (based on [hw-cycles])
UTIL_SOURCE = "printed"

RESUME      = True               # skip (M,N,P) already in results.csv
SIM_TIMEOUT = None               # seconds per simulation, None = no limit
RESULTS_DIR = ARA_ROOT / "sweep_results"
# ==========================================================================

NR_LANES_TOTAL = NR_CLUSTERS * int(CONFIG.split("_")[0])
RAW_CSV = RESULTS_DIR / "results.csv"
FIELDS = ["M", "N", "P", "hw_cycles", "exec_cycles", "flop_per_cycle",
          "util_printed", "util_hw", "verified", "status"]

# The UART output sometimes drops the first character of a line
# ("he execution took ...", "assed."), so the patterns avoid the line starts.
RE_HW     = re.compile(r"\[hw-cycles\]:\s*(\d+)")
RE_EXEC   = re.compile(r"execution took (\d+) cycles")
RE_PERF   = re.compile(r"performance is ([\d.]+) FLOP/cycle \(([\d.]+)% utilization\)")
RE_VERIFY = re.compile(r"assed\.")


def parse_log(text, M, N, P):
    hw = RE_HW.search(text)
    ex = RE_EXEC.search(text)
    pf = RE_PERF.search(text)
    row = dict(M=M, N=N, P=P,
               hw_cycles=int(hw.group(1)) if hw else None,
               exec_cycles=int(ex.group(1)) if ex else None,
               flop_per_cycle=float(pf.group(1)) if pf else None,
               util_printed=float(pf.group(2)) if pf else None,
               verified=bool(RE_VERIFY.search(text)),
               status="ok")
    row["util_hw"] = (100.0 * 2 * M * N * P / row["hw_cycles"] / (2 * NR_LANES_TOTAL)
                      if row["hw_cycles"] else None)
    if hw is None:
        row["status"] = "no_hw_cycles"
    elif not row["verified"]:
        row["status"] = "not_verified"
    return row


def run_one(M, N, P):
    apps, hw = ARA_ROOT / "apps", ARA_ROOT / "hardware"
    log = RESULTS_DIR / f"log_{APP}_{M}_{N}_{P}.txt"
    args = f"{M} {N} {P}"

    # clean (same as: rm -f fmatmul/data.S fmatmul/*.o bin/fmatmul)
    to_remove = [apps / APP / "data.S", apps / "bin" / APP]
    to_remove += list((apps / APP).glob("*.o"))
    for p in to_remove:
        if p.exists():
            p.unlink()

    build = ["make", f"bin/{APP}", f"nr_clusters={NR_CLUSTERS}",
             f"config={CONFIG}", f"def_args_{APP}={args}"]
    sim = ["make", "simc", f"app={APP}", f"nr_clusters={NR_CLUSTERS}",
           f"config={CONFIG}"]

    with open(log, "w") as f:
        rc = subprocess.run(build, cwd=apps, stdout=f, stderr=subprocess.STDOUT).returncode
        if rc != 0:
            return dict(M=M, N=N, P=P, status="build_failed", verified=False)
        try:
            rc = subprocess.run(sim, cwd=hw, stdout=f, stderr=subprocess.STDOUT,
                                timeout=SIM_TIMEOUT).returncode
        except subprocess.TimeoutExpired:
            return dict(M=M, N=N, P=P, status="timeout", verified=False)

    row = parse_log(log.read_text(errors="replace"), M, N, P)
    if rc != 0 and row["status"] == "ok":
        row["status"] = f"sim_rc_{rc}"
    return row


def load_results():
    if not RAW_CSV.exists():
        return {}
    with open(RAW_CSV, newline="") as f:
        return {(int(r["M"]), int(r["N"]), int(r["P"])): r for r in csv.DictReader(f)}


def save_results(results):
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    with open(RAW_CSV, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore", restval="")
        w.writeheader()
        for k in sorted(results):
            w.writerow(results[k])


def as_float(v):
    try:
        x = float(v)
        return x if not math.isnan(x) else None
    except (TypeError, ValueError):
        return None


def write_matrices(results):
    util_key = "util_hw" if UTIL_SOURCE == "hw" else "util_printed"
    for M in M_VALUES:
        for name, key, fmt in (("hwcycles", "hw_cycles", "{:.0f}"),
                               ("util", util_key, "{:.2f}")):
            header = ["N\\P"] + [str(p) for p in P_VALUES]
            table = []
            for N in N_VALUES:
                line = [str(N)]
                for P in P_VALUES:
                    r = results.get((M, N, P))
                    v = as_float(r.get(key)) if r else None
                    line.append(fmt.format(v) if v is not None else "nan")
                table.append(line)

            with open(RESULTS_DIR / f"matrix_{name}_M{M}.csv", "w", newline="") as f:
                w = csv.writer(f)
                w.writerow(header)
                w.writerows(table)

            title = "HW cycles" if name == "hwcycles" else f"Utilization [%] ({UTIL_SOURCE})"
            print(f"\n=== M = {M}: {title} (rows N, cols P) ===")
            widths = [max(len(r[i]) for r in [header] + table) for i in range(len(header))]
            for r in [header] + table:
                print("  ".join(c.rjust(w_) for c, w_ in zip(r, widths)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true", help="only rebuild matrices")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    results = load_results() if (RESUME or a.report) else {}
    combos = [(M, N, P) for M in M_VALUES for N in N_VALUES for P in P_VALUES]

    if not a.report:
        todo = [c for c in combos if not (RESUME and results.get(c, {}).get("status") == "ok")]
        print(f"{len(combos)} configs, {len(todo)} to run (~5 min each).")
        for i, (M, N, P) in enumerate(todo, 1):
            print(f"[{i}/{len(todo)}] M={M} N={N} P={P}", flush=True)
            if a.dry_run:
                continue
            t0 = time.time()
            row = run_one(M, N, P)
            results[(M, N, P)] = row
            save_results(results)            # persist after every run
            print(f"    -> {row.get('status')}  hw_cycles={row.get('hw_cycles')}  "
                  f"util={row.get('util_printed')}%  ({time.time()-t0:.0f}s)", flush=True)
        if a.dry_run:
            return

    write_matrices(results)
    print(f"\nFiles in {RESULTS_DIR}")


if __name__ == "__main__":
    main()
