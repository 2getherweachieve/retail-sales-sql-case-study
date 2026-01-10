/*      LEVEL 1: Data Understanding & Cleaning      
====================================================================================================*/

/* 1. Count total number of records in the dataset.*/

SELECT COUNT(*)
FROM retails_sales;

/* 2. Check if there are any NULL values in important columns.*/

SELECT
SUM(CASE WHEN transactions_id IS NULL THEN 1 ELSE 0 END) AS transaction_id_nulls,
SUM(CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END) AS sale_date_nulls,
SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls,
SUM(CASE WHEN quantiy IS NULL THEN 1 ELSE 0 END) AS quantiy_nulls,
SUM(CASE WHEN price_per_unit IS NULL THEN 1 ELSE 0 END) AS price_per_unit_nulls,
SUM(CASE WHEN total_sale IS NULL THEN 1 ELSE 0 END) AS total_sale_nulls
FROM retails_sales;

/* 3. Find the first sale date and the last sale date in the dataset.*/

SELECT MIN(sale_date) AS first_sale_date,
MAX(sale_date) AS last_sale_date
FROM retails_sales;

/* 4. Count how many unique customers are there in the dataset.*/

SELECT COUNT(DISTINCT customer_id) AS unique_cx_count
FROM retails_sales;

/* 5. Find how many transactions each category has.*/

SELECT category, COUNT(transactions_id) AS total_transactions
FROM retails_sales
GROUP BY category;

/*===============================================================================================================*/
/*       LEVEL 2: Core Business Metrics       
=========================================================================================================*/

/* 6. Find total sales revenue.*/

SELECT SUM(total_sale) AS total_sales_revenue
FROM retails_sales;

/* 7. Find total quantity sold.*/

SELECT SUM(quantiy) AS total_quantity
FROM retails_sales;

/* 8. Find total profit.*/

SELECT SUM(total_sale - cogs) AS total_profit
FROM retails_sales;

/* 9. Find the average order value (AOV).*/

SELECT AVG(total_sale) AS avg_order_value
FROM retails_sales;

/* 10. Find the average number of items per transaction.*/

SELECT AVG(quantiy) AS avg_no_of_items
FROM retails_sales;

/* ============================================================================================================
			LEVEL 3: Category & Product Analysis
=================================================================================================================*/

/* 11. Find total sales and total profit by category.*/

SELECT category,
SUM(total_sale) AS total_sales,
SUM(total_sale - cogs) AS total_profit
FROM retails_sales
GROUP BY category;

/* 12. Rank categories by total sales (highest to lowest).*/

SELECT category,
SUM(total_sale) AS total_sales,
DENSE_RANK() OVER (ORDER BY SUM(total_sale) DESC) AS drnk
FROM retails_sales
GROUP BY category;

/* 13. Find the average price per unit by category.*/

SELECT category,
AVG(price_per_unit) AS avg_price_per_unit
FROM retails_sales
GROUP BY category;

/* 14. Which category has the highest profit margin?*/

SELECT category, SUM(total_sale) AS total_sales,
SUM(total_sale - cogs) AS total_profit,
SUM(total_sale - cogs) / SUM(total_sale) AS profit_margin
FROM retails_sales
GROUP BY category
ORDER BY profit_margin DESC
LIMIT 1;

/* 15. Find categories where average transaction value is above the overall average transaction value.*/

SELECT category, AVG(total_sale) AS avg_category_sale
FROM retails_sales
GROUP BY category
HAVING AVG(total_sale) > (
SELECT AVG(total_sale)
FROM retails_sales
);

/*===================================================================================================================
				LEVEL 4: Time-Based Analysis
===================================================================================================================*/

-- 16. Find total sales by year and month.

SELECT YEAR(sale_date) AS year,
MONTH(sale_date) AS month,
SUM(total_sale) AS total_sales
FROM retails_sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
ORDER BY year, month;

-- 17. Find the best-selling month (by total revenue).

SELECT year,
month,
total_revenue
FROM (
SELECT SUM(total_sale) AS total_revenue,
YEAR(sale_date) AS year,
MONTH(sale_date) AS month,
RANK() OVER(ORDER BY SUM(total_sale) DESC) AS rnk
FROM retails_sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
ORDER BY year, month
) t
WHERE rnk = 1;

-- 18. Find the daily average sales.

SELECT ROUND(AVG(sales_per_day), 2) AS daily_avg_sales
FROM
(
SELECT sale_date,
SUM(total_sale) AS sales_per_day
FROM retails_sales
GROUP BY sale_date
) t;

-- 19. Find the hour of the day with the highest total sales.

SELECT 
    hour,
    total_sales
FROM (
    SELECT 
        EXTRACT(HOUR FROM sale_time) AS hour,
        SUM(total_sale) AS total_sales,
        RANK() OVER (ORDER BY SUM(total_sale) DESC) AS rnk
    FROM retails_sales
    GROUP BY EXTRACT(HOUR FROM sale_time)
) t
WHERE rnk = 1;

-- 20. Compare weekday vs weekend total sales.

SELECT
CASE 
  WHEN DAYOFWEEK(sale_date) IN (1,7) THEN 'Weekend'
  ELSE 'Weekday'
END AS day_type,
SUM(total_sale) AS total_sales
FROM retails_sales
GROUP BY day_type;

/*==================================================================================================================
				LEVEL 5: Customer Analysis
===================================================================================================================*/

-- 21. Count number of customers by gender.

SELECT gender,
COUNT(DISTINCT customer_id) AS total_customers
FROM retails_sales
GROUP BY gender;

-- 22. Find total sales by gender.

SELECT gender,
SUM(total_sale) AS total_sales
FROM retails_sales
GROUP BY gender;

-- 23. Find average age of customers per category.

SELECT category,
AVG(age) AS avg_age
FROM retails_sales
GROUP BY category;

-- 24. Find top 10 customers by total spending.

SELECT customer_id,
SUM(total_sale) AS total_spent
FROM retails_sales
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- 25. Find the average number of transactions per customer.

SELECT ROUND(AVG(total_transactions), 0) AS avg_transactions
FROM
(
SELECT customer_id,
COUNT(transactions_id) AS total_transactions
FROM retails_sales
GROUP BY customer_id
) t;

/*====================================================================================================================
					LEVEL 6: Advanced SQL / Interview Level
===================================================================================================================*/

-- 26. Find repeat customers (customers with more than 1 transaction).

SELECT customer_id,
COUNT(transactions_id) AS total_transactions
FROM retails_sales
GROUP BY customer_id
HAVING total_transactions > 1;

-- 27. Identify one-time customers (customers with exactly 1 transaction).

SELECT customer_id
FROM
(
SELECT customer_id,
COUNT(transactions_id) AS total_transactions
FROM retails_sales
GROUP BY 1
) t
WHERE total_transactions = 1;

-- 28. Find each customer’s first and last purchase date.

SELECT customer_id,
MIN(sale_date) AS first_purchase,
MAX(sale_date) AS last_purchase
FROM retails_sales
GROUP BY customer_id;

-- 29. Find month-over-month sales growth.

SELECT year,
month,
total_sales,
prev_month_sales,
(total_sales - prev_month_sales) AS growth
FROM
(
SELECT year, month, total_sales,
LAG(total_sales) OVER(ORDER BY year,month) AS prev_month_sales
FROM
(
SELECT YEAR(sale_date) AS year,
MONTH(sale_date) AS month,
SUM(total_sale) AS total_sales
FROM retails_sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
) t1
) t2;

-- 30. Find transactions where total_sale is higher than the category average.

SELECT *
FROM (
    SELECT 
        transactions_id,
        category,
        total_sale,
        AVG(total_sale) OVER (PARTITION BY category) AS category_avg
    FROM retails_sales
) t
WHERE total_sale > category_avg;

-- 31. Rank customers within each category by total sales.

SELECT category,
customer_id,
total_sales,
RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS rnk
FROM (
	SELECT category,
    customer_id,
    SUM(total_sale) AS total_sales
    FROM retails_sales
    GROUP BY category, customer_id
    ) t;

-- 32. Find the top 3 highest-revenue days.

SELECT 
    sale_date,
    total_sales
FROM (
    SELECT 
        sale_date,
        SUM(total_sale) AS total_sales,
        RANK() OVER (ORDER BY SUM(total_sale) DESC) AS rnk
    FROM retails_sales
    GROUP BY sale_date
) t
WHERE rnk <= 3;

/* 33. Create customer segments based on total spending:
Low (< 5,000)
Medium (5,000–20,000)
High (> 20,000) */

SELECT customer_id,
SUM(total_sale) AS total_spent,
CASE
	WHEN SUM(total_sale) < 5000 THEN 'Low'
    WHEN SUM(total_sale) >= 5000 AND SUM(total_sale) <= 20000 THEN 'Medium'
    ELSE 'High'
    END AS segment
FROM retails_sales
GROUP BY customer_id;

/* ==================================================================================================================
				LEVEL 7: Case-Study / Business Insight Queries (Final Round)
=====================================================================================================================

/* 34. Which category is most popular among each age group:
Age groups:
18–25
26–35
36–45
46+ */

SELECT age_group,
category,
total_transactions
FROM (
SELECT age_group,
category,
total_transactions,
RANK() OVER(PARTITION BY age_group ORDER BY total_transactions DESC) AS rnk
FROM (
SELECT
CASE
	WHEN age BETWEEN 18 AND 25 THEN '18-25'
    WHEN age BETWEEN 26 AND 35 THEN '26-35'
    WHEN age BETWEEN 36 AND 45 THEN '36-45'
    ELSE '46+'
    END AS age_group,
    category,
    COUNT(*) AS total_transactions
    FROM retails_sales
    GROUP BY category, age_group
) t1
) t2
WHERE rnk = 1;

-- 35. Find customers whose spending increased month over month.

SELECT DISTINCT customer_id
FROM (
SELECT
customer_id, year, month, monthly_sales,
LAG(monthly_sales) OVER (PARTITION BY customer_id ORDER BY year, month) AS prev_month_sales
FROM (
SELECT customer_id,
YEAR(sale_date) AS year,
MONTH(sale_date) AS month,
SUM(total_sale) AS monthly_sales
FROM retails_sales
GROUP BY customer_id, YEAR(sale_date), MONTH(sale_date)
) t1
) t2
WHERE monthly_sales > prev_month_sales;

-- 36. Find categories with high sales volume but low profit margin.

WITH category_metrics AS (
    SELECT 
        category,
        SUM(quantity) AS total_quantity,
        SUM(total_sale - cogs) / SUM(total_sale) AS profit_margin
    FROM retails_sales
    GROUP BY category
)
SELECT *
FROM category_metrics
WHERE 
    total_quantity > (SELECT AVG(total_quantity) FROM category_metrics)
AND 
    profit_margin < (SELECT AVG(profit_margin) FROM category_metrics);

-- 37. Find top 5% highest-value transactions.

SELECT transactions_id,
total_sale
FROM (
	SELECT transactions_id,
    total_sale,
    NTILE(20) OVER (ORDER BY total_sale DESC) AS tile
    FROM retails_sales
    ) t
WHERE tile = 1;

/* 38. Build a KPI result table containing:
Total Sales
Total Profit
Total Customers
Avg Order Value
Best Category (by sales)
Best Month (by sales) */

WITH base_kpis AS (
	SELECT SUM(total_sale) AS total_sales,
    SUM(total_sale - cogs) AS total_profit,
    COUNT(DISTINCT customer_id) AS total_customers,
    AVG(total_sale) AS avg_order_value
    FROM retails_sales
),
best_category AS (
	SELECT category
    FROM (
		SELECT category,
		SUM(total_sale) AS total_sales,
		RANK() OVER (ORDER BY SUM(total_sale) DESC) AS rnk
		FROM retails_sales
		GROUP BY category
    ) t
    WHERE rnk = 1
),
best_month AS (
	SELECT CONCAT(year, '-', month) AS best_month
    FROM (
		SELECT YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        SUM(total_sale) AS total_sales,
        RANK() OVER (ORDER BY SUM(total_sale) DESC) AS rnk
        FROM retails_sales
        GROUP BY YEAR(sale_date), MONTH(sale_date)
        ) t
	WHERE rnk = 1
)
SELECT b.total_sales,
b.total_profit,
b.total_customers,
b.avg_order_value,
bc.category AS best_category,
bm.best_month
FROM base_kpis b
CROSS JOIN best_category bc
CROSS JOIN best_month bm;

/* =========================X========================X=============================X=============================*/