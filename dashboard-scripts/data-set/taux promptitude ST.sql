
/*** Filters to use programs, frequence, period et facility ***/

{% macro check_facility_type() %}
  CASE 
    WHEN EXISTS (
      SELECT f.name 
      FROM referencedata.facilities f 
      JOIN referencedata.facility_types t ON t.id = f.typeid
      WHERE (t.code = 'CENTRE DE SANTE' OR t.code = 'HOPITAL PREFECTORAL/CMC') 
      AND ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
             f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
             if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
    ) 
    THEN f1.name 
    ELSE f.name    
  END
{% endmacro %}

{% macro check_facility_type_where() %}
  CASE 
    WHEN EXISTS (
      SELECT f.name 
      FROM referencedata.facilities f 
      JOIN referencedata.facility_types t ON t.id = f.typeid
      WHERE (t.code = 'CENTRE DE SANTE' OR t.code = 'HOPITAL PREFECTORAL/CMC') 
      AND ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
           f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
           if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
    ) 
    THEN  ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
           f1.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
           if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
    ELSE  ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
           f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
           if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }})) 
  END
{% endmacro %}


WITH nbre_rapport_soumi AS(
SELECT COUNT(f1.id) as nbre_rapport_soumis,														
						p.name as period_name,
						pr.name as program_name,
						{{ check_facility_type() }} as facility_name
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
         {{ check_facility_type_where() }}
         AND
    		 (t.code='CENTRE DE SANTE' OR t.code='HOPITAL PREFECTORAL/CMC') AND   
    		 r.facilityid=f1.id  AND
    		 (r.status='APPROVED' OR r.status='AUTHORIZED') AND
    		 r.createddate <= p.enddate + 10 
   GROUP BY p.name, pr.name
         {{ check_facility_type() }}
),
nbre_tt_rapport_attendu AS(
SELECT COUNT(rq.id) as nbre_rapport_attendus,	
						{{ check_facility_type() }} as facility_name
	 FROM referencedata.supervisory_nodes s 																				
	             JOIN referencedata.facilities f ON s.facilityid=f.id
	             JOIN referencedata.requisition_groups rq ON rq.supervisorynodeid=s.id
	             JOIN referencedata.requisition_group_members rm ON rm.requisitiongroupid=rq.id
				 JOIN referencedata.facilities f1 ON f1.id=rm.facilityid
				 JOIN referencedata.facility_types t ON f1.typeid=t.id
	WHERE {{ check_facility_type_where() }}
       AND (t.code='CENTRE DE SANTE' OR t.code='HOPITAL PREFECTORAL/CMC')  --t.code!='warehouse'
	GROUP BY {{ check_facility_type() }} 
	   
)
SELECT p.period_name as period_name,
       p.facility_name as facility_name,
       p.program_name as program_name,
       ROUND(((p.nbre_rapport_soumis::NUMERIC / r.nbre_rapport_attendus) * 100), 2) AS taux_promptitude_rapport,
       p.nbre_rapport_soumis || '/' || r.nbre_rapport_attendus as sur
      FROM nbre_rapport_soumi p 
      JOIN nbre_tt_rapport_attendu r ON p.facility_name=r.facility_name;

















