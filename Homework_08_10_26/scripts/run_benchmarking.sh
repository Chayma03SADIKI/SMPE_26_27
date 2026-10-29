#!/bin/bash

# ============================================================
# run_benchmarking.sh
# Compiles parallelQuicksort, runs measurements per size
# per method (sequential, parallel, built-in libc qsort),
# and writes results directly to CSV files.
#
# Configuration is loaded from config.sh at project root.
# Edit config.sh to change sizes, thread level, output dirs.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$ROOT_DIR/src"

# --- Load config ---
CONFIG_FILE="$ROOT_DIR/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: config.sh not found at $ROOT_DIR"
    exit 1
fi
source "$CONFIG_FILE"
echo "Config loaded:"
echo "  THREAD_LEVEL : $THREAD_LEVEL"
echo "  SIZES        : ${SIZES[*]}"
echo "  REPS         : $REPS"
echo "  RESULTS_DIR  : $RESULTS_DIR"
echo "  FIGURES_DIR  : $FIGURES_DIR"

# --- Resolve absolute paths ---
RESULTS_ABS="$ROOT_DIR/$RESULTS_DIR"
FIGURES_ABS="$ROOT_DIR/$FIGURES_DIR"

# --- Compile (no sed needed: THREAD_LEVEL is passed as argument) ---
echo ""
echo "Compiling..."
make -C "$SRC_DIR"
echo "Compilation done."

# --- Setup output directories ---
mkdir -p "$RESULTS_ABS"
mkdir -p "$FIGURES_ABS"

SEQ_CSV="$RESULTS_ABS/sequential.csv"
PAR_CSV="$RESULTS_ABS/parallel.csv"
LIB_CSV="$RESULTS_ABS/libc.csv"

# Write CSV headers
echo "size,rep,time_sec" > "$SEQ_CSV"
echo "size,rep,time_sec" > "$PAR_CSV"
echo "size,rep,time_sec" > "$LIB_CSV"

# --- Build randomized experiment list ---
EXPERIMENTS=()
for size in "${SIZES[@]}"; do
    for rep in $(seq 1 $REPS); do
        EXPERIMENTS+=("$size $rep")
    done
done

# Shuffle to avoid cache bias
SHUFFLED=$(printf "%s\n" "${EXPERIMENTS[@]}" | shuf)

TOTAL=$(echo "$SHUFFLED" | wc -l)
COUNT=0

echo ""
echo "Running $TOTAL experiments (${#SIZES[@]} sizes x $REPS repetitions x 3 methods)..."

while IFS= read -r experiment; do
    size=$(echo "$experiment" | awk '{print $1}')
    rep=$(echo "$experiment"  | awk '{print $2}')

    COUNT=$((COUNT + 1))
    echo "[$COUNT/$TOTAL] size=$size rep=$rep"

    # Pass size and THREAD_LEVEL as arguments — no source patching needed
    output=$("$SRC_DIR/parallelQuicksort" "$size" "$THREAD_LEVEL")

    # Parse each line and append to the right CSV
    seq_time=$(echo "$output" | grep "^Sequential" | awk '{print $(NF-1)}')
    par_time=$(echo "$output" | grep "^Parallel"   | awk '{print $(NF-1)}')
    lib_time=$(echo "$output" | grep "^Built-in"   | awk '{print $(NF-1)}')

    echo "$size,$rep,$seq_time" >> "$SEQ_CSV"
    echo "$size,$rep,$par_time" >> "$PAR_CSV"
    echo "$size,$rep,$lib_time" >> "$LIB_CSV"

done <<< "$SHUFFLED"

# --- Sort CSV files by size then rep ---
echo ""
echo "Sorting CSV files..."
for csv in "$SEQ_CSV" "$PAR_CSV" "$LIB_CSV"; do
    header=$(head -1 "$csv")
    tail -n +2 "$csv" | sort -t',' -k1,1n -k2,2n > "${csv}.tmp"
    echo "$header" > "$csv"
    cat "${csv}.tmp" >> "$csv"
    rm "${csv}.tmp"
done

echo ""
echo "Done. Results written to:"
echo "  $SEQ_CSV"
echo "  $PAR_CSV"
echo "  $LIB_CSV"
echo ""
echo "Now open analysis/analysis.R in RStudio and update config.R:"
echo "  results_dir <- \"$RESULTS_DIR\""
echo "  figures_dir <- \"$FIGURES_DIR\""