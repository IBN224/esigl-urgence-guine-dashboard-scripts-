--Filter columns program_name, period_name and facility_name 
-- 1 program_name is the "SELECT p.name as program_name FROM referencedata.programs p";

-- 2 period_name is the "SELECT p.name as period_name from referencedata.processing_periods p"

-- 3 facility_name is the "SELECT f.name as facility_name FROM referencedata.facilities f"


WITH qt_intrats_perdu AS(
SELECT SUM(a.quantity) as qt_intrats_perdus,
                       pr.name as program_name,
                       p.name as period_name,
                       f.name as facility_name
                      FROM requisition.requisition_line_items i JOIN requisition.requisitions r ON i.requisitionid=r.id   
                                        JOIN referencedata.facilities f ON r.facilityid=f.id
            												    JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
            												    JOIN requisition.stock_adjustments a ON a.requisitionlineitemid = i.id
              													JOIN stockmanagement.stock_card_line_item_reasons rs ON a.reasonid=rs.id
              													JOIN referencedata.programs pr ON r.programid=pr.id
                     WHERE  f.name='{{filter_values('facility_name')[0]}}' AND 
      							        pr.name='{{filter_values('program_name')[0]}}' AND
      									    p.name='{{filter_values('period_name')[0]}}' AND
      									    (r.status='APPROVED' OR r.status='AUTHORIZED') AND
      									    (rs.name='Pertes' OR rs.name='Expiré')
      							 GROUP BY pr.name, p.name, f.name
),
qtt_intrats_recu AS(
SELECT SUM(i.totalreceivedquantity) as qtt_intrats_recus,
                                       pr.name as program_name,
                                       p.name as period_name,
                                       f.name as facility_name
                     FROM requisition.requisition_line_items i JOIN requisition.requisitions r ON i.requisitionid=r.id  --qt tt intrats recus 
                                        JOIN referencedata.facilities f ON r.facilityid=f.id
												                JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
												                JOIN referencedata.programs pr ON r.programid=pr.id
                     WHERE  f.name='{{filter_values('facility_name')[0]}}' AND 
							              pr.name='{{filter_values('program_name')[0]}}' AND
        									  p.name='{{filter_values('period_name')[0]}}' AND
        									  (r.status='APPROVED' OR r.status='AUTHORIZED')
									   GROUP BY pr.name, p.name, f.name
)
SELECT p.program_name as program_name,
       p.period_name as period_name,
       p.facility_name AS facility_name, 
       (p.qt_intrats_perdus::NUMERIC / r.qtt_intrats_recus) * 100 AS taux_perte_intrats
      FROM qt_intrats_perdu p 
      JOIN qtt_intrats_recu r ON p.program_name=r.program_name;
      
		
		
		
		
		