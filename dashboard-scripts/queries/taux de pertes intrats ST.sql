
WITH qt_intrats_perdu AS(
SELECT SUM(quantity) as qt_intrats_perdus,
                       program_name as program_name,
                       facility_name as facility_name,
                       product_name as product_name,
                       'Feb, 2022' as period_name,
                       'year' AS frequence_name
                       FROM(
                            SELECT a.quantity,
                                   pr.name as program_name,
                                   f.name as facility_name,
                                   o.fullproductname as product_name,
                                   'Feb, 2022' as period_name,
                                   'year' AS frequence_name
                                  FROM requisition.requisition_line_items i JOIN requisition.requisitions r ON i.requisitionid=r.id   
                                                    JOIN referencedata.facilities f ON r.facilityid=f.id
                        												    JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
                        												    JOIN requisition.stock_adjustments a ON a.requisitionlineitemid = i.id
                          													JOIN stockmanagement.stock_card_line_item_reasons rs ON a.reasonid=rs.id
                          													JOIN referencedata.programs pr ON r.programid=pr.id
                          													JOIN referencedata.orderables o ON i.orderableid=o.id
                          													JOIN (
                                                    		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p 
                                              		          where p.name='Feb, 2022'
                                                    		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
                                 WHERE  
                    							        pr.name='VACCINS' AND
                                          DATE_TRUNC('year', r.createddate) = DATE_TRUNC('year', CURRENT_DATE) AND
                  									    --f.name='CSR KOLABOUI' AND 
                  									    --o.fullproductname in ('MODERNA', 'SPUTNIK V') AND
                                         f.name IN ('CSR SINKO', 'CSR KOLABOUI', 'CSA SANGAREDI') AND
                                         --o.fullproductname IN () AND
                  									    (r.status='APPROVED' OR r.status='AUTHORIZED') AND
                  									    (rs.name='Pertes' OR rs.name='Expiré')
                  							 GROUP BY pr.name, a.quantity, f.name, o.fullproductname
                  							      ) as grouped_data
			                           GROUP BY program_name, product_name, facility_name
),
qtt_intrats_recu AS(
SELECT SUM(i.totalreceivedquantity + i.beginningbalance) as qtt_intrats_recus,
                                       pr.name as program_name,
                                       'Feb, 2022' as period_name,
                                       f.name as facility_name,
                                       'day' AS frequence_name
                     FROM requisition.requisition_line_items i JOIN requisition.requisitions r ON i.requisitionid=r.id  --qt tt intrats recus 
                                        JOIN referencedata.facilities f ON r.facilityid=f.id
												                JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
												                JOIN referencedata.programs pr ON r.programid=pr.id
												                JOIN (
                                        		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p 
                                  		          where p.name='Feb, 2022'
                                        		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
                     WHERE  pr.name='VACCINS' AND
                             f.name IN ('CSR SINKO', 'CSR KOLABOUI', 'CSA SANGAREDI') AND 
                              DATE_TRUNC('year', r.createddate) = DATE_TRUNC('year', CURRENT_DATE) AND
        									  (r.status='APPROVED' OR r.status='AUTHORIZED')
									   GROUP BY pr.name, f.name
)
--******** first case with not avg *******-------
SELECT p.program_name as program_name,
      p.facility_name AS facility_name,
      p.product_name as product_name,
      '2025' as year_name,
      p.period_name as period_name,
      ROUND(((p.qt_intrats_perdus::NUMERIC / r.qtt_intrats_recus) * 100), 2) AS taux_perte_intrats,
      p.qt_intrats_perdus || ' / ' || r.qtt_intrats_recus AS sur
      FROM qt_intrats_perdu p 
      JOIN qtt_intrats_recu r ON p.program_name=r.program_name AND p.facility_name=r.facility_name 
--****************************************-----------

--******** second case with avg *******-------
-- ,
-- calculated_taux AS (
--     SELECT p.program_name as program_name,
--       p.facility_name AS facility_name,
--       p.product_name as product_name,
--       '2025' as year_name,
--       p.period_name as period_name,
--       ROUND(((p.qt_intrats_perdus::NUMERIC / r.qtt_intrats_recus) * 100), 2) AS taux_perte_intrats,
--       p.qt_intrats_perdus || ' / ' || r.qtt_intrats_recus AS sur
--       FROM qt_intrats_perdu p 
--       JOIN qtt_intrats_recu r ON p.program_name=r.program_name AND p.facility_name=r.facility_name 
-- )
-- -- Final single-line result with aggregated values
-- SELECT 
--     'VACCINS' AS program_name,                     
--     'NAN' AS facility_name, 
--     'NAN' AS product_name,
--     'Feb, 2022' as period_name,                 
--     '2025' AS year_name,                          
--     ROUND((AVG(taux_perte_intrats)), 2) AS taux_perte_intrats, 
--     ROUND((SUM(taux_perte_intrats)), 2) || ' / ' || COUNT(program_name) AS sur -- Summed sur values
-- FROM 
--     calculated_taux     

