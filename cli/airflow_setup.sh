#!/bin/bash

# initialize the airflow metastore
airflow db init

# run the scheduler in background
airflow scheduler &> /dev/null &

# create user
#   -u: username
#   -p: password
#   -r: role
#   -e: email
#   -f: first name
#   -l: last name
airflow users create -u ${AIRFLOW_USER} -p ${AIRFLOW_PASSWORD} -r Admin -e ${AIRFLOW_EMAIL} \
    -f ${AIRFLOW_FNAME} -l ${AIRFLOW_LNAME}

# run the webserver in foreground (for docker logs)
exec airflow webserver