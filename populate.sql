-- 3) Popolamento dim_date
INSERT INTO public.dim_date(date, month, year)
SELECT DISTINCT date, month, year
  FROM public.staging_fight
 WHERE date IS NOT NULL
ON CONFLICT (date) DO NOTHING;

-- 4) Popolamento dim_event
INSERT INTO public.dim_event(event, date_key, location, city, state, country)
SELECT DISTINCT s.event,
       d.date_key,
       s.location,
       s.city,
       s.state,
       s.country
  FROM public.staging_fight AS s
  JOIN public.dim_date       AS d ON d.date = s.date
 WHERE NOT EXISTS (
    SELECT 1
      FROM public.dim_event e
     WHERE e.event = s.event
 );
 
-- 5) Popolamento dim_b_fighter
INSERT INTO public.dim_b_fighter(
   b_fighter, gender, weightclass, b_age, b_stance, b_heightcms, b_reachcms, b_weightlbs,
   b_record, b_losses, b_draws, b_wins,
   b_winbydecisionmajority, b_winbydecisionunanimous,
   b_winsbydecisionmajority, b_winsbydecisionsplit, b_winsbydecisionunanimous,
   b_winsbyko, b_winsbysubmission, b_winsbytkodoctorstoppage,
   b_matchwcrank, b_pfprank
)
SELECT DISTINCT
   b_fighter, gender, weightclass, b_age, b_stance, b_heightcms, b_reachcms, b_weightlbs,
   b_record, b_losses, b_draws, b_wins,
   b_winbydecisionmajority, b_winbydecisionunanimous,
   b_winsbydecisionmajority, b_winsbydecisionsplit, b_winsbydecisionunanimous,
   b_winsbyko, b_winsbysubmission, b_winsbytkodoctorstoppage,
   b_matchwcrank, b_pfprank
  FROM public.staging_fight
;

-- 6) Popolamento dim_r_fighter
INSERT INTO public.dim_r_fighter(
   r_fighter, gender, weightclass, r_age, r_stance, r_heightcms, r_reachcms, r_weightlbs,
   r_record, r_losses, r_draws, r_wins,
   r_winbydecisionmajority, r_winbydecisionunanimous,
   r_winsbydecisionmajority, r_winsbydecisionsplit, r_winsbydecisionunanimous,
   r_winsbyko, r_winsbysubmission, r_winsbytkodoctorstoppage,
   r_matchwcrank, r_pfprank
)
SELECT DISTINCT
   r_fighter, gender, weightclass, r_age, r_stance, r_heightcms, r_reachcms, r_weightlbs,
   r_record, r_losses, r_draws, r_wins,
   r_winbydecisionmajority, r_winbydecisionunanimous,
   r_winsbydecisionmajority, r_winsbydecisionsplit, r_winsbydecisionunanimous,
   r_winsbyko, r_winsbysubmission, r_winsbytkodoctorstoppage,
   r_matchwcrank, r_pfprank
  FROM public.staging_fight
;

-- 7) Popolamento dim_winner
INSERT INTO public.dim_winner(winner, finishdetails, finish, finishround, totalfighttimesecs)
SELECT DISTINCT winner, finishdetails, finish, finishround, totalfighttimesecs
  FROM public.staging_fight
ON CONFLICT (winner) DO NOTHING;

-- 8) Popolamento fact_fight
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
   r_avgctrltime, b_avgctrltime
)
SELECT
  d.date_key,
  e.event_key,
  s.referee,
  rf.r_fighter_key,
  bf.b_fighter_key,
  w.winner_key,
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
  JOIN public.dim_date       d  ON d.date = s.date
  JOIN public.dim_event      e  ON e.event = s.event
  JOIN public.dim_r_fighter  rf ON rf.r_fighter = s.r_fighter
  JOIN public.dim_b_fighter  bf ON bf.b_fighter = s.b_fighter
  JOIN public.dim_winner     w  ON w.winner = s.winner
;