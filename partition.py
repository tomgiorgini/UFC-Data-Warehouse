import pandas as pd

# 1. Percorso del file originale
INPUT_CSV = 'df_common.csv'

# 2. Leggi il dataset
df = pd.read_csv(INPUT_CSV, parse_dates=['date'])

# 3. Rinomina colonne avgctrltime per semplicità
df = df.rename(columns={
    'r_avgctrltime(seconds)': 'r_avgctrltime',
    'b_avgctrltime(seconds)': 'b_avgctrltime'
})

# 4. Genera dim_date.csv
dim_date = (
    df[['date']]
      .drop_duplicates()
      .assign(
          month=lambda x: x['date'].dt.month,
          year=lambda x: x['date'].dt.year
      )
)
dim_date.to_csv('dim_date.csv', index=False)

# 5. Genera dim_event.csv
dim_event = (
    df[['event', 'date', 'location', 'city', 'state', 'country']]
      .drop_duplicates()
)
dim_event.to_csv('dim_event.csv', index=False)

# 6. Genera dim_r_fighter.csv
r_cols = [
    'r_fighter', 'gender', 'weightclass',
    'r_age', 'r_stance', 'r_heightcms', 'r_reachcms', 'r_weightlbs', 'r_record',
    'r_losses', 'r_draws', 'r_wins',
    'r_winbydecisionmajority', 'r_winbydecisionunanimous',
    'r_winsbydecisionmajority', 'r_winsbydecisionsplit', 'r_winsbydecisionunanimous',
    'r_winsbyko', 'r_winsbysubmission', 'r_winsbytkodoctorstoppage',
    'r_matchwcrank', 'r_pfprank'
]
dim_r_fighter = df[r_cols].drop_duplicates()


# 7. Genera dim_b_fighter.csv
b_cols = [
    'b_fighter', 'gender', 'weightclass',
    'b_age', 'b_stance', 'b_heightcms', 'b_reachcms', 'b_weightlbs', 'b_record',
    'b_losses', 'b_draws', 'b_wins',
    'b_winbydecisionmajority', 'b_winbydecisionunanimous',
    'b_winsbydecisionmajority', 'b_winsbydecisionsplit', 'b_winsbydecisionunanimous',
    'b_winsbyko', 'b_winsbysubmission', 'b_winsbytkodoctorstoppage',
     'b_matchwcrank', 'b_pfprank'
]


dim_b_fighter = df[b_cols].drop_duplicates()

dim_r_fighter = dim_r_fighter[
    (dim_r_fighter['r_record'].notna())
    & (dim_r_fighter['r_record'] != 'nan-nan-nan')
]

dim_b_fighter = dim_b_fighter[
    (dim_b_fighter['b_record'].notna())
    & (dim_b_fighter['b_record'] != 'nan-nan-nan')
]


dim_b_fighter.to_csv('dim_b_fighter.csv', index=False)
dim_r_fighter.to_csv('dim_r_fighter.csv', index=False)
# 8. Genera dim_finish.csv
dim_finish = df[['finish', 'finishdetails', 'winner', 'finishround', 'totalfighttimesecs']].drop_duplicates()
dim_finish.to_csv('dim_finish.csv', index=False)

# 9. Genera fact_fight.csv includendo tutte le misure
fact_cols = [
    'date', 'event', 'referee',
    'r_fighter', 'b_fighter', 'finish',
    'totalfighttimesecs', 'finishround',
    'heightdif', 'agedif', 'reachdif',
    'r_odds', 'b_odds',
    'r_avgkd', 'b_avgkd',
    'r_avgsigstratt', 'b_avgsigstratt',
    'r_avgsigstrlanded', 'b_avgsigstrlanded',
    'r_avgtdatt', 'b_avgtdatt',
    'r_avgtdlanded', 'b_avgtdlanded',
    'r_avgsubatt', 'b_avgsubatt',
    'r_avgctrltime', 'b_avgctrltime'
]
fact_fight = df[fact_cols]
fact_fight.to_csv('fact_fight.csv', index=False)

print("CSV generati con le colonne corrette:")
print(" - dim_date.csv")
print(" - dim_event.csv")
print(" - dim_r_fighter.csv")
print(" - dim_b_fighter.csv")
print(" - dim_finish.csv")
print(" - fact_fight.csv")