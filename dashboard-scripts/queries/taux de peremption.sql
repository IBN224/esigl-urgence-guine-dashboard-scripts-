

 WITH qt_produit_perime AS(
 WITH max_dates AS (
    SELECT s.lotid,
           h.id AS stock_id,
           h.processeddate,
           p.name as program_name,
		       o.fullproductname as product_name,
		       f.name as facility_name,
           ROW_NUMBER() OVER (PARTITION BY s.lotid, s.orderableid, f.name ORDER BY h.processeddate, h.occurreddate DESC) AS row_num
    FROM stockmanagement.stock_cards s
         JOIN referencedata.lots l ON l.id=s.lotid
         JOIN referencedata.orderables o ON o.id = s.orderableid
         JOIN stockmanagement.calculated_stocks_on_hand h ON h.stockcardid = s.id
         JOIN referencedata.facilities f ON s.facilityid = f.id
         JOIN referencedata.programs p ON s.programid=p.id
    WHERE 
          p.name='VACCINS' AND
           --f.name IN () AND 
          -- o.fullproductname IN () AND
          -- {% if current_year() != filter_values('year_name')[0] | int %}
          --   DATE_TRUNC('year', l.expirationdate) = DATE_TRUNC('year', TO_DATE('{{filter_values('year_name')[0]}}'||'-01-01', 'YYYY-MM-DD')) 
          -- {% endif %}
          -- {% if current_year() == filter_values('year_name')[0] | int %}
          --   DATE_TRUNC('{{ frequ_valu }}', l.expirationdate) = DATE_TRUNC('{{ frequ_valu }}', CURRENT_DATE)
          -- {% endif %}
           DATE_TRUNC('year', l.expirationdate) = DATE_TRUNC('year', TO_DATE('2024-10-31', 'YYYY-MM-DD'))
          
)
SELECT SUM(h.stockonhand) as qt_produit_perimes,
       program_name as program_name,
       facility_name as facility_name,
       product_name as product_name,
       'Feb, 2022' AS frequence_name
from (
		SELECT lotid,
		       stock_id,
		       program_name,
			     product_name,
			     facility_name,
		       processeddate AS max_processeddate
		FROM max_dates
		WHERE row_num = 1) as result_1
		JOIN stockmanagement.calculated_stocks_on_hand h ON h.id = result_1.stock_id
 GROUP BY program_name, facility_name, product_name
-- {% if (filter_values('product_name')[0] | default('') == '' and
--       filter_values('facility_name')[0] | default('') != '') or 
--       (filter_values('product_name')[0] | default('') != '' and
--       filter_values('facility_name')[0] | default('') == '') or
--       (filter_values('product_name')[0] | default('') != '' and
--       filter_values('facility_name')[0] | default('') != '')%}
--       ,facility_name, product_name
-- {% endif %}
),
qt_produit_en_stock AS(
WITH max_dates AS (
    SELECT s.lotid,
           h.id AS stock_id,
           h.processeddate,
		       o.fullproductname,
           ROW_NUMBER() OVER (PARTITION BY s.lotid, s.orderableid, f.name ORDER BY h.processeddate, h.occurreddate DESC) AS row_num
    FROM stockmanagement.stock_cards s
         JOIN referencedata.lots l ON l.id=s.lotid
         JOIN referencedata.orderables o ON o.id = s.orderableid
         JOIN stockmanagement.calculated_stocks_on_hand h ON h.stockcardid = s.id
         JOIN referencedata.facilities f ON s.facilityid = f.id
         JOIN referencedata.programs p ON s.programid=p.id
    WHERE p.name='VACCINS'
)
SELECT SUM(h.stockonhand) as qunatite_tt_produit_enStock,
       'Feb, 2022' AS frequence_name
from (
		SELECT lotid,
		       stock_id,
			     fullproductname,
		       processeddate AS max_processeddate
		FROM max_dates
		WHERE row_num = 1) as result_1
		JOIN stockmanagement.calculated_stocks_on_hand h ON h.id = result_1.stock_id
)
SELECT p.program_name as program_name,
       p.facility_name AS facility_name,
       p.product_name as product_name,
       p.frequence_name as frequence_name,
      --   {% if filter_values('product_name')[0] | default('') != '' or 
      --   filter_values('facility_name')[0] | default('') != '' %}
      --   ROUND(((p.qt_produit_perimes::NUMERIC / r.qunatite_tt_produit_enStock) * 100), 2) AS taux_peremption,
      -- {% endif %}
      -- {% if filter_values('product_name')[0] | default('') == '' and 
      --     filter_values('facility_name')[0] | default('') == '' %}
      --     ROUND((p.qt_produit_perimes::NUMERIC / r.qunatite_tt_produit_enStock), 2) AS taux_peremption,
      -- {% endif %}
       ROUND(((p.qt_produit_perimes::NUMERIC / r.qunatite_tt_produit_enStock) * 100), 2) AS taux_peremption,
       p.qt_produit_perimes || ' / ' || r.qunatite_tt_produit_enStock AS sur
      FROM qt_produit_perime p 
      JOIN qt_produit_en_stock r ON p.frequence_name=r.frequence_name


