import pandas as pd

# Path to the CSV files

file_path = 'd1.csv' #2010-2024
df1 = pd.read_csv(file_path)

file_path = 'd2.csv' #1994-2021
df2 = pd.read_csv(file_path)

df_events = pd.read_csv('d3.csv') #For the event name
df_events.drop('location',axis=1)

#################################################
# Column Renaming procedure - Integration

def rename_blue(col):
    if col.startswith("Blue"):
        new_col = col.replace("Blue", "B_", 1)
    else:
        new_col = col
    return new_col

def rename_red(col):
    if col.startswith("Red"):
        new_col = col.replace("Red", "R_", 1)
    else:
        new_col = col
    
    return new_col

def add_underscore(col):
    # Se la colonna inizia per 'R' o 'B'
    if col.startswith(('R', 'B')) and col != 'ReachDif' and col!='BetterRank':
        if len(col) > 1 and col[1] != '_':
            return col[0] + '_' + col[1:]
    return col

df1 = df1.rename(columns=lambda x: rename_blue(x))
df1 = df1.rename(columns=lambda x: rename_red(x))
df1 = df1.rename(columns=lambda x: add_underscore(x))

def normalize(col_name):
    col_name = col_name.lower()
    
    if col_name.startswith('r_') or col_name.startswith('b_'):
        prefix = col_name[:2]          # 'r_' o 'b_'
        rest = col_name[2:]           #es. 'height_cms'
        rest_no_underscores = rest.replace('_', '')  # 'heightcms'
        return prefix + rest_no_underscores          # 'r_heightcms'
    else:
        return col_name.replace('_', '')
    
df1.columns = [col.lower() for col in df1.columns]
df2.columns = [col.lower() for col in df2.columns]

df1 = df1.rename(columns=lambda x: normalize(x))
df2 = df2.rename(columns=lambda x: normalize(x))

df2 = df2.rename(
    columns={'b_draw': 'b_draws', 'r_draw': 'r_draws',
            'b_winbyko/tko':'b_winsbyko','r_winbyko/tko':'r_winsbyko', 
            'r_winbytkodoctorstoppage': 'r_winsbytkodoctorstoppage',
            'b_winbytkodoctorstoppage': 'b_winsbytkodoctorstoppage',
            'r_winbysubmission': 'r_winsbysubmission',
            'b_winbysubmission': 'b_winsbysubmission',
            'r_winbydecisionsplit': 'r_winsbydecisionsplit',
            'b_winbydecisionsplit': 'b_winsbydecisionsplit',
            'r_winbydecisionmajority':'r_winsbydecisionmajority',
            'b_winbydecisionmajority': 'b_winsbydecisionmajority', 
            'r_winbydecisionunanimous':'r_winsbydecisionunanimous' ,
            'b_winbydecisionunanimous': 'b_winsbydecisionunanimous',})

##############################################################

# Date and Location columns operations

# Sorting by date 
df1 = df1.sort_values(by=["date","r_fighter"]).reset_index(drop=True)
df2 = df2.sort_values(by=["date","r_fighter"]).reset_index(drop=True)


# Change all int columns in float
for col in df1.select_dtypes(include='int'):
    df1[col] = df1[col].astype(float)
    
for col in df1.select_dtypes(include='object'):
    df1[col] = df1[col].fillna('').astype(str)
for col in df2.select_dtypes(include='object'):
    df2[col] = df2[col].fillna('').astype(str)
    
df1 = df1.round(2)
df2 = df2.round(2)

# Convert date in datetime
df1['date'] = pd.to_datetime(df1['date'], errors='coerce')
df2['date'] = pd.to_datetime(df2['date'], errors='coerce')

start_date = '2010-03-21'
end_date   = '2021-03-20'

# Operation for date and location columns/subcolumns

df1['month'] = df1['date'].dt.month
df1['year'] = df1['date'].dt.year
df1['b_record'] = (
    df1['b_wins'].astype(str) + '-' +
    df1['b_losses'].astype(str) + '-' +
    df1['b_draws'].astype(str)
)
df1['r_record'] = (
    df1['r_wins'].astype(str) + '-' +
    df1['r_losses'].astype(str) + '-' +
    df1['r_draws'].astype(str)
)

parts = df1['location'].str.split(',', n=2, expand=True)
parts = parts.apply(lambda col: col.str.strip())
parts.columns = ['city','state','country']

mask = parts['country'].isna() & parts['state'].notna()
parts.loc[mask, 'country'] = parts.loc[mask, 'state']
parts.loc[mask, 'state'] = ''

# Deleting pre-existing city, state, country columns from df1 if they exists
df1 = df1.drop(columns=['city','state','country'], errors='ignore')

#join the three new columns
df1 = df1.join(parts[['city','state','country']])

df2['month'] = df2['date'].dt.month
df2['year'] = df2['date'].dt.year
df2['b_record'] = (
    df2['b_wins'].astype(str) + '-' +
    df2['b_losses'].astype(str) + '-' +
    df2['b_draws'].astype(str)
)
df2['r_record'] = (
    df2['r_wins'].astype(str) + '-' +
    df2['r_losses'].astype(str) + '-' +
    df2['r_draws'].astype(str)
)

# Same for df2
parts = df2['location'].str.split(',', n=2, expand=True)
parts = parts.apply(lambda col: col.str.strip())
parts.columns = ['city','state','country']

mask = parts['country'].isna() & parts['state'].notna()
parts.loc[mask, 'country'] = parts.loc[mask, 'state']
parts.loc[mask, 'state'] = ''

df2 = df2.drop(columns=['city','state','country'], errors='ignore')

df2 = df2.join(parts[['city','state','country']])


########################################################
#Filtering for columns needed for the two main datasets

cols_to_keep = ['r_fighter','b_fighter', 'event','date','month','year', 'gender', 'location', 
    'city','state', 'country', 'referee', 'winner', 'finish', 'finishdetails','finishround',
    'totalfighttimesecs','titlebout', 'weightclass', 'numberofrounds', 'emptyarena',
    'heightdif','agedif', 'reachdif', 
    'r_age' ,'r_stance', 'r_heightcms', 'r_reachcms', 'r_weightlbs', 'b_odds', 'b_record',
    'b_age', 'b_stance', 'b_heightcms', 'b_reachcms', 'b_weightlbs', 'r_odds', 'r_record',
    'r_losses','r_draws', 'r_wins','r_winsbydecisionmajority', 'r_winsbydecisionunanimous', 
    'r_winsbydecisionmajority', 'r_winsbydecisionsplit', 'r_winsbydecisionunanimous',
    'r_winsbyko', 'r_winsbysubmission', 'r_winsbytkodoctorstoppage',
    'b_losses', 'b_draws', 'b_wins','b_winsbydecisionmajority', 'b_winsbydecisionunanimous',
    'b_winsbydecisionmajority', 'b_winsbydecisionsplit', 'b_winsbydecisionunanimous',
    'b_winsbyko', 'b_winsbysubmission', 'b_winsbytkodoctorstoppage',
    'r_avgkd','r_avgsigstratt', 'r_avgsigstrlanded', 'r_avgtdatt', 'r_avgtdlanded',
    'r_avgsubatt', 'r_avgctrltime(seconds)', 'r_matchwcrank', 'r_pfprank',
    'b_avgkd','b_avgsigstratt', 'b_avgsigstrlanded','b_avgtdatt', 'b_avgtdlanded',
    'b_avgsubatt', 'b_avgctrltime(seconds)','b_matchwcrank', 'b_pfprank'
    ]

# only keep the date that are in common for the two datasets
df1 = df1[(df1['date'] >= start_date) & (df1['date'] <= end_date)].copy()
df2 = df2[(df2['date'] >= start_date) & (df2['date'] <= end_date)].copy()

# only keeping the needed columns for each dataset
common1 = [c for c in cols_to_keep if c in df1.columns]
df1 = df1[common1]

common2 = [c for c in cols_to_keep if c in df2.columns]
df2 = df2[common2]

# Keeping only needed columns per each dataset before the merge

col1 =['r_fighter', 'b_fighter', 'date', 'month', 'year', 'gender', 'location',
       'city', 'state', 'country', 'finish', 'finishdetails',
       'finishround', 'totalfighttimesecs', 'titlebout', 'weightclass',
       'numberofrounds', 'emptyarena', 'heightdif', 'agedif', 'reachdif',
       'r_odds', 'r_age', 'r_stance', 'r_heightcms', 'r_reachcms', 'r_weightlbs',
       'b_odds',  'b_age', 'b_stance', 'b_heightcms', 'b_reachcms','b_weightlbs', 
       'r_matchwcrank', 'r_pfprank', 'b_matchwcrank', 'b_pfprank']

col2 = ['r_fighter', 'b_fighter', 'date', 'referee', 'winner', 
       'r_record','r_losses', 'r_draws', 'r_wins','r_winsbydecisionmajority', 'r_winsbydecisionunanimous',
       'r_winsbydecisionsplit', 'r_winsbyko', 'r_winsbysubmission',
       'r_winsbytkodoctorstoppage','b_record', 'b_losses', 'b_draws', 'b_wins',
       'b_winsbydecisionmajority', 'b_winsbydecisionunanimous',
       'b_winsbydecisionsplit', 'b_winsbyko', 'b_winsbysubmission',
       'b_winsbytkodoctorstoppage', 'r_avgkd', 'r_avgsigstratt',
       'r_avgsigstrlanded', 'r_avgtdatt', 'r_avgtdlanded', 'r_avgsubatt',
       'r_avgctrltime(seconds)', 'b_avgkd', 'b_avgsigstratt',
       'b_avgsigstrlanded', 'b_avgtdatt', 'b_avgtdlanded', 'b_avgsubatt',
       'b_avgctrltime(seconds)']
df1= df1[col1]
df2= df2[col2]

########################################################

# check for fighter that are in the blue corner in one dataset and in the red one in the other dataset
def find_swapped_between(df1: pd.DataFrame, df2: pd.DataFrame) -> pd.DataFrame:
    a = df1[["date", "r_fighter", "b_fighter"]].copy().reset_index(names="df1_row")
    b = df2[["date", "r_fighter", "b_fighter"]].copy().reset_index(names="df2_row")

    a["key"] = a["date"].astype(str) + "||" + a["r_fighter"].astype(str) + "||" + a["b_fighter"].astype(str)
    b["key"] = b["date"].astype(str) + "||" + b["b_fighter"].astype(str) + "||" + b["r_fighter"].astype(str)

    m = a.merge(b, on="key", how="inner", suffixes=("_df1", "_df2"))

    return (
        m[[
            "date_df1", "df1_row", "df2_row",
            "r_fighter_df1", "b_fighter_df1",
            "r_fighter_df2", "b_fighter_df2"
        ]]
        .rename(columns={"date_df1": "date"})
        .sort_values(["date", "r_fighter_df1", "b_fighter_df1"])
        .reset_index(drop=True)
    )
cross = find_swapped_between(df1, df2)
#print(cross.head(50))

# Swap every column values in df2 for red and blue
def swap_red_blue_rows_df2(df2: pd.DataFrame, df2_rows: list[int]) -> pd.DataFrame:
    df2 = df2.copy()

    # --- build pairs (r_x <-> b_x) that exist in df2
    r_cols = [c for c in df2.columns if c.startswith("r_")]
    pairs = [(c, "b_" + c[2:]) for c in r_cols if ("b_" + c[2:]) in df2.columns]

    # --- swap all paired columns for the selected rows
    for r, b in pairs:
        tmp = df2.loc[df2_rows, r].copy()
        df2.loc[df2_rows, r] = df2.loc[df2_rows, b].values
        df2.loc[df2_rows, b] = tmp.values

    # --- flip winner (Blue <-> Red) for selected rows, only if winner column exists
    if "winner" in df2.columns:
        w = df2.loc[df2_rows, "winner"].astype("string").str.strip()
        w_low = w.str.lower()

        df2.loc[df2_rows, "winner"] = w_low.map({
            "blue": "Red",
            "red": "Blue"
        }).fillna(w)  # leave other values unchanged (e.g., Draw/NC/NULL)

    return df2
cross = find_swapped_between(df1, df2)
#print(cross.head(50))

#result of the finding + swap
rows_to_fix = [5413, 5516, 5557, 5562, 5564, 5561]
df2 = swap_red_blue_rows_df2(df2, rows_to_fix)

########################################################

# Check for fighters who are named differently in the two datasets
def partial_matches(df1: pd.DataFrame, df2: pd.DataFrame) -> pd.DataFrame:
    a = df1.reset_index().rename(columns={"index": "df1_row"})
    b = df2.reset_index().rename(columns={"index": "df2_row"})

    #same date + same r_fighter, but b_fighter differs
    rr = a.merge(b, on=["date", "r_fighter"], how="inner", suffixes=("_df1", "_df2"))
    rr = rr[rr["b_fighter_df1"] != rr["b_fighter_df2"]]
    rr = rr[["date", "df1_row", "df2_row", "r_fighter", "b_fighter_df1", "b_fighter_df2"]]
    rr["anchor_side"] = "R"

    #same date + same b_fighter, but r_fighter differs
    bb = a.merge(b, on=["date", "b_fighter"], how="inner", suffixes=("_df1", "_df2"))
    bb = bb[bb["r_fighter_df1"] != bb["r_fighter_df2"]]
    bb = bb[["date", "df1_row", "df2_row", "b_fighter", "r_fighter_df1", "r_fighter_df2"]]
    bb["anchor_side"] = "B"

    #unify column names
    rr = rr.rename(columns={
        "r_fighter": "anchor_fighter",
        "b_fighter_df1": "df1_other",
        "b_fighter_df2": "df2_other"
    })
    bb = bb.rename(columns={
        "b_fighter": "anchor_fighter",
        "r_fighter_df1": "df1_other",
        "r_fighter_df2": "df2_other"
    })

    out = pd.concat([rr, bb], ignore_index=True).drop_duplicates()
    return out.sort_values(["date", "anchor_side", "anchor_fighter"]).reset_index(drop=True)

# Force df1 names in df2
def force_df2_names_from_df1(df2: pd.DataFrame, mism: pd.DataFrame) -> pd.DataFrame:
    df2 = df2.copy()
    # In anchor_side == "R", anchor fighter is r_fighter -> other is b_fighter
    mask_r = mism["anchor_side"] == "R"
    if mask_r.any():
        rows = mism.loc[mask_r, "df2_row"].astype(int).to_numpy()
        df2.loc[rows, "b_fighter"] = mism.loc[mask_r, "df1_other"].astype(str).to_numpy()

    # In anchor_side == "B", anchor fighter is b_fighter -> other is r_fighter
    mask_b = mism["anchor_side"] == "B"
    if mask_b.any():
        rows = mism.loc[mask_b, "df2_row"].astype(int).to_numpy()
        df2.loc[rows, "r_fighter"] = mism.loc[mask_b, "df1_other"].astype(str).to_numpy()

    return df2

mism = partial_matches(df1, df2)
df2 = force_df2_names_from_df1(df2, mism)

###################################################
#MERGE OPERATION

key_cols = ['r_fighter', 'b_fighter', 'date']

df1.to_csv("d1_post_ETL.csv",index = False)
df2.to_csv("d2_post_ETL.csv",index = False)

df = pd.merge(df1, df2, how='outer', on=key_cols)
df = df.sort_values(by=['date','r_fighter']).reset_index(drop=True)
df_events['date'] = pd.to_datetime(df_events['date'])
df = df.merge(df_events[['date','event']], on =['date'], how = 'left')

##################################################
# Cleaning the results

# we need to have a winner and a location: These are NULL if the fight did not happened, but was in the fight list
df = df.dropna(subset=['winner'])
df = df.dropna(subset=['location'])

#Computing physical attribute differences red-blue
df['heightdif'] = round(df['r_heightcms'] - df['b_heightcms'],2)
df['reachdif'] = round(df['r_reachcms'] - df['b_reachcms'],2)
df['agedif'] = round(df['r_age'] - df['b_age'],2)

###########################################################
# Columns typing and management of null values

# Integer columns
int_cols = [
    'month','year','finishround','totalfighttimesecs','numberofrounds',
    'r_odds','b_odds','r_age','b_age','agedif','r_weightlbs','b_weightlbs',
    'r_matchwcrank','r_pfprank','b_matchwcrank','b_pfprank',
    'r_losses','r_draws','r_wins','b_losses','b_draws','b_wins',
    'r_winsbydecisionsplit','r_winsbyko','r_winsbysubmission',
    'r_winsbydecisionmajority','r_winsbydecisionunanimous',
    'r_winsbytkodoctorstoppage','b_winsbydecisionmajority',
    'b_winsbydecisionunanimous','b_winsbydecisionsplit','b_winsbyko',
    'b_winsbysubmission','b_winsbytkodoctorstoppage'
]

for x in int_cols:
    df[x] = df[x].astype('Int64')

df['titlebout'] = df['titlebout'].astype('bool')
df['emptyarena'] = df['emptyarena'].astype('bool')

avg_cols = [c for c in df.columns if c.startswith(('r_avg','b_avg'))]

# Null are 0 for the avg columns
df[avg_cols] = df[avg_cols].fillna(0)


#check for null values counts in each column
null_counts = df.isna().sum().reset_index()
null_counts.columns = ['column', 'null_count']
#print(null_counts)

###################################################
#Check for duplicates produced by the merge operation

#There is no fighter with 2 fights on the same date
def fighter_date_duplicate_row_pairs(df: pd.DataFrame) -> pd.DataFrame:
    x = df[["date", "r_fighter", "b_fighter"]].copy()
    x = x.reset_index(names="row_id")

    # Build an "appearances" table: one row per (original_row, date, fighter, side)
    red = x[["row_id", "date", "r_fighter"]].rename(columns={"r_fighter": "fighter"})
    red["side"] = "R"
    blue = x[["row_id", "date", "b_fighter"]].rename(columns={"b_fighter": "fighter"})
    blue["side"] = "B"

    app = pd.concat([red, blue], ignore_index=True).dropna(subset=["date", "fighter"])
    app = app[app["fighter"] != ""]  # drop empty strings if any

    # Self-join within same (date, fighter) to get row pairs; keep row_id_1 < row_id_2
    pairs = app.merge(app, on=["date", "fighter"], suffixes=("_1", "_2"))
    pairs = pairs[pairs["row_id_1"] < pairs["row_id_2"]]

    return (
        pairs[["date", "fighter", "row_id_1", "row_id_2", "side_1", "side_2"]]
        .sort_values(["date", "fighter", "row_id_1", "row_id_2"])
        .reset_index(drop=True)
    )

pairs = fighter_date_duplicate_row_pairs(df)
#print(pairs.head(1000))

###################################################
# Ordering
desired_order = [
    'r_fighter','b_fighter','event','date','month','year','gender',
    'location','city','state','country','referee','winner','finish',
    'finishdetails','finishround','totalfighttimesecs','titlebout',
    'weightclass','numberofrounds','emptyarena','heightdif','agedif',
    'reachdif','r_odds','r_age','r_stance','r_heightcms','r_reachcms',
    'r_weightlbs','b_odds','b_age','b_stance','b_heightcms','b_reachcms',
    'b_weightlbs','r_record','r_losses','r_draws','r_wins',
    'r_winsbydecisionmajority','r_winsbydecisionunanimous',
    'r_winsbydecisionsplit','r_winsbyko','r_winsbysubmission',
    'r_winsbytkodoctorstoppage','b_record','b_losses','b_draws',
    'b_wins','b_winsbydecisionunanimous','b_winsbydecisionmajority',
    'b_winsbydecisionsplit','b_winsbyko','b_winsbysubmission',
    'b_winsbytkodoctorstoppage','r_avgkd','r_avgsigstratt',
    'r_avgsigstrlanded','r_avgtdatt','r_avgtdlanded','r_avgsubatt',
    'r_avgctrltime(seconds)','r_matchwcrank','r_pfprank','b_avgkd',
    'b_avgsigstratt','b_avgsigstrlanded','b_avgtdatt','b_avgtdlanded',
    'b_avgsubatt','b_avgctrltime(seconds)','b_matchwcrank','b_pfprank'
]

#some columns are duplicated
df = df.loc[:, ~df.columns.duplicated()]

#Reorder and print in csv the final dataset
df = df[desired_order]
df.to_csv("df_common.csv",index = False)