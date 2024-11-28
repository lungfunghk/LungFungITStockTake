-- 如果表已存在則刪除
IF OBJECT_ID('dbo.Inventory_Lending', 'U') IS NOT NULL
    DROP TABLE [dbo].[Inventory_Lending];

-- 創建 Inventory_Lending 表
CREATE TABLE [dbo].[Inventory_Lending] (
    [lending_id] INT IDENTITY(1,1) NOT NULL,
    [inventory_number] varchar(20) NOT NULL,  -- 改為與 Inventory 表一致的 varchar
    [borrower_id] varchar(50) NOT NULL,
    [borrow_date] date NOT NULL,
    [expected_return_date] date NOT NULL,
    [actual_return_date] date NULL,
    [status] varchar(20) NOT NULL DEFAULT 'BORROWED',
    [remark] ntext NULL,  -- 使用與 Inventory 表一致的 ntext
    [created_datetime] datetime2 NOT NULL DEFAULT GETDATE(),  -- 使用 datetime2
    [updated_datetime] datetime2 NOT NULL DEFAULT GETDATE(),  -- 使用 datetime2
    [created_user_id] varchar(50) NOT NULL,
    [updated_user_id] varchar(50) NOT NULL,
    
    CONSTRAINT [PK_Inventory_Lending] PRIMARY KEY CLUSTERED ([lending_id] ASC),
    CONSTRAINT [FK_Inventory_Lending_Inventory] 
        FOREIGN KEY ([inventory_number]) 
        REFERENCES [dbo].[Inventory]([Inventory_Number])  -- 注意大小寫要匹配
);

-- 創建索引
CREATE INDEX [IX_Inventory_Lending_borrow_date] ON [dbo].[Inventory_Lending]([borrow_date] DESC);

-- 檢查約束確保 status 只能是允許的值
ALTER TABLE [dbo].[Inventory_Lending] ADD CONSTRAINT 
    [CK_Inventory_Lending_Status] CHECK 
    ([status] IN ('BORROWED', 'RETURNED', 'OVERDUE', 'LOST'));