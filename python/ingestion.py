
import pandas as pd
import numpy as np


def load_dataset(file_path, selected_columns):

    dataframe = pd.read_csv(file_path, usecols=selected_columns)

    return dataframe

def create_time_split(transactions, identity, sample_size=100000):
    """
    Selects a contiguous time-ordered slice of ~sample_size transactions,
    instead of a random sample. Preserves TransactionDT order so a later
    train/validation split by time is valid.
    """
    transactions_sorted = transactions.sort_values("TransactionDT").reset_index(drop=True)

    # Take the first `sample_size` rows in time order
    transactions_sample = transactions_sorted.iloc[:sample_size].copy()

    identity_sample = identity[
        identity["TransactionID"].isin(transactions_sample["TransactionID"])
    ].copy()

    print("\nTime-Ordered Sample:")
    print("Transactions:", transactions_sample.shape)
    print("Time range:", transactions_sample["TransactionDT"].min(),
          "to", transactions_sample["TransactionDT"].max())
    print("Filtered Identity:", identity_sample.shape)

    return transactions_sample, identity_sample
    
def remove_duplicates(dataframe, subset_column):

    dataframe = dataframe.drop_duplicates(subset=subset_column)

    return dataframe
