###############################
# 1. Load packages, read data, fit the model
###############################
library(lavaan)
library(dplyr)

# Read and clean data
data <- read.csv("D:/Z-data/test3/jgfc/los_合并.csv")  # NOTE: keep your local path as-is
data <- na.omit(data)

# Define the SEM
model <- '
  tmp ~ slope + aspect + dem
  pre ~ slope + aspect + dem
  los ~ tmp + pre
  los ~ slope + aspect + dem
'

# Fit
fit <- sem(model, data = data)

#####################################
# 2. Standardized coefficients and indirect effects
#####################################
std_est <- parameterEstimates(fit, standardized = TRUE) %>%
    filter(op == "~") %>%
    select(lhs, rhs, std.all)

# Helper: fetch the standardized coefficient for a specific path (lhs ~ rhs)
get_coef <- function(lhs, rhs) {
    std_est$std.all[std_est$lhs == lhs & std_est$rhs == rhs]
}

# Compute two indirect paths and the total indirect effect:
# from_var -> tmp -> los  and  from_var -> pre -> los
get_indirect <- function(from_var) {
    a1 <- get_coef("tmp", from_var)
    b1 <- get_coef("los", "tmp")
    a2 <- get_coef("pre", from_var)
    b2 <- get_coef("los", "pre")
    c(
        indirect1 = a1 * b1,
        indirect2 = a2 * b2,
        total     = a1 * b1 + a2 * b2
    )
}

slope_eff  <- get_indirect("slope")
aspect_eff <- get_indirect("aspect")
dem_eff    <- get_indirect("dem")

#####################################
# 3. Fig. 1: Side-by-side bar chart (indirect effects)
#####################################
effect_mat <- matrix(
    c(slope_eff, aspect_eff, dem_eff),
    nrow = 3, byrow = FALSE,
    dimnames = list(
        c("Indirect effect 1 (via tmp)", "Indirect effect 2 (via pre)", "Total indirect effect"),
        c("Slope", "Aspect", "Elevation")
    )
)

barplot(
    effect_mat,
    beside      = TRUE,
    col         = c("pink", "lightblue", "lightgreen"),
    ylim        = c(min(effect_mat), max(effect_mat) * 1.1),
    ylab        = "Standardized effect size",
    main        = "Indirect effects of slope, aspect, and elevation on LOS",
    legend.text = rownames(effect_mat),
    args.legend = list(x = "topright", inset = 0.02)
)

#############################################
# 4. Fig. 2: Path diagram (topography -> climate -> LOS)
#############################################
# --- Prepare coefficients (rounded for display) ---
coef_list <- list(
    slope_tmp   = round(get_coef("tmp", "slope"), 3),
    slope_pre   = round(get_coef("pre", "slope"), 3),
    aspect_tmp  = round(get_coef("tmp", "aspect"), 3),
    aspect_pre  = round(get_coef("pre", "aspect"), 3),
    dem_tmp     = round(get_coef("tmp", "dem"), 3),
    dem_pre     = round(get_coef("pre", "dem"), 3),
    tmp_los     = round(get_coef("los", "tmp"), 3),
    pre_los     = round(get_coef("los", "pre"), 3)
)

# --- Canvas ---
plot(
    c(0, 10), c(0, 10),
    type = "n", axes = FALSE, xlab = "", ylab = "",
    main = "Path diagram: indirect regulation of LOS via temperature and precipitation"
)

# --- Draw nodes ---
# Left: topographic factors
left_nodes <- c("Slope", "Aspect", "Elevation")
left_y     <- c(8, 5, 2)
for (i in 1:3) {
    rect(0.2, left_y[i] - 0.6, 1.8, left_y[i] + 0.6, col = "lightgrey", border = "black")
    text(1, left_y[i], left_nodes[i], cex = 0.9)
}

# Middle: climate factors
mid_nodes <- c("Temperature", "Precipitation")
mid_y     <- c(7, 3)
for (i in 1:2) {
    rect(4.2, mid_y[i] - 0.6, 5.8, mid_y[i] + 0.6, col = "lightyellow", border = "black")
    text(5, mid_y[i], mid_nodes[i], cex = 0.9)
}

# Right: LOS
rect(8.2, 4.4, 9.8, 5.6, col = "lightblue", border = "black")
text(9, 5, "LOS", cex = 1)

# --- Arrows and coefficient labels ---
arrow_len <- 0.1

# Topography -> Temperature / Precipitation
for (i in 1:3) {
    # -> Temperature
    arrows(1.8, left_y[i], 4.2, 7, length = arrow_len)
    text(
        3.1, (left_y[i] + 7) / 2 + 0.3,
        coef_list[[c("slope_tmp", "aspect_tmp", "dem_tmp")[i]]],
        cex = 0.75
    )
    
    # -> Precipitation
    arrows(1.8, left_y[i], 4.2, 3, length = arrow_len)
    text(
        3.1, (left_y[i] + 3) / 2 - 0.3,
        coef_list[[c("slope_pre", "aspect_pre", "dem_pre")[i]]],
        cex = 0.75
    )
}

# Temperature / Precipitation -> LOS
arrows(5.8, 7, 8.2, 5, length = arrow_len)
text(7, 6.2, coef_list$tmp_los, cex = 0.8)

arrows(5.8, 3, 8.2, 5, length = arrow_len)
text(7, 4.2, coef_list$pre_los, cex = 0.8)

#############################################
# 5. (Optional) Print numeric results for checking
#############################################
cat("Indirect effects (slope):\n");  print(slope_eff)
cat("Indirect effects (aspect):\n"); print(aspect_eff)
cat("Indirect effects (elevation):\n"); print(dem_eff)
