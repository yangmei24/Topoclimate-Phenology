# ========= 1. Environment setup & package loading =========
setwd("D:/Z-data/test/JGFC/test2/class/aspect_reclass")  # Working directory

packages <- c("piecewiseSEM", "readr", "DiagrammeR")
lapply(packages, library, character.only = TRUE)

# ========= 2. Data import & standardization =========
data_set <- read_csv("byangp.csv")  # Example: semi-sunny-slope (aspect) samples
data_set <- na.omit(data_set)
df <- as.data.frame(scale(data_set))  # Standardize all variables (aspect, tmp, pre, los)

# ========= 3. Define the PSEM model (aspect -> climate -> phenology) =========
model_psem <- psem(
    lm(tmp ~ aspect, data = df),
    lm(pre ~ aspect + tmp, data = df),
    lm(los ~ aspect + tmp + pre, data = df)
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

aspect_tmp <- as.numeric(coef_extract("tmp", "aspect"))
aspect_pre <- as.numeric(coef_extract("pre", "aspect"))
tmp_pre    <- as.numeric(coef_extract("pre", "tmp"))
aspect_los <- as.numeric(coef_extract("los", "aspect"))
tmp_los    <- as.numeric(coef_extract("los", "tmp"))
pre_los    <- as.numeric(coef_extract("los", "pre"))

# ========= 6. Effect decomposition =========
# Indirect path 1: aspect -> tmp -> los
indirect1 <- aspect_tmp * tmp_los

# Indirect path 2: aspect -> pre -> los
indirect2 <- aspect_pre * pre_los

# Total effect = indirect1 + indirect2 + direct (aspect -> los)
total_effect <- indirect1 + indirect2 + aspect_los

# ========= 7. Bar chart (effects) =========
heights <- rbind(
    "Indirect effect 1" = indirect1,
    "Indirect effect 2" = indirect2,
    "Direct effect"     = aspect_los,
    "Total effect"      = total_effect
)

cols <- c("#8CB3D9", "#F4B183", "#90EE90", "#D9D9D9")

bp <- barplot(
    heights,
    beside    = TRUE,
    col       = cols,
    ylim      = c(min(0, heights) - 0.05, max(heights) + 0.05),
    names.arg = "Semi-sunny slope",
    ylab      = "Standardized effect",
    main      = "Standardized effect decomposition of aspect on LOS (semi-sunny slope)"
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
  
  aspect [label = 'Aspect']
  tmp    [label = 'Temperature']
  pre    [label = 'Precipitation']
  los    [label = 'LOS']
  
  aspect -> tmp [label = '%s']
  aspect -> pre [label = '%s']
  tmp    -> pre [label = '%s']
  aspect -> los [label = '%s']
  tmp    -> los [label = '%s']
  pre    -> los [label = '%s']
}
",
edge_label(aspect_tmp),
edge_label(aspect_pre),
edge_label(tmp_pre),
edge_label(aspect_los),
edge_label(tmp_los),
edge_label(pre_los)
))
