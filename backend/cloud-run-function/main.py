# import os
# import mysql.connector
# import sqlalchemy
# from google.cloud import secretmanager
# from google.cloud import functions_v1
# from google.auth import default

# # Cloud SQL connection settings
# INSTANCE_CONNECTION_NAME = os.environ.get('INSTANCE_CONNECTION_NAME')
# # 'your-project-id:your-region:your-instance-id'
# DB_USER = os.environ.get('DB_USER')
# DB_NAME = os.environ.get('DB_NAME')
# DB_PASSWORD = os.environ.get('DB_PASSWORD')
# table_name = "InventoryImages"

# # Function to connect to Cloud SQL
# def get_db_connection():
#     """Return a MySQL database connection."""
#     connection = mysql.connector.connect(
#         user=DB_USER,
#         database=DB_NAME,
#         unix_socket=f'/cloudsql/{INSTANCE_CONNECTION_NAME}',
#         password=DB_PASSWORD
#     )
#     return connection

# def check_table_exists(connection, table_name):
#     with connection.cursor() as cursor:
#         # SQL query to check if the table exists
#         sql = """
#         SELECT COUNT(*)
#         FROM information_schema.tables 
#         WHERE table_schema = %s 
#         AND table_name = %s
#         """
#         cursor.execute(sql, (connection.db.decode(), table_name))
#         result = cursor.fetchone()
#         return result[0] > 0

# def insertRecord(connection,inventoryId,path,type,description):
#     cursor = connection.cursor()
#     insert_query = "INSERT INTO InventoryImages (inventoryId,path,type,description) VALUES (%s, %s, %s, %s)"
#     cursor.execute(insert_query, (inventoryId,path,type,description))
#     connection.commit()

# def handler(event, context):
#     """HTTP Cloud Function to insert a user into the database."""
#     print("Event")
#     print(event)
#     print("Context")
#     print(context)
#     try:
#         connection = get_db_connection()

#         if check_table_exists(connection, table_name):
#             insertRecord(connection,"a", "b", "c", "d")
#         else:
#             with connection.cursor() as cursor:
#                 sql = """
#                     CREATE TABLE IF NOT EXISTS InventoryImages (
#                     id INT AUTO_INCREMENT PRIMARY KEY,
#                     inventoryId VARCHAR(255) NOT NULL,
#                     path VARCHAR(255) NOT NULL,
#                     type VARCHAR(255) NOT NULL,
#                     description VARCHAR(255) NOT NULL
#                 )
#                 """
#                 cursor.execute(sql)
#                 connection.commit()
#             insertRecord(connection,"a", "b", "c", "d")

#         # Close the connection
#         cursor.close()
#         connection.close()

#         return f"Record inserted successfully.", 200

#     except mysql.connector.Error as err:
#         print(err)
#         return f"Error: {err}", 500

import os
import sqlalchemy
from datetime import datetime
from google.cloud import secretmanager
from google.cloud import functions_v1
from google.auth import default

# Cloud SQL connection settings
INSTANCE_CONNECTION_NAME = os.environ.get('INSTANCE_CONNECTION_NAME')
DB_USER = os.environ.get('DB_USER')
DB_NAME = os.environ.get('DB_NAME')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
table_name = "InventoryImages"

driver_name = 'mysql+pymysql'
query_string = dict({"unix_socket": "/cloudsql/{}".format(INSTANCE_CONNECTION_NAME)})

def handler(event, context):
    """HTTP Cloud Function to insert a user into the database."""
    print("Event")
    print(event)
    print("Context")
    print(context)
    dt = datetime.now
    stmt = sqlalchemy.text('insert into {} ({},{},{}) values ({},{},{})'.format(table_name, "inventoryId","createdAt","updatedAt",1,str(dt),str(dt)))
    
    db = sqlalchemy.create_engine(
      sqlalchemy.engine.url.URL(
        drivername=driver_name,
        username=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        query=query_string,
      ),
      pool_size=5,
      max_overflow=2,
      pool_timeout=30,
      pool_recycle=1800
    )
    try:
        with db.connect() as conn:
            conn.execute(stmt)
    except Exception as e:
        print(e)
        return 'Error: {}'.format(str(e))