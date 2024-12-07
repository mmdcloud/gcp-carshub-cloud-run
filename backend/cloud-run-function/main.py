import os
import mysql.connector
from google.cloud import secretmanager
from google.cloud import functions_v1
from google.auth import default

# Cloud SQL connection settings
INSTANCE_CONNECTION_NAME = 'your-project-id:your-region:your-instance-id'
DB_USER = 'root'
DB_NAME = 'carshub'

# Function to connect to Cloud SQL
def get_db_connection():
    """Return a MySQL database connection."""
    connection = mysql.connector.connect(
        user=DB_USER,
        database=DB_NAME,
        unix_socket=f'/cloudsql/{INSTANCE_CONNECTION_NAME}',
        password=os.environ.get('DB_PASSWORD')
    )
    return connection

def handler(event, context):
    """HTTP Cloud Function to insert a user into the database."""
    try:
        # Parse the incoming request (you can modify this as needed)
        request_json = request.get_json(silent=True)
        if request_json and 'name' in request_json and 'email' in request_json:
            name = request_json['name']
            email = request_json['email']
        else:
            return "Missing 'name' or 'email' parameter", 400

        # Connect to Cloud SQL and insert the record
        connection = get_db_connection()
        cursor = connection.cursor()

        # Prepare the SQL statement to insert the record
        insert_query = "INSERT INTO users (name, email) VALUES (%s, %s)"
        cursor.execute(insert_query, (name, email))
        connection.commit()

        # Close the connection
        cursor.close()
        connection.close()

        return f"User {name} inserted successfully.", 200

    except mysql.connector.Error as err:
        return f"Error: {err}", 500
