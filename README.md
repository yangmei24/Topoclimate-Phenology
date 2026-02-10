# Topoclimate-Phenology
A transferable analytical framework for investigating topography-structured climate–phenology relationships using remote sensing and interpretable machine learning. 
Code repository for analyzing topography-structured climate–vegetation phenology relationships
This repository contains the core scripts used in the study:
“Topography restructures climate–phenology relationships across the Loess Plateau”
The code supports the main analytical steps of the study, including vegetation phenology extraction, climate–phenology analysis, and topography-based comparative assessment.
This repository is not designed as a fully automated or standalone workflow, and it does not include input data or parameter tuning for direct reproduction.
Structure
Topoclimate-Phenology/
├── scripts/
│   ├── phenology/
│   │   └── phenology_kndvi.m          # SOS/EOS extraction from kNDVI
│   │
│   ├── trend_analysis/
│   │   ├── mk.m                       # Mann–Kendall trend test
│   │   └── sen.m                      # Sen’s slope estimation
│   │
│   ├── modeling/
│   │   ├── XGBoost_SHAP.py             # Climate–phenology modeling (XGBoost + SHAP)
│   │   └── VIF.py                     # Multicollinearity diagnosis (VIF)
│   │
│   ├── sem/
│   │   └── SEM.R                      # Structural equation modeling
│   │
│   └── classification/
│       ├── Elevation_classification.R # Elevation stratification
│       ├── Slope_classification.R     # Slope stratification
│       └── Aspect_classification.R    # Aspect stratification
│
└── README.md
Data Availability
Input data (remote sensing, climate, and topographic datasets) are not included in this repository due to data volume and licensing constraints.
All data sources and preprocessing procedures are described in detail in the associated manuscript.
This repository is provided for academic reference purposes only.
