--Filter columns period_name
-- period_name is the "SELECT p.name as period_name from referencedata.processing_periods p"

WITH nbr_rapport_saisi_dans_delais AS(
SELECT COUNT(r.id) as nbr_rapport_saisi_delais,
                      p.name as period_name
            FROM requisition.requisitions r JOIN referencedata.processing_periods p ON r.processingperiodid=p.id  
            WHERE p.name='{{filter_values('period_name')[0]}}' AND 
					        (r.status='APPROVED' OR r.status='AUTHORIZED') AND 
									r.createddate <= p.enddate + 10     -- TO_DATE('2024-10-31', 'YYYY-MM-DD')  p.enddate
						GROUP BY p.name
),
nbr_tt_rapport_attendu AS(
SELECT COUNT(r.id) as nbr_tt_rapport_attendus,
            p.name as period_name
            FROM  requisition.requisitions r JOIN referencedata.processing_periods p ON r.processingperiodid=p.id   
				    WHERE p.name='{{filter_values('period_name')[0]}}' AND r.status='INITIATED'
				    GROUP BY p.name
)
SELECT p.period_name as period_name, 
       ROUND(((p.nbr_rapport_saisi_delais::NUMERIC / r.nbr_tt_rapport_attendus) * 100), 2) AS taux_promptitude_rapport
      FROM nbr_rapport_saisi_dans_delais p 
      JOIN nbr_tt_rapport_attendu r ON p.period_name=r.period_name;
