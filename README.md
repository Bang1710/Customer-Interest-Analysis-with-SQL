# FCustomer Interest Analysis

## Introduction
A digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.

Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

## Dataset Description

### > Table ```fresh_segments.interest_map```

| Field           | Description                               | Datatype   |
|-----------------|-------------------------------------------|------------|
| id              | Unique identifier for the interest        | INTEGER    |
| interest_name   | Name of the interest                      | TEXT       |
| interest_summary| Summary information about the interest    | TEXT       |
| created_at      | Timestamp indicating creation time         | TIMESTAMP  |
| last_modified   | Timestamp indicating last modification    | TIMESTAMP  |

### > Table ```fresh_segments.interest_metrics```

| Field             | Description                                           | Datatype    |
|-------------------|-------------------------------------------------------|-------------|
| _month            | Month of the data record                              | VARCHAR(4)  |
| _year             | Year of the data record                               | VARCHAR(4)  |
| month_year        | Combination of month and year                         | VARCHAR(7)  |
| interest_id       | Identifier for the interest                           | VARCHAR(5)  |
| composition       | Composition metric value                              | FLOAT       |
| index_value       | Index value representing the composition value         | FLOAT       |
| ranking           | Ranking of the index value within the month year      | INTEGER     |
| percentile_ranking| Percentile ranking of the index value within the month| FLOAT       |

### Additional Information

- The composition metric is 11.89, meaning that 11.89% of the client’s customer list interacted with the interest interest_id = 32486 - we can link interest_id to a separate mapping table to find the segment name called “Vacation Rental Accommodation Researchers”.

- The index_value is 6.19, which means that the composition value is 6.19 times the average composition value for all Fresh Segments clients’ customers for this particular interest in the month of July 2018.

- The ranking and percentile_ranking relate to the order of index_value records in each month-year. This mapping table links the interest_id with their relevant interest information. You will need to join this table onto the previous interest_details table to obtain the interest_name as well as any details about the summary information.

## A. Data Exploration and Cleansing

### 1. Update Data Type for `month_year` column 
- Dùng truy vấn SQL để cập nhật kiểu dữ liệu của cột `month_year` thành kiểu DATE.
```sql
--Modify the length of column month_year so it can store 10 characters
ALTER TABLE interest_metrics
ALTER COLUMN month_year VARCHAR(10);

--Update values in month_year column
UPDATE interest_metrics
SET month_year =  CONVERT(DATE, '01-' + month_year, 105)

--Convert month_year to DATE
ALTER TABLE fresh_segments.dbo.interest_metrics
ALTER COLUMN month_year DATE;

SELECT TOP(10) * FROM fresh_segments.dbo.interest_metrics;
```
| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking |
|--------|-------|------------|-------------|-------------|-------------|---------|--------------------|
| 7      | 2018  | 2018-07-01 | 32486       | 11.89       | 6.19        | 1       | 99.86              |
| 7      | 2018  | 2018-07-01 | 6106        | 9.93        | 5.31        | 2       | 99.73              |
| 7      | 2018  | 2018-07-01 | 18923       | 10.85       | 5.29        | 3       | 99.59              |
| 7      | 2018  | 2018-07-01 | 6344        | 10.32       | 5.1         | 4       | 99.45              |
| 7      | 2018  | 2018-07-01 | 100         | 10.77       | 5.04        | 5       | 99.31              |
| 7      | 2018  | 2018-07-01 | 69          | 10.82       | 5.03        | 6       | 99.18              |
| 7      | 2018  | 2018-07-01 | 79          | 11.21       | 4.97        | 7       | 99.04              |
| 7      | 2018  | 2018-07-01 | 6111        | 10.71       | 4.83        | 8       | 98.9               |
| 7      | 2018  | 2018-07-01 | 6214        | 9.71        | 4.83        | 8       | 98.9               |
| 7      | 2018  | 2018-07-01 | 19422       | 10.11       | 4.81        | 10      | 98.63              |

### 2. Count of Records for Each `month_year` Value:
- Sử dụng truy vấn SQL để đếm số bản ghi cho mỗi giá trị `month_year` được sắp xếp theo thứ tự thời gian.
```sql
SELECT month_year, COUNT(*) AS cnt
    FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;
```
| month_year | cnt  |
|------------|------|
| NULL       | 1194 |
| 2018-07-01 | 729  |
| 2018-08-01 | 767  |
| 2018-09-01 | 780  |
| 2018-10-01 | 857  |
| 2018-11-01 | 928  |
| 2018-12-01 | 995  |
| 2019-01-01 | 973  |
| 2019-02-01 | 1121 |
| 2019-03-01 | 1136 |
| 2019-04-01 | 1099 |
| 2019-05-01 | 857  |
| 2019-06-01 | 824  |
| 2019-07-01 | 864  |
| 2019-08-01 | 1149 |
### 3. Handling Null Values:
- Trả lời câu hỏi về việc xử lý giá trị null trong bảng `fresh_segments.interest_metrics`.
```sql
--interest_id = 21246 have NULL _month, _year, and month_year
SELECT * FROM interest_metrics
    WHERE month_year IS NULL
ORDER BY interest_id DESC;
```
| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking |
|--------|-------|------------|-------------|-------------|-------------|---------|--------------------|
| NULL   | NULL  | NULL       | 21246       | 1.61        | 0.68        | 1191    | 0.25               |
| NULL   | NULL  | NULL       | NULL        | 1.51        | 0.63        | 1193    | 0.08               |
| NULL   | NULL  | NULL       | NULL        | 1.64        | 0.62        | 1194    | 0                  |
| NULL   | NULL  | NULL       | NULL        | 6.12        | 2.85        | 43      | 96.4               |
| NULL   | NULL  | NULL       | NULL        | 7.13        | 2.84        | 45      | 96.23              |
| NULL   | NULL  | NULL       | NULL        | 6.82        | 2.84        | 45      | 96.23              |
| NULL   | NULL  | NULL       | NULL        | 5.96        | 2.83        | 47      | 96.06              |
| NULL   | NULL  | NULL       | NULL        | 7.73        | 2.82        | 48      | 95.98              |
| NULL   | NULL  | NULL       | NULL        | 5.37        | 2.82        | 48      | 95.98              |
| NULL   | NULL  | NULL       | NULL        | 6.15        | 2.82        | 48      | 95.98              |
```sql
--Delete rows that are null in column interest_id (1193 rows)
DELETE FROM interest_metrics
WHERE interest_id IS NULL;
```
### 4. Identify Missing or Extra Interest IDs:
- Sử dụng truy vấn SQL để xác định số lượng `interest_id` không tồn tại trong bảng `fresh_segments.interest_map`.
```sql
SELECT 
    COUNT(DISTINCT map.id) AS count_id_in_map,
    COUNT(DISTINCT metrics.interest_id) AS count_id_in_metric,
    SUM(CASE WHEN map.id IS NULL THEN 1 END) AS not_in_metric,
    SUM(CASE WHEN metrics.interest_id is NULL THEN 1 END) AS not_in_map
FROM interest_metrics metrics
    FULL JOIN interest_map map ON metrics.interest_id = map.id;
```

| count_id_in_map | count_id_in_metric | not_in_metric | not_in_map |
|--------------|------------------|---------------|------------|
| 1209         | 1202             | NULL          | 7          |

Comments:
- There are 1209 id in table interest_map.
- There are 1202 interest_id in table interest_metrics.
- No id values appear in table interest_map but don't appear in interest_id of table interest_metrics.
- There are 7 interest_id appearing in table interest_metrics but not appearing in id of table interest_map.

### 5. Summarize Interest IDs:
   - Tính toán tổng số bản ghi cho mỗi giá trị `interest_id` trong bảng `fresh_segments.interest_map`.
```sql
SELECT COUNT(*) AS count_id_in_map
FROM interest_map;
```

| map_id_count |
|--------------|
| 1209         |
### 6. Table Join for Analysis:
   - Xác định loại join cần sử dụng để phân tích dữ liệu và minh chứng.
 ```sql
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
```

| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking | interest_name                   | interest_summary                                       | created_at                   | last_modified                |
|--------|-------|------------|-------------|-------------|-------------|---------|--------------------|---------------------------------|--------------------------------------------------------|------------------------------|------------------------------|
| 7      | 2018  | 2018-07-01 | 21246       | 2.26        | 0.65        | 722     | 0.96               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 8      | 2018  | 2018-08-01 | 21246       | 2.13        | 0.59        | 765     | 0.26               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 9      | 2018  | 2018-09-01 | 21246       | 2.06        | 0.61        | 774     | 0.77               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 10     | 2018  | 2018-10-01 | 21246       | 1.74        | 0.58        | 855     | 0.23               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 11     | 2018  | 2018-11-01 | 21246       | 2.25        | 0.78        | 908     | 2.16               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 12     | 2018  | 2018-12-01 | 21246       | 1.97        | 0.7         | 983     | 1.21               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 1      | 2019  | 2019-01-01 | 21246       | 2.05        | 0.76        | 954     | 1.95               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 2      | 2019  | 2019-02-01 | 21246       | 1.84        | 0.68        | 1109    | 1.07               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 3      | 2019  | 2019-03-01 | 21246       | 1.75        | 0.67        | 1123    | 1.14               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| 4      | 2019  | 2019-04-01 | 21246       | 1.58        | 0.63        | 1092    | 0.64               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
| NULL   | NULL  | NULL       | 21246       | 1.61        | 0.68        | 1191    | 0.25               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04.0000000 | 2018-06-11 17:50:04.0000000 |
### 7. Validating Data in Joined Tables:
   - Kiểm tra xem có bản ghi nào có giá trị `month_year` trước giá trị `created_at` trong bảng `fresh_segments.interest_map` hay không.
```sql
SELECT COUNT(*) AS count_month_year_before_created_at
FROM interest_metrics metrics
    JOIN interest_map map
    ON metrics.interest_id = map.id
WHERE metrics.month_year < CAST(map.created_at AS DATE);
```
| cnt  |
|------|
| 188  |
- There are 188 month_year values that are before created_at values. 
- However, it may be the case that those 188 created_at values were created at the same month as month_year values.
- The reason is because month_year values were set on the first date of the month by default in Question 1.
- To check that, we turn the create_at to the first date of the month:

```sql
SELECT COUNT(*) AS count_month_year_before_created_at_in_first_date_of_the_month
FROM interest_metrics metrics
    JOIN interest_map map
    ON map.id = metrics.interest_id
WHERE metrics.month_year < CAST(DATEADD(DAY, -DAY(map.created_at)+1, map.created_at) AS DATE);

SELECT map.created_at, DATEADD(DAY, -DAY(map.created_at)+1, map.created_at) FROM interest_map as map
```
| cnt  |
|------|
| 0  |
- Yes, all month_year and created_at were at the same month. Therefore, these values are valid.
## B. Segment Analysis

### 1. Top and Bottom Interests by Composition:
- Xác định 10 interests có giá trị composition lớn nhất và nhỏ nhất cho mỗi `month_year`.
- Create a temporary table ```interest_metrics_edited```
```sql
SELECT * INTO #interest_metrics_edited
FROM interest_metrics
WHERE interest_id NOT IN (
    SELECT interest_id
    FROM interest_metrics
    WHERE interest_id IS NOT NULL
    GROUP BY interest_id
    HAVING COUNT(DISTINCT month_year) < 6
);
```
- Check the count of interests_id
```sql
SELECT 
  COUNT(interest_id) AS all_interests,
  COUNT(DISTINCT interest_id) AS unique_interests
FROM #interest_metrics_edited
```
- Create a CTE max_composition to find the maximum composition value for each interest.
- To keep the corresponding month_year, use the window funtion MAX() OVER() instead of the aggregate function MAX() with GROUP BY.
- Create a CTE composition_rank to rank all maximum compositions for each interest_id in any month_year from the CTE max_composition
- Filter top 10 or bottom 10 interests using WHERE
- then JOIN max_composition with interest_map to take the interest_name for each corresponding interest_id

```sql
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
```
- Top 10 interests that have the largest composition values
```sql
SELECT 
  DISTINCT TOP 10 cr.interest_id,
  im.interest_name,
  cr.rnk
FROM composition_rank cr
JOIN interest_map im ON cr.interest_id = im.id
ORDER BY cr.rnk
```
- Bottom 10 interests that have the largest composition values
```sql
SELECT 
  DISTINCT TOP 10 cr.interest_id,
  im.interest_name,
  cr.rnk
FROM composition_rank cr
JOIN interest_map im ON cr.interest_id = im.id
ORDER BY cr.rnk DESC;
```
### 2. Lowest Average Ranking Values:
   - Tìm 5 interests có giá trị ranking trung bình thấp nhất.
```sql
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
```
### 3. Largest Standard Deviation in Percentile Ranking:
   - Tìm 5 interests có độ lệch chuẩn lớn nhất trong giá trị percentile_ranking.
```sql
SELECT 
    DISTINCT TOP 5
    metrics.interest_id,
    map.interest_name,
    ROUND(STDEV(metrics.percentile_ranking) OVER(PARTITION BY metrics.interest_id), 2) AS std_percentile_ranking
FROM #interest_metrics_edited metrics
JOIN interest_map map
    ON metrics.interest_id = map.id
ORDER BY std_percentile_ranking DESC;
```
### 4. Minimum and Maximum Percentile Rankings:
- Xác định giá trị percentile_ranking tối thiểu và tối đa cho 5 interests từ câu hỏi trước.
- Based on the query for the previous question
```sql
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
```

## C. Index Analysis

### 1. Top 10 Interests by Average Composition:
- Xác định 10 interests hàng đầu theo giá trị composition trung bình cho mỗi tháng.
- -Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.
```sql
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
```
### 2. Most Frequently Appearing Interest:
- Xác định interest xuất hiện nhiều nhất trong top 10.
```sql
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
```
### 3. Average of Average Composition:
- Tính trung bình của giá trị composition trung bình cho 10 interests hàng đầu cho mỗi tháng.
```sql
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
```



