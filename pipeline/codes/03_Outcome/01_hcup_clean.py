import os
import pandas as pd
import numpy as np
import regex as re

n_drive = 'N:/Transfer/KSkvoretz/AHRQ/data//03_Outcome/HCUP'

hcup_files = os.listdir(n_drive)
hcup_files = [file for file in hcup_files if "csv" in file]
hcup_files = [file for file in hcup_files if "selections" not in file]
print(hcup_files)

# parameters used for each dataframe
selections_df = pd.read_csv(os.path.join(n_drive, "HCUP_selections.csv"))

# Turn each dataframe into long and concatenate all
for i in range(len(hcup_files)):
    # 16th data frame doesn't work? - HCUP_8 is corrupt
    data = pd.read_csv(os.path.join(n_drive, f"HCUP_{i}.csv"))
    # remove the junk above the data
    data = data.iloc[6:]
    # use the first row as the column names
    data.columns = data.iloc[0]
    data.columns.values[0:2] = ["County","FIPS"]
    data = data.iloc[7:]

    # also need to drop bottom rows with notes and no data

    # assign data with the parameter selections, to make column names later
    data['Analysis Selection'] = selections_df.iloc[i]['Analysis Selection']
    data['Classification'] = selections_df.iloc[i]['Classification']
    data['Diagnosis'] = selections_df.iloc[i]['Diagnosis']
    data['num'] = i

    # wide to long data
    # key columns: county, FIPS, Analysis Selection, Classification, Diagnosis
    data = pd.melt(data, id_vars = ['County','FIPS','Analysis Selection','Classification','Diagnosis','num'],
    var_name='metric', value_name = 'value')

    # stack all HCUP data frames
    if i == 0:
        full_data = data
    else:
        full_data = full_data.append(data)

# drop all rows with * or blank metric
pre_rows = full_data.shape[0]
full_data = full_data[full_data['value'] != "*"]
full_data = full_data[pd.notnull(full_data['value'])]
full_data = full_data[pd.notnull(full_data['County'])]
full_data = full_data[pd.notnull(full_data['FIPS'])]
print(f"{pre_rows - full_data.shape[0]} rows dropped")

# concatenate analysis selection, classification, and diagnosis in some way with shortened metric names
# these will eventually be column names
def change_metric(row):
    if row['metric'] == "Total number of discharges":
        return 'discharge_total'
    elif row['metric'] == "Rate of discharges per 100,000 population":
        return 'discharge_p100'
    else:
        return 'discharge_adj'

full_data['new_metric'] = full_data.apply(change_metric, axis = 1)

full_data['column'] = [re.sub(r'[0-9]+ ', '', diag) for diag in full_data['Diagnosis']]
full_data['column'] = [diag.replace("& ","").replace(" ","_").replace("for_","").replace("/","") for diag in full_data['column']]
full_data['column'] = full_data['column'] + "_" + full_data['new_metric']

full_data = full_data[['FIPS','column','value']]

# long to wide data - one row for every FIPS code 
full_data = full_data.pivot(index = 'FIPS', columns = 'column', values = 'value')
print(full_data.shape)
print(full_data.head())

# output data
full_data.to_csv(os.path.join(os.path.dirname(n_drive),'cleaned','HCUP_cleaned.csv'))