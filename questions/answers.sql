-- Answer1:
select p.id, p.name,count(o.order_id)as num_items_in_succesful_orders
-- product_id, product_name and count  order_id was selected
from alt_school.products p 
join alt_school.line_items li  on p.id =li.item_id 
-- I joined line_items table with products table using inner join in order to find the common values between the two tables
join alt_school.orders o   on li.order_id =o.order_id  
-- joined order table and line_item table as well 
where o.status = 'success'
-- filter the selected columns to only where status in the order table ='success'
group by p.id
order by num_items_in_succesful_orders desc;
-- This will display the count of orders from the highest to the lowest.


--Answer 2:
with success_checkouts as (
    -- a CTE is created with the name success_checkouts
select
	e.customer_id,
	(e.event_data ->> 'item_id')::int as item_id,
	(e.event_data ->> 'quantity')::int as quantity,
	(
        --customer_id, item_id and quantity are selected 
	select
		count(*)
		-- counting the items in the cart during checkout
	from
		alt_school.events e2
	where
		e2.customer_id = e.customer_id
		and e2.event_data ->> 'item_id' = e.event_data ->> 'item_id'
		and e2.event_data ->> 'status' = 'add_to_cart') as cart_items
	-- where
from
	alt_school.events e
where
	e.customer_id in (
	select
		e.customer_id --customer_id was  selected from events table
	from
		alt_school.events e
	where
		e.event_data ->> 'status' = 'success')
	-- filtering cutomers who had successful checkouts 
	and e.event_data ->> 'event_type' = 'add_to_cart'
	-- and added event_type is 'add_to_cart'
order by
	e.customer_id
    
 )
 select
	sc.customer_id,
	c.location,
	sum(sc.quantity * p.price) total_spend
    -- customer_id from the CTE succcessful_checkout,location from customers table 
    -- and the sum of the products of sc.quantity and price which equals to total_spend
from
	success_checkouts sc
join alt_school.customers c
		using(customer_id)
join alt_school.products p on
	sc.item_id = p.id
group by
	sc.customer_id,
	c."location"
order by
	total_spend desc
limit 5;
-- The five countries with highest
-- spenders are Taiwan, Rwanda, Switzerland, Singapore and Korea in descending order.



--Answer 3:
select c.location, count(e.event_data ->>'event_type')as checkout_count
--location of the customer, event type was selected as checkout count
from alt_school.customers c 
join alt_school.events e on c.customer_id =e.customer_id
-- joined the table cutomers and events
where e.event_data ->>'status'='success'
--to determine where the checkout was a success, the status condition was set to success. 
group by c.location

order by checkout_count desc limit 1;
-- To determine the most common country, the limit was set to one. 
--The most commmon country where successful checkout occured was Korea.



--Answer 4:
with abandoned_carts as( --a CTE was created and name as abandoned_carts
select
	e.customer_id  --customer_id was selected from the events_table
from
	alt_school.events e
where
	e.event_data ->>'event_type' in ('visit', 'add_to_cart', 'remove_from_cart', 'checkout')
	and e.event_data ->>'status' != 'success'
	
-- all the events in the event_type jsonb column was selected and status that did not include successful checkouts.
-- This will enable the cutomers who engaged in all events but at the end abandoned their carts to be selected.
)
select
	ac.customer_id, -- this is to select from the table expression abandoned_carts ac (i.e the customer_id with all the conditions)
	count(*) as num_events
from
	alt_school.events e2
join abandoned_carts ac on
	e2.customer_id = ac.customer_id
where
	e2.event_data->>'event_type' in('add_to_cart', 'remove_from_cart')
-- This will enable the events before abandonement excluding visits that is adding to and removing from the cart to be selected.
group by
	ac.customer_id
order by
	num_events desc;
-- customers that visited, added, removed , checkout but abandoned their cart will be displayed in the first column 
-- and the number of events (adding to and removing from cart) each customer did will be displayed in the second column
-- The highest number of events before abandoning the cart is 23.


--Answer 5:
select
	ROUND(AVG(visits),2) as average_visits
--The ROUND() function is used to round the average visits to two decimal places.
--calculates the average number of visits per customer.
from
	(
	select
		e.customer_id::uuid as customer_id,
		COUNT(*) as visits
	from
		alt_school.events e
	where
		e.event_data ->> 'event_type' = 'visit'
		and exists (
		select
			1
		from
			alt_school.events e2
		where
			e2.customer_id = e.customer_id
			and e2.event_data ->> 'status' = 'success'
      )
-- customer_id and counts the number of visits (event_type = 'visit') 
--for each customer who has at least one successful transaction (event_data ->> 'status' = 'success').
	group by
		e.customer_id
) as visit_counts;
-- The average visits per customer is 4.47
