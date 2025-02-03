import os
import mysql.connector
import sqlalchemy
from datetime import datetime
from google.cloud import secretmanager
from google.cloud import functions_v1
from google.auth import default

# Cloud SQL connection settings
INSTANCE_CONNECTION_NAME = os.environ.get('INSTANCE_CONNECTION_NAME')
# 'your-project-id:your-region:your-instance-id'
DB_USER = os.environ.get('DB_USER')
DB_PATH = os.environ.get('DB_PATH')
DB_NAME = "carshub"
DB_PASSWORD = os.environ.get('DB_PASSWORD')
table_name = "InventoryImages"

# Function to connect to Cloud SQL
def get_db_connection():
    """Return a MySQL database connection."""
    connection = mysql.connector.connect(
        user=DB_USER,
        database=DB_NAME,
        # host=DB_PATH,
        unix_socket=f'/cloudsql/{INSTANCE_CONNECTION_NAME}',
        password=DB_PASSWORD
    )
    return connection

def insertRecord(connection,inventoryId,path,type,description):
    cursor = connection.cursor()
    ts = datetime.now().isoformat()
    insert_query = "INSERT INTO InventoryImages (inventoryId,path,type,description,createdAt,updatedAt) VALUES (%s, %s, %s, %s, %s, %s)"
    cursor.execute(insert_query, (1,path,type,description,ts,ts))
    connection.commit()

def handler(event, context):
    """HTTP Cloud Function to insert a user into the database."""
    print("Event")
    print(event)
    print("Context")
    print(context)
    try:
        connection = get_db_connection()        
        insertRecord(connection,event["metadata"]["inventoryid"], "b", event["metadata"]["typeofdocument"], event["metadata"]["descriptionofdocument"])
        connection.close()
        return f"Record inserted successfully.", 200

    except mysql.connector.Error as err:
        print(err)
        return f"Error: {err}", 500