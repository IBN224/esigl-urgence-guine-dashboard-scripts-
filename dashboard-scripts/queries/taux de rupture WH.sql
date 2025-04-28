
WITH nbr_produit_en_rupture AS(
--nombre de produit en rupture de stock
WITH max_dates AS (
    SELECT s.lotid,
		       s.orderableid,
           h.id AS stock_id,
           h.processeddate,
           o.fullproductname as product_name,
		       f.name as facility_name,
		       p.name as program_name,
		       'year' as frequence_name,
           ROW_NUMBER() OVER (PARTITION BY s.lotid, s.orderableid, f.name, p.name ORDER BY h.processeddate DESC) AS row_num
    FROM stockmanagement.stock_cards s
         JOIN referencedata.orderables o ON o.id = s.orderableid
         JOIN stockmanagement.calculated_stocks_on_hand h ON h.stockcardid = s.id
         JOIN referencedata.programs p ON s.programid=p.id
         JOIN referencedata.facilities f ON s.facilityid = f.id
    WHERE 
           --f.name IN ('BOKE', 'BEYLA') AND 
          p.name='VACCINS' AND
          -- o.fullproductname IN ('') AND
          DATE_TRUNC(
                'year', 
                CASE 
                    WHEN 2023 = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('2023' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('year', h.occurreddate)
)
SELECT COUNT(program_name) as nbre_produits_en_ruptures,
                              program_name as program_name,
                              'year' as frequence_name
            FROM (
              SELECT SUM(h.stockonhand) as sum_stockonhand,
                     facility_name,
                     program_name,
                     product_name,
                     'year' as frequence_name
                from (
                		SELECT lotid,
                		       stock_id,
                			     product_name,
                			     facility_name,
                			     program_name,
                			     'year' as frequence_name,
                		       processeddate AS max_processeddate
                		FROM max_dates
                		WHERE row_num = 1) as result_1
                		JOIN stockmanagement.calculated_stocks_on_hand h ON h.id = result_1.stock_id
                	  GROUP BY result_1.facility_name, result_1.program_name, result_1.product_name) as final_result
	      WHERE final_result.sum_stockonhand=0
	      GROUP BY program_name  
),
nbr_tt_produit AS(
--nombre total de produit
SELECT COUNT(DISTINCT o.id) as nbre_tt_produits,
                      'year' AS frequence_name
          FROM referencedata.orderables o JOIN referencedata.program_orderables po ON po.orderableid = o.id
                                          JOIN referencedata.programs p ON p.id = po.programid 
                                          WHERE p.name = 'VACCINS' AND po.active = true
)
SELECT p.frequence_name as frequence_name,
       p.program_name as program_name,
        'NAN' as product_name,
        'NAN' as facility_name,
       'year' as year_name,
       ROUND(((p.nbre_produits_en_ruptures::NUMERIC / r.nbre_tt_produits) * 100), 2) AS taux_rupture_stock,
       p.nbre_produits_en_ruptures || ' / ' || r.nbre_tt_produits as sur
      FROM nbr_produit_en_rupture p 
      JOIN nbr_tt_produit r ON p.frequence_name=r.frequence_name;
      
      
      
      