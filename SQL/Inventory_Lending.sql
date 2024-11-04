CREATE TABLE Inventory_Lending (
    Lending_ID INT IDENTITY(1,1) PRIMARY KEY,
    Inventory_Number VARCHAR(20),
    Borrower_ID VARCHAR(50),
    Borrow_Date DATE,
    Expected_Return_Date DATE,
    Actual_Return_Date DATE,
    Status VARCHAR(20)
);