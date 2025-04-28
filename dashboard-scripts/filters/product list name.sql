#Query

SELECT DISTINCT p.orderableid, o.fullproductname as product_name FROM referencedata.program_orderables p JOIN referencedata.orderables o ON p.orderableid=o.id 


#Dataset

SELECT DISTINCT p.orderableid, o.fullproductname as product_name FROM referencedata.program_orderables p JOIN referencedata.orderables o ON p.orderableid=o.id 

