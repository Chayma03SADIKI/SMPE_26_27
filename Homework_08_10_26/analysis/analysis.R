library(ggplot2)
library(dplyr)
library(tidyr)

# ============================================================
# Load config (results_dir and figures_dir)
# Edit config.R at project root to change paths
# ============================================================
if (file.exists("../config.R")) {
  source("../config.R")
} else {
  results_dir <- "../results"
  figures_dir <- "../figures"
}

# 1. Load data
seq_df <- read.csv(file.path(results_dir, "sequential.csv"))
par_df <- read.csv(file.path(results_dir, "parallel.csv"))
lib_df <- read.csv(file.path(results_dir, "libc.csv"))

seq_df$method <- "Sequential"
par_df$method <- "Parallel"
lib_df$method <- "Built-in (libc)"

df <- rbind(seq_df, par_df, lib_df)
df$method <- factor(df$method, levels = c("Sequential", "Parallel", "Built-in (libc)"))

# 2. Summary statistics (mean + 95% CI via t-distribution)
summary_df <- df %>%
  group_by(size, method) %>%
  summarise(
    n        = n(),
    mean     = mean(time_sec),
    sd       = sd(time_sec),
    se       = sd / sqrt(n),
    ci_lower = mean - qt(0.975, df = n - 1) * se,
    ci_upper = mean + qt(0.975, df = n - 1) * se,
    .groups  = "drop"
  )

# 3. Performance curves
p1 <- ggplot(summary_df, aes(x = size, y = mean, color = method, fill = method)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
  scale_x_log10(
    breaks = unique(df$size),
    labels = scales::comma
  ) +
  scale_y_log10(labels = scales::scientific) +
  scale_color_manual(values = c(
    "Sequential"      = "#E63946",
    "Parallel"        = "#457B9D",
    "Built-in (libc)" = "#2D6A4F"
  )) +
  scale_fill_manual(values = c(
    "Sequential"      = "#E63946",
    "Parallel"        = "#457B9D",
    "Built-in (libc)" = "#2D6A4F"
  )) +
  labs(
    title    = "Quicksort performance: sequential vs parallel vs built-in",
    subtitle = "Mean execution time with 95% confidence interval — log/log scale",
    x        = "Array size (log scale)",
    y        = "Execution time in seconds (log scale)",
    color    = "Method",
    fill     = "Method",
    caption  = paste("Machine:", Sys.info()["nodename"], "— Date:", Sys.Date())
  ) +
  theme_bw(base_size = 12) +
  theme(
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(color = "grey40", size = 10)
  )

ggsave(file.path(figures_dir, "performance_curves.png"), plot = p1, width = 10, height = 6, dpi = 150)

# 4. Speedup relative to sequential (delta method for CI)
wide_df <- summary_df %>%
  select(size, method, mean, se) %>%
  pivot_wider(names_from = method, values_from = c(mean, se))

names(wide_df) <- gsub(" ", "_", names(wide_df))
names(wide_df) <- gsub("[()]", "", names(wide_df))

speedup_df <- wide_df %>%
  mutate(
    speedup_parallel = mean_Sequential / mean_Parallel,
    speedup_libc     = mean_Sequential / `mean_Built-in_libc`,

    se_speedup_parallel = speedup_parallel * sqrt(
      (se_Sequential / mean_Sequential)^2 +
      (se_Parallel   / mean_Parallel)^2
    ),
    se_speedup_libc = speedup_libc * sqrt(
      (se_Sequential      / mean_Sequential)^2 +
      (`se_Built-in_libc` / `mean_Built-in_libc`)^2
    ),

    ci_lower_parallel = speedup_parallel - qt(0.975, df = 29) * se_speedup_parallel,
    ci_upper_parallel = speedup_parallel + qt(0.975, df = 29) * se_speedup_parallel,
    ci_lower_libc     = speedup_libc     - qt(0.975, df = 29) * se_speedup_libc,
    ci_upper_libc     = speedup_libc     + qt(0.975, df = 29) * se_speedup_libc
  )

speedup_long <- speedup_df %>%
  select(size,
         speedup_parallel, ci_lower_parallel, ci_upper_parallel,
         speedup_libc,     ci_lower_libc,     ci_upper_libc) %>%
  pivot_longer(
    cols          = -size,
    names_to      = c(".value", "comparison"),
    names_pattern = "(.+)_(parallel|libc)"
  ) %>%
  mutate(comparison = recode(comparison,
    "parallel" = "Sequential / Parallel",
    "libc"     = "Sequential / Built-in (libc)"
  ))

p2 <- ggplot(speedup_long, aes(x = size, y = speedup, color = comparison, fill = comparison)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "grey40") +
  annotate("text", x = min(df$size) * 1.5, y = 1.05,
           label = "speedup = 1 (no gain)", color = "grey40", size = 3) +
  scale_x_log10(
    breaks = unique(df$size),
    labels = scales::comma
  ) +
  scale_color_manual(values = c(
    "Sequential / Parallel"        = "#457B9D",
    "Sequential / Built-in (libc)" = "#2D6A4F"
  )) +
  scale_fill_manual(values = c(
    "Sequential / Parallel"        = "#457B9D",
    "Sequential / Built-in (libc)" = "#2D6A4F"
  )) +
  labs(
    title    = "Speedup relative to sequential quicksort",
    subtitle = "Values > 1 mean the alternative is faster — shaded area: 95% CI (delta method)",
    x        = "Array size (log scale)",
    y        = "Speedup (sequential time / method time)",
    color    = NULL,
    fill     = NULL,
    caption  = paste("Machine:", Sys.info()["nodename"], "— Date:", Sys.Date())
  ) +
  theme_bw(base_size = 12) +
  theme(
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(color = "grey40", size = 10)
  )

ggsave(file.path(figures_dir, "speedup.png"), plot = p2, width = 10, height = 5, dpi = 150)

# 5. Boxplot — variability across repetitions
p3 <- ggplot(df, aes(x = factor(size), y = time_sec, fill = method)) +
  geom_boxplot(outlier.size = 0.8, linewidth = 0.4) +
  scale_fill_manual(values = c(
    "Sequential"      = "#E63946",
    "Parallel"        = "#457B9D",
    "Built-in (libc)" = "#2D6A4F"
  )) +
  scale_y_log10(labels = scales::scientific) +
  labs(
    title   = "Distribution of execution times across repetitions",
    x       = "Array size",
    y       = "Execution time in seconds (log scale)",
    fill    = "Method",
    caption = paste("Machine:", Sys.info()["nodename"], "— Date:", Sys.Date())
  ) +
  theme_bw(base_size = 11) +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1),
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold")
  )

ggsave(file.path(figures_dir, "boxplot_variability.png"), plot = p3, width = 11, height = 6, dpi = 150)

message("Done — figures saved to ", figures_dir)