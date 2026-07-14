SELECT * 
FROM dw_gold.fact_sales f
LEFT JOIN dw_gold.dim_products p ON p.product_key = f.product_key
WHERE f.product_key IS NULL;
