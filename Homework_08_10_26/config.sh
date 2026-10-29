# =============================================
# Edit this file to configure the experiment
# =============================================

# Thread level for parallel quicksort (THREAD_LEVEL in parallelQuicksort.c)
# Default: 10 (up to 2^10 = 1024 threads)
THREAD_LEVEL=10

# Array sizes to benchmark
SIZES=(100 500 1000 5000 10000 50000 100000 500000 1000000 2000000)

# Number of repetitions per size per method
REPS=30

# Output directories (relative to project root)
# These will be created automatically if they don't exist
RESULTS_DIR="results"
FIGURES_DIR="figures"