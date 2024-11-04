import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import ipaddress

# 設定隨機種子確保可重現性
np.random.seed(42)

# 建立模擬資料
n_records = 100

# 定義資料類別
catalogs = ['IT-EQ', 'OFF-EQ', 'FURNITURE', 'SOFTWARE']
brands = ['Dell', 'HP', 'Lenovo', 'Apple', 'Microsoft']
statuses = ['使用中', '借用中', '維修中', '已報廢', '庫存中']

def generate_inventory_number(i):
    category = random.choice(['IT', 'OF'])
    dept = f"{random.randint(100, 999)}"
    number = f"{i:05d}"
    return f"{category}-{dept}-{number}"

def generate_ip():
    return str(ipaddress.IPv4Address(random.randint(0, 2**32-1)))

# 生成資料
data = {
    'Inventory_Number': [generate_inventory_number(i) for i in range(n_records)],
    'Catalog': pd.Categorical([random.choice(catalogs) for _ in range(n_records)]),
    'Serial_Number': [f"SN{random.randint(10000, 99999)}" for _ in range(n_records)],
    'Brand': [random.choice(brands) for _ in range(n_records)],
    'Model': [f"Model-{random.randint(100, 999)}" for _ in range(n_records)],
    'Date': pd.date_range(start='2020-01-01', periods=n_records, freq='D'),
    'Hostname': [f"HOST-{random.randint(1000, 9999)}" for _ in range(n_records)],
    'IP_Address': [generate_ip() for _ in range(n_records)],
    'Old_serial': [f"OLD-{random.randint(1000, 9999)}" for _ in range(n_records)],
    'Remark': [''] * n_records,
    'Payment_Number': [f"PAY-{random.randint(10000, 99999)}" for _ in range(n_records)],
    'Unit_Price': np.random.uniform(1000, 50000, n_records).round(2),
    'Status': pd.Categorical([random.choice(statuses) for _ in range(n_records)]),
    'Created_datetime': datetime.now() - pd.to_timedelta(np.random.randint(0, 365, n_records), unit='D'),
    'Updated_datetime': datetime.now() - pd.to_timedelta(np.random.randint(0, 30, n_records), unit='D'),
    'Created_user_id': [f"USER{random.randint(100, 999)}" for _ in range(n_records)],
    'Updated_user_id': [f"USER{random.randint(100, 999)}" for _ in range(n_records)]
}

# 建立 DataFrame
df = pd.DataFrame(data)

# 設定適當的資料類型
df['Date'] = pd.to_datetime(df['Date'])
df['Created_datetime'] = pd.to_datetime(df['Created_datetime'])
df['Updated_datetime'] = pd.to_datetime(df['Updated_datetime'])

# 輸出到 CSV
df.to_csv('inventory.csv', index=False, encoding='utf-8-sig')

# 顯示資料基本統計
print("資料集基本資訊：")
print(df.info())
print("\n前五筆資料：")
print(df.head())