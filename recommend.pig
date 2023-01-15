/* 
 * recommend.pig
 *
 * The purpose of this script is to provide movie recommendations based on 
 * the ratings made be multiple users.
 *
 * It uses a collaborative filtering algorithm in order to construct user profiles,
 * detect the closest users and construct a set of movies that the users will most
 * likey appreciate.
 * 
 * The algorithm is based on the work presented in the following book (chapter 9):
 * Title: Minning of Massive Datasets,
 * Authors: Jure Leskovec, Anand Rajaraman and Jeffrey D, Ullman.
 * 
 * Input:
 * - a CSV file with user ratings that has the following columns at least:userId, movieId and rating,
 * - a CSV file with movie data that has the following columns at least: movieId and movieTitle,
 * - the id of the user for which we want to make the recommendations, 
 * - the size of the sample from the ratings file on which we should base our algorithm.
 * 
 * Output:
 * - a list of recommended movie titles.
 */


-- This script is used for computing the cosine distance between two user profiles.
REGISTER 'cosineDistance.py' USING jython AS helpers;


/* 
 Select a sample from the set of all ratings together with all
 the ratings made by the user to which we need to make the recommendations.
*/
--allRatings = LOAD '/movie-recommendations/ratings/' 
allRatings = LOAD 'ratings/ratings.csv' -- Used for local testing.
	USING PigStorage(',')
	AS (userId:int, movieId:int, rating:float);

sampleRatings = sample allRatings $SAMPLE_SIZE;
ratingsMadeByRecommendationsSubject = FILTER allRatings BY userId == $USER_ID;  
ratings = UNION sampleRatings, ratingsMadeByRecommendationsSubject;


/*
 * Compute the average movie rating for each user.
 **/
groupedRatings = GROUP ratings BY userId;
avgRatings = FOREACH groupedRatings 
			 GENERATE group AS userId, 
					  AVG(ratings.rating) AS rating;


/*
 * Normalize the ratings made by each user by subrating the average 
 * rating made by him from each movie ratings.
 **/
joinedRatings = JOIN ratings BY userId, avgRatings BY userId;
normalizedRatings = FOREACH joinedRatings
					GENERATE ratings::userId, 
							 ratings::movieId, 
							 (ratings::rating - avgRatings::rating) AS rating;


/*
 * Combine the target user for recommendations with each other user.
 **/
groupedNormalizedRatings = GROUP normalizedRatings BY userId;
filteredGroupedNormalizedRatings = FILTER groupedNormalizedRatings BY group != $USER_ID; 
targetUserNormalizedRatings = FILTER groupedNormalizedRatings BY group == $USER_ID;
crossedUserRatings = CROSS targetUserNormalizedRatings, filteredGroupedNormalizedRatings;


/*
 * Compute the cosine distances between the target user and each other user.
 **/
userCosineDistances = 
	FOREACH crossedUserRatings
	GENERATE targetUserNormalizedRatings::group AS userId1,
			 filteredGroupedNormalizedRatings::group AS userId2, 
			 helpers.cosineDistance
				  (
   				  targetUserNormalizedRatings::normalizedRatings,
				  filteredGroupedNormalizedRatings::normalizedRatings
 				  ) AS cosineDist;


/*
 * This should improve performance by eliminating the need for 
 * the crossed relation computation, but it does not work 
 * and I need to figure out why.
 **/

/*
userCosineDistances = 
	FOREACH filteredGroupedNormalizedRatings
	GENERATE targetUserNormalizedRatings.group AS userId1,
			 filteredGroupedNormalizedRatings.group AS userId2, 
			 helpers.cosineDistance(
								targetUserNormalizedRatings.normalizedRatings,
								filteredGroupedNormalizedRatings.normalizedRatings
 								) AS cosineDist;
*/


/*
 * Find the closest users for the recommendations target users.
 **/
groupedDistances = GROUP userCosineDistances BY userId1;

closestUsers = FOREACH groupedDistances {
	orderedDistances = ORDER userCosineDistances BY cosineDist DESC;
	closestDistances = LIMIT orderedDistances $CLOSEST_USERS_NUMBER;
	closestUsers = FOREACH closestDistances GENERATE userId2;

	GENERATE group AS userId1, FLATTEN(closestUsers) AS userId2;
};


/*
 * Find the top movies to recommend for the target user.
 **/
closestUsersRatings = JOIN closestUsers BY userId2, normalizedRatings BY userId;
groupedClosestUsersRatings = GROUP closestUsersRatings BY (userId1, movieId);

moviesAverageRating = 
	FOREACH groupedClosestUsersRatings 
	GENERATE group,  AVG(closestUsersRatings.rating) AS movieAvgRating;

/*
targeUserRatedMovies = FOREACH ratingsMadeByRecommendationsSubject GENERATE movieId;
-- It doesn't work in the current version of CDH.
filteredMovies = FILTER moviesAverageRating BY movieId NOT IN targetUserRatedMovies.

*/

orderedMoviesAverageRating = ORDER moviesAverageRating BY movieAvgRating DESC;
topMovies = LIMIT orderedMoviesAverageRating $RECOMMENDATIONS_NUMBER;

topMovies = FOREACH topMovies  
			GENERATE group.$0 AS userId, group.$1 as movieId, movieAvgRating;


/*
 * Load movies data as well in order to be able to recommend movie titles.
 **/
--movies = LOAD '/movie-recommendations/movies/'
movies = LOAD 'movies/' -- User for local testing.
         USING PigStorage(',')
         AS (movieId:int, title:chararray);


topMoviesAugmented = JOIN topMovies BY movieId, movies BY movieId;

recommendations = FOREACH topMoviesAugmented GENERATE title;
DUMP recommendations;
