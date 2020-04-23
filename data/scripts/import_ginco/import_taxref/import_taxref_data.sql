COPY taxonomie.import_taxref FROM  '/tmp/taxhub/TAXREFv12.txt'
WITH  CSV HEADER 
DELIMITER E'\t'  encoding 'UTF-8';


