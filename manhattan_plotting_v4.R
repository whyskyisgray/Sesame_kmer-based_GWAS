# Load necessary libraries
library(data.table)
library(ggplot2)

# Read command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5) {
  stop("Please provide an input file, output file, y limits, and .fai file")
}

input_file <- args[1]
output_file <- args[2]
ylim_lower <- as.numeric(args[3])
ylim_upper <- as.numeric(args[4])
fai_file <- args[5]

# Load data from the input file
data <- fread(input_file, sep = "\t", header = TRUE)

# Read the .fai file
fai_data <- fread(fai_file, sep = "\t", header = FALSE)
colnames(fai_data) <- c("chromosome", "length", "other1", "other2", "other3")

# Create a complete list of chromosomes with evenly distributed positions
backbone_data <- fai_data[, .(position = seq(1, length, by = 1e5)), by = .(chromosome)]  # 1Mb intervals
backbone_data[, pvalue := NA]
backbone_data[, category := NA]
backbone_data[, color_category := NA]

# Merge backbone data with actual data
all_data <- rbind(backbone_data, data, fill = TRUE)

# Calculate log_pvalue for non-placeholder rows
all_data[!is.na(pvalue), log_pvalue := -log10(pvalue + 1e-300)]

# Ensure that all chromosomes are displayed, even if no data
all_data[is.na(log_pvalue), log_pvalue := 0]

# Generate the Manhattan plot
manhattan_plot <- ggplot(all_data, aes(x = position, y = log_pvalue)) +
  geom_point(data = subset(all_data, !is.na(pvalue)), aes(shape = category, color = color_category, group = chromosome), alpha = 0.6, size = 2) +
  geom_point(data = subset(all_data, is.na(pvalue)), shape = 1, color = "grey", alpha = 0, size = 2.5) + # Placeholder points
  geom_hline(yintercept = 7.6, color = "purple4", linetype = "dashed", linewidth = 0.5) +
  geom_hline(yintercept = 6.3, color = "orangered", linetype = "dashed", linewidth = 0.5) +
  scale_shape_manual(values = c("A" = 0, "B" = 1, "C" = 2, "D" = 3, "E" = 4, "F" = 5)) +
  scale_color_identity() +
  scale_y_continuous(breaks = seq(from = ylim_lower, to = ylim_upper, by = 2.5),
                     limits = c(ylim_lower, ylim_upper),
                     expand = expansion(mult = c(0.02, 0.1))) +
  scale_x_continuous(expand = expansion(0.04, 0.04)) +
  facet_grid(cols = vars(chromosome), scales = "free_x", space = "free_x", switch = "x") +
  theme_minimal() +
  theme(
    plot.background = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.line.x = element_line(colour = "black", linewidth = 1),
    axis.line.y.left = element_line(colour = "black", linewidth = 1),
    axis.text.x = element_blank(),
    axis.text.y = element_text(size = 20),
    axis.ticks.y = element_line(colour = "black", linewidth = 1),
    axis.ticks.length = unit(0.5, "cm"),
    axis.title.x = element_blank(),
    axis.title.y = element_text(size = 20),
    strip.placement = "outside",
    strip.background = element_blank(),
    strip.text.x.bottom = element_text(size = 20)
  ) +
  labs(y = "-log10(P-value)", title = input_file)

# Save the plot as a PDF
ggsave(output_file, plot = manhattan_plot, width = 15, device = "pdf")
