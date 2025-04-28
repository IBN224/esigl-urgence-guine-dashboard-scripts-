
--***** first case without avg *****------------
WITH summed_quantities AS (
-- First query for quantity sum with reasons 'Expiré' or 'Pertes'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        o.fullproductname as product_name,
        'year' AS frequence_name,
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
    JOIN 
        referencedata.orderables o ON o.id = i.orderableid
    WHERE 
        pr.name = 'VACCINS' AND
        f.name IN ('KINDIA', 'BOKE') AND 
        o.fullproductname in ('JOHNSON & JOHNSON', 'MODERNA', 'SINOVAC') AND 
           (r.name = 'Expiré' OR r.name = 'Pertes') AND
           DATE_TRUNC(
                'year', 
                CASE 
                    WHEN 2023 = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('2023' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('year', p.occurreddate)
    GROUP BY 
        pr.name, f.name, o.fullproductname
),
received_quantities AS (
    -- Second query for quantity sum with reason 'Réception'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        o.fullproductname as product_name,
        'year' AS frequence_name,
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
    JOIN 
        referencedata.orderables o ON o.id = s.orderableid
    WHERE 
        pr.name = 'VACCINS' AND
        f.name IN ('KINDIA', 'BOKE') AND
        o.fullproductname in ('JOHNSON & JOHNSON', 'MODERNA', 'SINOVAC') AND
        r.name = 'Réception'
        AND DATE_TRUNC(
                'year', 
                CASE 
                    WHEN 2023 = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('2023' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('year', i.occurreddate)
    GROUP BY 
        pr.name, f.name, o.fullproductname
)
-- Final query to join the results and perform the division

SELECT 
    sq.program_name,
    sq.facility_name as facility_name,
    sq.frequence_name as frequence_name,
    sq.product_name AS product_name,
    'year' as year_name,
    ROUND(((sq.quantity_expired::NUMERIC / rq.quantity_received::NUMERIC) * 100), 2) AS taux_perte_intrats,
    sq.quantity_expired || ' / ' || rq.quantity_received as sur
FROM 
    summed_quantities sq
JOIN 
    received_quantities rq 
    ON sq.facility_name = rq.facility_name AND sq.product_name = rq.product_name
    
--**** end ***-----------


--- ** second case with avg ******---------
WITH summed_quantities AS (
    -- First query for quantity sum with reasons 'Expiré' or 'Pertes'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        o.fullproductname as product_name,
        'year' AS frequence_name,
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
    JOIN 
        referencedata.orderables o ON o.id = i.orderableid
    WHERE 
        pr.name = 'VACCINS'
        AND (r.name = 'Expiré' OR r.name = 'Pertes')
        AND DATE_TRUNC(
                'year', 
                CASE 
                    WHEN 2023 = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('2023' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('year', p.occurreddate)
    GROUP BY 
        pr.name, f.name, o.fullproductname
),
received_quantities AS (
    -- Second query for quantity sum with reason 'Réception'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        o.fullproductname as product_name,
        'year' AS frequence_name,
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
    JOIN 
        referencedata.orderables o ON o.id = s.orderableid
    WHERE 
        pr.name = 'VACCINS'
        AND r.name = 'Réception'
        AND DATE_TRUNC(
                'year', 
                CASE 
                    WHEN 2023 = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('2023' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('year', i.occurreddate)
    GROUP BY 
        pr.name, f.name, o.fullproductname
),
calculated_taux AS (
    SELECT 
        sq.program_name,
        sq.facility_name,
        sq.frequence_name,
        sq.product_name,
        'year' AS year_name,
        ROUND(((sq.quantity_expired::NUMERIC / rq.quantity_received::NUMERIC) * 100), 2) AS taux_perte_intrats,
        sq.quantity_expired AS total_expired,
        rq.quantity_received AS total_received
    FROM 
        summed_quantities sq
    JOIN 
        received_quantities rq 
        ON sq.facility_name = rq.facility_name AND sq.product_name = rq.product_name
)
-- Final single-line result with aggregated values
SELECT 
    'VACCINS' AS program_name,                     
    'NAN' AS facility_name,                       
    'year' AS frequence_name,                      
    'NAN' AS product_name,                        
    '2023' AS year_name,                          
    ROUND((AVG(taux_perte_intrats)), 2) AS taux_perte_intrats, 
    SUM(total_expired) || ' / ' || SUM(total_received) AS sur 
FROM 
    calculated_taux
    
    



