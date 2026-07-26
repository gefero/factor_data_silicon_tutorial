library(tidyverse)

prpt1 <- read_csv('./outputs_for_analysis/Q130_distributions_prompt_1.csv') %>%
  mutate(prompt = "V1")
prpt2 <- read_csv('./outputs_for_analysis/Q130_distributions_prompt_2.csv') %>%
  mutate(prompt = "V2")
empirical <- read_csv('./outputs_for_analysis/Q130_distributions_empirical.csv') %>%
  mutate(prompt = "empirical")

df <- bind_rows(empirical, prpt1, prpt2)
df <-df %>%
  mutate(size = case_when(
    size == "-" ~ "empirical",
    size == "4o" ~ "400B",
    TRUE ~ size
  )) %>%
  mutate(size = factor(size, levels = c("20B", "120B", "400B","empirical")))

df %>%
  filter(prompt %in% c("empirical", "V1")) %>%
  filter(category != "invalid/no answer") %>%
  ggplot() +
    geom_col(aes(x=category, y=proportion, fill=size)) +
    theme_minimal() + 
    theme(axis.text.x = element_text(hjust = 1, size=6)) +
    scale_fill_viridis_d() +
    scale_x_discrete(labels = scales::label_wrap(11)) +
    labs(x="Response",
         y="Prop.",
         fill="Type",
         title = "Prompt V1") +  
    facet_wrap(~country+model+size)

ggsave('./figures_R/MPIDR_fig1a.png', width = 14, height = 6)

df %>%
  filter(prompt %in% c("empirical", "V2")) %>%
  filter(category != "invalid/no answer") %>%
  ggplot() +
  geom_col(aes(x=category, y=proportion, fill=size)) +
  theme_minimal() + 
  theme(axis.text.x = element_text(hjust = 1, size=6)) +
  scale_fill_viridis_d() +
  scale_x_discrete(labels = scales::label_wrap(11)) +
  labs(x="Response",
       y="Prop.",
       fill="Type",
       title = "Prompt V2") +  
  facet_wrap(~country+model+size)

ggsave('./figures_R/MPIDR_fig1b.png', width = 14, height = 6)


metrics <- read_csv('./results/metrics.csv')

library(tidyverse)

# --- data --------------------------------------------------------------
metrics <- metrics %>%
  mutate(
    diff   = JSD_hi - JSD_lo,
    prompt = factor(prompt)
  )

# shared y-axis ordering (model then prompt) — identical across all countries
y_levels <- metrics %>%
  distinct(model, prompt) %>%
  arrange(model, prompt) %>%
  mutate(y_label = paste(model, prompt, sep = " - ")) %>%
  pull(y_label)

metrics <- metrics %>%
  mutate(
    y_label = paste(model, prompt, sep = " - "),
    y_label = factor(y_label, levels = rev(y_levels))
  )

col_lo <- "#4B0082"   # deep purple, low end
col_hi <- "#1B9E77"   # teal, high end

# --- plot ------------------------------------------------------------
p <- ggplot(metrics, aes(y = y_label)) +
  
  geom_segment(aes(x = JSD_lo, xend = JSD_hi, yend = y_label),
               color = "grey85", linewidth = 3, lineend = "round") +
  
  geom_text(aes(x = (JSD_lo + JSD_hi) / 2,
                label = sprintf("%.3f", diff)),
            size = 2.8, color = "grey40") +
  
  geom_point(aes(x = JSD_lo), color = col_lo, size = 3) +
  geom_point(aes(x = JSD_hi), color = col_hi, size = 3) +
  
  facet_wrap(~ country, ncol = 3, scales = "fixed") +
  
  labs(
    title = "JSD by Model and Prompt",
    x = "JSD",
    y = NULL
  ) +
  
  theme_minimal(base_size = 12, base_family = "sans") +
  theme(
    # panel & background
    panel.background   = element_blank(),
    plot.background    = element_blank(),
    panel.border       = element_blank(),
    panel.spacing      = unit(1.2, "lines"),
    
    # gridlines: keep only faint horizontal
    panel.grid.major.x = element_blank(),
    panel.grid.minor    = element_blank(),
    panel.grid.major.y  = element_line(color = "grey93", linewidth = 0.3),
    
    # axes
    axis.line.x   = element_line(color = "grey40", linewidth = 0.3),
    axis.ticks    = element_blank(),
    axis.text.y   = element_text(size = 9.5, color = "grey20"),
    axis.text.x   = element_text(size = 9, color = "grey40"),
    axis.title.x  = element_text(size = 11, color = "grey30", margin = margin(t = 8)),
    
    # facet strips: plain text, no boxes
    strip.background = element_blank(),
    strip.text        = element_text(size = 11, color = "grey20", face = "plain"),
    
    # title
    plot.title    = element_text(size = 16, color = "grey10", face = "plain",
                                 margin = margin(b = 14)),
    plot.margin   = margin(10, 10, 10, 10)
  )

p

