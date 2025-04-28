
/*** Filters to use programs, frequence, year, facility et product ***/
    


 {% set frequ_valu = (
    'day' if filter_values('frequence_name')[0] == 'Hebdomadaire' else
    'month' if filter_values('frequence_name')[0] == 'Mensuelle' else
    'quarter' if filter_values('frequence_name')[0] == 'Trimestrielle' else
    'year' if filter_values('frequence_name')[0] == 'Annuelle' else None
) %}

{% set facility_name_list = filter_values('facility_name') | default([]) %}
{% set product_name_list = filter_values('product_name') | default([]) %}

{% macro avg_value() %} --****** case with avg
,
calculated_taux AS (
    SELECT 
        sq.program_name,
        sq.facility_name,
        sq.frequence_name,
        sq.product_name,
        '{{filter_values('year_name')[0]}}' AS year_name,
        (sq.quantity_expired::NUMERIC / rq.quantity_received::NUMERIC) AS taux_perte_intrats,
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
    '{{filter_values('program_name')[0]}}' AS program_name,                     
    'NAN' AS facility_name,                       
    '{{filter_values('frequence_name')[0]}}' AS frequence_name,                      
    'NAN' AS product_name,                        
    '{{filter_values('year_name')[0]}}' AS year_name,                          
    ROUND((AVG(taux_perte_intrats)), 2) AS taux_perte_intrats, 
    ROUND((SUM(taux_perte_intrats)), 2) || ' / ' || COUNT(program_name) AS sur 
FROM 
    calculated_taux
{% endmacro %}
 
 

{% macro not_avg_value() %} --****** case without avg
SELECT 
    sq.program_name,
    sq.facility_name as facility_name,
    sq.frequence_name as frequence_name,
    sq.product_name AS product_name,
    '{{filter_values('year_name')[0]}}' as year_name,
    ROUND(((sq.quantity_expired::NUMERIC / rq.quantity_received::NUMERIC) * 100), 2) AS taux_perte_intrats,
    sq.quantity_expired || ' / ' || rq.quantity_received as sur
FROM 
    summed_quantities sq
JOIN 
    received_quantities rq 
    ON sq.facility_name = rq.facility_name AND sq.product_name = rq.product_name
{% endmacro %}
 
 





WITH summed_quantities AS (
    -- First query for quantity sum with reasons 'Expiré' or 'Pertes'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        o.fullproductname as product_name,
        '{{filter_values('frequence_name')[0]}}' AS frequence_name,
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
        pr.name = '{{filter_values('program_name')[0]}}'
        AND 
        ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
           f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
           if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
        AND 
        ('{{ filter_values('product_name', []) | length }}' = 0 OR 
           o.fullproductname IN ( {{ "'" + "','".join(filter_values('product_name', ['default_product1', 'default_product2'])) + "'" 
           if filter_values('product_name', []) else "'default_product1','default_product2'" }}))
        AND (r.name = 'Expiré' OR r.name = 'Pertes')
        AND DATE_TRUNC(
                '{{ frequ_valu }}', 
                CASE 
                    WHEN {{filter_values('year_name')[0]}} = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('{{filter_values('year_name')[0]}}' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('{{ frequ_valu }}', p.occurreddate)
    GROUP BY 
        pr.name, f.name, o.fullproductname
),
received_quantities AS (
    -- Second query for quantity sum with reason 'Réception'
    SELECT 
        pr.name AS program_name,
        f.name AS facility_name,
        o.fullproductname as product_name,
        '{{filter_values('frequence_name')[0]}}' AS frequence_name,
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
        pr.name = '{{filter_values('program_name')[0]}}'
        AND 
        ('{{ filter_values('facility_name', []) | length }}' = 0 OR 
           f.name IN ( {{ "'" + "','".join(filter_values('facility_name', ['default_facility1', 'default_facility2'])) + "'" 
           if filter_values('facility_name', []) else "'default_facility1','default_facility2'" }}))
        AND 
        ('{{ filter_values('product_name', []) | length }}' = 0 OR 
           o.fullproductname IN ( {{ "'" + "','".join(filter_values('product_name', ['default_product1', 'default_product2'])) + "'" 
           if filter_values('product_name', []) else "'default_product1','default_product2'" }}))
        AND r.name = 'Réception'
        AND DATE_TRUNC(
                '{{ frequ_valu }}', 
                CASE 
                    WHEN {{filter_values('year_name')[0]}} = EXTRACT(YEAR FROM CURRENT_DATE) 
                        THEN CURRENT_DATE 
                    ELSE TO_DATE('{{filter_values('year_name')[0]}}' || '-01-01', 'YYYY-MM-DD') 
                END
            ) = DATE_TRUNC('{{ frequ_valu }}', i.occurreddate)
    GROUP BY 
        pr.name, f.name, o.fullproductname
)
{% if facility_name_list | length != 0 or product_name_list | length != 0 %}
 {{not_avg_value()}}
{% else %}

{{avg_value()}}

{% endif %}









