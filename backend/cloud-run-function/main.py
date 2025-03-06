import os
import mysql.connector
import sqlalchemy
from google.cloud import storage
import base64
from datetime import datetime
from google.cloud import secretmanager
from google.cloud import functions_v1
from google.auth import default

DB_USER = os.environ.get('DB_USER')
DB_PATH = os.environ.get('DB_PATH')
DB_NAME = "carshub"
SECRET_NAME = os.environ.get('SECRET_NAME')
table_name = "InventoryImages"

storage_client = storage.Client()

def access_secret(secret_name, version_id="1"):
    # Create the Secret Manager client
    client = secretmanager.SecretManagerServiceClient()
    
    # Build the resource name of the secret version
    name = f"{secret_name}/versions/{version_id}"
    
    # Access the secret version
    response = client.access_secret_version(request={"name": name})
    
    # Return the decoded payload
    return response.payload.data.decode("UTF-8")

# Function to connect to Cloud SQL
def get_db_connection():
    db_password = access_secret(SECRET_NAME)
    """Return a MySQL database connection."""
    connection = mysql.connector.connect(
        user=DB_USER,
        database=DB_NAME,
        host=DB_PATH,        
        password=db_password
    )
    return connection

def insertRecord(connection,inventoryId,path,type,description):
    cursor = connection.cursor()
    ts = datetime.now().isoformat()
    insert_query = "INSERT INTO InventoryImages (inventoryId,path,type,description,createdAt,updatedAt) VALUES (%s, %s, %s, %s, %s, %s)"
    cursor.execute(insert_query, (inventoryId,path,type,description,ts,ts))
    connection.commit()

def handler(event, context):
    """HTTP Cloud Function to insert a user into the database."""
    print("Event")
    print(event)
    print("Context")
    print(context)
    try:
        connection = get_db_connection()
        if event["attributes"]["eventType"] == "OBJECT_FINALIZE":
            decoded_dict = base64.b64decode(event["data"]).decode('utf-8')            
            bucket = storage_client.bucket(event["attributes"]["bucketId"])
            blob = bucket.get_blob(decoded_dict["name"])
            insertRecord(connection,blob.metadata["inventoryid"], decoded_dict["name"], blob.metadata["typeofdocument"], blob.metadata["descriptionofdocument"])
        connection.close()
        return f"Record inserted successfully.", 200

    except mysql.connector.Error as err:
        print(err)
        return f"Error: {err}", 500