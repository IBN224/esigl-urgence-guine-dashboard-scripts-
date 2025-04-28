

WITH sum_duree_tout_rupture AS(
-- somme des duree de toutes les ruptures 
SELECT SUM(totalstockoutdays) as sum_duree_tt_rupture,
        program_name as program_name,
        product_name as product_name,
        facility_name as facility_name,
        'Feb 2022' as period_name,
        'day' AS frequence_name
                      FROM (
                           SELECT  i.totalstockoutdays, 
                                   pr.name as program_name,
                                   o.fullproductname as product_name,
                                   f.name as facility_name,
                                   'Feb 2022' as period_name,
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
                      		          where p.name='Feb, 2022'
                            		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
                         WHERE  
                                pr.name='VACCINS' AND
                                  DATE_TRUNC('year', r.createddate) = DATE_TRUNC('year', CURRENT_DATE) AND
                                   f.name IN ('CSR SINKO', 'CSR KOLABOUI', 'CSA SANGAREDI') AND 
                                   --o.fullproductname IN ('') AND
            									  (r.status='APPROVED' OR r.status='AUTHORIZED') AND 
            									  i.totalstockoutdays!=0 
        								 GROUP BY pr.name, i.totalstockoutdays, f.name, o.fullproductname
        								 ) as grouped_data
        								 GROUP BY program_name, product_name, facility_name 
),
nbre_tt_de_rupture AS(
--nombre total de ruptures
SELECT COUNT(DISTINCT i.id) as nbre_tt_rupture,
                      pr.name as program_name,
                      o.fullproductname as product_name,
                     'Feb, 2022' as period_name,
                     'day' AS frequence_name
               FROM requisition.requisition_line_items i 
                           JOIN requisition.requisitions r ON i.requisitionid=r.id  
												   JOIN referencedata.orderables o ON i.orderableid=o.id
												   JOIN referencedata.programs pr ON pr.id=r.programid
												   JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
                           JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
                        	 JOIN (
                        		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p where p.name='Feb, 2022'
                        		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
               WHERE  pr.name='VACCINS' AND
                       --o.fullproductname IN () AND
  									  (r.status='APPROVED' OR r.status='AUTHORIZED') AND 
                        DATE_TRUNC('year', r.createddate) = DATE_TRUNC('year', CURRENT_DATE) AND
  									  i.totalstockoutdays!=0
						  GROUP BY pr.name, o.fullproductname
)
--******* comment one case to run *******--------------

--******** first case with not avg *******-------
SELECT s.program_name as program_name,
      s.facility_name as facility_name,
      s.product_name as product_name,
      'Feb, 2022' as period_name,
      'year' AS frequence_name,
      '2022' as year_name,
      ROUND((s.sum_duree_tt_rupture::NUMERIC / n.nbre_tt_rupture), 2) AS duree_moyen_rupture,
      s.sum_duree_tt_rupture || ' / ' || n.nbre_tt_rupture AS sur
      FROM sum_duree_tout_rupture s 
      JOIN nbre_tt_de_rupture n ON s.program_name=n.program_name AND s.product_name=n.product_name
--****************************************-----------

--******** second case with avg *******-------
,
calculated_taux AS (
    SELECT s.program_name as program_name,
      s.facility_name as facility_name,
      s.product_name as product_name,
      'Feb, 2022' as period_name,
      'year' AS frequence_name,
      '2022' as year_name,
      ROUND((s.sum_duree_tt_rupture::NUMERIC / n.nbre_tt_rupture), 2) AS duree_moyen_rupture,
      s.sum_duree_tt_rupture || ' / ' || n.nbre_tt_rupture AS sur
      FROM sum_duree_tout_rupture s 
      JOIN nbre_tt_de_rupture n ON s.program_name=n.program_name AND s.product_name=n.product_name
)
-- Final single-line result with aggregated values
SELECT 
    'VACCINS' AS program_name,                     
    'NAN' AS facility_name, 
    'NAN' AS product_name,
    'Feb, 2022' as period_name,
    'year' AS frequence_name,                 
    '2022' AS year_name,                          
    ROUND((AVG(duree_moyen_rupture)), 2) AS duree_moyen_rupture, 
    ROUND((SUM(duree_moyen_rupture)), 2) || ' / ' || COUNT(program_name) AS sur 
FROM 
    calculated_taux 



