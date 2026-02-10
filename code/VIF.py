import pandas as pd
from statsmodels.stats.outliers_influence import variance_inflation_factor


def calculate_vif(file_path):
    try:
        # Read CSV file
        data = pd.read_csv(file_path)

        # Separate dependent and independent variables
        y = data['X']
        X = data.drop('X', axis=1)

        # Calculate VIF
        vif_data = pd.DataFrame()
        vif_data["feature"] = X.columns
        vif_data["VIF"] = [
            variance_inflation_factor(X.values, i)
            for i in range(len(X.columns))
        ]

        # Add interpretation column
        def vif_interpretation(vif):
            if vif < 5:
                return "No significant multicollinearity"
            elif 5 <= vif < 10:
                return "Potential multicollinearity"
            else:
                return "Severe multicollinearity"

        vif_data["Interpretation"] = vif_data["VIF"].apply(vif_interpretation)

        return vif_data

    except FileNotFoundError:
        print("Error: File not found. Please check the file path.")
    except KeyError:
        print("Error: Column 'X' does not exist in the dataset. Please check the data.")
    except Exception as e:
        print(f"Error: An unexpected error occurred: {e}")


if __name__ == "__main__":
    file_path = r"D:\mydata\x.csv"
    vif_result = calculate_vif(file_path)

    if vif_result is not None:
        print("Variance Inflation Factor (VIF) results:")
        print(vif_result)

        # Export results to CSV file
        output_file = r"D:\mydata\vif_results.csv"
        vif_result.to_csv(output_file, index=False)
        print(f"Results have been exported to {output_file}")
