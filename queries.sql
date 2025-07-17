
--Valutare la avgstats dei fighter appartenteni alle varie categorie di peso, raggruppati per categoria
--nei fight conclusi con decisione rispetto a quelli conclusi con KO/TKO e SUBMISSION

WITH stats AS (
  SELECT
    CASE
      WHEN dw.finish IN ('M-DEC','U-DEC','S-DEC') THEN 'Decision'
      WHEN dw.finish = 'KO/TKO'                  THEN 'KO/TKO'
      WHEN dw.finish = 'SUB'                     THEN 'Submission'
	  ELSE 'Other'
    END                     AS finish_type,
    dt.weightclass,
    f.r_avgkd              AS avgkd,
    f.r_avgsigstrlanded    AS avgsigstrlanded,
    f.r_avgsigstratt       AS avgsigstratt,
    f.r_avgtdlanded        AS avgtdlanded,
    f.r_avgtdatt           AS avgtdatt,
    f.r_avgctrltime        AS avgctrltime,
    f.r_avgsubatt          AS avgsubatt
  FROM public.fact_fight f
  JOIN public.dim_winner dw USING(winner_key)
  JOIN public.dim_type   dt USING(type_key)


  UNION ALL

  SELECT
    CASE
      WHEN dw.finish IN ('M-DEC','U-DEC','S-DEC') THEN 'Decision'
      WHEN dw.finish = 'KO/TKO'                  THEN 'KO/TKO'
      WHEN dw.finish = 'SUB'                     THEN 'Submission'
	  ELSE 'Other'
    END                     AS finish_type,
    dt.weightclass,
    f.b_avgkd              AS avgkd,
    f.b_avgsigstrlanded    AS avgsigstrlanded,
    f.b_avgsigstratt       AS avgsigstratt,
    f.b_avgtdlanded        AS avgtdlanded,
    f.b_avgtdatt           AS avgtdatt,
    f.b_avgctrltime        AS avgctrltime,
    f.b_avgsubatt          AS avgsubatt
  FROM public.fact_fight f
  JOIN public.dim_winner dw USING(winner_key)
  JOIN public.dim_type   dt USING(type_key)
)
SELECT
  finish_type,
  weightclass,
  COUNT(*)                              AS num_fights,
  ROUND( AVG(avgkd         )::numeric, 3) AS avg_avgkd,
  ROUND( AVG(avgsigstrlanded)::numeric, 1) AS avg_avgsigstrlanded,
  ROUND( AVG(avgsigstratt  )::numeric, 1) AS avg_avgsigstratt,
  ROUND( AVG(avgtdlanded   )::numeric, 2) AS avg_avgtdlanded,
  ROUND( AVG(avgtdatt      )::numeric, 2) AS avg_avgtdatt,
  ROUND( AVG(avgctrltime   )::numeric, 1) AS avg_avgctrltime,
  ROUND( AVG(avgsubatt     )::numeric, 3) AS avg_avgsubatt
FROM stats
GROUP BY finish_type, weightclass
ORDER BY finish_type, weightclass;

--Total rows: 52 Query complete 00:00:00.073

--query 2  Identify every event location (city where the underdog—defined by
--having longer odds—won the fight. For each location, compute the total
--number of upsets and the upset percentage relative to total fights held there,
--then compare which venues produce the most surprises.

SELECT
  e.city                                AS city,
  e.country								AS country,
  COUNT(*)                              AS total_fights,
  COUNT(*) FILTER (
    WHERE (dw.winner = 'Blue' AND f.b_odds > f.r_odds)
       OR (dw.winner = 'Red'  AND f.r_odds > f.b_odds)
  )                                      AS num_upsets,
  ROUND(
    100.0
    * COUNT(*) FILTER (
        WHERE (dw.winner = 'Blue' AND f.b_odds > f.r_odds)
           OR (dw.winner = 'Red'  AND f.r_odds > f.b_odds)
      )
    / COUNT(*)
  , 2)                                   AS pct_upsets
FROM public.fact_fight   f
JOIN public.dim_event    e  ON f.event_key   = e.event_key
JOIN public.dim_winner   dw ON f.winner_key  = dw.winner_key
GROUP BY e.city, e.country
HAVING COUNT(*) >= 1
ORDER BY  pct_upsets DESC, num_upsets DESC;

--Total rows: 140 Query complete 00:00:00.072

--query 3: For each (male) weight class, derive the average physical and performance profile of 
--winners (height, reach, average control time, takedown success, and
--significant-strike rate) versus non-winners. Highlight which attributes most
--strongly differentiate champions in each division.

WITH participants AS (
  /* stessa CTE di sopra */
  SELECT
    dt.weightclass,
    'Winner' AS role,
    CASE WHEN dw.winner = 'Red'  THEN df_red.heightcms  ELSE df_blue.heightcms  END AS height,
    CASE WHEN dw.winner = 'Red'  THEN df_red.reachcms   ELSE df_blue.reachcms   END AS reach,
    CASE WHEN dw.winner = 'Red'  THEN df_red.age        ELSE df_blue.age        END AS age
  FROM public.fact_fight f
  JOIN public.dim_winner  dw     USING(winner_key)
  JOIN public.dim_fighter df_red  ON f.red_fighter_key  = df_red.fighter_key
  JOIN public.dim_fighter df_blue ON f.blue_fighter_key = df_blue.fighter_key
  JOIN public.dim_type    dt     USING(type_key)
  WHERE df_red.gender  = 'MALE'
    AND df_blue.gender = 'MALE'

  UNION ALL

  SELECT
    dt.weightclass,
    'Loser' AS role,
    CASE WHEN dw.winner = 'Red'  THEN df_blue.heightcms  ELSE df_red.heightcms  END AS height,
    CASE WHEN dw.winner = 'Red'  THEN df_blue.reachcms   ELSE df_red.reachcms   END AS reach,
    CASE WHEN dw.winner = 'Red'  THEN df_blue.age        ELSE df_red.age        END AS age
  FROM public.fact_fight f
  JOIN public.dim_winner  dw     USING(winner_key)
  JOIN public.dim_fighter df_red  ON f.red_fighter_key  = df_red.fighter_key
  JOIN public.dim_fighter df_blue ON f.blue_fighter_key = df_blue.fighter_key
  JOIN public.dim_type    dt     USING(type_key)
  WHERE df_red.gender  = 'MALE'
    AND df_blue.gender = 'MALE'
),
agg AS (
  SELECT
    weightclass,
    AVG(height) FILTER (WHERE role = 'Winner') AS winner_height,
    AVG(height) FILTER (WHERE role = 'Loser')  AS loser_height,
    AVG(reach)  FILTER (WHERE role = 'Winner') AS winner_reach,
    AVG(reach)  FILTER (WHERE role = 'Loser')  AS loser_reach,
    AVG(age)    FILTER (WHERE role = 'Winner') AS winner_age,
    AVG(age)    FILTER (WHERE role = 'Loser')  AS loser_age
  FROM participants
  GROUP BY weightclass
)
SELECT
  weightclass,
  ROUND((winner_height - loser_height)::numeric,2) AS diff_height_cm,
  ROUND((winner_reach  - loser_reach)::numeric,2)  AS diff_reach_cm,
  ROUND((winner_age    - loser_age)::numeric,2)    AS diff_age_yrs
FROM agg
ORDER BY weightclass;

--Total rows: 9 Query complete 00:00:00.135

--Query 4: This query first “flattens” every fight so each fighter (red or blue) appears once per bout, 
--capturing wins, striking accuracy, takedowns landed, control time and knockdown rate. 
--It then aggregates per fighter—requiring at least five fights—to compute each athlete’s win total and 
--average of those four metrics. Next, it ranks fighters on each statistic (better performance → lower rank).
--Finally, it calculates an overall_rank by summing these five ranks (win % doubled, if desired) and orders fighters 
--so that the most consistently dominant athletes (high accuracy, grappling, control and finishing ability) appear at the top.

WITH participants AS (
  -- Red corner
  SELECT
    f.red_fighter_key   AS fighter_key,
    df_red.fighter      AS fighter,
    CASE WHEN dw.winner = 'Red' THEN 1 ELSE 0 END  AS is_win,
    (f.r_avgsigstrlanded::numeric 
       / NULLIF(f.r_avgsigstratt,0))               AS sig_str_rate,
    f.r_avgtdlanded                                AS td_landed,
    f.r_avgctrltime                                AS ctrl_time,
    f.r_avgkd                                     AS avgkd
  FROM public.fact_fight f
  JOIN public.dim_winner dw      USING (winner_key)
  JOIN public.dim_fighter df_red ON f.red_fighter_key  = df_red.fighter_key

  UNION ALL

  -- Blue corner
  SELECT
    f.blue_fighter_key  AS fighter_key,
    df_blue.fighter     AS fighter,
    CASE WHEN dw.winner = 'Blue' THEN 1 ELSE 0 END AS is_win,
    (f.b_avgsigstrlanded::numeric 
       / NULLIF(f.b_avgsigstratt,0))               AS sig_str_rate,
    f.b_avgtdlanded                                AS td_landed,
    f.b_avgctrltime                                AS ctrl_time,
    f.b_avgkd                                     AS avgkd
  FROM public.fact_fight f
  JOIN public.dim_winner dw       USING (winner_key)
  JOIN public.dim_fighter df_blue ON f.blue_fighter_key = df_blue.fighter_key
),
fighter_stats AS (
  SELECT
    fighter,
    COUNT(*)                     AS fights,
    SUM(is_win)                  AS wins,
    AVG(sig_str_rate)            AS avg_sig_str_rate,
    AVG(td_landed)               AS avg_td_landed,
    AVG(ctrl_time)               AS avg_ctrl_time,
    AVG(avgkd)                   AS avg_avgkd
  FROM participants
  GROUP BY fighter
  having count(*)>=5
),
ranked AS (
  SELECT
    *,
    RANK() OVER (ORDER BY avg_sig_str_rate DESC) AS r_sigstr,
    RANK() OVER (ORDER BY avg_td_landed      DESC) AS r_tdlanded,
    RANK() OVER (ORDER BY avg_ctrl_time      DESC) AS r_ctrl,
    RANK() OVER (ORDER BY avg_avgkd          DESC) AS r_kd,
    RANK() OVER (ORDER BY (wins::numeric / fights) DESC) AS r_winpct
  FROM fighter_stats
)
-- risultati finali con casting a numeric per il ROUND
SELECT
  fighter,
  fights,
  wins,
  ROUND((wins::numeric / fights)::numeric, 2)        AS win_pct,
  ROUND(avg_sig_str_rate::numeric, 3)               AS avg_sig_str_rate,
  r_sigstr                                          AS rank_sigstr,
  ROUND(avg_td_landed::numeric, 2)                  AS avg_td_landed,
  r_tdlanded                                        AS rank_td_landed,
  ROUND(avg_ctrl_time::numeric, 1)                  AS avg_ctrl_time_s,
  r_ctrl                                            AS rank_ctrl_time,
  ROUND(avg_avgkd::numeric, 2)                      AS avg_avgkd,
  r_kd                                              AS rank_avgkd,
   RANK() OVER (
    ORDER BY 
      (0.25 * r_sigstr
     + 0.15 * r_tdlanded
     + 0.15 * r_ctrl
     + 0.15 * r_kd
     + 0.40 * r_winpct) ASC
  ) AS overall_rank
FROM ranked
ORDER BY overall_rank;

--Total rows: 745 Query complete 00:00:00.263