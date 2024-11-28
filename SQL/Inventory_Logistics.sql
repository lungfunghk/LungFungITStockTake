-- 建立位置主表
CREATE TABLE Location_Master (
    Location_Code VARCHAR(20) PRIMARY KEY,
    Location_Name NVARCHAR(100) NOT NULL,
    Location_Type VARCHAR(20) NOT NULL, -- 倉庫/店舖/辦公室等
    Is_Active BIT DEFAULT 1,
    Created_datetime DATETIME2 DEFAULT GETDATE(),
    Created_user_id VARCHAR(50) NOT NULL,
    CONSTRAINT CHK_Location_Type CHECK (Location_Type IN ('WAREHOUSE', 'SHOP', 'OFFICE'))
);

-- 建立 Inventory Logistics 表（與 Inventory 表關聯）
CREATE TABLE Inventory_Logistics (
    Logistics_ID INT IDENTITY(1,1),
    -- 關聯到 Inventory 表的外鍵
    Inventory_Number VARCHAR(20) NOT NULL,
    From_Location VARCHAR(20) NOT NULL,
    To_Location VARCHAR(20) NOT NULL,
    Staff_ID VARCHAR(20) NOT NULL,
    Remark NVARCHAR(500),
    Is_Initialized BIT NOT NULL DEFAULT 0,
    Status VARCHAR(20) NOT NULL,
    Created_datetime DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_datetime DATETIME2 NOT NULL DEFAULT GETDATE(),
    Created_user_id VARCHAR(50) NOT NULL,
    Updated_user_id VARCHAR(50) NOT NULL,
    -- 主鍵約束
    CONSTRAINT PK_Inventory_Logistics PRIMARY KEY (Logistics_ID),
    -- 外鍵約束
    CONSTRAINT FK_Logistics_Inventory 
        FOREIGN KEY (Inventory_Number) 
        REFERENCES Inventory(Inventory_Number)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT FK_Logistics_From_Location 
        FOREIGN KEY (From_Location) 
        REFERENCES Location_Master(Location_Code),
    CONSTRAINT FK_Logistics_To_Location 
        FOREIGN KEY (To_Location) 
        REFERENCES Location_Master(Location_Code),
    -- 檢查約束    
    CONSTRAINT CHK_Different_Locations 
        CHECK (From_Location != To_Location)
);

-- 建立索引以優化查詢效能
CREATE INDEX IX_Inventory_Logistics_Number 
    ON Inventory_Logistics(Inventory_Number);
CREATE INDEX IX_Inventory_Logistics_Dates 
    ON Inventory_Logistics(Created_datetime);
CREATE INDEX IX_Inventory_Logistics_Status 
    ON Inventory_Logistics(Status);

-- 範例查詢：追蹤特定資產的完整移動歷史
SELECT
    i.Inventory_Number,
    i.Brand,
    i.Model,
    il.From_Location,
    il.To_Location,
    il.Created_datetime as Movement_Date,
    il.Status,
    il.Staff_ID,
    il.Remark,
    i.Status as Asset_Status
FROM Inventory i
JOIN Inventory_Logistics il ON i.Inventory_Number = il.Inventory_Number
WHERE i.Inventory_Number = 'IT-123-00001'
ORDER BY il.Created_datetime DESC;

-- 範例查詢：查看特定位置當前的所有資產
sql
WITH LatestMovement AS (
SELECT
Inventory_Number,
To_Location,
Created_datetime,
ROW_NUMBER() OVER (
PARTITION BY Inventory_Number
ORDER BY Created_datetime DESC
) as rn
FROM Inventory_Logistics
WHERE Status = '已完成'
)
SELECT
i.Inventory_Number,
i.Brand,
i.Model,
i.Status as Asset_Status,
lm.To_Location as Current_Location
FROM Inventory i
JOIN LatestMovement lm ON i.Inventory_Number = lm.Inventory_Number
WHERE lm.rn = 1
AND lm.To_Location = 'SHOP-001';

-- 新增物流記錄時的交易處理範例
sql
BEGIN TRANSACTION;
DECLARE @CurrentLocation VARCHAR(20);
-- 獲取資產當前位置
SELECT TOP 1 @CurrentLocation = To_Location
FROM Inventory_Logistics
WHERE Inventory_Number = 'IT-123-00001'
AND Status = '已完成'
ORDER BY Created_datetime DESC;
-- 確保來源位置正確
IF @CurrentLocation != 'IT-WH'
BEGIN
ROLLBACK;
THROW 50001, '資產當前位置與來源位置不符', 1;
RETURN;
END


-- 插入新的物流記錄
INSERT INTO Inventory_Logistics (
Inventory_Number,
From_Location,
To_Location,
Staff_ID,
Status,
Remark,
Created_user_id,
Updated_user_id
) VALUES (
'IT-123-00001',
'IT-WH',
'SHOP-001',
'STAFF001',
'待處理',
'設備調動',
'USER001',
'USER001'
);
COMMIT TRANSACTION;