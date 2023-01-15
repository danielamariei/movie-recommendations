--SET mapred.job.tracker=local;
--SET mapred.local.dir=/home/training/movie-recommendations;
SET hive.cli.print.header=true;

DROP DATABASE IF EXISTS movie_recommendations CASCADE;
CREATE DATABASE IF NOT EXISTS movie_recommendations;


USE movie_recommendations;


CREATE EXTERNAL TABLE IF NOT EXISTS ratings
	(user_id INT,
	 movie_id INT,
	 rating FLOAT
	)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY ','
	LOCATION '/movie-recommendations/ratings';

SELECT * FROM ratings LIMIT 10; 


CREATE EXTERNAL TABLE IF NOT EXISTS avg_ratings
	(user_id INT,
	 rating FLOAT
	)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY ','
	LOCATION '/movie-recommendations/avg-ratings';

INSERT OVERWRITE TABLE  avg_ratings
	SELECT user_id, AVG(rating)  
	FROM ratings
	GROUP BY user_id;

SELECT * FROM avg_ratings LIMIT 10;


CREATE EXTERNAL TABLE IF NOT EXISTS normalized_ratings
	(user_id INT,
	 movie_id INT,
	 rating FLOAT
	)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY ','
	LOCATION '/movie-recommendations/normalized-ratings';

INSERT OVERWRITE TABLE normalized_ratings
	SELECT r.user_id, r.movie_id, r.rating - avg.rating
	FROM ratings r
	JOIN avg_ratings avg
	ON r.user_id = avg.user_id;

SELECT * FROM normalized_ratings LIMIT 10;


CREATE EXTERNAL TABLE IF NOT EXISTS user_ratings
	(user_id INT,
	 ratings ARRAY<STRING>
	)
	ROW FORMAT DELIMITED
	FIELDS TERMINATED BY ','
	COLLECTION ITEMS TERMINATED BY '|'
	LOCATION '/movie-recommendations/user-ratings';

INSERT OVERWRITE TABLE user_ratings
	SELECT user_id, 
		   collect_set(concat(
							CAST(movie_id AS STRING),
							"=", 
							CAST(rating AS STRING))) AS ratings
	FROM normalized_ratings
	GROUP BY user_id;

SELECT * FROM user_ratings;





quit;

--select a.user_id, a.movie_id, a.rating, b.rating, c.rating
--from ratings a 
--JOIN normalized_ratings b 
--ON (a.user_id = b.user_id AND a.movie_id = b.movie_id)
--JOIN avg_ratings c 
--ON a.user_id = c.user_id;

-- Create a view for selecting the recommendations for a user that join recommendations
-- with movie data in order to display the movie names.
