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


WITH sum_duree_tout_rupture AS(
SELECT SUM(grouped_data.totalstockoutdays) as sum_duree_tt_rupture,
        '{{filter_values('product_name')[0]}}' as product_name,
        '{{filter_values('period_name')[0]}}' as period_name,
        '{{filter_values('frequence_name')[0]}}' AS frequence_name
                      FROM (
                           SELECT  i.totalstockoutdays, 
                                   '{{filter_values('product_name')[0]}}' as product_name,
                                   '{{filter_values('period_name')[0]}}' as period_name,
                                   '{{filter_values('frquence_name')[0]}}' AS frequence_name
                         FROM requisition.requisition_line_items i 
                               JOIN requisition.requisitions r ON i.requisitionid=r.id
        										   JOIN referencedata.orderables o ON i.orderableid=o.id
        										   JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
                               JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
                            	 JOIN (
                            		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p 
                      		          where p.name='{{filter_values('period_name')[0]}}'
                            		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
                         WHERE  s.code='{{filter_values('frequence_name')[0]}}' AND
                                o.fullproductname='{{filter_values('product_name')[0]}}' AND
            									  (r.status='APPROVED' OR r.status='AUTHORIZED') AND 
            									  i.totalstockoutdays!=0 
        								 GROUP BY o.fullproductname, i.totalstockoutdays) as grouped_data
        								 GROUP BY grouped_data.product_name
								 
),
nbre_tt_de_rupture AS(
SELECT COUNT(DISTINCT i.id) as nbre_tt_rupture,
                     '{{filter_values('product_name')[0]}}' as product_name,
                     '{{filter_values('period_name')[0]}}' as period_name,
                     '{{filter_values('frequence_name')[0]}}' AS frequence_name
               FROM requisition.requisition_line_items i 
                           JOIN requisition.requisitions r ON i.requisitionid=r.id  
												   JOIN referencedata.orderables o ON i.orderableid=o.id
												   JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
                           JOIN referencedata.processing_schedules s ON s.id=p.processingscheduleid
                        	 JOIN (
                        		   SELECT p.startdate as startDate_border, p.enddate as endDate_border FROM referencedata.processing_periods p 
                  		          where p.name='{{filter_values('period_name')[0]}}'
                        		 ) as borderDates ON (borderDates.startDate_border<=p.startdate and borderDates.endDate_border>=p.enddate)
               WHERE  o.fullproductname='{{filter_values('product_name')[0]}}' AND
  									  (r.status='APPROVED' OR r.status='AUTHORIZED') AND 
  									  s.code='{{filter_values('frequence_name')[0]}}' AND
  									  i.totalstockoutdays!=0
						  GROUP BY o.fullproductname
)
SELECT s.frequence_name AS frequence_name,
       s.product_name as product_name,
       s.period_name as period_name,
       ROUND((s.sum_duree_tt_rupture::NUMERIC / n.nbre_tt_rupture), 2) AS duree_moyen_rupture
      FROM sum_duree_tout_rupture s 
      JOIN nbre_tt_de_rupture n ON s.product_name=n.product_name;



		
		
		
		
		
		