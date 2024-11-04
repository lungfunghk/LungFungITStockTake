CREATE TABLE Inventory (
    -- 主要識別欄位
    Inventory_Number VARCHAR(20) NOT NULL PRIMARY KEY,
    Catalog VARCHAR(20) NOT NULL,
    Serial_Number VARCHAR(50) NOT NULL,
    
    -- 設備資訊
    Brand VARCHAR(100),
    Model VARCHAR(100),
    Date DATE NOT NULL,
    Hostname VARCHAR(100),
    IP_Address VARCHAR(15),
    Old_serial VARCHAR(50),
    Remark NVARCHAR(MAX),
    
    -- 財務資訊
    Payment_Number VARCHAR(20) NOT NULL,
    Unit_Price DECIMAL(15, 2),
    
    -- 狀態資訊
    Status VARCHAR(20) NOT NULL,
    
    -- 稽核欄位
    Created_datetime DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_datetime DATETIME2 NOT NULL DEFAULT GETDATE(),
    Created_user_id VARCHAR(50) NOT NULL,
    Updated_user_id VARCHAR(50) NOT NULL,
    
    -- 約束條件
    CONSTRAINT CHK_IP_Address CHECK (
        IP_Address IS NULL OR 
        IP_Address LIKE '[0-9]%.[0-9]%.[0-9]%.[0-9]%'
    )
);

-- 建立索引
CREATE INDEX IX_Inventory_Status ON Inventory(Status);
CREATE INDEX IX_Inventory_Catalog ON Inventory(Catalog);
CREATE INDEX IX_Inventory_Date ON Inventory(Date);
CREATE INDEX IX_Inventory_Serial_Number ON Inventory(Serial_Number);

-- 建立觸發器以自動更新 Updated_datetime
CREATE TRIGGER trg_Inventory_UpdateTimestamp
ON Inventory
AFTER UPDATE
AS
BEGIN
    UPDATE Inventory
    SET Updated_datetime = GETDATE()
    FROM Inventory i
    INNER JOIN inserted ins ON i.Inventory_Number = ins.Inventory_Number;
END;

-- 這個 SQL 結構包含以下特點：
-- 資料類型選擇：
-- 使用 VARCHAR 而不是 CHAR 以節省空間
-- 使用 DECIMAL(15,2) 處理金額
-- 使用 DATETIME2 提供更精確的時間戳記
-- 使用 NVARCHAR(MAX) 處理可能包含中文的備註欄位

-- IP 地址格式檢查

-- 索引設計：
-- 為常用查詢欄位建立索引
-- 包含 Status、Catalog、Date 和 Serial_Number
-- 自動更新機制：
-- Created_datetime 和 Updated_datetime 預設值
-- 觸發器自動更新 Updated_datetime

-- 使用建議：
-- 1. 插入新記錄：

INSERT INTO Inventory (
    Inventory_Number, Catalog, Serial_Number, Date,
    Payment_Number, Status, Created_user_id, Updated_user_id
) VALUES (
    'IT-123-00001', 'IT-EQ', 'SN12345', '2024-03-20',
    'PAY-12345', '使用中', 'USER001', 'USER001'
);

-- 2. 更新記錄：
UPDATE Inventory
SET Status = '維修中',
    Updated_user_id = 'USER002'
WHERE Inventory_Number = 'IT-123-00001';

-- 3. 查詢範例：
-- 查詢特定分類的設備
SELECT * FROM Inventory 
WHERE Catalog = 'IT-EQ' 
AND Status = '使用中';

-- 查詢特定日期範圍的採購
SELECT * FROM Inventory 
WHERE Date BETWEEN '2024-01-01' AND '2024-03-31';