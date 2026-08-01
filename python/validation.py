
import pandas as pd
import numpy as np

def dataset_overview(dataframe, dataset_name):

    rows = dataframe.shape[0]
    columns = dataframe.shape[1]

    missing_cells = dataframe.isnull().sum().sum()
    total_cells = rows * columns

    missing_pct = round((missing_cells / total_cells) * 100, 2) if total_cells > 0 else 0

    duplicate_rows = dataframe.duplicated().sum()
    duplicate_pct = round((duplicate_rows / rows) * 100, 2) if rows > 0 else 0

    print(f"{dataset_name} Overview")
    display(dataframe.head())

    summary = pd.DataFrame({
        "Metric": ["Rows", "Columns", "Missing Cells", "Missing Percent", "Duplicate Rows", "Duplicate Percent"],
        "Value": [rows, columns, missing_cells, f"{missing_pct}%", duplicate_rows, f"{duplicate_pct}%"]
    })

    display(summary)

    return summary


def schema_validation(dataframe, missing_only=False):

    schema_df = pd.DataFrame({
        "Column": dataframe.columns,
        "DataType": dataframe.dtypes.astype(str),
        "Missing_Count": dataframe.isnull().sum().values,
        "Missing_Percentage": (
            dataframe.isnull().mean() * 100
        ).round(2).values
    })

    schema_df = schema_df.sort_values(
        by="Missing_Percentage",
        ascending=False
    ).reset_index(drop=True)

    display(schema_df)

    return schema_df


def fraud_distribution(dataframe):

    summary = (dataframe["isFraud"].value_counts().reset_index())

    summary.columns = ["Fraud_Label","Count"]

    summary["Percentage"] = (summary["Count"]/ len(dataframe)* 100).round(2)

    overall_fraud_rate = round(dataframe["isFraud"].mean() * 100,2)

    print(f"\nOverall Fraud Rate: "f"{overall_fraud_rate}%")
    display(summary)

    return summary


def numeric_overview(dataframe):

    summary = (dataframe.describe().transpose().round(2))

    print("\nNumeric Feature Overview")
    display(summary)

    return summary

def cardinality_overview(dataframe):

    cardinality = pd.DataFrame({"Column": dataframe.columns,"Unique_Values": [dataframe[col].nunique(dropna=True) for col in dataframe.columns]})

    cardinality = cardinality.sort_values(by="Unique_Values",ascending=False)

    print("Cardinality Overview")
    display(cardinality)

    return cardinality

