--Filter columns product_name, period_name and frequence_name 
-- 1 product_name is the "SELECT o.fullproductname as product_name FROM referencedata.orderables o GROUP BY o.fullproductname";

-- 2 period_name is the "SELECT p.name as period_name
--  FROM referencedata.processing_periods p 
--        JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
--  WHERE s.code!='Dayly' AND s.code!='Weekly' "

-- 3 frequence_name Values are dependent on period_name filter
--   here is the dataset "SELECT p.name as period_name,
--                             s.code as frequence_name
-- 	                   FROM referencedata.processing_periods p 
--                       JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
--             		 JOIN (
--             			   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p where p.name='{{filter_values('period_name')[0]}}' -- Jan-Fev,2022
--             			 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate) "



{% set frequ_valu = (
    'day' if filter_values('frequence_name')[0] == 'Hebdomadaire' else
    'month' if filter_values('frequence_name')[0] == 'Mensuelle' else
    'quarter' if filter_values('frequence_name')[0] == 'Trimestrielle' else
    'year' if filter_values('frequence_name')[0] == 'Annuelle' else None
) %}

{% set facility_name_list = filter_values('facility_name') | default([]) %}
{% set product_name_list = filter_values('product_name') | default([]) %}


{% macro avg_value() %}
,
calculated_taux AS (
    SELECT s.program_name as program_name,
       s.facility_name as facility_name,
       s.product_name as product_name,
       '{{filter_values('period_name')[0]}}' as period_name,
       '{{filter_values('frequence_name')[0]}}' AS frequence_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       ROUND((s.sum_duree_tt_rupture::NUMERIC / n.nbre_tt_rupture), 2) AS duree_moyen_rupture,
       s.sum_duree_tt_rupture || ' / ' || n.nbre_tt_rupture AS sur
      FROM sum_duree_tout_rupture s 
      JOIN nbre_tt_de_rupture n ON s.program_name=n.program_name AND s.product_name=n.product_name
)
-- Final single-line result with aggregated values
SELECT 
    '{{filter_values('program_name')[0]}}' AS program_name,                     
    'NAN' AS facility_name, 
    'NAN' AS product_name,
    '{{filter_values('period_name')[0]}}' as period_name,
    '{{filter_values('frequence_name')[0]}}' AS frequence_name,                 
    '{{filter_values('year_name')[0]}}' AS year_name,                          
    ROUND((AVG(duree_moyen_rupture)), 2) AS duree_moyen_rupture, 
    ROUND((SUM(duree_moyen_rupture)), 2) || ' / ' || COUNT(program_name) AS sur -- Summed sur values
FROM 
    calculated_taux   
{% endmacro %}
 
 

{% macro not_avg_value() %}
SELECT s.program_name as program_name,
       s.facility_name as facility_name,
       s.product_name as product_name,
       '{{filter_values('period_name')[0]}}' as period_name,
       '{{filter_values('frequence_name')[0]}}' AS frequence_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       ROUND((s.sum_duree_tt_rupture::NUMERIC / n.nbre_tt_rupture), 2) AS duree_moyen_rupture,
       s.sum_duree_tt_rupture || ' / ' || n.nbre_tt_rupture AS sur
      FROM sum_duree_tout_rupture s 
      JOIN nbre_tt_de_rupture n ON s.program_name=n.program_name AND s.product_name=n.product_name
{% endmacro %}





WITH sum_duree_tout_rupture AS(
SELECT SUM(totalstockoutdays) as sum_duree_tt_rupture,
        program_name as program_name,
        product_name as product_name,
        facility_name as facility_name,
        '{{filter_values('period_name')[0]}}' as period_name,
        '{{filter_values('frequence_name')[0]}}' AS frequence_name
                      FROM (
                           SELECT  i.totalstockoutdays, 
                                   pr.name as program_name,
                                   o.fullproductname as product_name,
                                   f.name as facility_name,
                                   '{{filter_values('period_name')[0]}}' as period_name,
                                   'day' AS frequence_name
                         FROM requisition.requisition_line_items i 
                               JOIN requisition.requisitions r ON i.requisitionid=r.id
        										   JOIN referencedata.orderables o ON i.orderableid=o.id
        										   JOIN referencedata.facilities f ON f.id=r.facilityid
        										   JOIN referencedata.programs pr ON pr.id=r.programid
        										   JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
                               JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
                            	 JOIN (
                            		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p 
                      		          where p.name='{{filter_values('period_name')[0]}}'
                            		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
                         WHERE  
                                pr.name='{{filter_values('program_name')[0]}}' AND
                                {% if current_year() == filter_values('year_name')[0] | int and 'Hebdomadaire' == filter_values('frequence_name')[0] %}
                                  DATE_TRUNC('{{ frequ_valu }}', r.createddate) = DATE_TRUNC('{{ frequ_valu }}', CURRENT_DATE) AND
                                {% endif %}
                                 ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
                                   f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
                                   if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
                                  AND 
                                  ('{{ filter_values('product_name', []) | length }}' = 0 OR 
                                   o.fullproductname IN ( {{ "'" + "','".join(filter_values('product_name', ['default_product1', 'default_product2'])) + "'" 
                                   if filter_values('product_name', []) else "'default_product1','default_product2'" }}))
                                  AND
            									  (r.status='APPROVED' OR r.status='AUTHORIZED') AND 
            									  i.totalstockoutdays!=0 
        								 GROUP BY pr.name, i.totalstockoutdays, f.name, o.fullproductname
        								 ) as grouped_data
        								 GROUP BY program_name, product_name, facility_name 
),
nbre_tt_de_rupture AS(
SELECT COUNT(DISTINCT i.id) as nbre_tt_rupture,
                      pr.name as program_name,
                      o.fullproductname as product_name,
                     '{{filter_values('period_name')[0]}}' as period_name,
                     '{{filter_values('frequence_name')[0]}}' AS frequence_name
               FROM requisition.requisition_line_items i 
                           JOIN requisition.requisitions r ON i.requisitionid=r.id  
												   JOIN referencedata.orderables o ON i.orderableid=o.id
												   JOIN referencedata.programs pr ON pr.id=r.programid
												   JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
                           JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
                        	 JOIN (
                        		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p where p.name='{{filter_values('period_name')[0]}}'
                        		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
               WHERE  pr.name='{{filter_values('program_name')[0]}}' AND
                      ('{{ filter_values('product_name', []) | length }}' = 0 OR 
                       o.fullproductname IN ( {{ "'" + "','".join(filter_values('product_name', ['default_product1', 'default_product2'])) + "'" 
                       if filter_values('product_name', []) else "'default_product1','default_product2'" }}))
                      AND
  									  (r.status='APPROVED' OR r.status='AUTHORIZED') AND 
  									  {% if current_year() == filter_values('year_name')[0] | int and 'Hebdomadaire' == filter_values('frequence_name')[0] %}
                        DATE_TRUNC('{{ frequ_valu }}', r.createddate) = DATE_TRUNC('{{ frequ_valu }}', CURRENT_DATE) AND
                      {% endif %}
                      -- and finally if current_year() != 2024 or frequence != day; result is => default
  									  i.totalstockoutdays!=0
						  GROUP BY pr.name, o.fullproductname
)
{% if facility_name_list | length != 0 or product_name_list | length != 0 %}
 {{not_avg_value()}}
{% else %}
--********** average case *****************
{{avg_value()}}

{% endif %}






      
      

    
    
    

     


	



		
		
		
		
		
		