
-- Create table and then import data to this table in SQL editor manually

CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);

SELECT * FROM sales;

-- FEATURE ENGINEERING

SELECT 
	time,
	(CASE
		WHEN `time` BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
        WHEN `time` BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
        WHEN `time` BETWEEN '18:00:00' AND '21:59:59' THEN 'Evening'
        ELSE 'Night'
	END) AS time_of_the_day
FROM sales;

ALTER TABLE sales ADD COLUMN time_of_the_day VARCHAR(10);

UPDATE sales
SET time_of_the_day = (
	CASE
		WHEN `time` BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
        WHEN `time` BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
        WHEN `time` BETWEEN '18:00:00' AND '21:59:59' THEN 'Evening'
        ELSE 'Night'
	END
);

SELECT 
	`date`,
	DAYNAME(`date`) AS day_name
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(`date`);


SELECT 
	`date`,
    MONTHNAME(`date`) AS month_name
FROM sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTHNAME(`date`);

SELECT * FROM sales;

-- EXPLORATORY DATA ANALYSIS

SELECT DISTINCT city
FROM sales;

SELECT DISTINCT branch
FROM sales;

SELECT DISTINCT city, branch
FROM sales;

-- product

SELECT DISTINCT product_line
FROM sales;

SELECT payment, COUNT(payment) AS num_of_payments
FROM sales
GROUP BY payment
ORDER BY num_of_payments DESC;


SELECT product_line, SUM(quantity) AS total_sold
FROM sales
GROUP BY product_line
ORDER BY total_sold DESC;

SELECT 
	month_name AS month, 
    ROUND(SUM(total), 2) AS total_revenue, 
	SUM(cogs) AS cogs,
    ROUND(SUM(gross_income), 2) AS gross_income
FROM sales
GROUP BY month_name
ORDER BY gross_income DESC;

SELECT 
	product_line, 
    ROUND(SUM(total), 2) AS total_revenue,
    SUM(cogs) AS cogs,
    ROUND(SUM(gross_income), 2) AS gross_income
FROM sales
GROUP BY product_line
ORDER BY gross_income DESC;

SELECT 
	city, 
    branch,
    ROUND(SUM(total), 2) AS total_revenue,
    SUM(cogs) AS cogs,
    ROUND(SUM(gross_income), 2) AS gross_income
FROM sales
GROUP BY city, branch
ORDER BY total_revenue DESC;

SELECT 
	product_line,
    AVG(tax_pct) AS avg_tax
FROM sales
GROUP BY product_line
ORDER BY avg_tax DESC;

SELECT branch, SUM(quantity) AS total_sold
FROM sales
GROUP BY branch
HAVING total_sold > (SELECT AVG(quantity) FROM sales);  

SELECT 
	gender,
    product_line,
    COUNT(gender) AS total_number
FROM sales
GROUP BY gender, product_line
ORDER BY 1, 3 DESC;

SELECT 
	ROUND(AVG(rating), 2) AS avg_rating,
    product_line
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;

-- sales

SELECT 
    day_name, 
    time_of_the_day, 
    COUNT(*) AS number_of_sales
FROM sales
GROUP BY day_name, time_of_the_day
ORDER BY FIELD(day_name, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), number_of_sales DESC;

SELECT
	customer_type,
    gender,
    COUNT(*) AS number_of_sales,
    ROUND(SUM(total), 2) AS total_revenue
FROM sales
GROUP BY customer_type, gender
ORDER BY total_revenue DESC;

SELECT
	city,
    customer_type,
    ROUND(AVG(tax_pct), 2) AS avg_tax_pct
FROM sales
GROUP BY city, customer_type 
ORDER BY city, avg_tax_pct DESC;

-- customer

SELECT * FROM sales;

SELECT
	city,
	gender,
    COUNT(*) AS number_of_sales
FROM sales
GROUP BY gender, city
ORDER BY 1, 3 DESC;
	
SELECT
	city,
	time_of_the_day,
    ROUND(AVG(rating), 3) AS avg_rating
FROM sales
GROUP BY city, time_of_the_day
ORDER BY city, avg_rating DESC;

SELECT
	day_name,
    ROUND(AVG(rating), 3) AS avg_rating
FROM sales
GROUP BY day_name
ORDER BY avg_rating DESC;

