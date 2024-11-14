
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

WITH nbre_produit_rupture AS (
  SELECT COUNT(DISTINCT i.id) AS nbre_prod_rupture,
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
    WHERE s.code='{{filter_values('frequence_name')[0]}}' AND
          (r.status='APPROVED' OR r.status='AUTHORIZED') AND
           o.fullproductname='{{filter_values('product_name')[0]}}' AND
           i.stockonhand=0 
    GROUP BY o.fullproductname
 ),
nbre_tt_produits AS (
SELECT COUNT(DISTINCT o.id) AS nbre_tt_produits,
            '{{filter_values('product_name')[0]}}' as product_name
            FROM referencedata.orderables o
)
SELECT np.frequence_name AS frequence_name,
       np.product_name as product_name,
       np.period_name as period_name,
       ROUND(((np.nbre_prod_rupture::NUMERIC / nt.nbre_tt_produits::NUMERIC) * 100), 2) AS taux_rupture_stock
      FROM nbre_produit_rupture np 
      JOIN nbre_tt_produits nt ON np.product_name=nt.product_name;


