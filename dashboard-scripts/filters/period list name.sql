#Query

SELECT p.name as period_name, EXTRACT(YEAR FROM p.startdate) as year_name 
FROM referencedata.processing_periods p
WHERE EXTRACT(YEAR FROM p.startdate) = 2022

#Dataset
#note that value depend on year filter
SELECT p.name as period_name, EXTRACT(YEAR FROM p.startdate) as year_name 
FROM referencedata.processing_periods p
WHERE EXTRACT(YEAR FROM p.startdate) = '{{filter_values('year_name')[0]}}'


