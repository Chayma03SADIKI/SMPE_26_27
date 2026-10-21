#!/bin/bash

# ============================================================
# run_benchmarking.sh
# Compiles parallelQuicksort, runs 30 measurements per size
# per method (sequential, parallel, built-in libc qsort),
# and writes results directly to CSV files in results/
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$ROOT_DIR/src"
RESULTS_DIR="$ROOT_DIR/results"

# --- Compile ---
echo "Compiling..."
make -C "$SRC_DIR"
echo "Compilation done."

# --- Setup results directory ---
mkdir -p "$RESULTS_DIR"

SEQ_CSV="$RESULTS_DIR/sequential.csv"
PAR_CSV="$RESULTS_DIR/parallel.csv"
LIB_CSV="$RESULTS_DIR/libc.csv"

# Write CSV headers
echo "size,rep,time_sec" > "$SEQ_CSV"
echo "size,rep,time_sec" > "$PAR_CSV"
echo "size,rep,time_sec" > "$LIB_CSV"

# --- Parameters ---
SIZES=(100 500 1000 5000 10000 50000 100000 500000 1000000 2000000)
REPS=30

# --- Build randomized experiment list ---
# Each line: "size rep"
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

echo "Running $TOTAL experiments (${#SIZES[@]} sizes x $REPS repetitions)..."

while IFS= read -r experiment; do
    size=$(echo "$experiment" | awk '{print $1}')
    rep=$(echo "$experiment"  | awk '{print $2}')

    COUNT=$((COUNT + 1))
    echo "[$COUNT/$TOTAL] size=$size rep=$rep"

    # Run the benchmark and capture output
    output=$("$SRC_DIR/parallelQuicksort" "$size")

    # Parse each line and append to the right CSV
    seq_time=$(echo "$output" | grep "^Sequential" | awk '{print $(NF-1)}')
    par_time=$(echo "$output" | grep "^Parallel"   | awk '{print $(NF-1)}')
    lib_time=$(echo "$output" | grep "^Built-in"   | awk '{print $(NF-1)}')

    echo "$size,$rep,$seq_time" >> "$SEQ_CSV"
    echo "$size,$rep,$par_time" >> "$PAR_CSV"
    echo "$size,$rep,$lib_time" >> "$LIB_CSV"

done <<< "$SHUFFLED"

echo ""
echo "Done. Results written to:"
echo "  $SEQ_CSV"
echo "  $PAR_CSV"
echo "  $LIB_CSV"

# Sort CSV files by size then rep
echo "Sorting CSV files..."

for csv in "$SEQ_CSV" "$PAR_CSV" "$LIB_CSV"; do
    header=$(head -1 "$csv")
    tail -n +2 "$csv" | sort -t',' -k1,1n -k2,2n > "${csv}.tmp"
    echo "$header" > "$csv"
    cat "${csv}.tmp" >> "$csv"
    rm "${csv}.tmp"
done

echo "CSV files sorted."