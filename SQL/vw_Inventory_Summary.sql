-- 資產總覽視圖
CREATE VIEW vw_Inventory_Summary AS
SELECT 
    Catalog,
    Status,
    COUNT(*) as Total_Count,
    SUM(Unit_Price) as Total_Value
FROM Inventory
GROUP BY Catalog, Status;
