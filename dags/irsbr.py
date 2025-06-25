"""DAG for IRSBR records data ingestion from Brazil taxation system."""
import logging
import os

from airflow.decorators import dag, task
from airflow.exceptions import AirflowException, AirflowFailException
from airflow.models.dagrun import DagRun
from airflow.operators.python import get_current_context
from airflow.utils.state import DagRunState
from dotenv import load_dotenv
from psycopg import connect
from stpstone.ingestion.countries.br.taxation.irsbr_records import IRSBR
from stpstone.utils.cals.handling_dates import DatesBR
from stpstone.utils.loggs.create_logs import CreateLog
from stpstone.utils.parsers.dicts import HandlingDicts

from config.global_slots import CLS_POSTGRES_RAW, USER, YAML_USER_CFG


logger = logging.getLogger(__name__)
env_paths = [
    os.path.join(os.getenv("AIRFLOW_PROJ_DIR", "/opt/airflow"), ".env"),
    "/opt/airflow/.env",
    ".env"
]

for path in env_paths:
    if os.path.exists(path):
        load_dotenv(path)
        break

def get_default_args() -> dict[str, str | list]:
    """Prepare and validate default arguments for the DAG."""
    if not YAML_USER_CFG.get("default_args_airflow"):
        raise ValueError("Missing 'default_args_airflow' in YAML configuration")
    if not os.getenv("LIST_EMAILS_ADDRESSES"):
        raise ValueError("Environment variable LIST_EMAILS_ADDRESSES not set")
    str_emails = os.getenv("LIST_EMAILS_ADDRESSES").strip()
    dict_replc = {
        "owner": USER,
        "list_email_addresses": [email.strip() for email in str_emails.split(",")],
        "start_date": DatesBR().sub_working_days(DatesBR().curr_date, 1),
        "end_date": DatesBR().add_working_days(DatesBR().curr_date, 30),
    }
    return HandlingDicts().fill_placeholders(YAML_USER_CFG["default_args_airflow"], dict_replc)


@dag(
    dag_id="irsbr",
    description="DAG for ingesting IRS BR records into PostgreSQL",
    tags=["taxation", "brazil", "data_ingestion"],
    default_args=get_default_args(),
    catchup=False,
    schedule_interval=None,
)
def irsbr_records_dag() -> None:
    """Orchestrate the ingestion of Brazilian tax system records."""

    @task(task_id="startup_trigger")
    def startup_trigger() -> bool:
        """Ensure DAG only runs once per day."""
        dag_run = get_current_context().get('dag_run')
        if not dag_run or dag_run.run_id.startswith('manual__') or dag_run.external_trigger:
            return True
        list_successful_runs = DagRun.find(dag_id="irsbr", state=DagRunState.SUCCESS,
                                   execution_start_date=DatesBR().curr_date)
        if not list_successful_runs:
            return True
        raise AirflowException("DAG already ran today. Manual trigger required.")

    @task(task_id="verify_db_connection")
    def verify_db_connection() -> bool:
        """Verify PostgreSQL database connection is working."""
        try:
            conn = connect(
                dbname=os.getenv("POSTGRES_DB"),
                user=os.getenv("POSTGRES_USER"),
                password=os.getenv("POSTGRES_PASSWORD"),
                host=os.getenv("POSTGRES_HOST"),
                port=int(os.getenv("POSTGRES_PORT")),
            )
            list_required_tables = [
                "br_irs_companies",
                "br_irs_businesses",
                "br_irs_taxation_system",
                "br_irs_shareholders"
            ]
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                result = cur.fetchone()
                if result[0] != 1:
                    raise ValueError("Test query returned unexpected result")
                cur.execute("""
                    SELECT table_name
                    FROM information_schema.tables
                    WHERE table_schema = %s
                    AND table_name = ANY(%s)
                """, (os.getenv("POSTGRES_SCHEMA", "raw"), list_required_tables))
                existing_tables = [row[0] for row in cur.fetchall()]
                missing_tables = set(list_required_tables) - set(existing_tables)
                if missing_tables:
                    raise ValueError(f"Missing tables: {', '.join(missing_tables)}")

                cur.execute("""
                    SELECT schema_name
                    FROM information_schema.schemata
                    WHERE schema_name = %s
                """, (os.getenv("POSTGRES_SCHEMA", "raw"),))
                if not cur.fetchone():
                    raise ValueError(f"Schema '{os.getenv('POSTGRES_SCHEMA', 'raw')}' not found")

            conn.close()
            return True

        except Exception as e:
            error_msg = f"Database connection failed: {str(e)}"
            CreateLog().log_message(None, error_msg, "error")
            raise AirflowFailException(error_msg) from e

    @task(task_id="initialize_client")
    def initialize_client() -> IRSBR:
        """Initialize client with database connection."""
        return IRSBR(session=None, cls_db=CLS_POSTGRES_RAW)

    @task(task_id="debug_check")
    def debug_check() -> bool:
        """Debug check."""
        print("DAG is executing, database connection is working.")
        return True

    @task(task_id="ingest_companies")
    def ingest_companies(irsbr: IRSBR) -> None:
        """Ingest company data."""
        irsbr.source("companies", bl_fetch=False)

    @task(task_id="ingest_businesses")
    def ingest_businesses(irsbr: IRSBR) -> None:
        """Ingest business entities data."""
        irsbr.source("businesses", bl_fetch=False)

    @task(task_id="ingest_taxation_system")
    def ingest_taxation_system(irsbr: IRSBR) -> None:
        """Ingest simplified taxation system records."""
        irsbr.source("simplified_taxation_system", bl_fetch=False)

    @task(task_id="ingest_shareholders")
    def ingest_shareholders(irsbr: IRSBR) -> None:
        """Ingest shareholder information."""
        irsbr.source("shareholders", bl_fetch=False)

    @task(task_id="ingest_countries")
    def ingest_countries(irsbr: IRSBR) -> None:
        """Ingest country data."""
        irsbr.source("countries", bl_fetch=False)

    @task(task_id="ingest_cities")
    def ingest_cities(irsbr: IRSBR) -> None:
        """Ingest city data."""
        irsbr.source("cities", bl_fetch=False)

    @task(task_id="ingest_shareholders_education")
    def ingest_shareholders_education(irsbr: IRSBR) -> None:
        """Ingest shareholder education data."""
        irsbr.source("shareholders_education", bl_fetch=False)

    @task(task_id="ingest_legal_form")
    def ingest_legal_form(irsbr: IRSBR) -> None:
        """Ingest legal form data."""
        irsbr.source("legal_form", bl_fetch=False)

    @task(task_id="ingest_ncea")
    def ingest_ncea(irsbr: IRSBR) -> None:
        """Ingest NCEA data."""
        irsbr.source("ncea", bl_fetch=False)

    @task(task_id="ingest_registration_status")
    def ingest_registration_status(irsbr: IRSBR) -> None:
        """Ingest registration status data."""
        irsbr.source("registration_status", bl_fetch=False)

    # task dependencies
    trigger = startup_trigger()
    db_check = verify_db_connection()
    client_instance = initialize_client()
    debug = debug_check()
    companies = ingest_companies(client_instance)
    businesses = ingest_businesses(client_instance)
    tax_system = ingest_taxation_system(client_instance)
    shareholders = ingest_shareholders(client_instance)
    countries = ingest_countries(client_instance)
    cities = ingest_cities(client_instance)
    shareholders_education = ingest_shareholders_education(client_instance)
    legal_form = ingest_legal_form(client_instance)
    ncea = ingest_ncea(client_instance)
    registration_status = ingest_registration_status(client_instance)

    # define workflow
    trigger >> db_check >> client_instance >> debug
    debug >> companies >> businesses >> tax_system >> shareholders
    shareholders >> countries >> cities >> shareholders_education >> legal_form >> ncea
    ncea >> registration_status


# instantiate the DAG
irsbr_dag = irsbr_records_dag()
