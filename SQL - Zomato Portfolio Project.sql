create database zomato_portfolio

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');


CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--what is the total amount each customer spent on zomato
select a.userid,sum(b.price) as total_amount_spent from sales a inner join product b on a.product_id=b.product_id
group by a.userid

--how many days has each customer visited zomato
select userid ,count(created_date) as distinct_days from sales 
group by userid

--what was the first product purchased by each customer
select *  from
(select * , rank() over(partition by userid order by created_date) as rankk from sales)a where rankk=1

--what is the most purchased item on menu and how many times it was purchased by customers
select userid,count(product_id) from sales where product_id=
(select top 1 product_id from sales group by(product_id) order by count(product_id) desc)
group by userid

--which item is more popular for each of the customer
select * from
(select *, rank() over(partition by userid order by countt desc) as rankk from
(select userid,product_id,count(product_id) as countt from sales group by userid,product_id)a)c
where rankk=1

--which item was first purchased by the customer after becoming a member
select*from
(select c. *,rank() over(partition by userid order by created_date)as rankk from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid=b.userid and created_date>=gold_signup_date)c)d where rankk=1;

--which item was purchased just before customer became a member
select * from
(select c. *,rank() over(partition by userid order by created_date desc)as rankk from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid=b.userid and created_date<=gold_signup_date)c)d where rankk=1;

--what are the total orders and amount spent for each member before they became a member
select userid,count(created_date),sum(price) from 
(select c.*,d.price from 
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid=b.userid and created_date<=gold_signup_date)as c inner join product as d on c.product_id=d.product_id)as e
group by userid

-- If buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points
--for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point and p3 5rs=1 zomato point  2rs =1zomato point,
--calculate points collected by each customer and for which product most points have been given till now.

select userid,sum(total_points)*2.5 as total_money_earned from
(select e.*,amount/rupee_Per_point as total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2
when product_id=3 then 5 else 0 end as rupee_per_point from
(select c.userid,c.product_id,sum(price) as amount from
(select a.*,b.price from sales as a inner join product as b on a.product_id=b.product_id)as c
group by userid,product_id)as d)as e)as f group by userid

select product_id,sum(total_points) as total_points_earned from
(select e.*,amount/rupee_Per_point as total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2
when product_id=3 then 5 else 0 end as rupee_per_point from
(select c.userid,c.product_id,sum(price) as amount from
(select a.*,b.price from sales as a inner join product as b on a.product_id=b.product_id)as c
group by userid,product_id)as d)as e)as f group by product_id

-- In the first year after a customer joins the gold program (including the join date )
--irrespective of what customer has purchased earn 5 zomato points for every 10rs spent
--who earned more more 1 or 3 what int earning in first yr ? 1zp = 2rs
--5zp = 10rs
--1zp=2rs
--0.5zp=1rs
select c.*,d.price*0.5 as total_points_earned from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid=b.userid and created_date>=gold_signup_date and created_date<=dateadd(year,1,gold_signup_date))as c
inner join product as d on c.product_id=d.product_id

--rank all transaction of the customers
select *, rank() over(partition by userid order by created_date) from sales

-- rank all transaction for each member whenever they are zomato gold member
--for every non gold member transaction mark as na

select e.*,case when rankk=0 then 'na' else rankk end as rankkkk from
(select c.*,cast((case when gold_signup_date is null then 0 else rank() 
over(partition by userid order by created_date desc) end)as varchar) as rankk from 
(select a.userid,a.product_id,a.created_date,b.gold_signup_date from sales as a left join goldusers_signup as b 
on a.userid=b.userid and created_date>=gold_signup_date)as c)as e
