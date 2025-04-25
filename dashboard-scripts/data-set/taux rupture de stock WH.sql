--Filter columns program_name, period_name and facility_name 
-- 1 program_name is the "SELECT p.name as program_name FROM referencedata.programs p";

-- 2 product_name is the "SELECT o.fullproductname as product_name FROM referencedata.orderables o GROUP BY o.fullproductname"

-- 3 frequence_name is the "SELECT *
--						   FROM (
--						       VALUES 
--						           (1, 'Hebdomadaire'),
--						           (2, 'Mensuelle'),
--						           (3, 'Trimestrielle'),
--						           (4, 'Annuelle')
--						   ) AS t(id, frequence_name);"



      





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
   SELECT p.frequence_name as frequence_name,
       p.program_name as program_name,
        p.product_name as product_name,
        p.facility_name as facility_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       ROUND(((p.nbre_produits_en_ruptures::NUMERIC / r.nbre_tt_produits) * 100), 2) AS taux_rupture_stock,
       p.nbre_produits_en_ruptures || ' / ' || r.nbre_tt_produits as sur
      FROM nbr_produit_en_rupture p 
      JOIN nbr_tt_produit r ON p.frequence_name=r.frequence_name
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
 
 

{% macro not_avg_value() %}
SELECT p.frequence_name as frequence_name,
       p.program_name as program_name,
        p.product_name as product_name,
        p.facility_name as facility_name,
       '{{filter_values('year_name')[0]}}' as year_name,
       ROUND(((p.nbre_produits_en_ruptures::NUMERIC / r.nbre_tt_produits) * 100), 2) AS taux_rupture_stock,
       p.nbre_produits_en_ruptures || ' / ' || r.nbre_tt_produits as sur
      FROM nbr_produit_en_rupture p 
      JOIN nbr_tt_produit r ON p.frequence_name=r.frequence_name
{% endmacro %}



WITH nbr_produit_en_rupture AS(
WITH max_dates AS (
    SELECT s.lotid,
		       s.orderableid,
           h.id AS stock_id,
           h.processeddate,
           o.fullproductname as product_name,
		       f.name as facility_name,
		       p.name as program_name,
		       '{{filter_values('frequence_name')[0]}}' as frequence_name,
           ROW_NUMBER() OVER (PARTITION BY s.lotid, s.orderableid, f.name, p.name ORDER BY h.processeddate DESC) AS row_num
    FROM stockmanagement.stock_cards s
         JOIN referencedata.orderables o ON o.id = s.orderableid
         JOIN stockmanagement.calculated_stocks_on_hand h ON h.stockcardid = s.id
         JOIN referencedata.programs p ON s.programid=p.id
         JOIN referencedata.facilities f ON s.facilityid = f.id
    WHERE 
          ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
           f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
           if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
          AND 
          p.name='{{filter_values('program_name')[0]}}'  
          AND
          ('{{ filter_values('product_name', []) | length }}' = 0 OR 
           o.fullproductname IN ( {{ "'" + "','".join(filter_values('product_name', ['default_product1', 'default_product2'])) + "'" 
           if filter_values('product_name', []) else "'default_product1','default_product2'" }}))
          AND
          DATE_TRUNC(
                '{{ frequ_valu }}', 
                CASE 
                    WHEN {{filter_values('year_name')[0]}} = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('{{filter_values('year_name')[0]}}' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('{{ frequ_valu }}', h.occurreddate)
)
SELECT COUNT(program_name) as nbre_produits_en_ruptures,
                              program_name as program_name,
                              product_name,
                              facility_name,
                              '{{filter_values('frequence_name')[0]}}' as frequence_name
            FROM (
              SELECT SUM(h.stockonhand) as sum_stockonhand,
                     facility_name,
                     program_name,
                     product_name,
                     '{{filter_values('frequence_name')[0]}}' as frequence_name
                from (
                		SELECT lotid,
                		       stock_id,
                			     product_name,
                			     facility_name,
                			     program_name,
                			     '{{filter_values('frequence_name')[0]}}' as frequence_name,
                		       processeddate AS max_processeddate
                		FROM max_dates
                		WHERE row_num = 1) as result_1
                		JOIN stockmanagement.calculated_stocks_on_hand h ON h.id = result_1.stock_id
                	  GROUP BY result_1.facility_name, result_1.program_name, result_1.product_name) as final_result
	      WHERE final_result.sum_stockonhand=0
	      GROUP BY program_name, product_name, facility_name
        	      
        	      
),
nbr_tt_produit AS(
SELECT COUNT(DISTINCT o.id) as nbre_tt_produits,
                      '{{filter_values('frequence_name')[0]}}' AS frequence_name
          FROM referencedata.orderables o JOIN referencedata.program_orderables po ON po.orderableid = o.id
                                          JOIN referencedata.programs p ON p.id = po.programid 
                                          WHERE p.name = '{{filter_values('program_name')[0]}}' AND po.active = true
)
{% if facility_name_list | length != 0 or product_name_list | length != 0 %}
 {{not_avg_value()}}
{% else %}
--********** average case *****************
{{avg_value()}}

{% endif %}
      
      






















		