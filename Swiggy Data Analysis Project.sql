select * from Swiggy_data;

-- data validation & cleaning 
-- null check 

select 
     sum(case when State is null then 1 else 0 end ) as null_state,
     sum(case when City is null then 1 else 0 end ) as null_city,
     sum(case when Order_date is null then 1 else 0 end ) as null_order_date,
     sum(case when Restaurant_name is null then 1 else 0 end ) as null_restrant_name,
     sum(case when location is null then 1 else 0 end ) as null_location,
     sum(case when Category is null then 1 else 0 end ) as null_category,
     sum(case when Dish_Name is null then 1 else 0 end ) as null_dish_name,
     sum(case when Price_INR is null then 1 else 0 end ) as null_price_inr,
     sum(case when Rating is null then 1 else 0 end ) as null_rating,
     sum(case when Rating_Count is null then 1 else 0 end ) as null_rating_count
     
     from Swiggy_data;

-- blank or empty string 

select * from Swiggy_data
where State ='' or  city=''  or Location='' or Category='' or Dish_Name='';


-- duplicate dictation 

select  State, city, order_date, Restaurant_Name,location , Category, Dish_Name, Price_INR, Rating, Rating_Count, count(*) as cnt   from Swiggy_data
group by 
State, city, order_date, Restaurant_Name,location , Category, Dish_Name, Price_INR, Rating, Rating_Count
having count(*)>1;


with cet as (
select *, row_number() over(
partition by State, city, order_date, Restaurant_Name,location , Category, Dish_Name, Price_INR, Rating, Rating_Count
order by (select null)) as rn 
from Swiggy_data)
delete from cet where rn>1;


-- creating schema 
-- dimension table 
-- date table 

create table dim_date (
date_id int identity(1,1) primary key,
full_date date ,
year int ,
month int ,
month_name varchar(20),
quarter int ,
day int ,
week int )

-- dim location 

create table dim_location (
location_id int identity(1,1) primary key, 
state varchar(100),
city varchar(100),
location varchar(200));

-- dim restaurant 

create table dim_restaurant(
restaurant_id int identity(1,1) primary key , 
restaurant_name varchar(200)
);

-- dim category 

create table dim_category (
category_id int identity(1,1) primary key, 
category varchar(200));

-- dim dish 

create table dim_dish (
dish_id int identity(1,1) primary key, 
dish_name varchar(200));



-- fact table 

create table fact_swiggy_orders (
order_id int identity(1,1) primary key,
date_id int,
price_inr decimal(10,2),
rating decimal(4,2),
rating_count int ,

location_id int,
restaurant_id int ,
category_id int ,
dish_id int 

foreign key (date_id) references dim_date(date_id),
foreign key (location_id) references dim_location(location_id),
foreign key (restaurant_id) references dim_restaurant(restaurant_id),
foreign key (category_id) references dim_category(category_id),
foreign key (dish_id) references dim_dish(dish_id));



-- inserting data into table 

-- dim date 


insert into dim_date ( full_date, year, month , month_name , quarter, day , week)

select distinct 
Order_Date,
YEAR(order_date),
month(order_date),
datename(month, order_date),
datepart(quarter, order_date),
day(order_date),
datepart(week, order_date)
from Swiggy_data
where order_date is not null;

select * from dim_date;

-- dim_location 

insert into dim_location ( state , city , location)

select distinct state , city , location 
from Swiggy_data;


-- dim restaurant

insert into dim_restaurant (restaurant_name)
select distinct 
restaurant_name from Swiggy_data;

-- dim category

insert into dim_category(category)
select distinct category from Swiggy_data;

--dim_dish


insert into dim_dish(dish_name)
select distinct dish_name from Swiggy_data;

-- dim fact 

INSERT INTO fact_swiggy_orders (
    date_id,
    price_inr,
    rating,
    rating_count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)

SELECT 
    d.date_id,
    s.price_inr,
    s.rating,
    s.rating_count,
    l.location_id,
    r.restaurant_id,
    c.category_id,
    di.dish_id

FROM Swiggy_data s

-- join with date dimension
JOIN dim_date d 
    ON s.order_date = d.full_date

-- join with location dimension
JOIN dim_location l 
    ON s.state = l.state 
    AND s.city = l.city 
    AND s.location = l.location

-- join with restaurant dimension
JOIN dim_restaurant r 
    ON s.restaurant_name = r.restaurant_name

-- join with category dimension
JOIN dim_category c 
    ON s.category = c.category

-- join with dish dimension
JOIN dim_dish di 
    ON s.dish_name = di.dish_name;


select * from fact_swiggy_orders;

select * from fact_swiggy_orders f
join dim_date d on f.date_id= d.date_id
join dim_location l on f.location_id = l.location_id
join dim_restaurant r on f.restaurant_id= r.restaurant_id
join dim_category c on f.category_id=c.category_id
join dim_dish di on f.dish_id= di.dish_id;


-- kpis 

-- total orders 

select count(*) as total_order
from fact_swiggy_orders;

-- total revenue (inr million)\

select format(sum(convert(float,price_inr))/1000000, 'n2') + 'inr_million' as  total_revenue from fact_swiggy_orders

-- average 

SELECT 
FORMAT(AVG(CAST(price_inr AS FLOAT)) / 1000000.0, 'N2') + ' Million INR' AS avg_revenue
FROM fact_swiggy_orders;


-- avg rating 

select avg(Rating) as avg_rating 
from fact_swiggy_orders



-- deep dive 

-- monthely order placed 

select d.year,
d.month ,
d.month_name,
count(*) as total_orders
from fact_swiggy_orders f

join dim_date d on f.date_id= d.date_id
group by  d.year,
d.month ,
d.month_name;

-- quaterly trends 

select d.year,
d.quarter,
count(*) as total_orders
from fact_swiggy_orders f

join dim_date d on f.date_id= d.date_id
group by  d.year,
d.quarter;


-- yearly ternds 
select d.year,
count(*) as total_orders
from fact_swiggy_orders f

join dim_date d on f.date_id= d.date_id
group by  d.year
;



select top 10 l.city , count(*) as total_order from fact_swiggy_orders f
join dim_location l
on l.location_id = f.location_id 
group by l.city
order by count(*) desc 



--Top Restaurants by Revenue


SELECT r.restaurant_name, SUM(f.price_inr) AS revenue
FROM fact_swiggy_orders f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY revenue DESC;

--Best Rated Dishes

SELECT di.dish_name, AVG(f.rating) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_dish di ON f.dish_id = di.dish_id
GROUP BY di.dish_name
ORDER BY avg_rating DESC;

-- Revenue by Category

SELECT c.category, SUM(f.price_inr) AS revenue
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category
ORDER BY revenue DESC;

-- Monthly Revenue Trend

SELECT d.year, d.month, SUM(f.price_inr) AS revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;