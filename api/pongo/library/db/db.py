import psycopg2
from psycopg2 import pool
from dotenv import load_dotenv
import os

# Load .env
load_dotenv()

# Get .env vars
db_host = os.getenv('DB_HOST')
db_name = os.getenv('DB_NAME')
db_user = os.getenv('DB_USER')
db_password = os.getenv('DB_PASSWORD')
  
# Global variable to hold the connection pool
db_pool = None

# Initialize the connection pool
def init_db_pool():
    global db_pool
    if db_pool is None:
        db_pool = psycopg2.pool.SimpleConnectionPool(
            minconn=10,  # Minimum number of connections in the pool
            maxconn=80,  # Maximum number of connections in the pool
            host = db_host,
            database = db_name,
            user = db_user,
            password = db_password
        )

# Get a connection from the pool
def connect():
    if db_pool is None:
        init_db_pool()
    connection = db_pool.getconn()
    return connection, connection.cursor()

# Close the connection by returning it to the pool
def close_connection(connection):
    if db_pool:
        db_pool.putconn(connection)

# Close all connections in the pool (useful for cleanup)
def close_all_connections():
    if db_pool:
        db_pool.closeall()