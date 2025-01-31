### DAG TO TEST AIRFLOW INITIATION ###

from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python import PythonOperator
from datetime import datetime


def print_hello():
    print("Hello, Airflow!")


with DAG(
    'demo_dag',
    description='A simple Airflow DAG',
    schedule_interval='@daily',
    start_date=datetime(2025, 1, 28),
    catchup=False,
) as dag:

    # define tasks
    start_task = DummyOperator(
        task_id='start_task'
    )

    hello_task = PythonOperator(
        task_id='hello_task',
        python_callable=print_hello
    )

    end_task = DummyOperator(
        task_id='end_task'
    )

    # set task dependencies
    start_task >> hello_task >> end_task
