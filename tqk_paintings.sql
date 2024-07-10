SELECT * FROM artist; --421 rows
SELECT * FROM canvas_size; --200 rows
SELECT * FROM image_link; --14775 rows
SELECT * FROM museum; --57 rows
SELECT * FROM museum_hours; --351 rows
SELECT * FROM product_size; --110347 rows
SELECT * FROM subject; --6771 rows
SELECT * FROM work; --14776 rows

-- Solve the below SQL problems using the Famous Paintings & Museum dataset:

-- 1) Fetch all the paintings which are not displayed on any museums?

SELECT * 
FROM work 
WHERE museum_id IS NULL;

-- 2) Are there museuems without any paintings?

SELECT *
FROM museum m
LEFT JOIN work w ON m.museum_id = w.museum_id
WHERE w.museum_id IS NULL;

-- NOT EXISTS works the opposite of EXISTS. The WHERE clause in NOT EXISTS is satisfied
-- if no rows are returned by the subquery

select * from museum m
	where not exists (select * from work w
					 where w.museum_id=m.museum_id)

-- 3) How many paintings have an asking price of more than their regular price? 

-- SOLUTION PROVIDED
select * from product_size
	where sale_price > regular_price;

-- MY SOLUTION
SELECT COUNT(1) FROM product_size
WHERE sale_price > regular_price;


-- 4) 4) Identify the paintings whose asking price is less than 50% of its regular price

-- ASKED QUETION
SELECT * FROM product_size
WHERE sale_price < (regular_price * 50)/100;

-- IMPROVIZATION
SELECT COUNT(1) as painting_count
FROM 
(SELECT * FROM product_size
WHERE sale_price < (regular_price * 50)/100) w;


-- 5) Which canvas size costs the most?

SELECT cs.label as canva, ps.sale_price
	FROM (SELECT *
		 ,rank() over(order by sale_price desc) as rnk 
		  from product_size) ps
	JOIN canvas_size cs ON cs.size_id  = TRY_CAST(ps.size_id as bigint)
	where ps.rnk=1;

-- DESCRIBE in MSSQL SERVER
EXEC sp_help product_size;
EXEC sp_help canvas_size;

SELECT * FROM product_size;
SELECT * FROM canvas_size;

-- SELECT TRY_CAST(size_id as bigint);
-- There is mismatch in size_id column type in both tables it is helpful there


-- 6) Delete duplicate records from work, product_size, subject and image_link tables

SELECT * FROM work;
SELECT * FROM product_size;
SELECT * FROM subject;
SELECT * FROM image_link;

delete from work 
	where work_id not in (select min(work_id)
						from work
						group by work_id );

delete from product_size 
	where ctid not in (select min(ctid)
						from product_size
						group by work_id, size_id );

	delete from subject 
	where ctid not in (select min(ctid)
						from subject
						group by work_id, subject );

	delete from image_link 
	where ctid not in (select min(ctid)
						from image_link
						group by work_id );

-- 7) Identify the museums with invalid city information in the given dataset

SELECT * FROM museum;			-- 57 rows

-- Taking invalid cities as which are not starting from A-Z 
SELECT * FROM museum				
WHERE city LIKE '[0-9]%';

-- 8) Museum_Hours table has 1 invalid entry. Identify it and remove it.

SELECT *
FROM museum_hours

EXEC sp_help museum_hours;

SELECT * from museum_hours 
	where museum_id not in (select min(museum_id)
						from museum_hours
						group by museum_id, day );

-- 9) Fetch the top 10 most famous painting subject

SELECT TOP 10 subject, COUNT(1) as famous_painting_subject
FROM subject
GROUP BY subject
ORDER BY  COUNT(1)  desc

select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;

-- 10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.

-- FIRST ATTEMPT
SELECT mh.museum_id, m.name, m.city, mh.day FROM
museum_hours mh 
JOIN museum m ON m.museum_id = mh.museum_id
WHERE mh.day in ('Saturday','Monday')

	
SELECT * FROM artist; --421 rows
SELECT * FROM canvas_size; --200 rows
SELECT * FROM image_link; --14775 rows
SELECT * FROM museum; --57 rows
SELECT * FROM museum_hours; --351 rows
SELECT * FROM product_size; --110347 rows
SELECT * FROM subject; --6771 rows
SELECT * FROM work; --14776 rows

select distinct m.name as museum_name, m.city, m.state,m.country
	from museum_hours mh 
	join museum m on m.museum_id=mh.museum_id
	where day='Sunday'
	and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');

-- AFTER SEEING SOLUTION

SELECT mh.museum_id, m.name, m.city, mh.day
	FROM museum_hours mh 
	JOIN museum m ON m.museum_id = mh.museum_id
	WHERE mh.day = 'Sunday'
	and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');

-- 11) How many museums are open every single day?

SELECT * FROM museum_hours; --351 rows

-- MY SOLUTION
SELECT museum_id, COUNT(day) AS day_count
FROM museum_hours
GROUP BY museum_id
HAVING COUNT(day) = 7 

-- GIVEN SOLUTION
select *
	from (select museum_id, count(1) as day_count
		  from museum_hours
		  group by museum_id
		  having count(1) = 7) x;


-- 12) Which are the top 5 most popular museum? 
-- (Popularity is defined based on most no of paintings in a museum)

SELECT * FROM museum;
SELECT * FROM product_size;
SELECT * FROM work;

-- MY APPROACH
SELECT TOP 5  w.museum_id, COUNT(w.work_id) as painting_count
FROM work w
JOIN museum m ON m.museum_id = w.museum_id
GROUP BY w.museum_id
ORDER BY COUNT(w.work_id) desc

-- GENERAL SOLUTION
select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;

-- 13) Who are the top 5 most popular artist? 
-- (Popularity is defined based on most no of paintings done by an artist)
SELECT * FROM work;
SELECT * FROM artist;

-- MY APPROACH
SELECT TOP 5 artist_id, COUNT(work_id) as no_of_paintings
FROM work
GROUP BY artist_id
ORDER BY COUNT(work_id) DESC

SELECT w.artist_id, a.full_name as artist, a.nationality, w.no_of_paintings 
FROM (SELECT TOP 5 artist_id, COUNT(work_id) as no_of_paintings
		FROM work
		GROUP BY artist_id
		ORDER BY COUNT(work_id) DESC) w
JOIN artist a ON a.artist_id = w.artist_id

-- GENERAL SOLUTION
select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;

-- 14) Display the 3 least popular canva sizes

SELECT * FROM product_size; 
SELECT * FROM canvas_size;

-- DESCRIBE in MSSQL SERVER
EXEC sp_help product_size;
EXEC sp_help canvas_size;

select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id  = TRY_CAST(ps.size_id as bigint)
		group by cs.size_id,cs.label) x
	where x.ranking<=3;

/*
-- 15) Which museum is open for the longest during a day. 
-- Dispay museum name, state and hours open and which day?

SELECT * FROM museum_hours;

EXEC sp_help museum_hours;

-- open and close are reserved keywords in SQL Server. To avoid this issue, 
-- you need to use square brackets around these column names
SELECT CONVERT(datetime, [open], 101)  AS open_time, CONVERT(datetime, [close], 101) AS close_time
FROM museum_hours;
-- Conversion failed while converting date and/or time from character string

SELECT 
    TRY_CONVERT(datetime, [open]) AS open_time, 
    TRY_CONVERT(datetime, [close]) AS close_time
FROM museum_hours;
--  TRY_CONVERT, which returns NULL if the conversion fails instead of throwing an error

-- NOT SOLVED
SELECT museum_name, state AS city, day, [open], [close], duration
FROM (
    SELECT 
        m.name AS museum_name, 
        m.state, 
        mh.day, 
        --mh.[open], 
        --mh.[close],
        CONVERT(datetime, mh.[open], 108) AS open_time  -- Convert 'open' to datetime
        --CONVERT(datetime, mh.[close], 108) AS close_time, -- Convert 'close' to datetime
        --DATEDIFF(MINUTE, CONVERT(datetime, mh.[open], 108), CONVERT(datetime, mh.[close], 108)) AS duration,  -- Calculate duration in minutes
        --RANK() OVER (ORDER BY DATEDIFF(MINUTE, CONVERT(datetime, mh.[open], 108), CONVERT(datetime, mh.[close], 108)) DESC) AS rnk
    FROM museum_hours mh
    JOIN museum m ON m.museum_id = mh.museum_id
) x
WHERE x.rnk = 1;
*/

-- 16) Which museum has the most no of most popular painting style?
SELECT * FROM work;
with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name, ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;

-- 17) Identify the artists whose paintings are displayed in multiple countries

SELECT * FROM artist;
SELECT * FROM work;
SELECT * FROM museum;

select distinct a.full_name as artist
		, w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id

with cte as
		(select distinct a.full_name as artist
		-- , w.name as painting_name, m.name as museum_name
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by no_of_countries desc;

--18) Display the country and the city with most no of museums.
--Output 2 seperate columns to mention the city and country.If there are multiple value,seperate them with comma.

SELECT * FROM museum;

WITH cte_city as
		(SELECT  city, COUNT(1) as no_of_museum,
		RANK() OVER (ORDER BY COUNT(name) desc) as rnk
		FROM museum
		WHERE city like '[A-Z]%'
		GROUP BY city),
	 cte_country as
		(SELECT  country, COUNT(1) as no_of_museum,
		RANK() OVER (ORDER BY COUNT(name) desc) as rnk
		FROM museum
		GROUP BY country),
	 distinct_country AS
		(SELECT DISTINCT country
		 FROM cte_country
		 WHERE rnk = 1),
	 distinct_city AS
		(SELECT DISTINCT city
		 FROM cte_city
		 WHERE rnk = 1)
SELECT
    (SELECT STRING_AGG(country, ',') FROM distinct_country) AS country,
    (SELECT STRING_AGG(city, ',') FROM distinct_city) AS city;

-- 19) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label


WITH cte_product as
	(SELECT *,  
	RANK() OVER (PARTITION BY work_id ORDER BY sale_price) as rnk,
	RANK() OVER (PARTITION BY work_id ORDER BY sale_price DESC) as rnk_desc
	FROM product_size)
SELECT a.full_name as artist_name, cp.sale_price as sale_price, w.name as painting_name
,m.name asmuseum_name, m.city as city_name, cz.label as label
FROM cte_product cp
JOIN work w ON cp.work_id = w.work_id
JOIN museum m ON m.museum_id = w.museum_id
JOIN artist a ON a.artist_id = w.artist_id
join canvas_size cz on cz.size_id = TRY_CAST(cp.size_id AS NUMERIC)
where rnk=1 or rnk_desc=1;

-- 20) Which country has the 5th highest no of paintings?

SELECT * FROM museum;  -- this will give u highest number of museum in city/country
SELECT * FROM work;

SELECT m.country as country,COUNT(1) as no_of_painting,
RANK() OVER (ORDER BY COUNT(1) desc) as rnk 
FROM work w
JOIN museum m ON w.museum_id = m.museum_id
group by m.country;

with cte as
	(SELECT m.country as country,COUNT(1) as no_of_painting,
	RANK() OVER ( ORDER BY COUNT(1) desc) as rnk 
	FROM work w
	JOIN museum m ON w.museum_id = m.museum_id
	group by m.country)
SELECT country, no_of_painting
FROM cte
WHERE rnk = 5

-- 21) Which are the 3 most popular and 3 least popular painting styles?

with cte as
	(SELECT style, count(1) as cnt,
	RANK() OVER (ORDER BY COUNT(style)) as rnk,
	count(1) over() as no_of_records
	FROM work
	WHERE style IS NOT NULL
	GROUP BY style)
select style
, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
from cte
where rnk <=3
or rnk > no_of_records - 3;				-- LAST LINE IS IMPORTANT TO DISTINGUISH BETWEEN OTHERS


-- 22) Which artist has the most no of Portraits paintings outside USA?. Display artist name,
-- no of paintings and the artist nationality.

SELECT * FROM artist;
SELECT * FROM subject;

select full_name as artist_name, nationality, no_of_paintings
	from (SELECT a.full_name as full_name, a.nationality as nationality, COUNT(1) as no_of_paintings,
		  rank() over(order by count(1) desc) as rnk
		  FROM artist a
		  JOIN work w ON a.artist_id = w.artist_id
		  JOIN subject s ON w.work_id = s.work_id
		  JOIN museum m ON w.museum_id = m.museum_id
		  WHERE m.country != 'USA' 
		  AND a.nationality != 'American'
		  AND  s.subject ='Portraits'
		  GROUP BY a.full_name, a.nationality) x
	where rnk = 1;

