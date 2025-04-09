from sqlalchemy import create_engine
import pandas as pd

# Path to the CSV file
file_path = 'fighters_common.csv'

fighters = pd.read_csv(file_path)

file_path = 'fights_common.csv'

fights = pd.read_csv(file_path)

engine = create_engine('postgresql://postgres:password@localhost:5432/ufc')


# if_exists options:
#   - 'fail': Raise an error if the table exists.
#   - 'replace': Drop the table before inserting new values.
#   - 'append': Insert new values into the existing table.
fighters.to_sql('fighters', con=engine, if_exists='replace', index=False)
fights.to_sql('fights', con=engine, if_exists='replace', index=False)
