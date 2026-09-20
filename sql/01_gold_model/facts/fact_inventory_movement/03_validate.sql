USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Gold row count' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_inventory_movement;

SELECT 'Silver row count' AS validation_check, COUNT_BIG(*) AS result
FROM silver.inventory_movements;

SELECT 'Duplicate inventory_move_id' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT inventory_move_id
    FROM gold.fact_inventory_movement
    GROUP BY inventory_move_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Zero signed quantity' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_inventory_movement
WHERE quantity_signed = 0;

/* Negative quantity_signed is valid for outbound/consumption movements. */
GO
