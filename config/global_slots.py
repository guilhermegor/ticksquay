"""GLOBAL SLOTS CONFIGURATION.

This module contains global slots configuration for the application.
It includes user configurations, webhooks, and database connectors.
"""

from getpass import getuser
import os
from socket import gethostname

from dotenv import load_dotenv
from stpstone.utils.connections.databases.postgresql import PostgreSQLDB
from stpstone.utils.parsers.yaml import reading_yaml
from stpstone.utils.webhooks.slack import WebhookSlack


USER = getuser()
HOSTNAME = gethostname()

path_project = os.environ.get("AIRFLOW_PROJ_DIR")
path_env = f"{path_project}/.env"
load_dotenv(path_env)

path_base = os.path.dirname(os.path.realpath(__file__))
YAML_USER_CFG = reading_yaml(os.path.join(path_base, "user_cfg.yaml"))

YAML_WEBHOOKS = reading_yaml(os.path.join(path_base, "webhooks.yaml"))
CLS_WEBHOOK_SLACK = WebhookSlack(
    os.getenv("SLACK_URL"),
    os.getenv("SLACK_ID_CHANNEL"),
    os.getenv("SLACK_USERNAME"),
    os.getenv("SLACK_ICON_EMOJI"),
)

if not all([os.getenv(x) is not None for x in [
    "POSTGRES_DB", "POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_HOST", "POSTGRES_PORT"
]]):
    raise ValueError("Environment variables for PostgreSQL not set, please check your .env file")
CLS_POSTGRES_RAW = PostgreSQLDB(
    os.getenv("POSTGRES_DB"),
    os.getenv("POSTGRES_USER"),
    os.getenv("POSTGRES_PASSWORD"),
    os.getenv("POSTGRES_HOST"),
    int(os.getenv("POSTGRES_PORT")),
    "raw",
)
