library(ggplot2)
library(scales)

# ============================================================
# FIGURE 1 — Slide 29: Total Brand Sales in Europe
# ============================================================

df29 <- read.csv("data_slide29.csv")

ggplot(df29, aes(x = year, y = sales, color = brand, linetype = brand)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.8) +
  # Direct labels at end of curves
  geom_text(
    data = subset(df29, year == 2013),
    aes(label = brand),
    hjust = -0.15,
    size = 3.2,
    show.legend = FALSE
  ) +
  scale_color_manual(values = c(
    "Audi"          = "#E63946",
    "BMW"           = "#457B9D",
    "Mercedes"      = "#2D2D2D"
  )) +
  scale_linetype_manual(values = c(
    "Audi"          = "solid",
    "BMW"           = "dashed",
    "Mercedes"      = "dotted"
  )) +
  scale_y_continuous(
    labels = label_comma(),
    limits = c(400000, 800000)
  ) +
  scale_x_continuous(
    breaks = seq(1997, 2013, by = 2),
    expand = expansion(mult = c(0.02, 0.15))
  ) +
  labs(
    title    = "Total brand sales in Europe (1997–2013)",
    subtitle = "Audi, BMW and Mercedes-Benz annual vehicle sales",
    x        = "Year",
    y        = "Number of vehicles sold",
    caption  = "Source: estimated from slide 29 — What a nice picture! (Arnaud, Legrand, Vincent 2022)"
  ) +
  theme_bw(base_size = 12) +
  theme(
    legend.position  = "none",
    panel.grid.minor = element_blank(),
    plot.caption     = element_text(size = 8, color = "grey50"),
    plot.title       = element_text(face = "bold")
  )


# ============================================================
# FIGURE 2 — Slide 33: Juvenile Drug Arrests vs Kids Killed
# ============================================================

df33 <- read.csv("data_slide33.csv")

# Reshape to long format for faceting
df33_long <- data.frame(
  year  = rep(df33$year, 2),
  value = c(df33$juvenile_drug_arrests, df33$kids_killed_by_parent),
  variable = c(
    rep("Juvenile drug arrests (US)", nrow(df33)),
    rep("Kids killed by a parent (US)", nrow(df33))
  )
)

ggplot(df33_long, aes(x = year, y = value)) +
  geom_line(color = "#457B9D", linewidth = 0.9) +
  geom_point(color = "#457B9D", size = 2) +
  facet_wrap(
    ~ variable,
    scales = "free_y",
    ncol   = 1
  ) +
  scale_x_continuous(breaks = seq(1999, 2009, by = 1)) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Juvenile drug arrests and child homicides by parents (US, 1999–2009)",
    subtitle = "Note: these two variables are displayed separately — no causal link is established",
    x        = "Year",
    y        = NULL,
    caption  = "Source: estimated from slide 33 — What a nice picture! (Arnaud, Legrand, Vincent 2022)"
  ) +
  theme_bw(base_size = 12) +
  theme(
    strip.text       = element_text(face = "bold", size = 10),
    strip.background = element_rect(fill = "#EAF3FB"),
    panel.grid.minor = element_blank(),
    plot.subtitle    = element_text(color = "#B03A2E", size = 9),
    plot.caption     = element_text(size = 8, color = "grey50"),
    plot.title       = element_text(face = "bold")
  )


# ============================================================
# FIGURE 3 — Slide 35: Natural Disasters Worldwide (1980–2017)
# ============================================================

df35 <- read.csv("data_slide35.csv")

ggplot(df35, aes(x = year, y = nb_disasters)) +
  geom_area(fill = "#AED6F1", alpha = 0.4) +
  geom_line(color = "#2471A3", linewidth = 0.9) +
  geom_point(color = "#2471A3", size = 1.5) +
  scale_x_continuous(breaks = seq(1980, 2017, by = 5)) +
  scale_y_continuous(
    limits = c(0, 850),
    breaks = seq(0, 800, by = 200)
  ) +
  labs(
    title    = "Number of natural disasters worldwide (1980–2017)",
    subtitle = "Annual count — definition of 'natural disaster' varies by source",
    x        = "Year",
    y        = "Number of disasters",
    caption  = "Source: Munich Re, via slide 35 — What a nice picture! (Arnaud, Legrand, Vincent 2022)"
  ) +
  theme_bw(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.caption     = element_text(size = 8, color = "grey50"),
    plot.subtitle    = element_text(color = "grey40", size = 9),
    plot.title       = element_text(face = "bold")
  )
