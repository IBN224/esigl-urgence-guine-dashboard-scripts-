#Query

SELECT *
FROM (
  VALUES
    ('Hebdomadaire'),
    ('Mensuelle'),
    ('Trimestrielle'),
    ('Annuelle')
) AS periodicities(frequence_name);

#Dataset

SELECT *
FROM (
  VALUES
    ('Hebdomadaire'),
    ('Mensuelle'),
    ('Trimestrielle'),
    ('Annuelle')
) AS periodicities(frequence_name);
