# Danny's Diner SQL Case Study

Welcome to the Danny's Diner SQL Case Study! This project explores customer transactions and membership information for a fictional Japanese restaurant. Using SQL, we dive into customer behaviors, spending patterns, and menu preferences to generate actionable insights for the restaurant.


## 📝 Case Study Questions and SQL Queries
## Table of Contents
- [Overview](#overview)
- [Problem Statement](#Problem-Statement)
- [Case Study Questions and Solutions](#Case-Study-Questions-and-Solutions)
  - [1. Total Amount Spent by Each Customer](#1-total-amount-spent-by-each-customer)
  - [2. Days Each Customer Visited](#2-days-each-customer-visited)
  - [3. First Item Purchased by Each Customer](#3-first-item-purchased-by-each-customer)
  - [4. Most Purchased Item on the Menu](#4-most-purchased-item-on-the-menu)
  - [5. Most Popular Item for Each Customer](#5-most-popular-item-for-each-customer)
  - [6. First Item Purchased After Joining](#6-first-item-purchased-after-joining)
  - [7. Item Purchased Before Becoming a Member](#7-item-purchased-before-becoming-a-member)
  - [8. Total Items and Amount Spent Before Membership](#8-total-items-and-amount-spent-before-membership)
  - [9. Points Earned by Each Customer](#9-points-earned-by-each-customer)
  - [10. Double Points in First Week of Membership](#10-double-points-in-first-week-of-membership)
- [Conclusion](#conclusion)

📖 ## Overview
Danny’s Diner opened in early 2021, focusing on three Japanese cuisine staples: sushi, curry, and ramen. Danny is curious about his customers' habits—what they enjoy, how frequently they visit, and how much they spend. The aim of this project is to extract insights to help Danny understand his customers and optimize his loyalty program. 

Through this analysis, Danny hopes to make data-driven decisions about expanding his customer loyalty program to build deeper connections and improve customer satisfaction.

🎯 ##  Problem Statement
Danny's primary goals are to:
- Understand customer visit patterns and preferences
- Track spending by each customer and identify top items
- Determine the impact of his loyalty program

The insights gathered will help Danny deliver a better experience and potentially expand the loyalty program to enhance customer engagement and retention.

 📊 ## Datasets and ER Diagram

We have three tables within the `dannys_diner` database:

1. **sales**: Customer purchases, with `order_date` and `product_id`.
2. **menu**: Menu items with `product_id`, `product_name`, and `price`.
3. **members**: Loyalty program membership data with `join_date`.

![Danny's Diner ERD Diagram](path/to/ERD-image.png) <!-- Update with actual image path -->

---




---

## Case Study Questions and Solutions

The SQL queries below answer various questions to understand customer behavior and loyalty at Danny's Diner. Each query is documented with the respective question .

  ### 1. Total Amount Spent by Each Customer
  
-- Question 1: What is the total amount spent by each customer?

```sql

SELECT c.customer_id,
       SUM(m.price) AS total_amount
FROM dannys_dinner.sales AS c
INNER JOIN dannys_dinner.menu AS m
    ON c.product_id = m.product_id
GROUP BY customer_id;
```
### 2. Days Each Customer Visited
   
-- Question 2: How many times has each customer visited?

```sql
SELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_count
FROM dannys_dinner.sales
GROUP BY customer_id;

```

### 3. First Item Purchased by Each Customer

-- Question 3: What was the first item from the menu purchased by each customer?

```sql
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
```


### 4. Most Purchased Item on the Menu
-- Question 4: What is the most purchased item on the menu and how many times was it purchased?

```sql
SELECT TOP 1 m.product_name,
             COUNT(s.product_id) AS total_purchases
FROM dannys_dinner.sales AS s
INNER JOIN dannys_dinner.menu AS m
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchases DESC;
```


### 5. Most Popular Item for Each Customer
 
-- Question 5: What is the most popular item for each customer?
```sql
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
```


### 6. First Item Purchased After Joining
  
-- Question 6: What was the first item purchased after each customer became a member?

```sql
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

```

### 7. Item Purchased Before Becoming a Member

-- Question 7: What was the last item purchased by each customer before they became a member?

```sql
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

```

### 8. Total Items and Amount Spent Before Membership

-- Question 8: What is the total number of items and total amount spent by each customer before they became a member?
```sql

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
```

### 9. Points Earned by Each Customer
  
-- Question 9: How many points did each customer earn from their purchases? (1 dollar = 10 points, sushi is 2x points)

```sql

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
```

### 10. Double Points in the First Week of Membership
-- Question 10: How many points did each customer earn in January?

```SQL
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

```
