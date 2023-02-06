select * from dbo.customer_orders
select * from dbo.pizza_names
select * from dbo.pizza_recipes
select * from dbo.runner_orders
select * from dbo.runners

---A. Pizza Metrics---
---How many pizzas were ordered?
SELECT count(pizza_id) AS ordered_pizza FROM dbo.customer_orders

---How many unique customer orders were made?
SELECT count(distinct order_id) AS unique_orders FROM dbo.customer_orders 

---How many successful orders were delivered by each runner?
SELECT 
  runner_id, 
  COUNT(order_id) AS successful_orders_delivered
FROM runner_orders
WHERE duration != ''
GROUP BY runner_id;

---How many of each type of pizza was delivered?
SELECT 
  n.pizza_name,
  COUNT(n.pizza_id) AS successful_pizza_delivered
FROM runner_orders as ro 
Join customer_orders as c
On ro.order_id=c.order_id
Join pizza_names as n
On c.pizza_id=n.pizza_id
WHERE ro.duration != ''
GROUP BY n.pizza_name;


---How many Vegetarian and Meatlovers were ordered by each customer?
select c.customer_id, p.pizza_name, count(c.pizza_id) as order_count
from dbo.customer_orders c join dbo.pizza_names p
on c.pizza_id=p.pizza_id
group by c.customer_id,p.pizza_name


---What was the maximum number of pizzas delivered in a single order?
with CTE as 
(select c.order_id, count(c.pizza_id) as pizza_delivered
from dbo.customer_orders c 
group by c.order_id)
select max(pizza_delivered) as max_pizza_delivered from CTE



---For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  c.customer_id
  ,SUM(
    CASE WHEN c.exclusions != '' OR c.extras != '' THEN 1
    ELSE 0
    END) AS at_least_1_change,
  SUM(
    CASE WHEN c.exclusions = '' AND c.extras = '' THEN 1 
    ELSE 0
    END) AS no_change
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
WHERE r.duration != ''
GROUP BY c.customer_id
ORDER BY c.customer_id;

---How many pizzas were delivered that had both exclusions and extras?
SELECT  
  SUM(
    CASE WHEN exclusions <> '' AND extras != '' THEN 1
    ELSE 0
    END) AS pizza_count_both_exclusions_extras
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
WHERE r.duration != '' 
  AND exclusions <> '' 
  AND extras != '';



---What was the total volume of pizzas ordered for each hour of the day?
Select 
   DATEPART(hour, order_time) as hours_of_day,
   COUNT(order_id) AS pizza_count
from customer_orders
group by DATEPART(hour, order_time)



---What was the volume of orders for each day of the week?
Select 
   DATEPART(day, order_time) as day_of_week,
   COUNT(order_id) AS pizza_count
from customer_orders
group by DATEPART(day, order_time)



----Runner and Customer Experience----
---How many runners signed up for each 1 week period?
Select 
   DATEPART(week, registration_date) as registration_week,
   COUNT(runner_id) AS runners
from dbo.runners
group by 
   DATEPART(week, registration_date)


---What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH time_taken_cte AS
(
 SELECT c.order_id, c.order_time, r.pickup_time, 
  DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS pickup_minutes
 FROM #customer_orders AS c
 JOIN #runner_orders AS r
  ON c.order_id = r.order_id
 WHERE r.distance != 0
 GROUP BY c.order_id, c.order_time, r.pickup_time
)
SELECT AVG(pickup_minutes) AS avg_pickup_minutes
FROM time_taken_cte
WHERE pickup_minutes > 1;



---Is there any relationship between the number of pizzas and how long the order takes to prepare?
 SELECT c.order_id, count(c.order_id), c.order_time, r.pickup_time, 
 DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_time
 FROM dbo.customer_orders AS c
 JOIN dbo.runner_orders AS r
 ON c.order_id = r.order_id
 WHERE r.distance != 0
 GROUP BY c.order_id, c.order_time, r.pickup_time



 ---What was the average distance travelled for each customer?
 SELECT c.customer_id, avg(distance) as avg_distance
 FROM dbo.customer_orders AS c
 JOIN dbo.runner_orders AS r
 ON c.order_id = r.order_id
 WHERE r.distance != 0
 GROUP BY c.customer_id




 ---What was the difference between the longest and shortest delivery times for all orders?
 SELECT 
    MAX(duration::NUMERIC) - MIN(duration::NUMERIC) AS delivery_time_difference
FROM dbo.runner_orders
WHERE duration not like '% %'




---What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT r.runner_id, c.customer_id, c.order_id, 
 COUNT(c.order_id) AS pizza_count, 
 r.distance, (r.duration / 60) AS duration_hr , 
 ROUND((r.distance/r.duration * 60), 2) AS avg_speed
FROM #runner_orders AS r
JOIN #customer_orders AS c
 ON r.order_id = c.order_id
WHERE distance != 0
GROUP BY r.runner_id, c.customer_id, c.order_id, r.distance, r.duration
ORDER BY c.order_id;



--- What is the successful delivery percentage for each runner?
SELECT runner_id, 
 ROUND(100 * SUM
  (CASE WHEN distance = 0 THEN 0
  ELSE 1
  END) / COUNT(*), 0) AS success_perc
FROM runner_orders
GROUP BY runner_id;