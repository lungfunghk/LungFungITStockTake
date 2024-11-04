-- 資產位置追蹤視圖
CREATE VIEW vw_Current_Asset_Location AS
WITH LatestLocation AS (
    SELECT 
        Inventory_Number,
        To_Location,
        ROW_NUMBER() OVER (PARTITION BY Inventory_Number 
                          ORDER BY Created_datetime DESC) as rn
    FROM Inventory_Logistics
)
SELECT 
    i.*,
    l.To_Location as Current_Location
FROM Inventory i
LEFT JOIN LatestLocation l ON i.Inventory_Number = l.Inventory_Number
WHERE l.rn = 1;