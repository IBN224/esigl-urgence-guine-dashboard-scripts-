
/*** Filters to use programs, frequence, year, period, facility et product ***/


{% set frequ_valu = (
    'day' if filter_values('frequence_name')[0] == 'Hebdomadaire' else
    'month' if filter_values('frequence_name')[0] == 'Mensuelle' else
    'quarter' if filter_values('frequence_name')[0] == 'Trimestrielle' else
    'year' if filter_values('frequence_name')[0] == 'Annuelle' else None
) %}

{% set facility_name_list = filter_values('facility_name') | default([]) %}
{% set product_name_list = filter_values('product_name') | default([]) %}


{% macro avg_value() %} --****** case with avg
,
calculated_taux AS (
 SELECT np.program_name as program_name,
       np.facility_name as facility_name,
       np.product_name as product_name,
       np.period_name as period_name,
       np.frequence_name AS frequence_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       ROUND(((np.nbre_prod_rupture::NUMERIC / nt.nbre_tt_produits::NUMERIC) * 100), 2) AS taux_rupture_stock,
       np.nbre_prod_rupture|| ' / ' ||nt.nbre_tt_produits as sur
      FROM nbre_produit_rupture np 
      JOIN nbre_tt_produits nt ON np.program_name=nt.program_name
)
-- Final single-line result with aggregated values
SELECT 
    '{{filter_values('program_name')[0]}}' AS program_name,                     
    'NAN' AS facility_name, 
    'NAN' AS product_name,
    '{{filter_values('period_name')[0]}}' as period_name,
    '{{filter_values('frequence_name')[0]}}' AS frequence_name,                 
    '{{filter_values('year_name')[0]}}' AS year_name,                          
    ROUND((AVG(taux_rupture_stock)), 2) AS taux_rupture_stock, 
    ROUND((SUM(taux_rupture_stock)), 2) || ' / ' || COUNT(program_name) AS sur -- Summed sur values
FROM 
    calculated_taux   
{% endmacro %}
 
 

{% macro not_avg_value() %} --****** case without avg
SELECT np.program_name as program_name,
       np.facility_name as facility_name,
       np.product_name as product_name,
       np.period_name as period_name,
       np.frequence_name AS frequence_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       ROUND(((np.nbre_prod_rupture::NUMERIC / nt.nbre_tt_produits::NUMERIC) * 100), 2) AS taux_rupture_stock,
       np.nbre_prod_rupture|| ' / ' ||nt.nbre_tt_produits as sur
      FROM nbre_produit_rupture np 
      JOIN nbre_tt_produits nt ON np.program_name=nt.program_name
{% endmacro %}



WITH nbre_produit_rupture AS(
SELECT COUNT(DISTINCT i.id) AS nbre_prod_rupture,
       pr.name as program_name,
       o.fullproductname as product_name,
       f.name AS facility_name,
      '{{filter_values('period_name')[0]}}' as period_name,
      '{{filter_values('frequence_name')[0]}}' AS frequence_name,
     '{{filter_values('year_name')[0]}}' as year_name
FROM requisition.requisition_line_items i
JOIN requisition.requisitions r ON i.requisitionid=r.id
JOIN referencedata.facilities f ON r.facilityid=f.id
JOIN referencedata.orderables o ON i.orderableid=o.id
JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
JOIN referencedata.programs pr ON pr.id = r.programid
JOIN (
   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p where p.name='{{filter_values('period_name')[0]}}'
 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
WHERE 
      {% if current_year() == filter_values('year_name')[0] | int and 'Hebdomadaire' == filter_values('frequence_name')[0] %}
        DATE_TRUNC('{{ frequ_valu }}', r.createddate) = DATE_TRUNC('{{ frequ_valu }}', CURRENT_DATE) AND
      {% endif %}
      (r.status='APPROVED' OR r.status='AUTHORIZED') AND
      ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
       f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
       if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
      AND 
      ('{{ filter_values('product_name', []) | length }}' = 0 OR 
       o.fullproductname IN ( {{ "'" + "','".join(filter_values('product_name', ['default_product1', 'default_product2'])) + "'" 
       if filter_values('product_name', []) else "'default_product1','default_product2'" }}))
      AND
      pr.name = '{{filter_values('program_name')[0]}}' AND
      i.stockonhand=0 
GROUP BY p.name, pr.name,o.fullproductname, f.name
),
nbre_tt_produits AS (
SELECT COUNT(DISTINCT o.id) as nbre_tt_produits,
          '{{filter_values('program_name')[0]}}' as program_name
          FROM referencedata.orderables o JOIN referencedata.program_orderables po ON po.orderableid = o.id
                                          JOIN referencedata.programs p ON p.id = po.programid 
                                          WHERE p.name = '{{filter_values('program_name')[0]}}' AND po.active = true
)
{% if facility_name_list | length != 0 or product_name_list | length != 0 %}
 {{not_avg_value()}}
{% else %}

{{avg_value()}}

{% endif %}

 



