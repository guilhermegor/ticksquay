"""DAG for IRSBR records data ingestion from Brazil taxation system."""
import os

from airflow.decorators import dag, task
from dotenv import load_dotenv
from stpstone.ingestion.countries.br.taxation.irsbr_records import IRSBR
from stpstone.utils.cals.handling_dates import DatesBR
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
    schedule_interval="@daily",
    catchup=False,
    tags=["taxation", "brazil", "data_ingestion"],
    default_args=get_default_args(),
)
def irsbr_records_dag() -> None:
    """Orchestrate the ingestion of Brazilian tax system records."""

    @task(task_id="verify_db_connection")
    def verify_db_connection() -> bool:
        """Verify PostgreSQL database connection is working."""
        import os

        from psycopg import connect
        from stpstone.utils.loggs.create_logs import CreateLog

        try:
            conn = connect(
                dbname=os.getenv("POSTGRES_DB"),
                user=os.getenv("POSTGRES_USER"),
                password=os.getenv("POSTGRES_PASSWORD"),
                host=os.getenv("POSTGRES_HOST"),
                port=int(os.getenv("POSTGRES_PORT")),
            )

            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                result = cur.fetchone()
                if result[0] != 1:
                    raise ValueError("Test query returned unexpected result")

            with conn.cursor() as cur:
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
            raise ValueError(error_msg) from e

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

    @task(task_id="ingest_reference_data")
    def ingest_reference_data(irsbr: IRSBR) -> None:
        """Ingest all reference data in parallel."""
        reference_tasks = [
            ("countries", "country_refecountriesence"),
            ("cities", "cities"),
            ("shareholders_education", "shareholders_education"),
            ("legal_form", "legal_form"),
            ("ncea", "ncea"),
            ("registration_status", "registration_status")
        ]

        for source_name, task_id in reference_tasks:
            @task(task_id=task_id)
            def ingest_reference(source: str, irsbr_instance: IRSBR) -> None:
                irsbr_instance.source(source, bl_fetch=False)

            ingest_reference(source_name, irsbr)

    # task dependencies
    irsbr_client = initialize_irsbr()
    companies = ingest_companies(irsbr_client)
    businesses = ingest_businesses(irsbr_client)
    tax_system = ingest_taxation_system(irsbr_client)
    shareholders = ingest_shareholders(irsbr_client)
    reference_data = ingest_reference_data(irsbr_client)

    # define workflow
    verify_db_connection >> irsbr_client
    irsbr_client >> [companies, businesses, tax_system, shareholders]
    shareholders >> reference_data


# instantiate the DAG
irsbr_dag = irsbr_records_dag()
