import pyodbc
from faker import Faker
import random
from datetime import datetime, timedelta
import ipaddress

# 配置數據庫連接
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.15.241;"
    "DATABASE=LungFungITStockTake;"
    "UID=sa;"
    "PWD=Lf86881234;"
)

fake = Faker()

def clear_all_tables(conn):
    """清空所有表的數據"""
    cursor = conn.cursor()
    tables = [
        'Inventory_Lending',
        'Inventory_Logistics',
        'Inventory',
        'Inventory_Payment',
        'Location_Master',
        'Company_Master'
    ]
    
    for table in tables:
        try:
            cursor.execute(f"DELETE FROM {table}")
            conn.commit()
            print(f"已清空 {table} 表")
        except Exception as e:
            print(f"清空 {table} 時出錯: {str(e)}")
            conn.rollback()

def get_existing_codes(conn, table_name, code_column):
    """獲取表中已存在的代碼"""
    cursor = conn.cursor()
    cursor.execute(f"SELECT {code_column} FROM {table_name}")
    return set(row[0] for row in cursor.fetchall())

def generate_unique_code(prefix, index, existing_codes, padding=3):
    """生成唯一的代碼"""
    while True:
        code = f"{prefix}{index:0{padding}d}"
        if code not in existing_codes:
            existing_codes.add(code)
            return code
        index += 1

def convert_date(date_obj):
    """轉換日期格式"""
    if date_obj is None:
        return None
    return date_obj.strftime('%Y-%m-%d')

def generate_company_master_data(conn):
    existing_codes = get_existing_codes(conn, 'Company_Master', 'Company_Code')
    companies = []
    index = len(existing_codes)
    
    for _ in range(10):
        company_code = generate_unique_code('COMP', index, existing_codes)
        companies.append((
            company_code,
            fake.company(),
            1,
            'SYSTEM'
        ))
        index += 1
    return companies

def generate_location_master_data(conn):
    existing_codes = get_existing_codes(conn, 'Location_Master', 'Location_Code')
    locations = []
    location_types = ['WAREHOUSE', 'SHOP', 'OFFICE']
    index = len(existing_codes)
    
    for _ in range(15):
        location_code = generate_unique_code('LOC', index, existing_codes)
        locations.append((
            location_code,
            fake.company(),
            random.choice(location_types),
            1,
            'SYSTEM'
        ))
        index += 1
    return locations

def generate_inventory_payment_data(conn, companies):
    existing_numbers = get_existing_codes(conn, 'Inventory_Payment', 'Payment_Number')
    payments = []
    index = len(existing_numbers)
    
    for _ in range(100):
        submit_date = fake.date_between(start_date='-1y', end_date='today')
        cheque_date = submit_date + timedelta(days=random.randint(1, 5))
        deposit_date = cheque_date + timedelta(days=random.randint(1, 5))
        slip_date = deposit_date + timedelta(days=random.randint(1, 3))
        
        payment_number = generate_unique_code('PAY', index, existing_numbers, padding=6)
        invoice_number = f'INV{index:06d}'
        
        payments.append((
            random.choice(companies)[0],
            f'QT{index:06d}',
            invoice_number,
            round(random.uniform(1000, 50000), 2),
            fake.text(max_nb_chars=100),
            fake.text(max_nb_chars=100),
            convert_date(submit_date),
            convert_date(cheque_date),
            convert_date(deposit_date),
            convert_date(deposit_date + timedelta(days=random.randint(1, 10))),
            convert_date(slip_date),
            payment_number,
            'SYSTEM',
            'SYSTEM'
        ))
        index += 1
    return payments

def generate_inventory_data(conn, payments):
    existing_numbers = get_existing_codes(conn, 'Inventory', 'Inventory_Number')
    inventories = []
    catalogs = ['IT-EQ', 'IT-SW', 'IT-NW']
    statuses = ['使用中', '維修中', '報廢', '庫存中']
    index = len(existing_numbers)
    
    for _ in range(100):
        inventory_number = generate_unique_code('IT', index, existing_numbers, padding=5)
        inventories.append((
            inventory_number,
            random.choice(catalogs),
            fake.uuid4(),
            fake.company(),
            f'Model-{fake.word()}',
            convert_date(fake.date_between(start_date='-1y', end_date='today')),
            fake.hostname(),
            str(fake.ipv4()),
            fake.uuid4(),
            fake.text(max_nb_chars=200),
            random.choice(payments)[11],
            round(random.uniform(1000, 10000), 2),
            random.choice(statuses),
            'SYSTEM',
            'SYSTEM'
        ))
        index += 1
    return inventories

def generate_inventory_logistics_data(conn, inventories, locations):
    logistics = []
    statuses = ['待處理', '運送中', '已完成']
    
    for _ in range(100):
        # 隨機選擇一個庫存項目
        inventory = random.choice(inventories)
        # 隨機選擇不同的來源和目標位置
        from_loc = random.choice(locations)
        to_locations = [l for l in locations if l[0] != from_loc[0]]  # 排除相同的位置
        to_loc = random.choice(to_locations)
        
        logistics.append((
            inventory[0],                    # Inventory_Number
            from_loc[0],                    # From_Location
            to_loc[0],                      # To_Location
            f'STAFF{random.randint(1,20):03d}',  # Staff_ID
            random.choice(statuses),        # Status
            fake.text(max_nb_chars=200),    # Remark
            'SYSTEM',                       # Created_user_id
            'SYSTEM'                        # Updated_user_id
        ))
    return logistics

def generate_inventory_lending_data(conn, inventories):
    lendings = []
    statuses = ['借出中', '已歸還', '逾期']
    
    for _ in range(100):
        # 隨機選擇一個庫存項目
        inventory = random.choice(inventories)
        borrow_date = fake.date_between(start_date='-6m', end_date='today')
        expected_return = borrow_date + timedelta(days=random.randint(7, 30))
        actual_return = None if random.random() < 0.3 else expected_return + timedelta(days=random.randint(-3, 10))
        
        lendings.append((
            inventory[0],                    # Inventory_Number
            f'EMP{random.randint(1,50):03d}', # Borrower_ID
            convert_date(borrow_date),        # Borrow_Date
            convert_date(expected_return),    # Expected_Return_Date
            convert_date(actual_return),      # Actual_Return_Date
            random.choice(statuses)           # Status
        ))
    return lendings

def insert_data(conn, table_name, data, columns):
    cursor = conn.cursor()
    placeholders = ','.join(['?' for _ in columns])
    insert_sql = f"INSERT INTO {table_name} ({','.join(columns)}) VALUES ({placeholders})"
    
    for item in data:
        try:
            cursor.execute(insert_sql, item)
            conn.commit()
        except Exception as e:
            print(f"插入數據時出錯: {str(e)}")
            print(f"數據: {item}")
            conn.rollback()

def main():
    conn = None
    try:
        conn = pyodbc.connect(conn_str)
        print("成功連接到數據庫")
        
        # 詢問是否清空現有數據
        choice = input("是否清空所有現有數據？(y/n): ").lower()
        if choice == 'y':
            clear_all_tables(conn)
        
        # 生成並插入公司數據
        print("正在插入公司數據...")
        companies = generate_company_master_data(conn)
        insert_data(conn, 'Company_Master', companies, 
                   ['Company_Code', 'Company_Name', 'Is_Active', 'Created_user_id'])
        
        # 生成並插入位置數據
        print("正在插入位置數據...")
        locations = generate_location_master_data(conn)
        insert_data(conn, 'Location_Master', locations,
                   ['Location_Code', 'Location_Name', 'Location_Type', 'Is_Active', 'Created_user_id'])
        
        # 生成並插入付款數據
        print("正在插入付款數據...")
        payments = generate_inventory_payment_data(conn, companies)
        insert_data(conn, 'Inventory_Payment', payments,
                   ['Company_Code', 'Quotation_Number', 'Invoice_Number', 'Amount', 'Description',
                    'Remarks', 'Accountant_Submit_Date', 'Cheque_Issue_Date', 'Deposit_Date',
                    'Delivery_Date', 'Bank_Slip_Send_Date', 'Payment_Number', 'Created_user_id',
                    'Updated_user_id'])
        
        # 生成並插入庫存數據
        print("正在插入庫存數據...")
        inventories = generate_inventory_data(conn, payments)
        insert_data(conn, 'Inventory', inventories,
                   ['Inventory_Number', 'Catalog', 'Serial_Number', 'Brand', 'Model', 'Date',
                    'Hostname', 'IP_Address', 'Old_serial', 'Remark', 'Payment_Number',
                    'Unit_Price', 'Status', 'Created_user_id', 'Updated_user_id'])
        
        # 生成並插入物流數據
        print("正在插入物流數據...")
        logistics = generate_inventory_logistics_data(conn, inventories, locations)
        insert_data(conn, 'Inventory_Logistics', logistics,
                   ['Inventory_Number', 'From_Location', 'To_Location', 'Staff_ID', 'Status',
                    'Remark', 'Created_user_id', 'Updated_user_id'])
        
        # 生成並插入借出數據
        print("正在插入借出數據...")
        lendings = generate_inventory_lending_data(conn, inventories)
        insert_data(conn, 'Inventory_Lending', lendings,
                   ['Inventory_Number', 'Borrower_ID', 'Borrow_Date', 'Expected_Return_Date',
                    'Actual_Return_Date', 'Status'])
        
        print("所有測試數據已成功插入！")
        
    except Exception as e:
        print(f"錯誤：{str(e)}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()