WITH Raw_reviews AS (

SELECT 
LISTING_ID,
DATE AS review_date,
REVIEWER_NAME,
COMMENTS AS review_text,
SENTIMENT AS review_sentiment
FROM 
{{source('airbnb', 'reviews') }}
)
SELECT * FROM raw_reviews

