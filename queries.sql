/* ============================================================
   Q1 — ROLL-UP: Year → Month → Total
   Show how fight pace and grappling intensity evolve over time.
   Measures: avg total sig-strike attempts, avg total takedown attempts, fights count.
   ============================================================ */
SELECT
  CASE WHEN GROUPING(d.year)  = 1 THEN 'ALL' ELSE d.year::text  END AS year,
  CASE WHEN GROUPING(d.month) = 1 THEN 'ALL' ELSE d.month::text END AS month,
  COUNT(*) AS fights,
  ROUND(AVG(f.r_avgsigstratt + f.b_avgsigstratt)::numeric, 1) AS avg_total_sig_att,
  ROUND(AVG(f.r_avgtdatt     + f.b_avgtdatt)::numeric, 2)     AS avg_total_td_att
FROM public.fact_fight f
JOIN public.dim_date d on d.date_key = f.date_key
GROUP BY ROLLUP (d.year, d.month)
ORDER BY d.year, d.month;



/* ============================================================
   Q2 — DRILL-DOWN: Weightclass × Scheduled rounds
   Compare fight pace by bout type (weight class) and format (3 vs 5 rounds).
   Measures: avg total sig-strike attempts, avg total control time, fights count.
   ============================================================ */
SELECT
  t.weightclass,
  t.numberofrounds,
  COUNT(*) AS fights,
  ROUND(AVG(f.r_avgsigstratt + f.b_avgsigstratt)::numeric, 1) AS avg_total_sig_att,
  ROUND(AVG(f.r_avgctrltime  + f.b_avgctrltime)::numeric, 1)  AS avg_total_ctrl_time
FROM public.fact_fight f
JOIN public.dim_type t on t.type_key = f.type_key
GROUP BY t.weightclass, t.numberofrounds
ORDER BY t.weightclass, t.numberofrounds;


/* ============================================================
   Q3 — SLICE/DICE: Finish category
   Summarize fight outcomes and relate them to duration.
   Measures: fights count, avg duration (secs).
   ============================================================ */
SELECT
  CASE
    WHEN w.finish IN ('M-DEC','U-DEC','S-DEC') THEN 'Decision'
    WHEN w.finish = 'KO/TKO'                  THEN 'KO/TKO'
    WHEN w.finish = 'SUB'                     THEN 'Submission'
    ELSE 'Other'
  END AS finish_category,
  COUNT(*) AS fights,
  ROUND(AVG(w.totalfighttimesecs)::numeric, 0) AS avg_duration_secs
FROM public.fact_fight f
JOIN public.dim_winner w on w.winner_key = f.winner_key
GROUP BY finish_category
ORDER BY fights DESC;


/* ============================================================
   Q4 — SLICE: Year, DRILL-DOWN: Country → Event
   Compare activity by geography and event, limited to one year.
   Measures: fights count, avg total takedown attempts.
   ============================================================ */
SELECT
  e.country,
  e.event,
  COUNT(*) AS fights,
  ROUND(AVG(f.r_avgtdatt + f.b_avgtdatt)::numeric, 2) AS avg_total_td_att
FROM public.fact_fight f
JOIN public.dim_event e ON e.event_key = f.event_key
JOIN public.dim_date  d ON d.date_key  = f.date_key
WHERE d.year = 2019
GROUP BY e.country, e.event
ORDER BY e.country, fights DESC;

/* ============================================================
   Q5 — Roll-up by Stance
   Show how fighter style (stance) relates to striking volume.
   Measures: appearances count (red+blue), avg sig-strike attempts 
   per appearance.
   ============================================================ */
SELECT
  CASE WHEN GROUPING(x.stance)=1 THEN 'ALL' ELSE COALESCE(x.stance, 'Unknown') END AS stance,
  COUNT(*) AS appearances,
  ROUND(AVG(x.sig_att)::numeric, 1) AS avg_sig_att
FROM (
  SELECT fr.stance, f.r_avgsigstratt AS sig_att
  FROM public.fact_fight f
  JOIN public.dim_fighter fr ON fr.fighter_key = f.red_fighter_key
  UNION ALL
  SELECT fb.stance, f.b_avgsigstratt AS sig_att
  FROM public.fact_fight f
  JOIN public.dim_fighter fb ON fb.fighter_key = f.blue_fighter_key
) x
GROUP BY ROLLUP (x.stance)
ORDER BY x.stance;


/* ============================================================
   Q6 — Top fighters by Control Time (slice: Year)
   Identify fighters who accumulate more control time from a given year.
   Measures: appearances count (red+blue), avg control time per appearance.
   ============================================================ */
WITH appearances AS (
  SELECT d.year, fr.fighter, f.r_avgctrltime AS ctrl_time
  FROM public.fact_fight f
  JOIN public.dim_date d ON d.date_key = f.date_key
  JOIN public.dim_fighter fr ON fr.fighter_key = f.red_fighter_key
  UNION ALL
  SELECT d.year, fb.fighter, f.b_avgctrltime AS ctrl_time
  FROM public.fact_fight f
  JOIN public.dim_date d ON d.date_key = f.date_key
  JOIN public.dim_fighter fb ON fb.fighter_key = f.blue_fighter_key
)
SELECT
  fighter,
  COUNT(*) AS appearances,
  ROUND(AVG(ctrl_time)::numeric, 1) AS avg_ctrl_time
FROM appearances
WHERE year >= 2018
GROUP BY fighter
HAVING COUNT(*) >= 3
ORDER BY avg_ctrl_time DESC
LIMIT 10;

