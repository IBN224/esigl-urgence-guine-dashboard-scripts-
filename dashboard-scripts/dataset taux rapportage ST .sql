--Filter columns program_name, period_name and facility_name 
-- 1 program_name is the "SELECT p.name as program_name FROM referencedata.programs p";

-- 2 period_name is the "SELECT p.name as period_name from referencedata.processing_periods p"

-- 3 facility_name is the "SELECT f.name as facility_name FROM referencedata.facilities f"

WITH nbre_rapport_soumi AS(
SELECT COUNT(f1.id) as nbre_rapport_soumis,														
						p.name as period_name,
						pr.name as program_name,
						f.name as facility_name
	FROM  requisition.requisitions r 
					JOIN referencedata.programs pr ON r.programid=pr.id
					JOIN referencedata.processing_periods p ON r.processingperiodid=p.id
					JOIN referencedata.supervisory_nodes s ON r.supervisorynodeid=s.id
					JOIN referencedata.facilities f ON s.facilityid=f.id
					JOIN referencedata.requisition_groups rq ON rq.supervisorynodeid=s.id
		            JOIN referencedata.requisition_group_members rm ON rm.requisitiongroupid=rq.id
					JOIN referencedata.facilities f1 ON f1.id=rm.facilityid 
					JOIN referencedata.facility_types t ON f1.typeid=t.id
   WHERE p.name='{{filter_values('period_name')[0]}}' AND 
   		 pr.name='{{filter_values('program_name')[0]}}' AND
         f.name='{{filter_values('facility_name')[0]}}' AND
		 t.code!='warehouse' AND
		 r.facilityid=f1.id  AND
		 (r.status='APPROVED' OR r.status='AUTHORIZED')
   GROUP BY p.name, pr.name, f.name, f.name
),
nbre_tt_rapport_attendu AS(
SELECT COUNT(rq.id) as nbre_rapport_attendus,																			
						f.name as facility_name
	 FROM referencedata.supervisory_nodes s 																				
	             JOIN referencedata.facilities f ON s.facilityid=f.id
	             JOIN referencedata.requisition_groups rq ON rq.supervisorynodeid=s.id
	             JOIN referencedata.requisition_group_members rm ON rm.requisitiongroupid=rq.id
				 JOIN referencedata.facilities f1 ON f1.id=rm.facilityid
				 JOIN referencedata.facility_types t ON f1.typeid=t.id
	WHERE f.name='{{filter_values('facility_name')[0]}}' AND
		    (t.code='CENTRE DE SANTE' OR t.code='HOPITAL PREFECTORAL/CMC')
	GROUP BY f.name
)
SELECT p.period_name as period_name,
       p.facility_name as facility_name,
       p.program_name as program_name,
       ROUND(((p.nbre_rapport_soumis::NUMERIC / r.nbre_rapport_attendus) * 100), 2) AS taux_rapportage,
       p.nbre_rapport_soumis || '/' || r.nbre_rapport_attendus as sur
      FROM nbre_rapport_soumi p 
      JOIN nbre_tt_rapport_attendu r ON p.facility_name=r.facility_name;


