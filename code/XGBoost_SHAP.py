import os
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import shap
import xgboost as xgb
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
from tqdm import tqdm
import numpy as np

plt.rcParams["font.family"] = ["Times New Roman"]

# ==== Path settings ====
csv_path = r"H:\SHAP\merged.csv"
output_dir = r"H:\SHAP\EOS"
os.makedirs(output_dir, exist_ok=True)

# ==== 1. Load data ====
print("📥 Loading data...")
df = pd.read_csv(csv_path)

feature_cols = ["Dtr", "Pre", "Tmp", "Vpd", "Soil"]
target_col = "EOS"

X = df[feature_cols]
y = df[target_col]

# ==== 2. Split training and testing sets ====
print("✂️ Splitting training and testing sets...")
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# ==== 3. Model training ====
print("🏋️‍♂️ Training XGBoost model...")
model = xgb.XGBRegressor(
    n_estimators=100,
    max_depth=6,
    learning_rate=0.05,
    subsample=0.8,
    colsample_bytree=0.8,
    random_state=42
)
model.fit(X_train, y_train)

# ==== 4. Model prediction ====
print("🔮 Predicting test set...")
y_pred = model.predict(X_test)

# ==== 5. SHAP analysis ====
print("🧠 Computing SHAP values...")
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X)

# ==== 6. Visualization ====

# 6.1 Observed vs Predicted
r2 = r2_score(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

plt.figure(figsize=(6, 6))
sns.scatterplot(x=y_test, y=y_pred, alpha=0.3)
plt.plot([y.min(), y.max()], [y.min(), y.max()], 'r--')
plt.xlabel("Observed EOS")
plt.ylabel("Predicted EOS")
plt.title("Observed vs Predicted")
plt.text(
    0.05, 0.95, f"R² = {r2:.4f}",
    fontsize=12, ha='left', va='top',
    transform=plt.gca().transAxes
)
plt.text(
    0.05, 0.90, f"RMSE = {rmse:.4f}",
    fontsize=12, ha='left', va='top',
    transform=plt.gca().transAxes
)
plt.grid(False)
plt.tight_layout()
plt.savefig(
    os.path.join(output_dir, "scatter_observed_vs_predicted_with_R2_EOS.jpg"),
    dpi=300
)
plt.close()

# 6.2 SHAP beeswarm plot
shap.summary_plot(shap_values, X, plot_type="violin", show=False)
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "shap_beeswarm.jpg"), dpi=300)
plt.close()

# 6.3 SHAP summary bar plot
shap.summary_plot(shap_values, X, plot_type="bar", show=False)
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "shap_summary_bar.jpg"), dpi=300)
plt.close()

# 6.4 SHAP force plot
shap.initjs()
force_plot = shap.plots.force(
    explainer.expected_value,
    shap_values[0],
    X.iloc[0],
    matplotlib=True,
    show=False
)
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "shap_force_plot.jpg"), dpi=600)
plt.close()

# 6.5 SHAP waterfall plot
shap.plots.waterfall(
    shap.Explanation(
        values=shap_values[0],
        base_values=explainer.expected_value,
        data=X.iloc[0].values,
        feature_names=feature_cols
    ),
    show=False
)
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "shap_waterfall_plot.jpg"), dpi=600)
plt.close()

# 6.6 Polynomial-fitted SHAP dependence plots
print("📈 Generating polynomial-fitted dependence plots...")
for i, feature in enumerate(tqdm(feature_cols, desc="Polynomial fitting")):
    shap_val = shap_values[:, i]
    feature_val = X[feature].values

    plt.figure(figsize=(6, 4))
    sns.regplot(
        x=feature_val,
        y=shap_val,
        order=2,
        scatter_kws={'alpha': 0.2, 's': 10},
        line_kws={'color': 'red', 'linewidth': 2}
    )
    plt.xlabel(feature)
    plt.ylabel(f"SHAP value for {feature}")
    plt.title(f"Dependence Plot with Polynomial Fit: {feature}")
    plt.grid(False)
    plt.tight_layout()
    plt.savefig(
        os.path.join(output_dir, f"shap_dependence_poly_{feature}.jpg"),
        dpi=600
    )
    plt.close()

# 6.7 Default SHAP interaction dependence plots
print("🔀 Generating SHAP interaction dependence plots...")
for feature in tqdm(feature_cols, desc="Interaction dependence plots"):
    shap.dependence_plot(feature, shap_values, X, show=False)
    plt.tight_layout()
    plt.savefig(
        os.path.join(output_dir, f"shap_dependence_interact_{feature}.jpg"),
        dpi=600
    )
    plt.close()

# ==== 7. Output model performance ====
print(f"✅ Model training completed. R² = {r2:.4f}")
print(f"📂 All figures have been saved to: {output_dir}")
