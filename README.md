# Movie Recommendations

## Introduction
The implementation of a movie recommendation system on top of the Hadoop platform using Apache Pig. 

## Context
The long tail phenomenon: the distinction between the physical and on-line worlds.This phenomenon forces institutions to recommend items to individual users. It is not reasonable to expect our users to have heard of each item they might like.


## Architecture 
- Input: movie ratings + movies
- Output: recommended movies

```mermaid
flowchart LR
        MR(Movie Ratings) -->|process| RS(Recommender System)
        M(Movies) -->|process| RS(Recommender System)
        RS(Recommender System) -->|output| RM(Recommended Movies)

```

## Recommendation System Stages

```mermaid
flowchart TD
        MR(Movie Ratings) -->|process| LSD(Loading and Sampling the Data)
        M(Movies) -->|process| LSD(Loading and Sampling the Data)
        LSD(Loading and Sampling the Data) --> ND(Normalizing the Data)
        ND(Normalizing the Data) --> DSSU(Determining the Set of Similar Users)
        DSSU(Determining the Set of Similar Users) --> DSM(Determining the set of Movies which Similar Users have Rated)
        DSM(Determining the set of Movies which Similar Users have Rated) --> RM(Recommend Movies)
```

## Technologies
* Hadoop
* Apache Pig
* Python



