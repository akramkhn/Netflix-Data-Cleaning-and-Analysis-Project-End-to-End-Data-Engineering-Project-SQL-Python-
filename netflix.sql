-- QUERY TO CREATE TABLE




create TABLE [dbo].[netflix_raw](
	[show_id] [varchar](10) primary key,
	[type] [varchar](10) NULL,
	[title] [nvarchar](200) NULL,
	[director] [varchar](250) NULL,
	[cast] [varchar](1000) NULL,
	[country] [varchar](150) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] [int] NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](10) NULL,
	[listed_in] [varchar](100) NULL,
	[description] [varchar](500) NULL
) 



-- QUERY TO FIND DUPLICATE


select * 
from netflix_raw 
where concat(upper(title),type) in (
	select concat(upper(title), type)
	from netflix_raw 
	group by upper(title), type
	having count(*) > 1
)
order by title



-- QUERY FOR DATA CLEANING AS PER THE REQUIREMENT AND MAKING FINAL DATA


with cte as (
select *,
row_number() over(partition by title, type order by show_id) as rn
from netflix_raw
)
select 
	show_id, 
	type,
	title,
	cast(date_added as date) as date_added, 
	release_year,
	rating,
	case when duration is null then rating else duration end as duration,
	description
into netflix
from cte
where rn=1




-- CREATE NEW TABLE netflix_genre USING EXISTING TABLE netflix_raw


select show_id, trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in,',')



--filling missing values in country

insert into netflix_country
select show_id, m.country
from netflix_raw nr
inner join (
select director,country from netflix_country nc
inner join netflix_directors nd on nc.show_id = nd.show_id
group by director,country
) m on nr.director = m.director
where nr.country is null



--- QUESTIONs FOR ANALYSIS





--   Q1) for each director count the number of movies and tv shows made by them in separate column
/* for directors who have created both movies and tv show */

select nd.director, 
	   count(case when n.type = 'Movie' then n.show_id end) as no_of_movies,
	   count(case when n.type = 'TV Show' then n.show_id end) as no_of_tvshow
from netflix n
inner join netflix_directors nd on n.show_id = nd.show_id
group by nd.director
having count(distinct n.type) > 1



-- Q2)  find the country whic has the highest number of comedy movies



select top 1 nc.country , count(*) as 'no of comedy movies'
from netflix_country nc
inner join netflix_genre ng on nc.show_id = ng.show_id
inner join netflix n on ng.show_id = n.show_id
where ng.genre = 'comedies' and n.type = 'Movie'
group by nc.country
order by 'no of comedy movies' desc



--- Q3)  for each year which year has maximum no of movies

	

with cte as (
select 
	director, 
	year(date_added) as date_year,
	count(*) as no_of_movies
from netflix_directors nd
inner join netflix n on nd.show_id = n.show_id
where type = 'Movie'
group by director, year(date_added)
)

, cte2 as (
select *,
	row_number() over(partition by date_year order by no_of_movies desc) as rn
from cte
)
select * from cte2
where rn=1



-- Q4) what is average duration of movies in each genre



select 
	genre, 
	avg(cast(left(duration, CHARINDEX(' ', duration) - 1) as int)) as avg_duration_movie
from netflix_genre ng
inner join netflix n on ng.show_id = n.show_id
where type = 'Movie'
group by genre



-- Q5) Find the list of directors who have made horror and comedy movies both.
-- Display director name with No.of Comedy and Horror Movies directed by them


with cte as (
select 
	director, 
	count(case when ng.genre = 'Horror Movies' then n.show_id end) no_of_horror_movies,
	count(case when ng.genre = 'Comedies' then n.show_id end) no_of_comedy_movies
from netflix n
join netflix_directors nd on n.show_id = nd.show_id
join netflix_genre ng on n.show_id = ng.show_id
where ng.genre in ('Comedies', 'Horror Movies') and n.type = 'Movie'
group by director
)

select * from cte
where no_of_horror_movies > 0 and no_of_comedy_movies > 0
 