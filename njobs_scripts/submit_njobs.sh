#!/bin/bash
# sub_jobs.sh
# Submits one PBS job per matching NetCDF file in INDIR.
# Each job passes INFILE and OUTFILE to ANALYSIS_SCRIPT via the environment.
# Log files land in LOGDIR named <jobid>.casper-pbs.OU by PBS.
#
# USER SETTINGS: adjust GLOB, ANALYSIS_SCRIPT, OUT_MODIFIER, and index range.

set -uo pipefail

# ---- user-defined section ----

#INDIR=/glade/campaign/cesm/km-scale/archive/c124_dyamond1_prod2/atm/hist
INDIR=/glade/campaign/cesm/km-scale/archive/cam77_dyamond1_prod1/atm/hist

SCRIPTDIR=/glade/campaign/cgd/amp/aherring/2026-cesm3-dyamond1/njobs_scripts
#ANALYSIS_SCRIPT=${SCRIPTDIR}/print_filename.ncl
ANALYSIS_SCRIPT=${SCRIPTDIR}/print_filename.py
OUTDIR=${SCRIPTDIR}/out_files
LOGDIR=${SCRIPTDIR}/logs

# Tape selector
GLOB="*.cam.h2i.*"

# Modifier just before .nc in the output filename.
OUT_MODIFIER="_datestamp"

# File index range (0-based, inclusive on both ends).
# Set IFILE_FINISH=-1 to process all files.
IFILE_START=0
IFILE_FINISH=1

# ---- end of user-defined section ----

mkdir -p "$OUTDIR" "$LOGDIR"

# Build sorted file list.
files=()
for f in "$INDIR"/$GLOB; do
    [[ -f "$f" ]] && files+=("$f")
done
total=${#files[@]}

# Resolve -1 sentinel to last index.
[[ "$IFILE_FINISH" -lt 0 ]] && IFILE_FINISH=$(( total - 1 ))

count=$(( IFILE_FINISH - IFILE_START + 1 ))
echo "Found ${total} files; submitting indices ${IFILE_START}–${IFILE_FINISH} (${count} jobs)."

for infile in "${files[@]:${IFILE_START}:${count}}"; do

    fname=$(basename "$infile")
    stamp="${fname%.nc}"
    stamp="${stamp##*.}"           # timestamp after the last dot, e.g. 2016-08-01-00000
    outfile="${OUTDIR}/${fname%.nc}${OUT_MODIFIER}.nc"

    qsub \
        -N "anl_${stamp}" \
        -o "$LOGDIR" \
        -v "INFILE=${infile},OUTFILE=${outfile},ANALYSIS_SCRIPT=${ANALYSIS_SCRIPT}" \
        << 'PBS_EOF'
#!/bin/bash
#PBS -A p03010039
#PBS -q main
#PBS -l select=1:ncpus=1:mem=4GB
#PBS -l walltime=00:05:00
#PBS -j oe

set -euo pipefail

## ---- NCL ----
#module load ncl
#ncl "$ANALYSIS_SCRIPT"

## ---- Python ----
module load conda
conda activate npl
python "$ANALYSIS_SCRIPT"
PBS_EOF

done

echo "Submitted ${count} jobs. Output in ${OUTDIR}/, logs in ${LOGDIR}/"
