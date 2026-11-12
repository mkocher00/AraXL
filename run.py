import subprocess, sys

ROOT = "/scratch/msc26h14/AraXL"
HW = ROOT + "/hardware"
APPS = ROOT + "/apps"
M, N = 16, 64
PS = (64, 128, 256)

C = int(sys.argv[1])
lanes = 4 * C

def sh(cmd, cwd, log):
    with open(log, "w") as f:
        subprocess.run(["bash", "-c", cmd], cwd=cwd, stdout=f, stderr=subprocess.STDOUT)

def read(f):
    try:
        return open(f, errors="ignore").read()
    except IOError:
        return ""

def parse(log):
    for f in (log, HW + "/build/transcript"):
        t = read(f)
        cyc, hdr = None, ""
        for line in t.splitlines():
            if "[hw-cycles]" in line:
                cyc = int(line.split(":")[1])
            if "multiplication" in line:
                hdr = line.strip("# ")
        if cyc is not None:
            return cyc, hdr, ("assed." in t)
    return None, "", False

# 1) rebuild the RTL for this cluster count
print("Compiling RTL for nr_clusters=%d ..." % C, flush=True)
sh("rm -rf build; make compile nr_clusters=%d config=4_lanes" % C,
   HW, ROOT + "/compile_c%d.txt" % C)

# 2) run the sweep
out = open(ROOT + "/results_c%d.txt" % C, "w")
for P in PS:
    sh("rm -f fmatmul/data.S fmatmul/*.o bin/fmatmul; "
       + 'make bin/fmatmul nr_clusters=%d config=4_lanes def_args_fmatmul="%d %d %d"' % (C, M, N, P),
       APPS, ROOT + "/build_c%d_P%d.txt" % (C, P))
    log = ROOT + "/log_fmatmul_c%d_%d_%d_%d.txt" % (C, M, N, P)
    sh("make simc app=fmatmul nr_clusters=%d config=4_lanes" % C, HW, log)
    cyc, hdr, ok = parse(log)
    if cyc is None:
        line = "C=%d P=%d: FAILED, see %s and compile_c%d.txt" % (C, P, log, C)
    else:
        I1, B = cyc / (M * N), P / lanes
        line = ("C=%d lanes=%d P=%d hw_cycles=%d verified=%s I1=%.2f B=%.2f G=%.2f | %s"
                % (C, lanes, P, cyc, ok, I1, B, I1 / B, hdr))
    print(line, flush=True)
    out.write(line + "\n")
    out.flush()
out.close()
