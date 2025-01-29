### XCOM FUNCS ###

# pypi.org libs
import os
import sys
from airflow.models.taskinstance import TaskInstance
from typing import Any
# project modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config.settings._global_slots import YAML_USER_CFG
from plugins.paths import PathFuncs
# private modules
sys.path.append(PathFuncs().root_py_dev)
from stpstone.finance.b3.up2data_web import UP2DATAB3
from stpstone.pool_conn.session import ReqSession
from stpstone.meta.validate_pm import ValidateAllMethodsMeta


class XCOMFuncs(metaclass=ValidateAllMethodsMeta):

    def opn_setup(self, ti:TaskInstance, **kwargs:Any) -> None:
        """
        Sets up and pushes essential objects to XCom for use in subsequent tasks in the Airflow 
            workflow.
        Args:
            ti (TaskInstance): The TaskInstance object used for XCom operations.
            **kwargs (Any): Additional arguments passed to the function. 
                Expected keys:
                    - 'ds' (str): Execution date string in the format required by `UP2DATAB3`.
        Raises:
            KeyError: If the `ds` key is missing in `kwargs` or if there are issues retrieving 
                the required objects from XCom.
        Returns:
            None
        """
        ti.xcom_push(
            key='cls_req_session', 
            value=ReqSession(bl_use_timer=YAML_USER_CFG['conf_panel']['bl_use_timer'])
        )
        ti.xcom_push(
            key='cls_up2data_b3', 
            value=UP2DATAB3(kwargs['ds'], ti.xcom_pull(key='req_session'))
        )