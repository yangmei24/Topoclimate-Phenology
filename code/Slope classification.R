# ========= 1. Environment setup & package loading =========
setwd("D:/Z-data/test/JGFC/test2/class/slope_reclass")  # Working directory

packages <- c("piecewiseSEM", "readr", "DiagrammeR")
lapply(packages, library, character.only = TRUE)

# ========= 2. Data import & standardization =========
data_set <- read_csv("≥9.csv")  # Example: slope-class samples (contains slope, tmp, pre, los)
data_set <- na.omit(data_set)
df <- as.data.frame(scale(data_set))  # Standardize variables

# ========= 3. Define the PSEM model (slope -> climate -> phenology) =========
model_psem <- psem(
    lm(tmp ~ slope, data = df),
    lm(pre ~ slope + tmp, data = df),
    lm(los ~ slope + tmp + pre, data = df)
)

# ========= 4. Extract and print R² =========
r_squared <- rsquared(model_psem)
cat("R² for endogenous variables:\n")
print(r_squared)

# ========= 5. Extract path coefficients =========
coefs_tbl <- coefs(model_psem)

coef_extract <- function(response, predictor) {
    coefs_tbl[coefs_tbl$Response == response & coefs_tbl$Predictor == predictor, "Estimate"]
}

slope_tmp <- as.numeric(coef_extract("tmp", "slope"))
slope_pre <- as.numeric(coef_extract("pre", "slope"))
tmp_pre   <- as.numeric(coef_extract("pre", "tmp"))
slope_los <- as.numeric(coef_extract("los", "slope"))
tmp_los   <- as.numeric(coef_extract("los", "tmp"))
pre_los   <- as.numeric(coef_extract("los", "pre"))

# ========= 6. Effect decomposition =========
# Indirect path 1: slope -> tmp -> los
indirect1 <- slope_tmp * tmp_los

# Indirect path 2: slope -> pre -> los
indirect2 <- slope_pre * pre_los

# Total effect = indirect1 + indirect2 + direct (slope -> los)
total_effect <- indirect1 + indirect2 + slope_los

# ========= 7. Bar chart (effects) =========
heights <- rbind(
    "Indirect effect 1" = indirect1,
    "Indirect effect 2" = indirect2,
    "Direct effect"     = slope_los,
    "Total effect"      = total_effect
)

cols <- c("#8CB3D9", "#F4B183", "#90EE90", "#D9D9D9")

bp <- barplot(
    heights,
    beside    = TRUE,
    col       = cols,
    ylim      = c(min(0, heights) - 0.05, max(heights) + 0.05),
    names.arg = ">= 9°",
    ylab      = "Standardized effect",
    main      = "Standardized effect decomposition of slope on LOS (>= 9°)"
)

text(bp, heights + 0.02 * sign(heights), labels = round(heights, 3), cex = 0.9)

legend(
    "topright",
    legend = rownames(heights),
    fill   = cols,
    bty    = "n",
    cex    = 0.9
)

# ========= 8. Path diagram =========
edge_label <- function(val) paste0(round(val, 2))

grViz(sprintf("
digraph SEM {
  graph [layout = dot, rankdir = LR]
  node [shape = box, style = filled, color = black, fillcolor = lightgray]
  
  slope [label = 'Slope']
  tmp   [label = 'Temperature']
  pre   [label = 'Precipitation']
  los   [label = 'LOS']
  
  slope -> tmp [label = '%s']
  slope -> pre [label = '%s']
  tmp   -> pre [label = '%s']
  slope -> los [label = '%s']
  tmp   -> los [label = '%s']
  pre   -> los [label = '%s']
}
",
edge_label(slope_tmp),
edge_label(slope_pre),
edge_label(tmp_pre),
edge_label(slope_los),
edge_label(tmp_los),
edge_label(pre_los)
))
