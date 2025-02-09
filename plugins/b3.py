### B3 EXCHANGE FUNCS ###

# pypi.org libs
import os
import sys
from dotenv import load_dotenv
from airflow.models.taskinstance import TaskInstance
from stpstone.pool_conn.postgresql import PostgreSQLDB
from stpstone.meta.validate_pm import ValidateAllMethodsMeta
# project modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config.settings._global_slots import YAML_DBS
from plugins.paths import PathFuncs


# venv
path_dotenv = os.path.join(PathFuncs().root_py_project, 'data', 'postgres_mktdata.env')
if os.path.exists(path_dotenv) == True:
    load_dotenv(dotenv_path=path_dotenv)
else:
    raise Exception('env file not found')


class B3Funcs(metaclass=ValidateAllMethodsMeta):

    def instruments_register_b3(self, ti:TaskInstance) -> None:
        """
        Processes and stores the instruments register data from the B3 exchange in the PostgreSQL 
            database.
        Args:
            ti (TaskInstance): The TaskInstance object, used to pull data from XComs.
        Raises:
            Exception: If the connection to the PostgreSQL database fails or the insert operation 
            encounters an error.
        Returns: 
            None
        """
        df_ = ti.xcom_pull(key='cls_up2data_b3').instruments_register
        cls_postgresql_raw = PostgreSQLDB(
            YAML_DBS['postgres_db']['dbname'],
            os.getenv('POSTGRES_USER'), 
            os.getenv('POSTGRES_PASSWORD'), 
            YAML_DBS['postgres_db']['host'],
            YAML_DBS['postgres_db']['port'], 
            YAML_DBS['postgres_db']['schema_raw']
        )
        cls_postgresql_raw._insert(
            df_.to_dict(orient='records'),
            str_table_name=YAML_DBS['instruments_register_row']['table_name'],
            bl_insert_or_ignore=YAML_DBS['instruments_register_row']['bl_insert_or_ignore']
        )