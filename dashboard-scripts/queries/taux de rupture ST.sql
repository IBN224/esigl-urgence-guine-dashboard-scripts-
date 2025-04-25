

WITH nbre_produit_rupture AS(
SELECT COUNT(DISTINCT i.id) AS nbre_prod_rupture,
       pr.name as program_name,
       o.fullproductname as product_name,
       f.name AS facility_name,
      'period_name' as period_name,
      'frequence_name' AS frequence_name,
      'year_name' as year_name
FROM requisition.requisition_line_items i
JOIN requisition.requisitions r ON i.requisitionid=r.id
JOIN referencedata.facilities f ON r.facilityid=f.id
JOIN referencedata.orderables o ON i.orderableid=o.id
JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
JOIN referencedata.programs pr ON pr.id = r.programid
JOIN (
   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p where p.name='Feb, 2022'
 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
WHERE 
        DATE_TRUNC('year', r.createddate) = DATE_TRUNC('year', CURRENT_DATE) AND  --TO_DATE('2024-10-31', 'YYYY-MM-DD')
        (r.status='APPROVED' OR r.status='AUTHORIZED') AND
        f.name IN('CSR SINKO', 'CSR KOLABOUI', 'CSA SANGAREDI') AND
        --o.fullproductname IN('JOHNSON & JOHNSON') AND
        pr.name = 'VACCINS' AND
        i.stockonhand=0 
GROUP BY p.name, pr.name,o.fullproductname, f.name
),
nbre_tt_produits AS (
SELECT COUNT(DISTINCT o.id) as nbre_tt_produits,
          'VACCINS' as program_name
          FROM referencedata.orderables o JOIN referencedata.program_orderables po ON po.orderableid = o.id
                                          JOIN referencedata.programs p ON p.id = po.programid 
                                          WHERE p.name = 'VACCINS' AND po.active = true
)
--******** first case with not avg *******-------
SELECT np.program_name as program_name,
      np.facility_name as facility_name,
      np.product_name as product_name,
      np.period_name as period_name,
      np.frequence_name AS frequence_name,
      '2025' as year_name,
      ROUND(((np.nbre_prod_rupture::NUMERIC / nt.nbre_tt_produits::NUMERIC) * 100), 2) AS taux_rupture_stock,
      np.nbre_prod_rupture|| ' / ' ||nt.nbre_tt_produits as sur
      FROM nbre_produit_rupture np 
      JOIN nbre_tt_produits nt ON np.program_name=nt.program_name
--****************************************-----------

--******** second case with avg *******-------
-- ,
-- calculated_taux AS (
-- SELECT np.program_name as program_name,
--       np.facility_name as facility_name,
--       np.product_name as product_name,
--       np.period_name as period_name,
--       np.frequence_name AS frequence_name,
--       '2025' as year_name,
--       ROUND(((np.nbre_prod_rupture::NUMERIC / nt.nbre_tt_produits::NUMERIC) * 100), 2) AS taux_rupture_stock,
--       np.nbre_prod_rupture|| ' / ' ||nt.nbre_tt_produits as sur
--       FROM nbre_produit_rupture np 
--       JOIN nbre_tt_produits nt ON np.program_name=nt.program_name
-- )
-- -- Final single-line result with aggregated values
-- SELECT 
--     'VACCINS' AS program_name,                     
--     'NAN' AS facility_name, 
--     'NAN' AS product_name,
--     'Feb, 2022' as period_name,
--     'year' AS frequence_name,                 
--     '2025' AS year_name,                          
--     ROUND((AVG(taux_rupture_stock)), 2) AS taux_rupture_stock, 
--     ROUND((SUM(taux_rupture_stock)), 2) || ' / ' || COUNT(program_name) AS sur -- Summed sur values
-- FROM 
--     calculated_taux 
    
    


