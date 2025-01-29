### GLOBAL VARIABLES ###

# pypi.org libs
import os
import sys
from getpass import getuser
from socket import gethostname
from dotenv import load_dotenv
# project modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from plugins.paths import PathFuncs
# private modules
sys.path.append(PathFuncs().root_py_dev)
from stpstone.opening_config.setup import reading_yaml
from stpstone.loggs.create_logs import CreateLog
from stpstone.cals.handling_dates import DatesBR
from stpstone.directories_files_manag.managing_ff import DirFilesManagement
from stpstone.pool_conn.postgresql import PostgreSQLDB
from stpstone.webhooks.slack import WebhookSlack


# configuring machine user
USER = getuser()

# configuring machine hostname
HOSTNAME = gethostname()

# charge variables from .env file
load_dotenv()

# user configurations
YAML_USER_CFG = reading_yaml(rf'{PathFuncs().root_py_dev}\config\settings\user_cfg.yaml')

# webhooks
YAML_WEBHOOKS = reading_yaml(rf'{PathFuncs().root_py_dev}\config\settings\webhooks.yaml')
CLS_WEBHOOK_SLACK = WebhookSlack(
    os.getenv('SLACK_URL'),
    os.getenv('SLACK_ID_CHANNEL'),
    os.getenv('SLACK_USERNAME'),
    os.getenv('SLACK_ICON_EMOJI'),
)

# database connectors
YAML_DBS = reading_yaml(rf'{PathFuncs().root_py_dev}\config\settings\dbs.yaml')
CLS_POSTGRESQL_RAW = PostgreSQLDB(
    os.getenv('POSTGRESQL_DB_NAME'),
    os.getenv('POSTGRESQL_USERNAME'), 
    os.getenv('POSTGRES_PASSWORD'), 
    os.getenv('POSTGRESQL_HOST'),
    os.getenv('POSTGRESQL_PORT'), 
    os.getenv('POSTGRESQL_SCHEMA_RAW'), 
)
