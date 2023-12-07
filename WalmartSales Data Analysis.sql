-- Create database ---------

CREATE DATABASE IF NOT EXISTS WalmartSales;

use WalmartSales;

-- Create table ----------

CREATE TABLE IF NOT EXISTS sales
(
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
    date text NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);

-- UPLOAD Dataset-----------

-- Data cleaning  ------------

-- viewing data in sales table ----
SELECT * FROM sales;


-- Checking the format and description of columns in the sales table ---
describe sales;


-- Add the time_of_day column  ----------
SELECT time,
	(CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END) AS time_of_day
FROM sales;


ALTER TABLE sales 
ADD COLUMN time_of_day VARCHAR(20);

SET SQL_SAFE_UPDATES = 0;

UPDATE sales
SET time_of_day = (
	CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END
);


-- Add day_name column  ----------
SELECT date, DAYNAME(date)
FROM sales;

ALTER TABLE sales 
ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(STR_TO_DATE(COALESCE(date, '2000-01-01'), '%d-%m-%Y'));


-- Add month_name column  ----------
SELECT date, MONTHNAME(date)
FROM sales;

ALTER TABLE sales 
ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTHNAME(STR_TO_DATE(date, '%d-%m-%Y %H:%i:%s'));



-- Business  Questions To Answer ----------------------


-- 1.How many unique cities does the data have?  --
Select distinct City from sales;  


-- 2. In which city is each branch? --
select distinct city, branch from sales;


-- 3. How many unique product lines does the data have? --
select distinct product_line from sales;


-- 4. What is the most selling product line? --
select sum(quantity) as qty, product_line
from sales
group by product_line
order by qty desc;


-- 5.  What is the total revenue by month? --
select month_name as month,sum(total) as total_Revenue
from sales
group by month_name
order by total_Revenue DESC;


-- 6. What month had the largest COGS? --
select month_name as month,sum(cogs) as max_cogs
from sales
group by month
order by max_cogs desc;


-- 7. What product line had the largest revenue? --
select product_line, sum(total) as revenue
from sales
group by product_line
order by revenue desc;


-- 8.  What is the city with the largest revenue? --
select city,sum(total) as revenue
from sales
group by city
order by revenue desc;


-- 9. Which branch sold more products than average product sold?  -- 
select branch, sum(quantity) 
from sales
group by branch
having sum(quantity) > (select avg(quantity) from sales);


-- 10. What is the most common product line by gender? --
select gender, product_line,count(gender) as total
from sales
group by gender, product_line
order by total desc 
limit 1;


-- 11. What is the average rating of each product line? --
select round(avg(rating),2) as average, product_line
from sales
group by product_line
order by  average desc;


-- 12. How many unique payment methods does the data have? --
select distinct Payment from sales;


-- 13. What is the gender of most of the customers? --
select gender,count(gender) as total
from sales
group by gender
order by total desc limit 1;


-- 14. What is the gender distribution per branch? --
SELECT gender,COUNT(*) as gender_count
FROM sales
WHERE branch = "C" 
GROUP BY gender
ORDER BY gender_count DESC;


-- 15. Which time of the day do customers give most ratings? --
SELECT time_of_day,round(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY time_of_day
ORDER BY avg_rating DESC;


-- 16. Which day fo the week has the best avg ratings? --
SELECT day_name,AVG(rating) AS avg_rating
FROM sales
GROUP BY day_name 
ORDER BY avg_rating DESC;


-- 17. Which day of the week has the best average ratings per branch? --
SELECT day_name,COUNT(day_name) total_sales
FROM sales
GROUP BY day_name
ORDER BY total_sales DESC;


-- 18. Number of sales made in each time of the day per weekday? --
SELECT time_of_day, COUNT(*) AS total_sales
FROM sales
GROUP BY time_of_day 
ORDER BY total_sales DESC;


-- 19. Rank Products Based on Quantity Sold Within Each Product Line? --
SELECT product_line,quantity,
       RANK() OVER (PARTITION BY product_line ORDER BY quantity DESC) AS QuantityRank
FROM sales;


-- 20. Calculate Running Total Revenue for Each Product Line Over Time? --
SELECT product_line, Date,total,
       SUM(total) OVER (PARTITION BY product_line ORDER BY Date) AS RunningTotalRevenue
FROM sales;


-- 21. Identify Products with Quantity Sold Above Average Within Each Product Line? --
SELECT product_line, quantity,
       AVG(quantity) OVER (PARTITION BY product_line) AS AvgQuantity,
       CASE
           WHEN quantity > ( AVG(quantity) OVER (PARTITION BY product_line) ) THEN 'Above Average'
           ELSE 'Below Average'
       END AS QuantityCategory
FROM sales;


-- 22. Categorize Products Based on Quantity Sold? --
SELECT product_line,quantity,
       CASE
           WHEN quantity <= 5 THEN 'Low Quantity'
           WHEN quantity > 5 AND quantity <= 8 THEN 'Moderate Quantity'
           WHEN quantity > 8 THEN 'High Quantity'
           ELSE 'Unknown'
       END AS QuantityCategory
FROM sales;


-- 23. Classify Revenue into Different Tiers? --
SELECT total,
       CASE
           WHEN total <= 350 THEN 'Low Revenue'
           WHEN total > 350 AND total <= 750 THEN 'Moderate Revenue'
           WHEN total > 750 THEN 'High Revenue'
           ELSE 'Unknown'
       END AS RevenueCategory
FROM sales; 


-- 24. Calculate Total Revenue by Product Line Using a CTE? --
WITH RevenueCTE AS 
   (
    SELECT product_line,SUM(total) AS TotalRevenue
    FROM sales
    GROUP BY product_line
   )
SELECT * FROM RevenueCTE;


-- 25. Identify Products with Quantity Sold Above Average Within Each Product Line Using a CTE? --
WITH AvgQuantityCTE AS 
   (    
    SELECT product_line,AVG(quantity) AS AvgQuantity
    FROM sales
    GROUP BY product_line
   )
SELECT s.product_line,s.quantity,
       CASE
           WHEN s.quantity > AvgQuantity THEN 'Above Average'
           ELSE 'Below Average'
       END AS QuantityCategory
FROM sales as s
JOIN AvgQuantityCTE as aq
ON s.product_line = aq.product_line;

