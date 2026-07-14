
DROP PROCEDURE IF EXISTS dw_silver.load_silver;

DELIMITER $$

CREATE PROCEDURE dw_silver.load_silver()
BEGIN
    DECLARE start_time_total TIMESTAMP(6);
    DECLARE end_time_total TIMESTAMP(6);
    DECLARE start_time_step TIMESTAMP(6);
    DECLARE end_time_step TIMESTAMP(6);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SELECT '❌ ERROR: An error occurred during the Silver Layer load process. Transaction rolled back!' AS error_message;
    END;

    START TRANSACTION;
    
    SET start_time_total = NOW(6);
    SELECT '===========================================' AS '---';
    SELECT ' Starting Silver Layer Load Process...' AS 'Status';
    SELECT '===========================================' AS '---';

    -- -------------------------------------------------------------------------
    -- الخطوة 1: جدول crm_cust_info
    -- -------------------------------------------------------------------------
    SET start_time_step = NOW(6);
    SELECT '>> Truncating and Inserting: silver.crm_cust_info...' AS 'Step';
    
    TRUNCATE TABLE dw_silver.crm_cust_info;
    
    INSERT INTO dw_silver.crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date
    )
    SELECT 
        cst_id, cst_key,
        TRIM(cst_firstname), TRIM(cst_lastname),
        CASE 
            WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE 
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM dw_bronze.crm_cust_info;
    
    SET end_time_step = NOW(6);
    SELECT CONCAT('  Finished crm_cust_info in ', 
                  ROUND(TIMESTAMPDIFF(MICROSECOND, start_time_step, end_time_step) / 1000000, 3), 
                  ' seconds.') AS 'Step Duration';

    -- -------------------------------------------------------------------------
    -- الخطوة 2: جدول crm_prd_info
    -- -------------------------------------------------------------------------
    SET start_time_step = NOW(6);
    SELECT '>> Truncating and Inserting: silver.crm_prd_info...' AS 'Step';
    
    TRUNCATE TABLE dw_silver.crm_prd_info;
    
    INSERT INTO dw_silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT 
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7, LENGTH(prd_key)),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE 
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        CAST(prd_start_dt AS DATE),
        CAST(DATE_SUB(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt), INTERVAL 1 DAY) AS DATE)
    FROM dw_bronze.crm_prd_info;
    
    SET end_time_step = NOW(6);
    SELECT CONCAT('Finished crm_prd_info in ', 
                  ROUND(TIMESTAMPDIFF(MICROSECOND, start_time_step, end_time_step) / 1000000, 3), 
                  ' seconds.') AS 'Step Duration';

    SET start_time_step = NOW(6);
    SELECT '>> Truncating and Inserting: silver.crm_sales_details...' AS 'Step';
    
    TRUNCATE TABLE dw_silver.crm_sales_details;
    
    INSERT INTO dw_silver.crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_qty, sls_price
    )
    SELECT 
        sls_ord_num, sls_prd_key, sls_cust_id,
        CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 THEN NULL ELSE STR_TO_DATE(sls_order_dt, '%Y%m%d') END,
        CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 THEN NULL ELSE STR_TO_DATE(sls_ship_dt, '%Y%m%d') END,
        CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 THEN NULL ELSE STR_TO_DATE(sls_due_dt, '%Y%m%d') END,
        CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price) ELSE sls_sales END,
        sls_quantity,
        CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0) ELSE sls_price END
    FROM dw_bronze.crm_sales_details;
    
    SET end_time_step = NOW(6);
    SELECT CONCAT('  Finished crm_sales_details in ', 
                  ROUND(TIMESTAMPDIFF(MICROSECOND, start_time_step, end_time_step) / 1000000, 3), 
                  ' seconds.') AS 'Step Duration';

   
    SET start_time_step = NOW(6);
    SELECT '>> Truncating and Inserting: silver.erp_cust_az12...' AS 'Step';
    
    TRUNCATE TABLE dw_silver.erp_cust_az12;
    
    INSERT INTO dw_silver.erp_cust_az12 (cid, bdate, gen)
    SELECT 
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) ELSE cid END,
        CASE WHEN bdate > CURRENT_DATE() OR bdate < '1924-01-01' THEN NULL ELSE bdate END,
        CASE 
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'n/a'
        END
    FROM dw_bronze.erp_cust_az12;
    
    SET end_time_step = NOW(6);
    SELECT CONCAT(' Finished erp_cust_az12 in ', 
                  ROUND(TIMESTAMPDIFF(MICROSECOND, start_time_step, end_time_step) / 1000000, 3), 
                  ' seconds.') AS 'Step Duration';

    
    SET start_time_step = NOW(6);
    SELECT '>> Truncating and Inserting: silver.erp_loc_a101...' AS 'Step';
    
    TRUNCATE TABLE dw_silver.erp_loc_a101;
    
    INSERT INTO dw_silver.erp_loc_a101 (cid, cntry)
    SELECT 
        REPLACE(cid, '-', ''),
        CASE 
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM dw_bronze.erp_loc_a101;
    
    SET end_time_step = NOW(6);
    SELECT CONCAT('  Finished erp_loc_a101 in ', 
                  ROUND(TIMESTAMPDIFF(MICROSECOND, start_time_step, end_time_step) / 1000000, 3), 
                  ' seconds.') AS 'Step Duration';

    
    SET start_time_step = NOW(6);
    SELECT '>> Truncating and Inserting: silver.erp_px_cat_g1v2...' AS 'Step';
    
    TRUNCATE TABLE dw_silver.erp_px_cat_g1v2;
    
    INSERT INTO dw_silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT TRIM(id), TRIM(cat), TRIM(subcat), TRIM(maintenance)
    FROM dw_bronze.erp_px_cat_g1v2;
    
    SET end_time_step = NOW(6);
    SELECT CONCAT('    Finished erp_px_cat_g1v2 in ', 
                  ROUND(TIMESTAMPDIFF(MICROSECOND, start_time_step, end_time_step) / 1000000, 3), 
                  ' seconds.') AS 'Step Duration';

    COMMIT;

    -- حساب وإظهار وقت النهاية الإجمالي
    SET end_time_total = NOW(6);
    SELECT '===========================================' AS '---';
    SELECT CONCAT(' SUCCESS: All Silver tables loaded in ', 
                  ROUND(TIMESTAMPDIFF(MICROSECOND, start_time_total, end_time_total) / 1000000, 3), 
                  ' seconds!') AS 'Final Status';
    SELECT '===========================================' AS '---';
    
END$$

DELIMITER ;
CALL dw_silver.load_silver();
