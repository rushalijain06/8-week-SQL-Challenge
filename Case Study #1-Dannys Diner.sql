CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  SELECT * FROM sales;

  SELECT * FROM menu;

  SELECT * FROM members;



  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
s.customer_id, SUM(price) AS Total_Amount 
FROM menu m 
INNER JOIN sales s 
ON m.product_id = s.product_id 
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
customer_id, COUNT(DISTINCT(order_date)) AS visit_count 
FROM sales 
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH ordered_item AS(
SELECT 
customer_id, order_date, product_name, 
DENSE_RANK() OVER (ORDER BY order_date ASC) dense_rank 
FROM sales s 
INNER JOIN menu m 
ON s.product_id = m.product_id)

SELECT 
customer_id, product_name 
FROM ordered_item
WHERE dense_rank = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
TOP 1 product_name, COUNT(product_name) AS total_purchase 
FROM menu m 
INNER JOIN sales s 
ON m.product_id = s.product_id 
GROUP BY product_name 
ORDER BY COUNT(product_name) DESC;

-- 5. Which item was the most popular for each customer?

WITH popular_item AS(
SELECT 
customer_id, COUNT(s.product_id) AS count_purchase, product_name, 
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank 
FROM sales  s 
INNER JOIN menu m 
ON s.product_id = m.product_id
GROUP BY customer_id, product_name)

SELECT 
customer_id, product_name 
FROM popular_item 
WHERE rank = 1
GROUP BY customer_id, product_name;

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchased_item_after_member AS(
SELECT 
m.customer_id, join_date, order_date, s.product_id, product_name,
RANK() OVER(PARTITION BY m.customer_id ORDER BY order_date ASC) AS rank
FROM members m 
INNER JOIN sales s 
ON m.customer_id = s.customer_id
INNER JOIN menu mm 
ON s.product_id = mm.product_id 
WHERE order_date >= join_date)

SELECT 
customer_id, product_name 
FROM first_purchased_item_after_member
WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH last_purchased_item_before_member AS(
SELECT 
m.customer_id, join_date, order_date, s.product_id, product_name,
RANK() OVER(PARTITION BY m.customer_id ORDER BY order_date DESC) AS rank
FROM members m 
INNER JOIN sales s 
ON m.customer_id = s.customer_id
INNER JOIN menu mm 
ON s.product_id = mm.product_id 
WHERE order_date < join_date)

SELECT 
customer_id, product_name 
FROM last_purchased_item_before_member
WHERE rank = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
m.customer_id, COUNT(s.product_id) AS total_items, SUM(price) AS amount_spent
FROM members m 
INNER JOIN sales s 
ON m.customer_id = s.customer_id
INNER JOIN menu mm 
ON s.product_id = mm.product_id 
WHERE order_date < join_date 
GROUP BY m.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points 
-- would each customer have?

WITH total AS(
SELECT customer_id,
CASE WHEN s.product_id = 1 THEN 20 * price
ELSE 10 * price 
END AS points
FROM sales s 
INNER JOIN menu m 
ON s.product_id = m.product_id)

SELECT 
customer_id, SUM(points) AS total_points
FROM total 
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x 
-- points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH total AS(
SELECT 
m.customer_id, join_date, order_date, s.product_id, product_name, price,
CASE WHEN order_date >= join_date AND order_date < DATEADD(week, 1, join_date) THEN 20 * price
WHEN s.product_id = 1 THEN 20 * price
ELSE 10 * price
END AS points
FROM members m 
INNER JOIN sales s 
ON m.customer_id = s.customer_id
INNER JOIN menu mm 
ON s.product_id = mm.product_id )

SELECT 
customer_id, SUM(points) AS total_points
FROM total 
WHERE order_date <= '2021-01-31'
GROUP BY customer_id;


/* --------------------
   Bonus Questions
   --------------------*/
 -- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to 
-- quickly derive insights without needing to join the underlying tables using SQL.

SELECT 
s.customer_id, order_date, product_name, price,
CASE WHEN order_date < join_date THEN 'N'
WHEN join_date IS NULL THEN 'N'
ELSE 'Y'
END AS member
FROM sales s 
INNER JOIN menu mm
ON s.product_id = mm.product_id
LEFT JOIN members m 
ON s.customer_id = m.customer_id
ORDER BY  s.customer_id, order_date, price DESC;

-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely 
-- does not need the ranking for non-member purchases so he expects null ranking values for the records 
-- when customers are not yet part of the loyalty program.

WITH ranking_table AS(
SELECT 
s.customer_id, order_date, product_name, price,
CASE WHEN order_date < join_date THEN 'N'
WHEN join_date IS NULL THEN 'N'
ELSE 'Y'
END AS member
FROM sales s 
INNER JOIN menu mm
ON s.product_id = mm.product_id
LEFT JOIN members m 
ON s.customer_id = m.customer_id
)

SELECT 
customer_id, order_date, product_name, price, member,
CASE WHEN member = 'N' THEN null
ELSE RANK() OVER (PARTITION BY customer_id, member ORDER BY customer_id, order_date, price DESC)
END AS ranking
FROM ranking_table;

