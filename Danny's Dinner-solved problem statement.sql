select * from dbo.sales
select * from dbo.menu
select * from dbo.members


--What is the total amount each customer spent at the restaurant?

select  s.customer_id, sum(m.price) as total_amount 
from sales s left join menu m
on s.product_id=m.product_id
group by s.customer_id


--How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) as total_days
from sales group by customer_id


--What was the first item from the menu purchased by each customer?

with CTE as
(select s.customer_id, 
       m.product_name,
	   s.order_date,
	   DENSE_RANK() over (partition by s.customer_id order by s.order_date) as rank
from sales s  join menu m
on s.product_id=m.product_id
group by s.customer_id, m.product_name, s.order_date)
select customer_id, product_name from CTE where rank=1 




--What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 m.product_name, count(m.product_id) as purchased
from sales s  join menu m
on s.product_id=m.product_id
group by  m.product_name
order by count(m.product_id) desc



--Which item was the most popular for each customer?

with CTE as
(select s.customer_id, 
        m.product_name,
		count(m.product_id) as count_product,
		DENSE_RANK() over (partition by s.customer_id order by count(m.product_id) desc) as rank 
from sales s  join menu m
on s.product_id=m.product_id
group by s.customer_id, m.product_name,m.product_id)
select customer_id, product_name from CTE where rank=1




--Which item was purchased first by the customer after they became a member?

with CTE as 
(select s.customer_id, 
       m.product_name,
       DENSE_RANK() over (partition by s.customer_id order by s.order_date)as rank
from sales s  join menu m
on s.product_id=m.product_id 
join members p
on s.customer_id=p.customer_id
where s.order_date>=p.join_date)
select customer_id, product_name, rank from CTE where rank=1




--Which item was purchased just before the customer became a member?

with CTE as 
(select s.customer_id, 
       m.product_name,
       DENSE_RANK() over (partition by s.customer_id order by s.order_date)as rank
from sales s  join menu m
on s.product_id=m.product_id 
join members p
on s.customer_id=p.customer_id
where s.order_date<p.join_date)
select customer_id, product_name, rank from CTE where rank=1




--What is the total items and amount spent for each member before they became a member?

select s.customer_id, 
       count(m.product_name),
	   sum(m.price)
from sales s  join menu m
on s.product_id=m.product_id 
join members p
on s.customer_id=p.customer_id
where s.order_date<p.join_date
group by s.customer_id



--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with CTE as 
(select s.customer_id, 
       m.product_name, 
	   (case when m.product_id=1 then m.price*20 else m.price*10 end) as points 
from sales s  join menu m
on s.product_id=m.product_id)
select customer_id, sum(points)  from CTE group by customer_id



--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?

with CTE as 
(select *, 
	   DATEADD (day, 6, join_date) as ddate,
	   EOMONTH('2021-01-31') as last_date
 from members
 )

select s.customer_id, 
       sum(case when m.product_id=1 then price*20 
	            when p.order_date between cte.ddate and cte.last_date then price*20
		   else price*10
		   end) as points

from CTE cte join sales s
On cte.customer_id = S.customer_id
Join Menu M
On M.product_id = S.product_id
Where S.order_date < cte.last_date
Group by S.customer_id




