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

1. **Update Data Type for `month_year` column** 
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

SELECT TOP(5) * FROM fresh_segments.dbo.interest_metrics;
```
2. **Count of Records for Each `month_year` Value**:
- Sử dụng truy vấn SQL để đếm số bản ghi cho mỗi giá trị `month_year` được sắp xếp theo thứ tự thời gian.
```sql
SELECT month_year, COUNT(*) AS cnt
    FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;
```
3. **Handling Null Values**:
   - Trả lời câu hỏi về việc xử lý giá trị null trong bảng `fresh_segments.interest_metrics`.
4. **Identify Missing or Extra Interest IDs**:
   - Sử dụng truy vấn SQL để xác định số lượng `interest_id` không tồn tại trong bảng `fresh_segments.interest_map`.
5. **Summarize Interest IDs**:
   - Tính toán tổng số bản ghi cho mỗi giá trị `interest_id` trong bảng `fresh_segments.interest_map`.
6. **Table Join for Analysis**:
   - Xác định loại join cần sử dụng để phân tích dữ liệu và minh chứng.
7. **Validating Data in Joined Tables**:
   - Kiểm tra xem có bản ghi nào có giá trị `month_year` trước giá trị `created_at` trong bảng `fresh_segments.interest_map` hay không.

### Phần B: Segment Analysis

1. **Top and Bottom Interests by Composition**:
   - Xác định 10 interests có giá trị composition lớn nhất và nhỏ nhất cho mỗi `month_year`.
2. **Lowest Average Ranking Values**:
   - Tìm 5 interests có giá trị ranking trung bình thấp nhất.
3. **Largest Standard Deviation in Percentile Ranking**:
   - Tìm 5 interests có độ lệch chuẩn lớn nhất trong giá trị percentile_ranking.
4. **Minimum and Maximum Percentile Rankings**:
   - Xác định giá trị percentile_ranking tối thiểu và tối đa cho 5 interests từ câu hỏi trước.

### Phần C: Index Analysis

1. **Top 10 Interests by Average Composition**:
   - Xác định 10 interests hàng đầu theo giá trị composition trung bình cho mỗi tháng.
2. **Most Frequently Appearing Interest**:
   - Xác định interest xuất hiện nhiều nhất trong top 10.
3. **Average of Average Composition**:
   - Tính trung bình của giá trị composition trung bình cho 10 interests hàng đầu cho mỗi tháng.
4. **3-Month Rolling Average of Max Composition**:
   - Tính giá trị trung bình 3 tháng cho giá trị composition lớn nhất từ tháng 9 năm 2018 đến tháng 8 năm 2019 và bao gồm các interests đứng đầu trước đó.

## Đóng góp

Nếu bạn muốn đóng góp vào dự án, vui lòng mở một issue hoặc gửi pull request trên GitHub.

## Giấy phép

[MIT License](LICENSE)

# Fresh Segments Database Analysis README

## A. Data Exploration and Cleansing

### 1. Update `month_year` column in `fresh_segments.interest_metrics` table:
- Change the data type of the `month_year` column to DATE with the start of the month.

```sql
-- SQL Queries
ALTER TABLE interest_metrics
ALTER COLUMN month_year VARCHAR(10);

UPDATE interest_metrics
SET month_year = CONVERT(DATE, '01-' + month_year, 105);

ALTER TABLE fresh_segments.dbo.interest_metrics
ALTER COLUMN month_year DATE;

SELECT TOP(5) * FROM fresh_segments.dbo.interest_metrics;
```
-- SQL Query
SELECT month_year, COUNT(*) AS cnt
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;
