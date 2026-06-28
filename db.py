from dotenv import load_dotenv
import os

##################################
#                               #
#          Load Env             #
#                               #
##################################


# Load .env credentials
load_dotenv()

HOST        = os.getenv("PG_HOST")
PORT        = os.getenv("PG_PORT")
DBNAME      = os.getenv("PG_DBNAME")
USER        = os.getenv("PG_USER")
PASSOWRD    = os.getenv("PG_PASSWORD")
SSLMODE     = os.getenv("PG_SSLMODE", "require")
