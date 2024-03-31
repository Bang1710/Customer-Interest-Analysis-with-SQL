/*--------------------------A. Data Exploration and Cleansing------------------------------------------------
1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest)
 with the null values appearing first?
3. What do you think we should do with these null values in the fresh_segments.interest_metrics
4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? 
What about the other way around?
5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246
in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except 
from the id column.
7. Are there any records in your joined table where the month_year value is before the created_at value 
from the fresh_segments.interest_map table? Do you think these values are valid and why?
*/

--1/
--Modify the length of column month_year so it can store 10 characters
ALTER TABLE interest_metrics
ALTER COLUMN month_year VARCHAR(10);

--Update values in month_year column
UPDATE interest_metrics
SET month_year =  CONVERT(DATE, '01-' + month_year, 105)

--Convert month_year to DATE
ALTER TABLE fresh_segments.dbo.interest_metrics
ALTER COLUMN month_year DATE;

SELECT TOP(5) * FROM fresh_segments.dbo.interest_metrics;

--2/ 
SELECT month_year, COUNT(*) AS cnt
    FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;

--3/
--interest_id = 21246 have NULL _month, _year, and month_year
SELECT * FROM interest_metrics
    WHERE month_year IS NULL
ORDER BY interest_id DESC;

--Delete rows that are null in column interest_id (1193 rows)
DELETE FROM interest_metrics
WHERE interest_id IS NULL;

--4/
SELECT 
    COUNT(DISTINCT map.id) AS count_id_in_map,
    COUNT(DISTINCT metrics.interest_id) AS count_id_in_metric,
    SUM(CASE WHEN map.id IS NULL THEN 1 END) AS not_in_metric,
    SUM(CASE WHEN metrics.interest_id is NULL THEN 1 END) AS not_in_map
FROM interest_metrics metrics
    FULL JOIN interest_map map ON metrics.interest_id = map.id;

-- Comments:
/*
- There are 1209 id in table interest_map.
- There are 1202 interest_id in table interest_metrics.
- No id values appear in table interest_map but don't appear in interest_id of table interest_metrics.
- There are 7 interest_id appearing in table interest_metrics but not appearing in id of table interest_map.
*/

--5/
SELECT COUNT(*) AS count_id_in_map
FROM interest_map;

--6/ 
SELECT 
    metrics.*,
    map.interest_name,
    map.interest_summary,
    map.created_at,
    map.last_modified
FROM interest_metrics metrics
    JOIN interest_map map
    ON metrics.interest_id = map.id
WHERE metrics.interest_id = 21246;

--7/
SELECT COUNT(*) AS count_month_year_before_created_at
FROM interest_metrics metrics
    JOIN interest_map map
    ON metrics.interest_id = map.id
WHERE metrics.month_year < CAST(map.created_at AS DATE);

--There are 188 month_year values that are before created_at values. 
--However, it may be the case that those 188 created_at values were created at the same month as month_year values.
--The reason is because month_year values were set on the first date of the month by default in Question 1.
--To check that, we turn the create_at to the first date of the month:

SELECT COUNT(*) AS count_month_year_before_created_at_in_first_date_of_the_month
FROM interest_metrics metrics
    JOIN interest_map map
    ON map.id = metrics.interest_id
WHERE metrics.month_year < CAST(DATEADD(DAY, -DAY(map.created_at)+1, map.created_at) AS DATE);

SELECT map.created_at, DATEADD(DAY, -DAY(map.created_at)+1, map.created_at) FROM interest_map as map

--Yes, all month_year and created_at were at the same month. Therefore, these values are valid.

/*----------------------------B. Segment Analysis-----------------------------------
1. Using our filtered dataset by removing the interests with less than 6 months worth of data, 
    which are the top 10 and bottom 10 interests which have the largest composition values in any month_year ?  
    Only use the maximum composition value for each interest but you must keep the corresponding month_year
2. Which 5 interests had the lowest average ranking value ?
3. Which 5 interests had the largest standard deviation in their percentile_ranking value ?
4. For the 5 interests found in the previous question - 
    what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value ? 
    Can you describe what is happening for these 5 interests ?
*/

--1/
--Create a temporary table [interest_metrics_edited]
SELECT * INTO #interest_metrics_edited
FROM interest_metrics
WHERE interest_id NOT IN (
    SELECT interest_id
    FROM interest_metrics
    WHERE interest_id IS NOT NULL
    GROUP BY interest_id
    HAVING COUNT(DISTINCT month_year) < 6
);

--Check the count of interests_id
SELECT 
  COUNT(interest_id) AS all_interests,
  COUNT(DISTINCT interest_id) AS unique_interests
FROM #interest_metrics_edited

--Create a CTE max_composition to find the maximum composition value for each interest.
--To keep the corresponding month_year, use the window funtion MAX() OVER() instead of the aggregate function MAX() with GROUP BY.
--Create a CTE composition_rank to rank all maximum compositions for each interest_id in any month_year from the CTE max_composition
--Filter top 10 or bottom 10 interests using WHERE
--then JOIN max_composition with interest_map to take the interest_name for each corresponding interest_id

WITH 
    max_composition AS (
    SELECT 
        month_year,
        interest_id,
        MAX(composition) OVER(PARTITION BY interest_id) AS largest_composition
    FROM #interest_metrics_edited -- filtered dataset in which interests with less than 6 months are removed
    WHERE month_year IS NOT NULL
),
    composition_rank AS (
    SELECT *,
        DENSE_RANK() OVER(ORDER BY largest_composition DESC) AS rnk --largest composition des -> rank asc
    FROM max_composition
)

--Top 10 interests that have the largest composition values
SELECT 
  DISTINCT TOP 10 cr.interest_id,
  im.interest_name,
  cr.rnk
FROM composition_rank cr
JOIN interest_map im ON cr.interest_id = im.id
ORDER BY cr.rnk

--Bottom 10 interests that have the largest composition values
SELECT 
  DISTINCT TOP 10 cr.interest_id,
  im.interest_name,
  cr.rnk
FROM composition_rank cr
JOIN interest_map im ON cr.interest_id = im.id
ORDER BY cr.rnk DESC;

--2/
WITH 
    avg_ranking_temp AS (
    SELECT 
        interest_id,
        interest_name,
        AVG(ranking) OVER(PARTITION BY interest_id) AS avg_ranking_value
    FROM #interest_metrics_edited as ime
    JOIN interest_map as im on ime.interest_id = im.id
    WHERE month_year IS NOT NULL
)

SELECT DISTINCT TOP 5 
        avg_tb.interest_id,
        avg_tb.interest_name,
        avg_tb.avg_ranking_value
FROM avg_ranking_temp as avg_tb
ORDER BY avg_tb.avg_ranking_value

--3/
SELECT 
    DISTINCT TOP 5
    metrics.interest_id,
    map.interest_name,
    ROUND(STDEV(metrics.percentile_ranking) OVER(PARTITION BY metrics.interest_id), 2) AS std_percentile_ranking
FROM #interest_metrics_edited metrics
JOIN interest_map map
    ON metrics.interest_id = map.id
ORDER BY std_percentile_ranking DESC;

--4/
--Based on the query for the previous question
WITH 
    largest_std_interests AS (
    SELECT 
    DISTINCT TOP 5 metrics.interest_id,
        map.interest_name,
        map.interest_summary,
        ROUND(STDEV(metrics.percentile_ranking) OVER(PARTITION BY metrics.interest_id), 2) AS std_percentile_ranking
    FROM #interest_metrics_edited metrics
    JOIN interest_map map ON metrics.interest_id = map.id
    ORDER BY std_percentile_ranking DESC
),
    max_min_percentiles AS (
    SELECT 
        lsi.interest_id,
        lsi.interest_name,
        lsi.interest_summary,
        ime.month_year,
        ime.percentile_ranking,
        MAX(ime.percentile_ranking) OVER(PARTITION BY lsi.interest_id) AS max_pct_rnk,
        MIN(ime.percentile_ranking) OVER(PARTITION BY lsi.interest_id) AS min_pct_rnk
    FROM largest_std_interests lsi
    JOIN #interest_metrics_edited ime ON lsi.interest_id = ime.interest_id
)

SELECT 
    interest_id,
    interest_name,
    interest_summary,
    MAX(CASE WHEN percentile_ranking = max_pct_rnk THEN month_year END) AS max_pct_month_year,
    MAX(CASE WHEN percentile_ranking = max_pct_rnk THEN percentile_ranking END) AS max_pct_rnk,
    MIN(CASE WHEN percentile_ranking = min_pct_rnk THEN month_year END) AS min_pct_month_year,
    MIN(CASE WHEN percentile_ranking = min_pct_rnk THEN percentile_ranking END) AS min_pct_rnk
FROM max_min_percentiles
GROUP BY interest_id, interest_name, interest_summary;

/*---------------------------C. Index Analysis------------------------------------------
1. What is the top 10 interests by the average composition for each month ?
2. For all of these top 10 interests - which interest appears the most often ?
3. What is the average of the average composition for the top 10 interests for each month ?
4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and 
include the previous top ranking interests in the same output shown below.
*/

--1/
--Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.
WITH avg_composition_rank AS (
    SELECT 
        metrics.interest_id,
        map.interest_name,
        metrics.month_year,
        ROUND(metrics.composition / metrics.index_value, 2) AS avg_composition,
        DENSE_RANK() OVER(PARTITION BY metrics.month_year ORDER BY metrics.composition / metrics.index_value DESC) AS rnk
    FROM interest_metrics metrics
    JOIN interest_map map 
        ON metrics.interest_id = map.id
    WHERE metrics.month_year IS NOT NULL
)
SELECT * FROM avg_composition_rank 
WHERE rnk <= 10; 

--2/
WITH 
    avg_composition_rank AS (
        SELECT 
            metrics.interest_id,
            map.interest_name,
            metrics.month_year,
            ROUND(metrics.composition / metrics.index_value, 2) AS avg_composition,
            DENSE_RANK() OVER(PARTITION BY metrics.month_year ORDER BY metrics.composition / metrics.index_value DESC) AS rnk
        FROM interest_metrics metrics
        JOIN interest_map map 
            ON metrics.interest_id = map.id
        WHERE metrics.month_year IS NOT NULL
),
    frequent_interests AS (
        SELECT 
            interest_id,
            interest_name,
            COUNT(*) AS freq
        FROM avg_composition_rank
        WHERE rnk <= 10
        GROUP BY interest_id, interest_name
)
SELECT * FROM frequent_interests
WHERE freq IN (SELECT MAX(freq) FROM frequent_interests);

--3/
WITH avg_composition_rank AS (
    SELECT 
        metrics.interest_id,
        map.interest_name,
        metrics.month_year,
        ROUND(metrics.composition / metrics.index_value, 2) AS avg_composition,
        DENSE_RANK() OVER(PARTITION BY metrics.month_year ORDER BY metrics.composition / metrics.index_value DESC) AS rnk
    FROM interest_metrics metrics
    JOIN interest_map map 
        ON metrics.interest_id = map.id
    WHERE metrics.month_year IS NOT NULL
)

SELECT 
    month_year,
    AVG(avg_composition) AS avg_of_avg_composition
FROM avg_composition_rank
WHERE rnk <= 10 
GROUP BY month_year;
