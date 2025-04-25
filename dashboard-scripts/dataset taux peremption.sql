--Filter columns frequence_name
-- frequence_name is the "SELECT *
--						   FROM (
--						       VALUES 
--						           (1, 'Hebdomadaire'),
--						           (2, 'Mensuelle'),
--						           (3, 'Trimestrielle'),
--						           (4, 'Annuelle')
--						   ) AS t(id, frequence_name);"


{% set frequence_name = filter_values('frequence_name') | default(['month']) %}

WITH qt_produit_perime AS(
SELECT 	SUM(h.stockonhand) as qt_produit_perimes,
        '{{ frequence_name[0] }}' AS frequence_name
  			FROM stockmanagement.stock_cards s
  			JOIN stockmanagement.calculated_stocks_on_hand h
  			    ON h.stockcardid = s.id
  			JOIN (
  			    SELECT s.lotid, MAX(h.processeddate) AS max_processeddate
  			    FROM stockmanagement.stock_cards s
  			    JOIN stockmanagement.calculated_stocks_on_hand h
  			        ON h.stockcardid = s.id
  			    GROUP BY s.lotid
  			) AS max_dates
  			    ON s.lotid = max_dates.lotid AND h.processeddate = max_dates.max_processeddate
  				JOIN referencedata.lots l ON s.lotid=l.id 
  				WHERE (('{{filter_values('frequence_name')[0]}}' = 'Hebdomadaire' AND 
                  DATE_TRUNC('day', l.expirationdate) = DATE_TRUNC('day', CURRENT_DATE)) OR
                ('{{filter_values('frequence_name')[0]}}' = 'Mensuelle' AND 
                 DATE_TRUNC('month', l.expirationdate) = DATE_TRUNC('month', CURRENT_DATE)) OR
                ('{{filter_values('frequence_name')[0]}}' = 'Trimestrielle' AND 
                 DATE_TRUNC('quarter', l.expirationdate) = DATE_TRUNC('quarter', CURRENT_DATE)) OR
                 ('{{filter_values('frequence_name')[0]}}' = 'Annuelle' AND 
                 DATE_TRUNC('year', l.expirationdate) = DATE_TRUNC('year', CURRENT_DATE))) 
),
qt_produit_en_stock AS(
SELECT SUM(h.stockonhand) as qunatite_tt_produit_enStock,
        '{{ frequence_name[0] }}' AS frequence_name
				FROM stockmanagement.stock_cards s
				JOIN stockmanagement.calculated_stocks_on_hand h
					ON h.stockcardid = s.id
				JOIN (
					SELECT s.lotid, MAX(h.processeddate) AS max_processeddate
					FROM stockmanagement.stock_cards s
					JOIN stockmanagement.calculated_stocks_on_hand h
						ON h.stockcardid = s.id
					GROUP BY s.lotid
				) AS max_dates
					ON s.lotid = max_dates.lotid AND h.processeddate = max_dates.max_processeddate
)
SELECT p.frequence_name as frequence_name, 
       (p.qt_produit_perimes::NUMERIC / r.qunatite_tt_produit_enStock) * 100 AS taux_peremption
      FROM qt_produit_perime p 
      JOIN qt_produit_en_stock r ON p.frequence_name=r.frequence_name;

		
		
		
		
		