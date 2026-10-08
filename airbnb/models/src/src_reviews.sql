WITH Raw_reviews AS (

SELECT 
LISTING_ID,
DATE AS review_date,
REVIEWER_NAME,
COMMENTS AS review_text,
SENTIMENT AS review_sentiment
FROM 
AIRBNB.RAW.RAW_REVIEWS
)
SELECT * FROM raw_reviews

