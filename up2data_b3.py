### UP2DATA B3 DAG ###

# pypi.org libs
import os
import sys
from dotenv import load_dotenv
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.trigger_rule import TriggerRule
from airflow.operators.dummy import DummyOperator
# project modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config.settings._global_slots import YAML_USER_CFG
from plugins.paths import PathFuncs
from plugins.b3 import B3Funcs
from plugins.xcom import XCOMFuncs
# private modules
sys.path.append(PathFuncs().root_py_dev)
from stpstone.cals.handling_dates import DatesBR
from stpstone.handling_data.dicts import HandlingDicts
from stpstone.airflow.plugins import AirflowPlugins


# classes
cls_b3 = B3Funcs()
cls_xcom = XCOMFuncs()

# dag
with DAG(
    'up2data_b3',
    description='DAG for UP2DATA B3',
    default_args=HandlingDicts().replace_variables(
        YAML_USER_CFG['default_args_airflow'], 
        {
            'list_emails_address': os.getenv('LIST_EMAILS_ADDRESS_ERRORS'),
            'start_date': DatesBR().sub_working_days(
                DatesBR().curr_date, YAML_USER_CFG['up2data_b3']['wd_bef_inf']),
            'end_date': DatesBR().sub_working_days(
                DatesBR().curr_date, YAML_USER_CFG['up2data_b3']['wd_bef_sup'])
        }
    ),
    schedule_interval='10 00 * * MON-FRI'
) as dag:

    validate_working_day = PythonOperator(
        task_id='validate_working_day',
        python_callable=AirflowPlugins().validate_working_day,
        provide_context=True
    )

    push_xcom_task = PythonOperator(
        task_id='opn_setup',
        python_callable=cls_xcom.opn_setup,
        provide_context=True
    )

    instr_regstr_b3 = PythonOperator(
        task_id='instruments_register_b3',
        python_callable=cls_b3.instruments_register_b3,
        provide_context=True
    )

    stop_dag = DummyOperator(task_id='stop_dag', trigger_rule=TriggerRule.ALL_FAILED)

    validate_working_day >> push_xcom_task >> instr_regstr_b3
    validate_working_day >> stop_dag