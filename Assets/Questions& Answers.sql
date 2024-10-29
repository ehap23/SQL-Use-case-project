-------------------------------------------Case Study Questions

--- Each of the following case study questions can be answered using a single SQL statement:

-- 1- What is the total amount each customer spent at the restaurant?

SELECT c.customer_id,
       SUM(m.price) AS total_amount
FROM dannys_dinner.sales AS c
INNER JOIN dannys_dinner.menu AS m
    ON c.product_id = m.product_id
GROUP BY customer_id;

--#################################################################


-- 2- How many days has each customer visited the restaurant?

SELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_count
FROM dannys_dinner.sales
GROUP BY customer_id;

--#################################################################

-- 3- What was the first item from the menu purchased by each customer?

WITH items AS (
    SELECT s.customer_id, 
           m.product_name,
           ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank_item
    FROM dannys_dinner.sales AS s
    INNER JOIN dannys_dinner.menu AS m
        ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM items
WHERE rank_item = 1;

-- 4- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name,
             COUNT(s.product_id) AS total_purchases
FROM dannys_dinner.sales AS s
INNER JOIN dannys_dinner.menu AS m
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchases DESC;

--##################################################################

-- 5- Which item was the most popular for each customer?

WITH item_rank AS (
    SELECT s.customer_id,
           m.product_name,
           COUNT(s.order_date) AS product_count,
           DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.order_date) DESC) AS rank
    FROM dannys_dinner.sales AS s
    INNER JOIN dannys_dinner.menu AS m
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name
FROM item_rank
WHERE rank = 1;

---###########################################################################

-- 6- Which item was purchased first by the customer after they became a member?

WITH purchases AS (
    SELECT s.customer_id,
           s.order_date,
           s.product_id,
           m.join_date,
           DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS order_rank
    FROM dannys_dinner.sales AS s
    JOIN dannys_dinner.members AS m
        ON s.customer_id = m.customer_id
    WHERE s.order_date > m.join_date
)
SELECT p.customer_id,
       menu.product_name
FROM purchases AS p
JOIN dannys_dinner.menu AS menu
    ON p.product_id = menu.product_id
WHERE order_rank = 1;



--############################################

-- 7- Which item was purchased just before the customer became a member?

WITH last_purchase AS (
    SELECT s.customer_id,
           s.order_date,
           s.product_id,
           m.join_date,
           DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS order_rank
    FROM dannys_dinner.sales AS s
    JOIN dannys_dinner.members AS m
        ON s.customer_id = m.customer_id
    WHERE s.order_date < m.join_date
)
SELECT lp.customer_id,
       menu.product_name
FROM last_purchase AS lp
JOIN dannys_dinner.menu AS menu
    ON lp.product_id = menu.product_id
WHERE order_rank = 1;


-- 8- What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id,
       COUNT(s.product_id) AS total_items_ordered,
       SUM(m.price) AS total_amount_spent
FROM dannys_dinner.menu AS m
JOIN dannys_dinner.sales AS s
    ON m.product_id = s.product_id
JOIN dannys_dinner.members AS mem
    ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;
--####################################################################

-- 9- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


WITH points_table AS (
    SELECT s.customer_id,
           m.product_name,
           m.price,
           CASE
               WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
               ELSE m.price * 10
           END AS points
    FROM dannys_dinner.sales AS s
    JOIN dannys_dinner.menu AS m
        ON s.product_id = m.product_id
)
SELECT customer_id,
       SUM(points) AS total_points
FROM points_table
GROUP BY customer_id;

--#################################################

-- 10- In the first week after a customer joins the program (including their join date) they earn 2x points 
--on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH january_points AS (
    SELECT s.customer_id,
           m.product_name,
           m.price,
           CASE
               WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day, 7, mb.join_date) THEN m.price * 10 * 2
               WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
               ELSE m.price * 10
           END AS points,
           s.order_date,
           mb.join_date
    FROM dannys_dinner.menu AS m
    JOIN dannys_dinner.sales AS s
        ON m.product_id = s.product_id
    JOIN dannys_dinner.members AS mb
        ON s.customer_id = mb.customer_id
    WHERE s.order_date < '2021-02-01'
)
SELECT customer_id,
       SUM(points) AS total_points
FROM january_points
GROUP BY customer_id;
