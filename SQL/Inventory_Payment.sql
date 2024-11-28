-- 建立公司主檔表
CREATE TABLE Company_Master (
    Company_Code VARCHAR(20) PRIMARY KEY,
    Company_Name NVARCHAR(100) NOT NULL,
    Is_Active BIT DEFAULT 1,
    Created_datetime DATETIME2 DEFAULT GETDATE(),
    Created_user_id VARCHAR(50) NOT NULL
);

-- 建立 Inventory Payment 表
CREATE TABLE Inventory_Payment (
    Payment_ID INT IDENTITY(1,1) PRIMARY KEY,
    Company_Code VARCHAR(20) NOT NULL,
    Quotation_Number VARCHAR(50),
    Invoice_Number VARCHAR(50) NOT NULL,
    Amount DECIMAL(15,2) NOT NULL,
    Description NVARCHAR(500),
    Remarks NVARCHAR(500),
    Accountant_Submit_Date DATE NOT NULL,
    Cheque_Issue_Date DATE NOT NULL,
    Deposit_Date DATE NOT NULL,
    Delivery_Date DATE,
    Bank_Slip_Send_Date DATE NOT NULL,
    Payment_Number VARCHAR(20) NOT NULL,
    Created_datetime DATETIME2 NOT NULL DEFAULT GETDATE(),
    Updated_datetime DATETIME2 NOT NULL DEFAULT GETDATE(),
    Created_user_id VARCHAR(50) NOT NULL,
    Updated_user_id VARCHAR(50) NOT NULL, 

    -- 外鍵約束
    CONSTRAINT FK_Payment_Company 
        FOREIGN KEY (Company_Code) 
        REFERENCES Company_Master(Company_Code),

    -- 檢查約束
    CONSTRAINT CHK_Amount 
        CHECK (Amount > 0),
    
    CONSTRAINT CHK_Dates 
        CHECK (
            Accountant_Submit_Date <= Cheque_Issue_Date
            AND Cheque_Issue_Date <= Deposit_Date
            AND (Delivery_Date IS NULL OR Delivery_Date >= Deposit_Date)
            AND Bank_Slip_Send_Date >= Deposit_Date
        ),

    -- 唯一約束
    CONSTRAINT UQ_Invoice_Number 
        UNIQUE (Invoice_Number),
    
    CONSTRAINT UQ_Payment_Number 
        UNIQUE (Payment_Number)
);

-- 建立索引
CREATE INDEX IX_Payment_Dates ON Inventory_Payment(
    Accountant_Submit_Date,
    Cheque_Issue_Date,
    Deposit_Date
);
CREATE INDEX IX_Payment_Company ON Inventory_Payment(Company_Code);
CREATE INDEX IX_Payment_Number ON Inventory_Payment(Payment_Number);

-- 建立更新時間觸發器
CREATE TRIGGER trg_Inventory_Payment_UpdateTimestamp
ON Inventory_Payment
AFTER UPDATE
AS
BEGIN
    UPDATE Inventory_Payment
    SET Updated_datetime = GETDATE()
    FROM Inventory_Payment ip
    INNER JOIN inserted ins ON ip.Payment_ID = ins.Payment_ID;
END;

-- 建立檢視表：付款追蹤
CREATE VIEW vw_Payment_Tracking AS
SELECT 
    ip.Payment_ID,
    cm.Company_Name,
    ip.Invoice_Number,
    ip.Payment_Number,
    ip.Amount,
    ip.Accountant_Submit_Date,
    ip.Cheque_Issue_Date,
    ip.Deposit_Date,
    ip.Delivery_Date,
    ip.Bank_Slip_Send_Date,
    CASE 
        WHEN ip.Bank_Slip_Send_Date IS NOT NULL THEN '已完成'
        WHEN ip.Deposit_Date IS NOT NULL THEN '已入賬'
        WHEN ip.Cheque_Issue_Date IS NOT NULL THEN '支票已開出'
        WHEN ip.Accountant_Submit_Date IS NOT NULL THEN '待處理'
        ELSE '未開始'
    END as Payment_Status
FROM Inventory_Payment ip
JOIN Company_Master cm ON ip.Company_Code = cm.Company_Code;

-- 範例查詢：查詢特定月份的付款記錄
SELECT
cm.Company_Name,
ip.Invoice_Number,
ip.Amount,
ip.Payment_Number,
ip.Accountant_Submit_Date,
ip.Cheque_Issue_Date,
ip.Description
FROM Inventory_Payment ip
JOIN Company_Master cm ON ip.Company_Code = cm.Company_Code
WHERE YEAR(ip.Accountant_Submit_Date) = YEAR(GETDATE())
AND MONTH(ip.Accountant_Submit_Date) = MONTH(GETDATE());

-- 範例查詢：未完成付款追蹤
SELECT
cm.Company_Name,
ip.Invoice_Number,
ip.Amount,
ip.Accountant_Submit_Date,
DATEDIFF(day, ip.Accountant_Submit_Date, GETDATE()) as Days_Outstanding
FROM Inventory_Payment ip
JOIN Company_Master cm ON ip.Company_Code = cm.Company_Code
WHERE ip.Bank_Slip_Send_Date IS NULL
ORDER BY ip.Accountant_Submit_Date;