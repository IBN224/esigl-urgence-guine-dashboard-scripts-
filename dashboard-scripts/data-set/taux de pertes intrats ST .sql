--Filter columns program_name, period_name and facility_name 
-- 1 program_name is the "SELECT p.name as program_name FROM referencedata.programs p";

-- 2 period_name is the "SELECT p.name as period_name from referencedata.processing_periods p"

-- 3 facility_name is the "SELECT f.name as facility_name FROM referencedata.facilities f"




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
    SELECT p.program_name as program_name,
       p.facility_name AS facility_name,
       p.product_name as product_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       p.period_name as period_name,
       ROUND(((p.qt_intrats_perdus::NUMERIC / r.qtt_intrats_recus) * 100), 2) AS taux_perte_intrats,
       p.qt_intrats_perdus || ' / ' || r.qtt_intrats_recus AS sur
      FROM qt_intrats_perdu p 
      JOIN qtt_intrats_recu r ON p.program_name=r.program_name AND p.facility_name=r.facility_name 
)
-- Final single-line result with aggregated values
SELECT 
    '{{filter_values('program_name')[0]}}' AS program_name,                     
    'NAN' AS facility_name, 
    'NAN' AS product_name,
    '{{filter_values('period_name')[0]}}' as period_name,                 
    '{{filter_values('year_name')[0]}}' AS year_name,                          
    ROUND((AVG(taux_perte_intrats)), 2) AS taux_perte_intrats, 
    ROUND((SUM(taux_perte_intrats)), 2) || ' / ' || COUNT(program_name) AS sur -- Summed sur values
FROM 
    calculated_taux   
{% endmacro %}
 
 

{% macro not_avg_value() %}
SELECT p.program_name as program_name,
       p.facility_name AS facility_name,
       p.product_name as product_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       p.period_name as period_name,
       ROUND(((p.qt_intrats_perdus::NUMERIC / r.qtt_intrats_recus) * 100), 2) AS taux_perte_intrats,
       p.qt_intrats_perdus || ' / ' || r.qtt_intrats_recus AS sur
      FROM qt_intrats_perdu p 
      JOIN qtt_intrats_recu r ON p.program_name=r.program_name AND p.facility_name=r.facility_name 
{% endmacro %}



WITH qt_intrats_perdu AS(
SELECT SUM(quantity) as qt_intrats_perdus,
                       program_name as program_name,
                       facility_name as facility_name,
                       product_name as product_name,
                       '{{filter_values('period_name')[0]}}' as period_name,
                       '{{filter_values('frequence_name')[0]}}' AS frequence_name
                       FROM(
                            SELECT a.quantity,
                                   pr.name as program_name,
                                   f.name as facility_name,
                                   o.fullproductname as product_name,
                                   '{{filter_values('period_name')[0]}}' as period_name,
                                   '{{filter_values('frequence_name')[0]}}' AS frequence_name
                                  FROM requisition.requisition_line_items i JOIN requisition.requisitions r ON i.requisitionid=r.id   
                                                    JOIN referencedata.facilities f ON r.facilityid=f.id
                        												    JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
                        												    JOIN requisition.stock_adjustments a ON a.requisitionlineitemid = i.id
                          													JOIN stockmanagement.stock_card_line_item_reasons rs ON a.reasonid=rs.id
                          													JOIN referencedata.programs pr ON r.programid=pr.id
                          													JOIN referencedata.orderables o ON i.orderableid=o.id
                          													JOIN (
                                                    		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p 
                                              		          where p.name='{{filter_values('period_name')[0]}}'
                                                    		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
                                 WHERE  
                  							        pr.name='{{filter_values('program_name')[0]}}' AND
                  							        {% if current_year() == filter_values('year_name')[0] | int and 'Hebdomadaire' == filter_values('frequence_name')[0] %}
                                          DATE_TRUNC('{{ frequ_valu }}', r.createddate) = DATE_TRUNC('{{ frequ_valu }}', CURRENT_DATE) AND
                                        {% endif %}
                  									    --f.name='CSR KOLABOUI' AND 
                  									    --o.fullproductname in ('MODERNA', 'SPUTNIK V') AND
                  									    ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
                                         f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
                                         if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
                                        AND 
                                        ('{{ filter_values('product_name', []) | length }}' = 0 OR 
                                         o.fullproductname IN ( {{ "'" + "','".join(filter_values('product_name', ['default_product1', 'default_product2'])) + "'" 
                                         if filter_values('product_name', []) else "'default_product1','default_product2'" }}))
                                        AND
                  									    (r.status='APPROVED' OR r.status='AUTHORIZED') AND
                  									    (rs.name='Pertes' OR rs.name='Expiré')
                  							 GROUP BY pr.name, a.quantity, f.name, o.fullproductname
                  							      ) as grouped_data
			                           GROUP BY program_name, product_name, facility_name
),
qtt_intrats_recu AS(
SELECT SUM(i.totalreceivedquantity + i.beginningbalance) as qtt_intrats_recus,
                                       pr.name as program_name,
                                       '{{filter_values('period_name')[0]}}' as period_name,
                                       f.name as facility_name,
                                       '{{filter_values('frequence_name')[0]}}' AS frequence_name
                     FROM requisition.requisition_line_items i JOIN requisition.requisitions r ON i.requisitionid=r.id  --qt tt intrats recus 
                                        JOIN referencedata.facilities f ON r.facilityid=f.id
												                JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
												                JOIN referencedata.programs pr ON r.programid=pr.id
												                JOIN (
                                        		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p 
                                  		          where p.name='{{filter_values('period_name')[0]}}'
                                        		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
                     WHERE  pr.name='{{filter_values('program_name')[0]}}' AND
                            ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
                             f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
                             if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
                            AND 
							              {% if current_year() == filter_values('year_name')[0] | int and 'Hebdomadaire' == filter_values('frequence_name')[0] %}
                              DATE_TRUNC('{{ frequ_valu }}', r.createddate) = DATE_TRUNC('{{ frequ_valu }}', CURRENT_DATE) AND
                            {% endif %}
        									  (r.status='APPROVED' OR r.status='AUTHORIZED')
									   GROUP BY pr.name, f.name
)
{% if facility_name_list | length != 0 or product_name_list | length != 0 %}
 {{not_avg_value()}}
{% else %}
--********** average case *****************
{{avg_value()}}

{% endif %}
      
		
		
		
		
		
		
		
	
		
		
		
		
		
		
		
		
	
		

      
		
		
		
		
		