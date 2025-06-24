"""DAG for IRSBR records data ingestion from Brazil taxation system."""
import os

from airflow.decorators import dag, task
from airflow.exception import AirflowException
from airflow.exceptions import AirflowFailException
from airflow.utils.dates import days_ago
from airflow.utils.models import DagRun
from airflow.utils.state import DagRunState
from dotenv import load_dotenv
from psycopg import connect
from stpstone.ingestion.countries.br.taxation.irsbr_records import IRSBR
from stpstone.utils.cals.handling_dates import DatesBR
from stpstone.utils.loggs.create_logs import CreateLog
from stpstone.utils.parsers.dicts import HandlingDicts

from config.global_slots import CLS_POSTGRES_RAW, USER, YAML_USER_CFG


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
        "start_date": DatesBR().curr_date,
        "end_date": DatesBR().curr_date,
    }
    return HandlingDicts().fill_placeholders(YAML_USER_CFG["default_args_airflow"], dict_replc)


@dag(
    dag_id="irsbr",
    description="DAG for ingesting IRS BR records into PostgreSQL",
    tags=["taxation", "brazil", "data_ingestion"],
    default_args=get_default_args(),
    catchup=False,
)
def irsbr_records_dag() -> None:
    """Orchestrate the ingestion of Brazilian tax system records."""

    @task(task_id="startup_trigger")
    def startup_trigger() -> bool:
        """Ensure DAG only runs once per day."""
        list_dag_runs = DagRun.find(dag_id="irsbr", state=DagRunState.SUCCESS)
        list_dag_runs.sort(key=lambda x: x.execution_date, reverse=True)
        if list_dag_runs and list_dag_runs[0].execution_date >= days_ago(1):
            raise AirflowException(f"DAG already ran on {list_dag_runs[0].execution_date}. "
                                   + "Manual trigger required for new execution.")
        return True

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
            CreateLog().error(None, error_msg)
            raise AirflowFailException(error_msg) from e

    @task(task_id="initialize_irsbr")
    def initialize_irsbr() -> IRSBR:
        """Initialize IRSBR client with database connection."""
        return IRSBR(session=None, cls_db=CLS_POSTGRES_RAW)

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
    irsbr_client = initialize_irsbr()
    companies = ingest_companies(irsbr_client)
    businesses = ingest_businesses(irsbr_client)
    tax_system = ingest_taxation_system(irsbr_client)
    shareholders = ingest_shareholders(irsbr_client)
    countries = ingest_countries(irsbr_client)
    cities = ingest_cities(irsbr_client)
    shareholders_education = ingest_shareholders_education(irsbr_client)
    legal_form = ingest_legal_form(irsbr_client)
    ncea = ingest_ncea(irsbr_client)
    registration_status = ingest_registration_status(irsbr_client)

    # define workflow
    trigger >> db_check >> irsbr_client
    irsbr_client >> companies >> businesses >> tax_system >> shareholders
    shareholders >> countries >> cities >> shareholders_education >> legal_form >> ncea
    ncea >> registration_status


# instantiate the DAG
irsbr_dag = irsbr_records_dag()
