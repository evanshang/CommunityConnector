import pandas as pd
# view non-truncated dataframe
pd.set_option('display.max_colwidth', -1)
pd.set_option('display.max_columns', 30)
import numpy as np
import sys
sys.path.insert(1, 'pipeline/codes')
from utilities import available_vars

datafile = "data/full_data.csv"
data = pd.read_csv(datafile)
print("Original shape of data: " + str(data.shape))
nrows = data.shape[0]
data.columns = map(str.lower, data.columns)

# keep variables from data dictionary - mostly created in cleaning codes
data_dictionary = pd.read_csv('data/data_dictionary.csv')
data_dictionary.columns = map(str.lower, data_dictionary.columns)
keep_cols = data_dictionary['column_name']
keep_cols = [col for col in keep_cols if 'sdoh_score' not in col]
data['med_2br_rent_per_med_inc'] = data['rent_twobed2015']/(data['median_income']/12)
data['state'] = "CO"

print("Number of columns from data dictionary: " + str(len(keep_cols)))

# doing this because I messed up the data dictionary - not sure if this is needed anymore
def custom_replace(col):
    return col.replace("% ","pct_").replace("< ","lt_").replace("/","_").replace("%","pct").replace(" ", "_").replace("(","").replace(")","").replace("-","").replace("__","_")
data.columns = [custom_replace(col) for col in data.columns.values]

data = data[keep_cols]
assert(data.shape[1] == len(keep_cols))

# are there any variables that don't have a ton of data? drop them if low coverage
count = 0
for var in data.columns.values:
    coverage = data[pd.notnull(data[var])].shape[0]/nrows
    # TODO: this is an arbitrary cutoff
    if coverage < 0.8:
        print(f"Dropping {var} due to low coverage ({round(coverage,2)*100}%)")
        data.drop([var], axis = 1, inplace = True)
        count += 1
print("# columns dropped due to low coverage: " + str(count))

data.to_csv('data/full_data_relative.csv', index = False)