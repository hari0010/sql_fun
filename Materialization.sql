-- Materialization with Global Temporary tables:
CREATE GLOBAL TEMPORARY TABLE my_temp_table (
  id           NUMBER,
  description  VARCHAR2(20)
)
ON COMMIT DELETE ROWS;

-- Materialization with WITH clause
WITH
sum_sales AS 
  ( select /*+ materialize */ 
    sum(quantity) all_sales from stores ),
number_stores AS 
  ( select /*+ materialize */ 
    count(*) nbr_stores from stores ),
sales_by_store AS
  ( select /*+ materialize */ 
  store_name, sum(quantity) store_sales from 
  store natural join sales )
SELECT
   store_name
FROM
   store,
   sum_sales,
   number_stores,
   sales_by_store
where
   store_sales > (all_sales / nbr_stores);