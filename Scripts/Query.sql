-- Create a list of employees and their immediate managers.
SELECT
  e1.firstName,
  e1.lastName,
  e1.title,
  e2.firstName as managername,
  e2.lastName as managername
FROM employee as e1
JOIN employee as e2 on e1.managerId = e2.employeeId;


SELECT * FROM sales;
SELECT * FROM employee;
SELECT * FROM customer;

-- Find sales people who have zero sales
SELECT e.firstName, e.lastName, e.title, e.startDate, s.salesId
FROM employee as e
LEFT JOIN sales as s ON e.employeeId = s.employeeId
WHERE e.title = 'Sales Person' AND s.salesId IS NULL;

-- List all customers & their sales, even if some data is gone
SELECT c.firstName, c.lastName, c.email, s.salesAmount, s.soldDate
FROM customer as c
LEFT JOIN sales as s ON c.customerId = s.customerId
WHERE s.customerId IS NULL
UNION
SELECT c.firstName, c.lastName, c.email, s.salesAmount, s.soldDate
FROM customer as c
RIGHT JOIN sales as s ON c.customerId = s.customerId
WHERE c.customerId IS NULL
UNION
SELECT c.firstName, c.lastName, c.email, s.salesAmount, s.soldDate
FROM customer as c
JOIN sales as s ON c.customerId = s.customerId;


-- How many cars has been sold per employee
SELECT s.employeeId, c.firstName, c.lastName,count(1) as carsold 
FROM sales as s
JOIN customer as c ON s.customerId = c.customerId
GROUP BY employeeId
ORDER BY carsold DESC;

-- Find the least and most expensive car sold by each employee this year
SELECT 
  e.employeeId,
  e.firstName,	
  e.lastName,
  MIN(salesAmount) as min, 
  MAX(salesAmount) as max
FROM employee AS e
JOIN sales AS s ON e.employeeId = s.employeeId
WHERE s.soldDate >= date('now','start of year')
GROUP BY e.employeeId, e.firstName,	e.lastName;

-- Display report for employees who have sold at least 5 cars
SELECT 
  count(1) as no_of_car_sold,
  e.employeeId,
  e.firstName,	
  e.lastName,
  MIN(salesAmount) as min, 
  MAX(salesAmount) as max
FROM employee AS e
JOIN sales AS s ON e.employeeId = s.employeeId
WHERE s.soldDate >= date('now','start of year')
GROUP BY e.employeeId, e.firstName,	e.lastName
HAVING no_of_car_sold > 5
ORDER BY no_of_car_sold DESC;

-- Summarise sales per year by using a CTE
WITH cte AS (
SELECT strftime('%Y', soldDate) AS soldYear, 
  salesAmount
FROM sales
)
SELECT soldYear, 
  FORMAT("$%.2f", sum(salesAmount)) AS AnnualSales
FROM cte
GROUP BY soldYear
ORDER BY soldYear

-- Display cars sold for each employee by month
SELECT emp.firstName, emp.lastName,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '01' 
        THEN salesAmount END) AS JanSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '02' 
        THEN salesAmount END) AS FebSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '03' 
        THEN salesAmount END) AS MarSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '04' 
        THEN salesAmount END) AS AprSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '05' 
        THEN salesAmount END) AS MaySales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '06' 
        THEN salesAmount END) AS JunSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '07' 
        THEN salesAmount END) AS JulSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '08' 
        THEN salesAmount END) AS AugSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '09' 
        THEN salesAmount END) AS SepSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '10' 
        THEN salesAmount END) AS OctSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '11' 
        THEN salesAmount END) AS NovSales,
  SUM(CASE 
        WHEN strftime('%m', soldDate) = '12' 
        THEN salesAmount END) AS DecSales
FROM sales sls
INNER JOIN employee emp
  ON sls.employeeId = emp.employeeId
WHERE sls.soldDate >= '2021-01-01'
  AND sls.soldDate < '2022-01-01'
GROUP BY emp.firstName, emp.lastName
ORDER BY emp.lastName, emp.firstName


-- Find sales of cars which are electric by using a subquery
SELECT sls.soldDate, sls.salesAmount, inv.colour, inv.year
FROM sales sls
INNER JOIN inventory inv
  ON sls.inventoryId = inv.inventoryId
WHERE inv.modelId IN (
  SELECT modelId
  FROM model
  WHERE EngineType = 'Electric'
)

-- For each sales person rank the car models they've sold most
SELECT e.firstName, e.lastName, m.model, COUNT(1) as count,
      rank() OVER(PARTITION BY s.employeeId ORDER BY COUNT(1) DESC) as rank
FROM inventory AS i
JOIN sales as s ON i.inventoryId = s.inventoryId
JOIN model as m ON i.modelId = m.modelId
JOIN employee as e ON s.employeeId = e.employeeId
GROUP BY m.model, e.firstName, e.lastName;

-- add the window function - simplify with cte
with cte_sales as (
SELECT strftime('%Y', soldDate) AS soldYear, 
  strftime('%m', soldDate) AS soldMonth,
  SUM(salesAmount) AS salesAmount
FROM sales
GROUP BY soldYear, soldMonth
)
SELECT soldYear, soldMonth, salesAmount,
  SUM(salesAmount) OVER (
    PARTITION BY soldYear 
    ORDER BY soldYear, soldMonth) AS AnnualSales_RunningTotal
FROM cte_sales
ORDER BY soldYear, soldMonth


-- Displays the number of cars sold this month, and last month
SELECT strftime('%Y-%m', soldDate) AS MonthSold,
  COUNT(*) AS NumberCarsSold,
  LAG (COUNT(*), 1, 0 ) OVER calMonth AS LastMonthCarsSold
FROM sales
GROUP BY strftime('%Y-%m', soldDate)
WINDOW calMonth AS (ORDER BY strftime('%Y-%m', soldDate))
ORDER BY strftime('%Y-%m', soldDate)
