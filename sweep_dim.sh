#!/usr/bin/env bash
# sweep_dim.sh - sweep the 'dim' parameter of streamcluster on AraXL

ROOT=/scratch/msc26h14/AraXL
NR_CLUSTERS=4
CONFIG=4_lanes
DIMS=(4 8 16 32 64 128 256 512 1024)

OUT=$ROOT/sweep_dim
mkdir -p "$OUT"
CSV=$OUT/results.csv
echo "dim,hw_cycles,fpu_mean,fpu_min,fpu_max,fpu_util_pct,dist_calcs,hw_cycles_per_dist,pspeedy_sw,pFL_sw,cva6_sb_full,sb_full_pct,cva6_dcache_stalls,cva6_icache_stalls,sim_ok" > "$CSV"

# last_val <regex> : last matching line in $LOG, final whitespace-separated field
last_val() {
  grep -E "1""LOG" | tail -1 | awk '{print $NF}'
}

# sum_sw <name> : sum of "[sw-cycles]: N" values for a given phase name
sum_sw() {
  grep -E "$1 \[sw-cycles\]" "$LOG" \
    | sed -E 's/.*
sw-cycles
: *([0-9]+).*/\1/' \
    | awk '{s+=$1} END{print s+0}'
}

for DIM in "${DIMS[@]}"; do
  ARGS="3 10 $DIM 64 64 20"
  LOG=OUT/logdim{DIM}.txt
  echo "=== dim=DIMargs='ARGS' ($(date)) ==="

  # 1) build the binary
  (cd "ROOT/apps"&&makerivecbinariesnrclusters=NR_CLUSTERS config=$CONFIG \
      def_args__streamcluster="$ARGS")
  if [ $? -ne 0 ]; then
    echo "DIM,BUILDFAILED">>"CSV"
    continue
  fi

  # 2) simulate
  (cd "ROOT/hardware"&&makesimcapp=streamclusternrclusters=NR_CLUSTERS config=$CONFIG \
      |& tee "$LOG")

  # 3) save traces (they are overwritten by the next run)
  mkdir -p "OUT/tracesdim{DIM}"
  mv "ROOT"/hardware/trace*.csv"OUT/traces_dim${DIM}/" 2>/dev/null

  # 4) parse
  OK=(grep-c'SUCCESS'"LOG")
  HW=$(last_val '
hw-cycles
')
  DIST=$(last_val 'Number of distance calculations')
  SB=$(last_val '
cva6-sb-full
')
  DC=$(last_val '\[cva6-d[$]-stalls\]')
  IC=$(last_val '\[cva6-i[$]-stalls\]')
  PSP=$(sum_sw pspeedy)
  PFL=$(sum_sw pFL)

  STATS=$(grep -E 'cluster-[0-9]+-lane-[0-9]+ \[fpu-cycles\]' "$LOG" \
    | awk '{v=$NF; s+=v; n++; if(n==1||v<mn)mn=v; if(n==1||v>mx)mx=v}
           END{if(n) printf "%.0f %d %d", s/n, mn, mx; else print "NA NA NA"}')
  FMEAN=(echo"STATS" | awk '{print $1}')
  FMIN=(echo"STATS" | awk '{print $2}')
  FMAX=(echo"STATS" | awk '{print $3}')

  UTIL=NA; CPD=NA; SBPCT=NA
  if [ -n "HW"]&&["FMEAN" != "NA" ]; then
    UTIL=(awk-vf="FMEAN" -v h="$HW" 'BEGIN{printf "%.3f", 100*f/h}')
  fi
  if [ -n "HW"]&&[-n"DIST" ]; then
    CPD=(awk-vh="HW" -v d="$DIST" 'BEGIN{if(d>0) printf "%.1f", h/d; else print "NA"}')
  fi
  if [ -n "HW"]&&[-n"SB" ]; then
    SBPCT=(awk-vs="SB" -v h="$HW" 'BEGIN{printf "%.2f", 100*s/h}')
  fi

  echo "DIM,{HW:-NA},FMEAN,FMIN,FMAX,UTIL,DIST:-NA,CPD,PSP,PFL,SB:-NA,SBPCT,DC:-NA,{IC:-NA},OK">>"CSV"
done

echo "Done. Results in $CSV"
column -s, -t "$CSV"
