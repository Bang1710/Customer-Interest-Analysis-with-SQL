# Fresh Segments Analysis 

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
### Result
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
### 3. Handling Null Values:
- Trả lời câu hỏi về việc xử lý giá trị null trong bảng `fresh_segments.interest_metrics`.
```sql
--interest_id = 21246 have NULL _month, _year, and month_year
SELECT * FROM interest_metrics
    WHERE month_year IS NULL
ORDER BY interest_id DESC;

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
### 7. Validating Data in Joined Tables:
   - Kiểm tra xem có bản ghi nào có giá trị `month_year` trước giá trị `created_at` trong bảng `fresh_segments.interest_map` hay không.
```sql
SELECT COUNT(*) AS count_month_year_before_created_at
FROM interest_metrics metrics
    JOIN interest_map map
    ON metrics.interest_id = map.id
WHERE metrics.month_year < CAST(map.created_at AS DATE);
```
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
- Yes, all month_year and created_at were at the same month. Therefore, these values are valid.
## B. Segment Analysis

### 1. Top and Bottom Interests by Composition:
- Xác định 10 interests có giá trị composition lớn nhất và nhỏ nhất cho mỗi `month_year`.
```sql

```
### Result

### 2. Lowest Average Ranking Values:
   - Tìm 5 interests có giá trị ranking trung bình thấp nhất.
```sql

```
### Result

### 3. Largest Standard Deviation in Percentile Ranking:
   - Tìm 5 interests có độ lệch chuẩn lớn nhất trong giá trị percentile_ranking.
```sql

```
### Result

### 4. Minimum and Maximum Percentile Rankings:
   - Xác định giá trị percentile_ranking tối thiểu và tối đa cho 5 interests từ câu hỏi trước.
```sql

```
### Result


## C. Index Analysis

### 1. Top 10 Interests by Average Composition:
- Xác định 10 interests hàng đầu theo giá trị composition trung bình cho mỗi tháng.
```sql

```
### Result

### 2. Most Frequently Appearing Interest:
- Xác định interest xuất hiện nhiều nhất trong top 10.
```sql

```
### Result

### 3. Average of Average Composition:
- Tính trung bình của giá trị composition trung bình cho 10 interests hàng đầu cho mỗi tháng.
```sql

```
### Result


