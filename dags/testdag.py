"""Example DAG demonstrating pure decorator style in Airflow.

This module contains a DAG definition that uses only task/DAG decorators
without traditional operators.
"""
from datetime import datetime
from typing import Any

from airflow.decorators import dag, task  # type: ignore[import]

DEFAULT_ARGS = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
}


@dag(
    dag_id="pure_decorator_dag",
    description="DAG using only decorator style (no traditional operators)",
    schedule_interval="@daily",
    start_date=datetime(2025, 6, 7),
    catchup=False,
    tags=["example", "pure_decorator"],
    default_args=DEFAULT_ARGS,
)
def pure_decorator_dag() -> Any:
    """Define a simple DAG using only decorators.

    This DAG demonstrates how to use Airflow's task decorators to create a workflow
    without relying on traditional operator syntax. It includes three tasks:
    - `start_task`: A dummy task that simulates the start of a workflow.
    - `hello_task`: A task that prints a hello message.
    - `end_task`: A dummy task that simulates the end of a workflow.
    Notes
    -----
    - This DAG is a simple example to illustrate the use of decorators in Airflow.
    - It does not perform any complex operations or data processing.
    """

    @task(task_id="start_task")
    def start() -> str:
        """Execute dummy start task.

        Returns
        -------
        str
            Starting message
        """
        print("Starting workflow")
        return "start"

    @task(task_id="hello_task")
    def print_hello() -> str:
        """Print hello message.

        Returns
        -------
        str
            Printed message
        """
        print("Hello, Airflow!")
        return "Hello, Airflow!"

    @task(task_id="end_task")
    def end() -> str:
        """Execute dummy end task.

        Returns
        -------
        str
            Completion message
        """
        print("Workflow completed")
        return "end"

    start_output = start()
    hello_output = print_hello()
    end_output = end()

    start_output >> hello_output >> end_output


dag = pure_decorator_dag()
