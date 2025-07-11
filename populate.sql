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
  finishround                REAL,
  totalfighttimesecs         REAL,
  titlebout                  BOOLEAN,
  weightclass                TEXT,
  numberofrounds             REAL,
  emptyarena                 TEXT,
  heightdif                  REAL,
  agedif                     REAL,
  reachdif                   REAL,
  r_age                      REAL,
  r_stance                   TEXT,
  r_heightcms                REAL,
  r_reachcms                 REAL,
  r_weightlbs                REAL,
  b_odds                     REAL,
  b_record                   TEXT,
  b_age                      REAL,
  b_stance                   TEXT,
  b_heightcms                REAL,
  b_reachcms                 REAL,
  b_weightlbs                REAL,
  r_odds                     REAL,
  r_record                   TEXT,
  r_losses                   REAL,
  r_draws                    REAL,
  r_wins                     REAL,
  r_winbydecisionmajority    REAL,
  r_winbydecisionunanimous   REAL,
  r_winsbydecisionmajority   REAL,
  r_winsbydecisionsplit      REAL,
  r_winsbydecisionunanimous  REAL,
  r_winsbyko                 REAL,
  r_winsbysubmission         REAL,
  r_winsbytkodoctorstoppage  REAL,
  b_losses                   REAL,
  b_draws                    REAL,
  b_wins                     REAL,
  b_winbydecisionmajority    REAL,
  b_winbydecisionunanimous   REAL,
  b_winsbydecisionmajority   REAL,
  b_winsbydecisionsplit      REAL,
  b_winsbydecisionunanimous  REAL,
  b_winsbyko                 REAL,
  b_winsbysubmission         REAL,
  b_winsbytkodoctorstoppage  REAL,
  r_avgkd                    REAL,
  r_avgsigstratt             REAL,
  r_avgsigstrlanded          REAL,
  r_avgtdatt                 REAL,
  r_avgtdlanded              REAL,
  r_avgsubatt                REAL,
  "r_avgctrltime(seconds)"   REAL,
  r_matchwcrank              REAL,
  r_pfprank                  REAL,
  b_avgkd                    REAL,
  b_avgsigstratt             REAL,
  b_avgsigstrlanded          REAL,
  b_avgtdatt                 REAL,
  b_avgtdlanded              REAL,
  b_avgsubatt                REAL,
  "b_avgctrltime(seconds)"   REAL,
  b_matchwcrank              REAL,
  b_pfprank                  REAL
);

-- 1) Drop di tutte le tabelle ad eccezione di staging_fight
DROP TABLE IF EXISTS public.fact_fight CASCADE;
DROP TABLE IF EXISTS public.dim_winner CASCADE;
DROP TABLE IF EXISTS public.dim_event CASCADE;
DROP TABLE IF EXISTS public.dim_r_fighter CASCADE;
DROP TABLE IF EXISTS public.dim_b_fighter CASCADE;
DROP TABLE IF EXISTS public.dim_date CASCADE;

-- 2) Aggiungo/resetto stg_id in staging_fight
ALTER TABLE public.staging_fight
  DROP COLUMN IF EXISTS stg_id CASCADE;
ALTER TABLE public.staging_fight
  ADD COLUMN stg_id SERIAL PRIMARY KEY;

-- 3) Creo le tabelle dimensione

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

CREATE TABLE public.dim_b_fighter (
  b_fighter_key SERIAL PRIMARY KEY,
  b_fighter     TEXT NOT NULL UNIQUE,
  gender        TEXT,
  weightclass   TEXT,
  b_age         REAL,
  b_stance      TEXT,
  b_heightcms   REAL,
  b_reachcms    REAL,
  b_weightlbs   REAL,
  b_record      TEXT,
  b_losses      REAL,
  b_draws       REAL,
  b_wins        REAL,
  b_winbydecisionmajority   REAL,
  b_winbydecisionunanimous  REAL,
  b_winsbydecisionmajority  REAL,
  b_winsbydecisionsplit     REAL,
  b_winsbydecisionunanimous REAL,
  b_winsbyko      REAL,
  b_winsbysubmission        REAL,
  b_winsbytkodoctorstoppage REAL,
  b_matchwcrank   REAL,
  b_pfprank       REAL
);

CREATE TABLE public.dim_r_fighter (
  r_fighter_key SERIAL PRIMARY KEY,
  r_fighter     TEXT NOT NULL UNIQUE,
  gender        TEXT,
  weightclass   TEXT,
  r_age         REAL,
  r_stance      TEXT,
  r_heightcms   REAL,
  r_reachcms    REAL,
  r_weightlbs   REAL,
  r_record      TEXT,
  r_losses      REAL,
  r_draws       REAL,
  r_wins        REAL,
  r_winbydecisionmajority   REAL,
  r_winbydecisionunanimous  REAL,
  r_winsbydecisionmajority  REAL,
  r_winsbydecisionsplit     REAL,
  r_winsbydecisionunanimous REAL,
  r_winsbyko      REAL,
  r_winsbysubmission        REAL,
  r_winsbytkodoctorstoppage REAL,
  r_matchwcrank   REAL,
  r_pfprank       REAL
);

CREATE TABLE public.dim_winner (
  winner_key         SERIAL PRIMARY KEY,
  stg_id             INTEGER NOT NULL UNIQUE
                      REFERENCES public.staging_fight(stg_id),
  winner             TEXT    NOT NULL,
  finishdetails      TEXT,
  finish             TEXT,
  finishround        SMALLINT,
  totalfighttimesecs REAL
);

-- 4) Popolo le dimensioni da staging_fight

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
) AS s0
JOIN public.dim_date AS d ON d.date = s0.date
LEFT JOIN public.dim_event AS e
  ON e.event = s0.event
 AND e.date_key = d.date_key
WHERE e.event_key IS NULL;

-- dim_b_fighter
INSERT INTO public.dim_b_fighter(
      b_fighter, gender, weightclass, b_age, b_stance,
      b_heightcms, b_reachcms, b_weightlbs, b_record,
      b_losses, b_draws, b_wins,
      b_winbydecisionmajority, b_winbydecisionunanimous,
      b_winsbydecisionmajority, b_winsbydecisionsplit,
      b_winsbydecisionunanimous, b_winsbyko,
      b_winsbysubmission, b_winsbytkodoctorstoppage,
      b_matchwcrank, b_pfprank
)
SELECT DISTINCT
       s.b_fighter, s.gender, s.weightclass, s.b_age,   s.b_stance,
       s.b_heightcms, s.b_reachcms, s.b_weightlbs, s.b_record,
       s.b_losses,     s.b_draws,     s.b_wins,
       s.b_winbydecisionmajority, s.b_winbydecisionunanimous,
       s.b_winsbydecisionmajority, s.b_winsbydecisionsplit,
       s.b_winsbydecisionunanimous, s.b_winsbyko,
       s.b_winsbysubmission,      s.b_winsbytkodoctorstoppage,
       s.b_matchwcrank,           s.b_pfprank
  FROM public.staging_fight AS s
LEFT JOIN public.dim_b_fighter AS bf
  ON bf.b_fighter = s.b_fighter
WHERE s.b_fighter IS NOT NULL
  AND bf.b_fighter_key IS NULL;

-- dim_r_fighter
INSERT INTO public.dim_r_fighter(
      r_fighter, gender, weightclass, r_age, r_stance,
      r_heightcms, r_reachcms, r_weightlbs, r_record,
      r_losses, r_draws, r_wins,
      r_winbydecisionmajority, r_winbydecisionunanimous,
      r_winsbydecisionmajority, r_winsbydecisionsplit,
      r_winsbydecisionunanimous, r_winsbyko,
      r_winsbysubmission, r_winsbytkodoctorstoppage,
      r_matchwcrank, r_pfprank
)
SELECT DISTINCT
       s.r_fighter, s.gender, s.weightclass, s.r_age,   s.r_stance,
       s.r_heightcms, s.r_reachcms, s.r_weightlbs, s.r_record,
       s.r_losses,     s.r_draws,     s.r_wins,
       s.r_winbydecisionmajority, s.r_winbydecisionunanimous,
       s.r_winsbydecisionmajority, s.r_winsbydecisionsplit,
       s.r_winsbydecisionunanimous, s.r_winsbyko,
       s.r_winsbysubmission,      s.r_winsbytkodoctorstoppage,
       s.r_matchwcrank,           s.r_pfprank
  FROM public.staging_fight AS s
LEFT JOIN public.dim_r_fighter AS rf
  ON rf.r_fighter = s.r_fighter
WHERE s.r_fighter IS NOT NULL
  AND rf.r_fighter_key IS NULL;

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

-- 1) Indici sulla tabella di staging per i campi usati nei JOIN
CREATE INDEX IF NOT EXISTS idx_stg_date       ON public.staging_fight(date);
CREATE INDEX IF NOT EXISTS idx_stg_event      ON public.staging_fight(event);
CREATE INDEX IF NOT EXISTS idx_stg_r_fighter  ON public.staging_fight(r_fighter);
CREATE INDEX IF NOT EXISTS idx_stg_b_fighter  ON public.staging_fight(b_fighter);
-- stg_id è PRIMARY KEY quindi ha già un indice

-- 2) Indice composito su dim_event per il join su (event, date_key)
CREATE INDEX IF NOT EXISTS idx_dim_event
  ON public.dim_event(event);

-- 3) (Opzionale) se vuoi essere super sicuro che dim_date faccia lookup rapido su date
CREATE INDEX IF NOT EXISTS idx_dim_date_date 
  ON public.dim_date(date);
TRUNCATE public.fact_fight;
ALTER SEQUENCE public.fact_fight_fight_key_seq RESTART WITH 1;

INSERT INTO public.fact_fight(
  date_key, event_key, referee,
  r_fighter_key, b_fighter_key, winner_key,
  heightdif, agedif, reachdif,
  r_odds, b_odds,
  r_avgkd, b_avgkd,
  r_avgsigstratt, b_avgsigstratt,
  r_avgsigstrlanded, b_avgsigstrlanded,
  r_avgtdatt, b_avgtdatt,
  r_avgtdlanded, b_avgtdlanded,
  r_avgsubatt, b_avgsubatt,
  "r_avgctrltime(seconds)","b_avgctrltime(seconds)"
)
SELECT DISTINCT ON (s.stg_id)
  d.date_key,
  e.event_key,
  s.referee,
  rf.r_fighter_key,
  bf.b_fighter_key,
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
FROM public.staging_fight AS s
  JOIN public.dim_date      AS d  ON d.date    = s.date
  JOIN public.dim_event     AS e  ON e.event   = s.event
                                 
  JOIN public.dim_r_fighter AS rf ON rf.r_fighter = s.r_fighter
  JOIN public.dim_b_fighter AS bf ON bf.b_fighter = s.b_fighter
  JOIN public.dim_winner    AS dw ON dw.stg_id     = s.stg_id
WHERE s.winner IS NOT NULL;