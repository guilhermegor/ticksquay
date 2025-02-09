### GLOBAL VARIABLES ###

# pypi.org libs
import os
import sys
from getpass import getuser
from socket import gethostname
from dotenv import load_dotenv
from stpstone.opening_config.setup import reading_yaml
from stpstone.pool_conn.postgresql import PostgreSQLDB
from stpstone.webhooks.slack import WebhookSlack


# configuring machine user
USER = getuser()

# configuring machine hostname
HOSTNAME = gethostname()

# charge variables from .env file
load_dotenv()

# base path
path_base = os.path.dirname(os.path.realpath(__file__))

# user configurations
YAML_USER_CFG = reading_yaml(os.path.join(path_base, 'user_cfg.yaml'))

# webhooks
YAML_WEBHOOKS = reading_yaml(os.path.join(path_base, 'webhooks.yaml'))
CLS_WEBHOOK_SLACK = WebhookSlack(
    os.getenv('SLACK_URL'),
    os.getenv('SLACK_ID_CHANNEL'),
    os.getenv('SLACK_USERNAME'),
    os.getenv('SLACK_ICON_EMOJI'),
)

# database connectors
YAML_DBS = reading_yaml(os.path.join(path_base, 'dbs.yaml'))
CLS_POSTGRESQL_RAW = PostgreSQLDB(
    os.getenv('POSTGRESQL_DB_NAME'),
    os.getenv('POSTGRESQL_USERNAME'), 
    os.getenv('POSTGRES_PASSWORD'), 
    os.getenv('POSTGRESQL_HOST'),
    os.getenv('POSTGRESQL_PORT'), 
    os.getenv('POSTGRESQL_SCHEMA_RAW'), 
)
