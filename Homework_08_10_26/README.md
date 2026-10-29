# M2R-ParallelQuicksort — Performance Evaluation

This project evaluates the performance of three sorting implementations:

- **Sequential quicksort** — standard recursive quicksort
- **Parallel quicksort** — multi-threaded version using Pthreads (`THREAD_LEVEL = 10`)
- **Built-in libc qsort** — C standard library reference

The original code was written by Joshua Stough (Washington and Lee University) and later adapted by Arnaud Legrand for performance evaluation purposes. The original experiment was conducted in 2014 on an Intel Core i7 running Debian/Linux 3.14.15.

---

## Project structure

```
.
├── analysis/
│   └── analysis.R          # R analysis script: statistics + figures
├── config.sh               # Benchmark configuration (sizes, thread level, paths)
├── config.R                # R analysis configuration (results and figures paths)
├── figures/                # Figures of experiment
├── original_figures/       # Original figures from the 2014 experiment
├── results/                # CSV results
├── scripts/
│   └── run_benchmarking.sh # Benchmark script
└── src/
    ├── parallelQuicksort.c # Source code
    └── Makefile
```

---

## How to reproduce

**1. Edit `config.sh`** to set your parameters:

```bash
THREAD_LEVEL=3
SIZES=(100 500 1000 5000 10000 50000 100000 500000 1000000 2000000)
REPS=30
RESULTS_DIR="results"
FIGURES_DIR="figures"
```

**2. Run the benchmark:**

```bash
bash scripts/run_benchmarking.sh
```

This will:
- Patch `THREAD_LEVEL` in `src/parallelQuicksort.c` and recompile
- Run `REPS` measurements per array size per method
- Randomize the experiment order to avoid cache bias
- Write results directly to CSV files in `RESULTS_DIR/`

**3. Edit `config.R`** to point to the right directories:

```r
results_dir <- "../results"
figures_dir <- "../figures"
```

**4. Run the analysis** in RStudio — open `analysis/analysis.R` and source it. Required packages:

```r
install.packages(c("ggplot2", "dplyr", "tidyr", "scales"))
```

Figures are saved to `figures_dir`.

---

## Experimental design

### Improvements over the original experiment

The original experiment (documented in `journal.org`, conducted by Arnaud Legrand in 2014) had several limitations:

- Only **5 repetitions** per size — insufficient for reliable statistical estimation
- Only **5 array sizes** (100 to 1M) — too coarse to identify the crossover point precisely
- **Fixed execution order** — all repetitions of a given size run consecutively, introducing cache bias
- **No statistical analysis** — no mean, no confidence intervals, no uncertainty reporting

Our improved design addresses all of these:

| | Original (2014) | This work (2026) |
|---|---|---|
| Array sizes | 5 (100 to 1M) | Configurable |
| Repetitions per size | 5 | 30 (configurable) |
| Experiment order | Fixed | Randomized (`shuf`) |
| Output format | Plain text → Perl extractor | Direct CSV |
| Statistical analysis | None | Mean + 95% CI (Student t-test) |
| Speedup uncertainty | Not reported | Propagated via delta method |
| Figures | Base R / gnuplot | ggplot2 |

### Configuration files (added 2026-10-29)

To avoid hardcoding parameters in the scripts and improve reusability,
all experiment parameters are now centralized in two configuration files:

**`config.sh`** — controls the benchmark script:
- `THREAD_LEVEL` : number of thread levels for parallel quicksort
- `SIZES` : array sizes to benchmark
- `REPS` : number of repetitions per size
- `RESULTS_DIR` : output directory for CSV files
- `FIGURES_DIR` : output directory for figures

**`config.R`** — controls the R analysis script:
- `results_dir` : path to the CSV results folder
- `figures_dir` : path to save the generated figures

This makes it easy to run multiple experiments with different parameters
(e.g. different thread levels or size ranges) without modifying the scripts
themselves — only `config.sh` and `config.R` need to be updated between runs.

### Why 30 repetitions?

By the **Central Limit Theorem**, 30 independent measurements are sufficient
for the sample mean to follow a normal distribution, enabling reliable 95%
confidence interval estimation regardless of the underlying distribution of
execution times.

### Why randomize the order?

Running all repetitions of the same size consecutively can bias results due
to CPU cache warm-up effects. Randomizing the order of all `(size, repetition)`
pairs ensures each measurement is independent.

---

## Original experiment (2014) — Arnaud Legrand

The original experiment was run on an Intel Core i7 laptop running Debian
with Linux 3.14.15. Only 5 sizes and 5 repetitions were used. Results were
extracted via a Perl script and plotted with base R and gnuplot.

### Original script

```bash
for i in 100 1000 10000 100000 1000000; do
    for rep in `seq 1 5`; do
        echo "Size: $i" >> $OUTPUT_FILE;
        ./src/parallelQuicksort $i >> $OUTPUT_FILE;
    done;
done
```

### Original figures

![Original scatter plot](original_figures/measurements_03_47.png)

*Figure: Base R scatter plot — no legend, no axis labels, no confidence intervals.*

![Original gnuplot](original_figures/measurements_03_47_wide.png)

*Figure: Gnuplot line chart — lines connect averages with no uncertainty shown.*

### Original conclusion

> "A first crude analysis seems to reveal that the parallel version is worth it for arrays larger than 400,000."
> — Arnaud Legrand, journal.org, 2014-10-13

Note: this conclusion was drawn from only 5 repetitions with no confidence
intervals, on a machine with more physical cores than the current one.

---

## Results — Chayma SADIKI (THREAD_LEVEL = 10)

### Machine specifications

| Property | Value |
|---|---|
| Hostname | ensietuhp06 |
| CPU | 12th Gen Intel Core i5-1235U |
| Logical cores | 12 (2 threads/core) |
| Max CPU frequency | 4400 MHz |
| RAM | 14 GB |
| OS | Ubuntu Linux 7.0.0-38-generic (x86_64) |
| Date | 2026-10-21 |

### Performance curves (mean ± 95% CI)

![Performance curves](figures_10Threads/performance_curves.png)

### Speedup relative to sequential (with propagated 95% CI)

![Speedup](figures_10Threads/speedup.png)

### Variability across 30 repetitions

![Boxplot variability](figures_10Threads/boxplot_variability.png)

### Key observations

- The **parallel quicksort is slower than sequential for all tested sizes**.
  The thread creation overhead (`THREAD_LEVEL = 10` → up to 1024 threads)
  dominates even at 2M elements.
- The **built-in libc qsort** performs very similarly to sequential across all sizes.
- Execution times are highly **consistent across repetitions** (tight boxplots),
  which validates the experimental design.
- This contrasts with the 2014 results where parallel was faster at 1M —
  likely due to a higher core count on that machine.

---

## Results — Chayma SADIKI (THREAD_LEVEL = 3)

### Machine specifications

Same machine as above (ensietuhp06).

### Performance curves (mean ± 95% CI)

![Performance curves](figures_3Threads/performance_curves.png)

### Speedup relative to sequential (with propagated 95% CI)

![Speedup](figures_3Threads/speedup.png)

### Variability across 30 repetitions

![Boxplot variability](figures_3Threads/boxplot_variability.png)

### Key observations

Reducing `THREAD_LEVEL` from 10 to 3 (at most 8 threads) significantly reduces
thread creation overhead. The parallel version becomes faster than sequential
starting around 500,000 elements. However, the original size range was not
sufficient to fully observe the performance gains at larger scales, which
motivated the next experiment.

Sizes used: `100, 500, 1000, 5000, 10000, 50000, 100000, 500000, 1000000, 2000000`

---

## Results — Chayma SADIKI (THREAD_LEVEL = 3, sizes up to 10,000,000)

### Machine specifications

Same machine as above (ensietuhp06).

Sizes used: `50000, 100000, 500000, 1000000, 2500000, 5000000, 7500000, 10000000`

### Performance curves (mean ± 95% CI)

![Performance curves](figures_3Threads_size10000000/performance_curves.png)

### Speedup relative to sequential (with propagated 95% CI)

![Speedup](figures_3Threads_size10000000/speedup.png)

### Variability across 30 repetitions

![Boxplot variability](figures_3Threads_size10000000/boxplot_variability.png)

### Key observations

- With `THREAD_LEVEL = 3` (at most 8 threads) and array sizes up to 10M, the
  **parallel quicksort becomes faster than sequential** starting around
  500,000–1,000,000 elements, reaching a speedup of approximately **1.16× at 10M**.
- The **three methods are nearly indistinguishable for small sizes** (50,000–500,000):
  all three curves overlap and confidence intervals are tight.
- The **built-in libc qsort is consistently ~9% slower than sequential** across
  all tested sizes (speedup ≈ 0.91), a stable and statistically significant gap.
- The **crossover point** lies between 500,000 and 1,000,000 elements, and the
  speedup continues to grow steadily beyond that.
- Execution times are **highly reproducible** across all 30 repetitions.
- Compared to `THREAD_LEVEL = 10`, this confirms that **tuning the thread level
  is critical**: too many threads eliminates any parallel advantage, while a
  moderate level allows parallelism to pay off at large array sizes.

---