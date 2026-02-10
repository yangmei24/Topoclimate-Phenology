# ========= 1. Environment setup & package loading =========
setwd("D:/Z-data/test/JGFC/test2/class/dem_reclass")  # Working directory

packages <- c("piecewiseSEM", "readr", "DiagrammeR")
lapply(packages, library, character.only = TRUE)

# ========= 2. Data import & standardization =========
data_set <- read_csv("los_4000.CSV")  # Samples with elevation <= 1000 m
data_set <- na.omit(data_set)
df <- as.data.frame(scale(data_set))

# ========= 3. Define the PSEM model (response: los) =========
model_psem <- psem(
    lm(tmp ~ elevation, data = df),
    lm(pre ~ elevation + tmp, data = df),
    lm(los ~ elevation + tmp + pre, data = df)
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

elev_tmp <- as.numeric(coef_extract("tmp", "elevation"))
elev_pre <- as.numeric(coef_extract("pre", "elevation"))
tmp_pre  <- as.numeric(coef_extract("pre", "tmp"))
elev_los <- as.numeric(coef_extract("los", "elevation"))
tmp_los  <- as.numeric(coef_extract("los", "tmp"))
pre_los  <- as.numeric(coef_extract("los", "pre"))

# ========= 6. Effect decomposition =========
# Indirect path 1: elevation -> tmp -> los
indirect1 <- elev_tmp * tmp_los

# Indirect path 2: elevation -> pre -> los
indirect2 <- elev_pre * pre_los

# Total effect = indirect1 + indirect2 + direct (elevation -> los)
total_effect <- indirect1 + indirect2 + elev_los

# ========= 7. Bar chart (effects) =========
heights <- rbind(
    "Indirect effect 1" = indirect1,
    "Indirect effect 2" = indirect2,
    "Direct effect"     = elev_los,
    "Total effect"      = total_effect
)

cols <- c("#8CB3D9", "#F4B183", "#90EE90", "#D9D9D9")

bp <- barplot(
    heights,
    beside    = TRUE,
    col       = cols,
    ylim      = c(min(0, heights) - 0.05, max(heights) + 0.05),
    names.arg = "Elevation <= 1000 m",
    ylab      = "Standardized effect",
    main      = "Standardized effect decomposition of elevation on LOS (<= 1000 m)"
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
  
  elevation [label = 'Elevation']
  tmp       [label = 'Temperature']
  pre       [label = 'Precipitation']
  los       [label = 'LOS']
  
  elevation -> tmp [label = '%s']
  elevation -> pre [label = '%s']
  tmp       -> pre [label = '%s']
  elevation -> los [label = '%s']
  tmp       -> los [label = '%s']
  pre       -> los [label = '%s']
}
",
edge_label(elev_tmp),
edge_label(elev_pre),
edge_label(tmp_pre),
edge_label(elev_los),
edge_label(tmp_los),
edge_label(pre_los)
))
