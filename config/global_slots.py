"""GLOBAL SLOTS CONFIGURATION.

This module contains global slots configuration for the application.
It includes user configurations, webhooks, and database connectors.
"""

from getpass import getuser
import os
from socket import gethostname

from dotenv import load_dotenv
from stpstone.utils.connections.databases.postgresql import PostgreSQLDB
from stpstone.utils.parsers.folders import DirFilesManagement
from stpstone.utils.parsers.yaml import reading_yaml
from stpstone.utils.webhooks.slack import WebhookSlack

# get user and hostname
USER = getuser()
HOSTNAME = gethostname()

# load environment variables
path_project = DirFilesManagement().find_project_root()
path_env = f"{path_project}/.env"
load_dotenv(path_env)

# user configurations
path_base = os.path.dirname(os.path.realpath(__file__))
YAML_USER_CFG = reading_yaml(os.path.join(path_base, "user_cfg.yaml"))

# webhooks
YAML_WEBHOOKS = reading_yaml(os.path.join(path_base, "webhooks.yaml"))
CLS_WEBHOOK_SLACK = WebhookSlack(
    os.getenv("SLACK_URL"),
    os.getenv("SLACK_ID_CHANNEL"),
    os.getenv("SLACK_USERNAME"),
    os.getenv("SLACK_ICON_EMOJI"),
)

# database connectors
CLS_POSTGRESQL_RAW = PostgreSQLDB(
    "mktdata_collector",
    os.getenv("POSTGRESQL_USERNAME"),
    os.getenv("POSTGRES_PASSWORD"),
    os.getenv("POSTGRESQL_HOST"),
    os.getenv("POSTGRESQL_PORT"),
    "RAW",
)
