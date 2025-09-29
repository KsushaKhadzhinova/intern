-- Display the number of films in each category, sorted in descending order.
SELECT c.name AS category, COUNT(fc.film_id) AS film_count
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
GROUP BY c.category_id, c.name
ORDER BY film_count DESC;

-- Display the top 10 actors whose films were rented the most, sorted in descending order.
SELECT a.actor_id, a.first_name, a.last_name, COUNT(r.rental_id) AS rental_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN inventory i ON fa.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY rental_count DESC
LIMIT 10;

-- Display the category of films that generated the highest revenue.
SELECT c.name AS category, SUM(p.amount) AS total_revenue
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.category_id, c.name
ORDER BY total_revenue DESC
LIMIT 1;

-- Display the titles of films not present in the inventory. Write the query without using the IN operator.
SELECT f.title
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL;

-- Display the top 3 actors who appeared the most in films within the "Children" category. If multiple actors have the same count, include all.
WITH actor_counts AS (
  SELECT fa.actor_id, a.first_name, a.last_name, COUNT(*) AS film_count
  FROM film_actor fa
  JOIN film_category fc ON fa.film_id = fc.film_id
  JOIN category c ON fc.category_id = c.category_id
  JOIN actor a ON fa.actor_id = a.actor_id
  WHERE c.name = 'Children'
  GROUP BY fa.actor_id, a.first_name, a.last_name
)
SELECT actor_id, first_name, last_name, film_count
FROM actor_counts
WHERE film_count >= (
  SELECT film_count
  FROM actor_counts
  ORDER BY film_count DESC
  LIMIT 1 OFFSET 2
)
ORDER BY film_count DESC;


-- Display cities with the count of active and inactive customers (active = 1). Sort by the count of inactive customers in descending order.
SELECT 
  MIN(ci.city) AS city, 
  SUM(CASE WHEN c.active = 1 THEN 1 ELSE 0 END) AS active_count,
  SUM(CASE WHEN c.active = 0 THEN 1 ELSE 0 END) AS inactive_count
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
GROUP BY ci.city_id
ORDER BY inactive_count DESC;


-- Display the film category with the highest total rental hours in cities where customer.address_id belongs to that city and starts with the letter "a". Do the same for cities containing the symbol "-". Write this in a single query.
WITH city_filter AS (
  SELECT city_id, city
  FROM city
  WHERE LOWER(city) LIKE 'a%' OR city LIKE '%-%'
),
rentals_with_lengths AS (
  SELECT r.rental_id, i.film_id, a.city_id, f.length
  FROM rental r
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN film f ON i.film_id = f.film_id
  JOIN customer c ON r.customer_id = c.customer_id
  JOIN address a ON c.address_id = a.address_id
  WHERE a.city_id IN (SELECT city_id FROM city_filter)
)
SELECT
  cf.city_id,
  cf.city,
  cat.name AS category,
  SUM(rwl.length) AS total_rental_hours
FROM rentals_with_lengths rwl
JOIN film_category fc ON rwl.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
JOIN city_filter cf ON rwl.city_id = cf.city_id
GROUP BY cf.city_id, cf.city, cat.name
ORDER BY total_rental_hours DESC
LIMIT 1;

