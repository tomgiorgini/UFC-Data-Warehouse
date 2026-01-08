-- Drop della tabella di staging se già esistente
DROP TABLE IF EXISTS public.staging_fight;
ALTER SEQUENCE public.fact_fight_fight_key_seq RESTART WITH 1;

-- Creazione della tabella di staging con le colonne in ordine identico al CSV
CREATE TABLE public.staging_fight (
  r_fighter                  TEXT,
  b_fighter                  TEXT,
  event                      TEXT,
  date                       DATE,
  month                      INTEGER,
  year                       INTEGER,
  gender                     TEXT,
  location                   TEXT,
  city                       TEXT,
  state                      TEXT,
  country                    TEXT,
  referee                    TEXT,
  winner                     TEXT,
  finish                     TEXT,
  finishdetails              TEXT,
  finishround                INTEGER,
  totalfighttimesecs         INTEGER,
  titlebout                  BOOLEAN,
  weightclass                TEXT,
  numberofrounds             INTEGER,
  emptyarena                 BOOLEAN,
  heightdif                  REAL,
  agedif                     INTEGER,
  reachdif                   REAL,
  r_odds                     INTEGER,
  r_age                      INTEGER,
  r_stance                   TEXT,
  r_heightcms                REAL,
  r_reachcms                 REAL,
  r_weightlbs                INTEGER,
  b_odds                     INTEGER,
  b_age                      INTEGER,
  b_stance                   TEXT,
  b_heightcms                REAL,
  b_reachcms                 REAL,
  b_weightlbs                INTEGER,
  r_record                   TEXT,
  r_losses                   INTEGER,
  r_draws                    INTEGER,
  r_wins                     INTEGER,
  r_winsbydecisionmajority   INTEGER,
  r_winsbydecisionsplit      INTEGER,
  r_winsbydecisionunanimous  INTEGER,
  r_winsbyko                 INTEGER,
  r_winsbysubmission         INTEGER,
  r_winsbytkodoctorstoppage  INTEGER,
  b_record                   TEXT,
  b_losses                   INTEGER,
  b_draws                    INTEGER,
  b_wins                     INTEGER,
  b_winsbydecisionmajority   INTEGER,
  b_winsbydecisionsplit      INTEGER,
  b_winsbydecisionunanimous  INTEGER,
  b_winsbyko                 INTEGER,
  b_winsbysubmission         INTEGER,
  b_winsbytkodoctorstoppage  INTEGER,
  r_avgkd                    REAL,
  r_avgsigstratt             REAL,
  r_avgsigstrlanded          REAL,
  r_avgtdatt                 REAL,
  r_avgtdlanded              REAL,
  r_avgsubatt                REAL,
  "r_avgctrltime(seconds)"   REAL,
  r_matchwcrank              INTEGER,
  r_pfprank                  INTEGER,
  b_avgkd                    REAL,
  b_avgsigstratt             REAL,
  b_avgsigstrlanded          REAL,
  b_avgtdatt                 REAL,
  b_avgtdlanded              REAL,
  b_avgsubatt                REAL,
  "b_avgctrltime(seconds)"   REAL,
  b_matchwcrank              INTEGER,
  b_pfprank                  INTEGER
);

ALTER TABLE public.staging_fight
  DROP COLUMN IF EXISTS stg_id CASCADE;
ALTER TABLE public.staging_fight
  ADD COLUMN stg_id SERIAL PRIMARY KEY;

-- PSQL CODE TO POPULATE STAGING FIGHT: 
--\copy public.staging_fight(r_fighter,b_fighter,event,date,month,year,gender,location,city,state,country,referee,winner,finish,finishdetails,finishround,totalfighttimesecs,titlebout,weightclass,numberofrounds,emptyarena,heightdif,agedif,reachdif,r_odds,r_age,r_stance,r_heightcms,r_reachcms,r_weightlbs,b_odds,b_age,b_stance,b_heightcms,b_reachcms,b_weightlbs,r_record,r_losses,r_draws,r_wins,r_winsbydecisionmajority,r_winsbydecisionsplit,r_winsbydecisionunanimous,r_winsbyko,r_winsbysubmission,r_winsbytkodoctorstoppage,b_record,b_losses,b_draws,b_wins,b_winsbydecisionmajority,b_winsbydecisionsplit,b_winsbydecisionunanimous,b_winsbyko,b_winsbysubmission,b_winsbytkodoctorstoppage,r_avgkd,r_avgsigstratt,r_avgsigstrlanded,r_avgtdatt,r_avgtdlanded,r_avgsubatt,"r_avgctrltime(seconds)",r_matchwcrank,r_pfprank,b_avgkd,b_avgsigstratt,b_avgsigstrlanded,b_avgtdatt,b_avgtdlanded,b_avgsubatt,"b_avgctrltime(seconds)",b_matchwcrank,b_pfprank) FROM '/Users/tommaso/Documents/GitHub/Progetto-DM/df_common.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"');


--CREATE TABLES--

CREATE TABLE public.dim_date (
  date_key SERIAL PRIMARY KEY,
  date     DATE    NOT NULL UNIQUE,
  month    SMALLINT,
  year     SMALLINT
);

CREATE TABLE public.dim_event (
  event_key SERIAL PRIMARY KEY,
  event     TEXT    NOT NULL,
  date_key  INTEGER NOT NULL REFERENCES public.dim_date(date_key),
  location  TEXT,
  city      TEXT,
  state     TEXT,
  country   TEXT
);

CREATE TABLE public.dim_winner (
  winner_key         SERIAL PRIMARY KEY,
  stg_id             INTEGER NOT NULL UNIQUE
                      REFERENCES public.staging_fight(stg_id),
  winner             TEXT    NOT NULL,
  finishdetails      TEXT,
  finish             TEXT,
  finishround        SMALLINT,
  totalfighttimesecs INTEGER
);

CREATE TABLE public.dim_type (
	type_key SERIAL PRIMARY KEY,
	weightclass TEXT,
	numberofrounds INTEGER,
	titlebout BOOLEAN,
	emptyarena BOOLEAN
);

--  dim_fighter
CREATE TABLE  public.dim_fighter (
  fighter_key   SERIAL    PRIMARY KEY,
  fighter       TEXT      NOT NULL,
  gender        TEXT,
  age           INTEGER,
  stance        TEXT,
  heightcms     REAL,
  reachcms      REAL,
  weightlbs     REAL,
  record        TEXT,
  losses        INTEGER,
  draws         INTEGER,
  wins          INTEGER,
  winsbydecisionmajority  INTEGER,
  winsbydecisionsplit     INTEGER,
  winsbydecisionunanimous INTEGER,
  winsbyko      INTEGER,
  winsbysubmission INTEGER,
  winsbytkodoctorstoppage INTEGER,
  matchwcrank   INTEGER,
  pfprank       INTEGER
);


-- POPULATE DIMENSIONS --

-- dim_date
INSERT INTO public.dim_date(date, month, year)
SELECT DISTINCT
       s.date,
       EXTRACT(MONTH FROM s.date)::SMALLINT,
       EXTRACT(YEAR  FROM s.date)::SMALLINT
  FROM public.staging_fight AS s
 WHERE s.date IS NOT NULL
   AND NOT EXISTS (
     SELECT 1 FROM public.dim_date d WHERE d.date = s.date
   );

-- dim_event
INSERT INTO public.dim_event(event, date_key, location, city, state, country)
SELECT
    s.event,
    d.date_key,
    s.location,
    s.city,
    s.state,
    s.country
FROM (
  SELECT DISTINCT event, date, location, city, state, country
    FROM public.staging_fight
    WHERE event IS NOT NULL
) AS s
JOIN public.dim_date AS d ON d.date = s.date
LEFT JOIN public.dim_event AS e
  ON e.event = s.event
 AND e.date_key = d.date_key
WHERE e.event_key IS NULL;



-- dim_winner (one-to-one su stg_id)
INSERT INTO public.dim_winner(stg_id, winner, finishdetails, finish, finishround, totalfighttimesecs)
SELECT
  s.stg_id,
  s.winner,
  s.finishdetails,
  s.finish,
  s.finishround,
  s.totalfighttimesecs
FROM public.staging_fight AS s
WHERE s.winner IS NOT NULL;

--dim_type
INSERT INTO public.dim_type (
    weightclass,
    numberofrounds,
    titlebout,
    emptyarena
)
SELECT DISTINCT
    s.weightclass,
    s.numberofrounds,
    s.titlebout                                     AS titlebout,
    s.emptyarena                                     AS emptyarena
FROM public.staging_fight s;

--dim_fighter
ALTER SEQUENCE public.dim_fighter_fighter_key_seq RESTART WITH 1;

INSERT INTO public.dim_fighter(
  fighter, gender, age, stance,
  heightcms, reachcms, weightlbs, record,
  losses, draws, wins,
  winsbydecisionmajority, winsbydecisionsplit,
  winsbydecisionunanimous, winsbyko,
  winsbysubmission, winsbytkodoctorstoppage,
  matchwcrank, pfprank
)
SELECT DISTINCT
   s.r_fighter AS fighter,
   s.gender,
   s.r_age    AS age,
   s.r_stance AS stance,
   s.r_heightcms,
   s.r_reachcms,
   s.r_weightlbs,
   s.r_record,
   s.r_losses,
   s.r_draws,
   s.r_wins,
   s.r_winsbydecisionmajority,
   s.r_winsbydecisionsplit,
   s.r_winsbydecisionunanimous,
   s.r_winsbyko,
   s.r_winsbysubmission,
   s.r_winsbytkodoctorstoppage,
   s.r_matchwcrank,
   s.r_pfprank
FROM public.staging_fight s
WHERE s.r_fighter IS NOT NULL

UNION

SELECT DISTINCT
   s.b_fighter AS fighter,
   s.gender,
   s.b_age    AS age,
   s.b_stance AS stance,
   s.b_heightcms,
   s.b_reachcms,
   s.b_weightlbs,
   s.b_record,
   s.b_losses,
   s.b_draws,
   s.b_wins,
   s.b_winsbydecisionmajority,
   s.b_winsbydecisionsplit,
   s.b_winsbydecisionunanimous,
   s.b_winsbyko,
   s.b_winsbysubmission,
   s.b_winsbytkodoctorstoppage,
   s.b_matchwcrank,
   s.b_pfprank
FROM public.staging_fight s
WHERE s.b_fighter IS NOT NULL;


--FACT TABLE FIGHT CREATION

DROP TABLE IF EXISTS public.fact_fight;

CREATE TABLE public.fact_fight AS
WITH base AS (
  SELECT 
    s.stg_id,
    d.date_key,
    e.event_key,
    t.type_key,                                -- ADDED
    s.referee,
    df_red.fighter_key   AS red_fighter_key,
    df_blue.fighter_key  AS blue_fighter_key,
    dw.winner_key,
    s.heightdif,
    s.agedif,
    s.reachdif,
    s.r_odds,
    s.b_odds,
    s.r_avgkd,
    s.b_avgkd,
    s.r_avgsigstratt,
    s.b_avgsigstratt,
    s.r_avgsigstrlanded,
    s.b_avgsigstrlanded,
    s.r_avgtdatt,
    s.b_avgtdatt,
    s.r_avgtdlanded,
    s.b_avgtdlanded,
    s.r_avgsubatt,
    s.b_avgsubatt,
    s."r_avgctrltime(seconds)" AS r_avgctrltime,
    s."b_avgctrltime(seconds)" AS b_avgctrltime
  FROM public.staging_fight s
  JOIN public.dim_date d
    ON d.date = s.date
  JOIN public.dim_event e
    ON e.event = s.event
   AND e.date_key = d.date_key
  JOIN public.dim_type t                          -- ADDED
    ON t.weightclass    IS NOT DISTINCT FROM s.weightclass
   AND t.numberofrounds IS NOT DISTINCT FROM s.numberofrounds
   AND t.titlebout      IS NOT DISTINCT FROM s.titlebout
   AND t.emptyarena     IS NOT DISTINCT FROM s.emptyarena
  JOIN public.dim_fighter df_red
    ON df_red.fighter = s.r_fighter
  JOIN public.dim_fighter df_blue
    ON df_blue.fighter = s.b_fighter
  JOIN public.dim_winner dw
    ON dw.stg_id = s.stg_id
  WHERE s.winner IS NOT NULL
)
SELECT
  ROW_NUMBER() OVER (ORDER BY stg_id) AS fight_key,
  date_key,
  event_key,
  red_fighter_key,
  blue_fighter_key,
  winner_key,
  type_key,                                     -- ADDED
  referee,
  heightdif,
  agedif,
  reachdif,
  r_odds,
  b_odds,
  r_avgkd,
  b_avgkd,
  r_avgsigstratt,
  b_avgsigstratt,
  r_avgsigstrlanded,
  b_avgsigstrlanded,
  r_avgtdatt,
  b_avgtdatt,
  r_avgtdlanded,
  b_avgtdlanded,
  r_avgsubatt,
  b_avgsubatt,
  r_avgctrltime,
  b_avgctrltime
FROM (
  SELECT DISTINCT ON (stg_id)
    *
  FROM base
  ORDER BY stg_id
) dedup
ORDER BY fight_key;