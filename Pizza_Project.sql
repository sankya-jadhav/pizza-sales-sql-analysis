create database pizza_store;
use pizza_store;
## orders
create table orders (
order_id int primary key,
date text,
time TIME
);

# pizza_types
create table pizza_types (
pizza_type_id varchar(200)primary key,
name varchar(255),
category varchar(100),
Ingredients text
);

## Pizzas
create table pizza(
pizza_id varchar(200) primary key,
pizza_type_id varchar(200),
size varchar(50),
price decimal,
foreign key(pizza_type_id) references pizza_types(pizza_type_id));

## order_details
create table order_details(
order_details_id int primary key,
order_id int,
pizza_id varchar(200),
quantity int,
foreign key (pizza_id) references pizza(pizza_id),
foreign key (order_id) references orders(order_id) );

show tables;

use pizza_store;

## orders
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, date, time);


## order_details
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_details.csv'
INTO TABLE order_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_details_id, order_id, pizza_id, quantity
);

-- Coverting dollar into indian ruppes
SET SQL_SAFE_UPDATES = 0;

UPDATE pizza
SET price = price * 90;

SET SQL_SAFE_UPDATES = 1;


select * from pizza;
select * from pizza_types;
select * from orders;
select * from order_details;



-- --------------------------------------------------------------------------------------------------------
# 1st Retrieve the total number of orders placed.
SELECT COUNT(DISTINCT order_id) FROM orders;

select count(*) as total_orders from orders;

# 2nd Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM order_details od
JOIN pizza p 
ON od.pizza_id = p.pizza_id;

# Q3 Identify the highest-priced pizza
SELECT pizza_id, price
FROM pizza
ORDER BY price DESC
LIMIT 1;

# 4. Identify the most common pizza size ordered.
SELECT p.size, COUNT(*) AS total_orders
FROM order_details od
JOIN pizza p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY total_orders DESC;

#5. List the top 5 most ordered pizza types along with their quantities.
SELECT pt.name, SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizza p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

SELECT pt.name, SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizza p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity asc
LIMIT 10;

#6. Find the total quantity of each pizza category ordered.
SELECT pt.category, SUM(od.quantity) AS total_quantity
FROM order_details as od
JOIN pizza as p ON od.pizza_id = p.pizza_id
JOIN pizza_types as pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category;

-- 7. Determine the distribution of orders by hour of the day-- 
SELECT HOUR(time) AS order_hour, COUNT(*) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;
#most busy hour 
SELECT HOUR(time) AS order_hour, COUNT(*) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY total_orders desc  ;

-- 8. Find the category-wise distribution of pizzas (count of pizza types per category).
SELECT category, COUNT(*) AS pizza_count
FROM pizza_types
GROUP BY category;

#9. Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    AVG(daily_pizzas) AS avg_pizzas_per_day
FROM (
    SELECT o.date, SUM(od.quantity) AS daily_pizzas
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.date
) t;

-- 10. Determine the top 3 most ordered pizza types based on revenue
SELECT pt.name, 
       SUM(od.quantity * p.price) AS revenue
FROM order_details od
JOIN pizza p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;

#11. Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
    pt.name,
    ROUND(
        (SUM(od.quantity * p.price) /
        (SELECT SUM(od2.quantity * p2.price)
         FROM order_details od2
         JOIN pizza p2 ON od2.pizza_id = p2.pizza_id)
        ) * 100, 2
    ) AS revenue_percentage
FROM order_details od
JOIN pizza p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue_percentage DESC;

#12. Analyze the cumulative revenue generated over time.
SELECT 
    o.date,
    SUM(od.quantity * p.price) AS daily_revenue,
    SUM(SUM(od.quantity * p.price)) 
        OVER (ORDER BY o.date) AS cumulative_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizza p ON od.pizza_id = p.pizza_id
GROUP BY o.date
ORDER BY o.date;

#13. Determine the top 3 most ordered pizza types based on revenue for each pizza
-- category.

SELECT category, name, revenue
FROM (
    SELECT 
        pt.category,
        pt.name,
        SUM(od.quantity * p.price) AS revenue,
        RANK() OVER (
            PARTITION BY pt.category 
            ORDER BY SUM(od.quantity * p.price) DESC
        ) AS rnk
    FROM order_details od
    JOIN pizza p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
) t
WHERE rnk <= 3;

#14. Find orders where multiple pizzas were ordered but all pizzas are from the same category.
SELECT o.order_id
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizza p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY o.order_id
HAVING COUNT(DISTINCT pt.category) = 1
   AND SUM(od.quantity) > 1;
   
   #15. Find the ingredient that contributes the most to revenue.
SELECT ingredient, SUM(revenue) AS total_revenue
FROM (
    SELECT 
        TRIM(j.ingredient) AS ingredient,
        (od.quantity * p.price) AS revenue
    FROM order_details od
    JOIN pizza p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    JOIN JSON_TABLE(
        CONCAT('["', REPLACE(pt.ingredients, ',', '","'), '"]'),
        '$[*]' COLUMNS (ingredient VARCHAR(100) PATH '$')
    ) j
) t
GROUP BY ingredient
ORDER BY total_revenue DESC
LIMIT 1;

DESCRIBE pizza;
DESCRIBE pizza_types;
DESCRIBE orders;
DESCRIBE order_details;

#16 What is the average revenue per order?
SELECT 
    SUM(p.price * od.quantity) / COUNT(DISTINCT od.order_id) AS avg_revenue_per_order
FROM order_details od
JOIN pizza p ON od.pizza_id = p.pizza_id;

#17 Day of the week with highest orders & revenue
SELECT 
    DAYNAME(o.date) AS day_of_week,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(p.price * od.quantity) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizza p ON od.pizza_id = p.pizza_id
GROUP BY DAYNAME(o.date)
ORDER BY total_revenue DESC;

#18 Monthly order & revenue trend (best performing month)
SELECT 
    DATE_FORMAT(o.date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(p.price * od.quantity) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizza p ON od.pizza_id = p.pizza_id
GROUP BY DATE_FORMAT(o.date, '%Y-%m')
ORDER BY month;

#19 Hour of the day that drives the most revenue
SELECT 
    HOUR(o.time) AS hour_of_day,
    SUM(p.price * od.quantity) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizza p ON od.pizza_id = p.pizza_id
GROUP BY HOUR(o.time)
ORDER BY total_revenue DESC;

#20 Pizza size contribution to revenue (by category)
SELECT 
    pt.category,
    p.size,
    SUM(p.price * od.quantity) AS revenue
FROM order_details od
JOIN pizza p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category, p.size
ORDER BY pt.category, revenue DESC;

