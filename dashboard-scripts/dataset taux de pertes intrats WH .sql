--Filter columns program_name and facility_name 
-- 1 program_name is the "SELECT p.name as program_name FROM referencedata.programs p"

-- 3 facility_name is the "SELECT f.name as facility_name FROM referencedata.facilities f"
    
    

WITH summed_quantities AS (
    -- First query for quantity sum with reasons 'Expiré' or 'Pertes'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        'Expiré ou Pertes' AS reason_name,  
        SUM(a.quantity) AS quantity_expired
    FROM 
        stockmanagement.physical_inventory_line_items i 
    JOIN 
        stockmanagement.physical_inventory_line_item_adjustments a ON a.physicalinventorylineitemid = i.id 
    JOIN 
        stockmanagement.stock_card_line_item_reasons r ON r.id = a.reasonid
    JOIN 
        stockmanagement.physical_inventories p ON p.id = i.physicalinventoryid
    JOIN 
        referencedata.programs pr ON p.programid = pr.id
    JOIN 
        referencedata.facilities f ON p.facilityid = f.id
    WHERE 
        pr.name = '{{filter_values('program_name')[0]}}'
        AND f.name = '{{filter_values('facility_name')[0]}}'
        AND (r.name = 'Expiré' OR r.name = 'Pertes')
    GROUP BY 
        pr.name, f.name
),
received_quantities AS (
    -- Second query for quantity sum with reason 'Réception'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        'Réception' AS reason_name,  
        SUM(i.quantity) AS quantity_received
    FROM 
        stockmanagement.stock_card_line_items i
    JOIN 
        stockmanagement.stock_cards s ON s.id = i.stockcardid    
    JOIN 
        stockmanagement.stock_card_line_item_reasons r ON r.id = i.reasonid
    JOIN 
        referencedata.programs pr ON s.programid = pr.id
    JOIN 
        referencedata.facilities f ON s.facilityid = f.id
    WHERE 
        pr.name = '{{filter_values('program_name')[0]}}'
        AND f.name = '{{filter_values('facility_name')[0]}}'
        AND r.name = 'Réception'
    GROUP BY 
        pr.name, f.name
)
-- Final query to join the results and perform the division
SELECT 
    sq.program_name,
    sq.facility_name,
    sq.reason_name AS reason_expired_or_lost,
    rq.reason_name AS reason_received,
    rq.program_name as program_name_2,
    rq.facility_name as facility_name_2,
    ROUND(((sq.quantity_expired::NUMERIC / rq.quantity_received::NUMERIC) * 100), 2) AS taux_perte_intrats
FROM 
    summed_quantities sq
JOIN 
    received_quantities rq 
    ON sq.program_name = rq.program_name 
    AND sq.facility_name = rq.facility_name;

