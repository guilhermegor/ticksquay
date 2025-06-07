"""DAG for IRSBR records data ingestion from Brazil taxation system."""
import os

from airflow.decorators import dag, task  # type: ignore[import]
from dotenv import load_dotenv
from stpstone.ingestion.countries.br.taxation.irsbr_records import IRSBR
from stpstone.utils.cals.handling_dates import DatesBR
from stpstone.utils.parsers.dicts import HandlingDicts
from stpstone.utils.parsers.folders import DirFilesManagement

from config.global_slots import CLS_POSTGRESQL_RAW, YAML_USER_CFG

path_project = DirFilesManagement().find_project_root()
path_env = f"{path_project}/.env"
load_dotenv(path_env)


@dag(
    dag_id="irsbr",
    description="DAG for ingesting IRS BR records",
    schedule_interval="@daily",
    catchup=False,
    tags=["taxation", "brazil", "data_ingestion"],
    default_args=HandlingDicts().fill_placeholders(
        YAML_USER_CFG["default_args_airflow"],
        {
            "list_emails_addresses": os.getenv("LIST_EMAILS_ADDRESSES"),
            "start_date": DatesBR().curr_date,
            "end_date": DatesBR().curr_date,
        },
    ),
)
def irsbr_records_dag() -> None:  # noqa: C901
    """Define workflow for IRSBR records data ingestion."""

    @task(task_id="class_")
    def class_() -> IRSBR:
        """Return an instance of the IRSBR class.

        Returns:
            IRSBR: An instance of the IRSBR class.
        """
        return IRSBR(session=None, cls_db=CLS_POSTGRESQL_RAW)

    @task(task_id="companies")
    def companies(cls_: IRSBR) -> None:
        """Insert IRS BR data for companies."""
        _ = cls_.source("companies", bl_fetch=False)

    @task(task_id="businesses")
    def businesses(cls_: IRSBR) -> None:
        """Insert IRS BR data for businesses."""
        cls_.source("businesses", bl_fetch=False)

    @task(task_id="simplified_taxation_system")
    def simplified_taxation_system(cls_: IRSBR) -> None:
        """Insert IRS BR data for simplified taxation system."""
        cls_.source("simplified_taxation_system", bl_fetch=False)

    @task(task_id="shareholders")
    def shareholders(cls_: IRSBR) -> None:
        """Insert IRS BR data for shareholders."""
        cls_.source("shareholders", bl_fetch=False)

    @task(task_id="countries")
    def countries(cls_: IRSBR) -> None:
        """Insert IRS BR data for countries."""
        cls_.source("countries", bl_fetch=False)

    @task(task_id="cities")
    def cities(cls_: IRSBR) -> None:
        """Insert IRS BR data for cities."""
        cls_.source("cities", bl_fetch=False)

    @task(task_id="shareholders_education")
    def shareholders_education(cls_: IRSBR) -> None:
        """Insert IRS BR data for shareholders education."""
        cls_.source("shareholders_education", bl_fetch=False)

    @task(task_id="legal_form")
    def legal_form(cls_: IRSBR) -> None:
        """Insert IRS BR data for legal form."""
        cls_.source("legal_form", bl_fetch=False)

    @task(task_id="ncea")
    def ncea(cls_: IRSBR) -> None:
        """Insert IRS BR data for NCEA."""
        cls_.source("ncea", bl_fetch=False)

    @task(task_id="registration_status")
    def registration_status(cls_: IRSBR) -> None:
        """Insert IRS BR data for registration status."""
        cls_.source("registration_status", bl_fetch=False)

    cls_instance = class_()
    companies_instance = companies(cls_instance)
    businesses_instance = businesses(cls_instance)
    simplified_taxation_system_instance = simplified_taxation_system(
        cls_instance)
    shareholders_instance = shareholders(cls_instance)
    countries_instance = countries(cls_instance)
    cities_instance = cities(cls_instance)
    shareholders_education_instance = shareholders_education(cls_instance)
    legal_form_instance = legal_form(cls_instance)
    ncea_instance = ncea(cls_instance)
    registration_status_instance = registration_status(cls_instance)

    cls_instance >> companies_instance >> businesses_instance
    businesses_instance >> simplified_taxation_system_instance
    simplified_taxation_system_instance >> shareholders_instance
    shareholders_instance >> countries_instance
    countries_instance >> cities_instance
    cities_instance >> shareholders_education_instance
    shareholders_education_instance >> legal_form_instance
    legal_form_instance >> ncea_instance
    ncea_instance >> registration_status_instance


dag = irsbr_records_dag()
