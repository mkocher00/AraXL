#!/usr/bin/env python3
"""Sweep the 'dim' parameter of streamcluster on AraXL and collect metrics.

Usage:
  python3 -u sweep_dim.py                 # full sweep
  python3 -u sweep_dim.py 4 8             # only these dims (for a quick test)
  python3 sweep_dim.py --parse LOGFILE    # just parse an existing log
"""
import csv
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path("/scratch/msc26h14/AraXL")
NR_CLUSTERS = 4
CONFIG = "4_lanes"
DIMS = [2048, 4096, 8192]
OUT = ROOT / "sweep_dim"

FIELDS = [
    "dim", "hw_cycles", "fpu_mean", "fpu_min", "fpu_max", "fpu_util_pct",
    "dist_calcs", "hw_cycles_per_dist", "pspeedy_sw", "pFL_sw",
    "cva6_sb_full", "sb_full_pct", "cva6_dcache_stalls", "cva6_icache_stalls",
    "sim_ok",
]

# NOTE: the log brackets are matched with "." so no backslash-bracket is needed.
PAT_FPU = r"cluster-\d+-lane-\d+ .fpu-cycles.\s*:\s*(\d+)"
PAT_HW = r" .hw-cycles.:\s*(\d+)"
PAT_DIST = r"Number of distance calculations:\s*(\d+)"
PAT_SB = r" .cva6-sb-full.:\s*(\d+)"
PAT_DC = r" .cva6-d.-stalls.:\s*(\d+)"
PAT_IC = r" .cva6-i.-stalls.:\s*(\d+)"
PAT_PSP = r"pspeedy .sw-cycles.:\s*(\d+)"
PAT_PFL = r"pFL .sw-cycles.:\s*(\d+)"


def parse(text):
    """Extract all metrics from the text of a simulation log."""
    def last(pattern):
        found = re.findall(pattern, text)
        return int(found[-1]) if found else None

    def total(pattern):
        found = re.findall(pattern, text)
        return sum(int(x) for x in found) if found else None

    fpu = [int(x) for x in re.findall(PAT_FPU, text)]

    r = {
        "hw_cycles": last(PAT_HW),
        "dist_calcs": last(PAT_DIST),
        "cva6_sb_full": last(PAT_SB),
        "cva6_dcache_stalls": last(PAT_DC),
        "cva6_icache_stalls": last(PAT_IC),
        "pspeedy_sw": total(PAT_PSP),
        "pFL_sw": total(PAT_PFL),
        "sim_ok": int("SUCCESS" in text),
        "fpu_mean": None, "fpu_min": None, "fpu_max": None,
        "fpu_util_pct": None, "hw_cycles_per_dist": None, "sb_full_pct": None,
    }
    if fpu:
        r["fpu_mean"] = round(sum(fpu) / len(fpu))
        r["fpu_min"] = min(fpu)
        r["fpu_max"] = max(fpu)
    hw = r["hw_cycles"]
    if hw:
        if r["fpu_mean"] is not None:
            r["fpu_util_pct"] = round(100.0 * r["fpu_mean"] / hw, 3)
        if r["dist_calcs"]:
            r["hw_cycles_per_dist"] = round(hw / r["dist_calcs"], 1)
        if r["cva6_sb_full"] is not None:
            r["sb_full_pct"] = round(100.0 * r["cva6_sb_full"] / hw, 2)
    return r


def run_cmd(cmd, cwd, logfile=None):
    """Run a command, writing combined stdout/stderr into logfile."""
    proc = subprocess.Popen(
        cmd, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        
    )
    fh = open(logfile, "wb") if logfile else None
    for line in proc.stdout:
        if fh:
            fh.write(line)
            fh.flush()
    proc.wait()
    if fh:
        fh.close()
    return proc.returncode


def append_row(csv_path, row):
    new_file = not csv_path.exists()
    with open(csv_path, "a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        if new_file:
            w.writeheader()
        w.writerow({k: ("NA" if row.get(k) is None else row[k]) for k in FIELDS})


def print_table(csv_path):
    with open(csv_path) as f:
        rows = list(csv.reader(f))
    widths = [max(len(r[i]) for r in rows if i < len(r)) for i in range(len(rows[0]))]
    for r in rows:
        print("  ".join(c.rjust(w) for c, w in zip(r, widths)))


def main():
    args = sys.argv[1:]

    if args and args[0] == "--parse":
        for p in args[1:]:
            text = Path(p).read_text(errors="replace")
            for k, v in parse(text).items():
                print(f"{k:22s} {v}")
        return

    dims = [int(a) for a in args] if args else DIMS
    OUT.mkdir(exist_ok=True)
    csv_path = OUT / "results.csv"

    for dim in dims:
        arg_str = f"3 10 {dim} 64 64 20"
        log = OUT / f"log_dim{dim}.txt"
        print(f"=== dim={dim} args='{arg_str}' ===", flush=True)

        # 1) build
        rc = run_cmd(
            ["make", "rivec_binaries",
             f"nr_clusters={NR_CLUSTERS}", f"config={CONFIG}",
             f"def_args__streamcluster={arg_str}"],
            cwd=ROOT / "apps", logfile=OUT / f"build_dim{dim}.txt",
        )
        if rc != 0:
            print(f"  build FAILED (rc={rc}), see build_dim{dim}.txt", flush=True)
            append_row(csv_path, {"dim": dim, "sim_ok": 0})
            continue

        # 2) simulate
        rc = run_cmd(
            ["make", "simc", "app=_streamcluster",
             f"nr_clusters={NR_CLUSTERS}", f"config={CONFIG}"],
            cwd=ROOT / "hardware", logfile=log,
        )
        print(f"  simulation finished (rc={rc})", flush=True)

        # 3) keep the traces, they are overwritten by the next run
        tdir = OUT / f"traces_dim{dim}"
        tdir.mkdir(exist_ok=True)
        for t in (ROOT / "hardware").glob("trace_*.csv"):
            shutil.move(str(t), str(tdir / t.name))

        # 4) parse and record immediately
        row = parse(log.read_text(errors="replace"))
        row["dim"] = dim
        append_row(csv_path, row)
        print(f"  hw_cycles={row['hw_cycles']}  util={row['fpu_util_pct']}%  "
              f"sb_full={row['cva6_sb_full']}", flush=True)

    print(f"\nDone. Results in {csv_path}")
    print_table(csv_path)


if __name__ == "__main__":
    main()
