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


WITH nbr_produit_en_rupture AS(
WITH max_dates AS (
    SELECT s.lotid,
		       s.orderableid,
           h.id AS stock_id,
           h.processeddate,
		       '{{filter_values('product_name')[0]}}' as product_name,
		       f.name as facility_name,
		       '{{filter_values('program_name')[0]}}' as program_name,
		       '{{filter_values('frequence_name')[0]}}' as frequence_name,
           ROW_NUMBER() OVER (PARTITION BY s.lotid, s.orderableid, f.name, p.name ORDER BY h.processeddate DESC) AS row_num
    FROM stockmanagement.stock_cards s
         JOIN referencedata.orderables o ON o.id = s.orderableid
         JOIN stockmanagement.calculated_stocks_on_hand h ON h.stockcardid = s.id
         JOIN referencedata.programs p ON s.programid=p.id
         JOIN referencedata.facilities f ON s.facilityid = f.id
    WHERE p.name='{{filter_values('program_name')[0]}}' AND
          o.fullproductname in ('{{filter_values('product_name')[0]}}') AND
          (('{{filter_values('frequence_name')[0]}}' = 'Hebdomadaire' AND 
            DATE_TRUNC('day', h.occurreddate) = DATE_TRUNC('day', TO_DATE('2023-06-30', 'YYYY-MM-DD'))) OR
          ('{{filter_values('frequence_name')[0]}}' = 'Mensuelle' AND 
           DATE_TRUNC('month', h.occurreddate) = DATE_TRUNC('month', TO_DATE('2023-06-30', 'YYYY-MM-DD'))) OR
          ('{{filter_values('frequence_name')[0]}}' = 'Trimestrielle' AND 
           DATE_TRUNC('quarter', h.occurreddate) = DATE_TRUNC('quarter', TO_DATE('2023-06-30', 'YYYY-MM-DD'))) OR
          ('{{filter_values('frequence_name')[0]}}' = 'Annuelle' AND 
           DATE_TRUNC('year', h.occurreddate) = DATE_TRUNC('year', TO_DATE('2023-06-30', 'YYYY-MM-DD')))) 
         -- DATE_TRUNC('week', h.occurreddate) = DATE_TRUNC('week', TO_DATE('2023-06-30', 'YYYY-MM-DD') ) --CURRENT_DATE  TO_DATE('2024-10-31', 'YYYY-MM-DD') 
)
SELECT COUNT(product_name) as nbre_produits_en_ruptures,
                              '{{filter_values('program_name')[0]}}' as program_name,
                              '{{filter_values('product_name')[0]}}' as product_name,
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
),
nbr_tt_produit AS(
SELECT COUNT(DISTINCT o.id) as nbre_tt_produits,
                      '{{filter_values('frequence_name')[0]}}' AS frequence_name
          FROM referencedata.orderables o
)
SELECT '{{filter_values('frequence_name')[0]}}' as frequence_name,
       '{{filter_values('program_name')[0]}}' as program_name,
       '{{filter_values('product_name')[0]}}' as product_name,
       ROUND(((p.nbre_produits_en_ruptures::NUMERIC / r.nbre_tt_produits) * 100), 2) AS taux_rupture_stock
      FROM nbr_produit_en_rupture p 
      JOIN nbr_tt_produit r ON p.frequence_name=r.frequence_name;
      



















		