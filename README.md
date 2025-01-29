<img src="data/img/mkt-data-collector-cover.png" alt="Market Data Collector" width="450" height="450"/>

# Market Data Collector

This project focuses on building an ETL pipeline to collect, transform, and store market data from Brazilian and North American markets. The pipeline supports data ingestion from over-the-counter (OTC), exchange, and registry sources. With a scalable design, the project aims to expand support for global markets and integrate additional data sources in the future.


## Getting Started

These instructions will get you a copy of the project running on your local machine for development and testing purposes.

### Prerequisities

* Python version, libs and Docker images already installed in Dockerfile.

### Installing

* Setting .env files:
```bash
(bash)

# execute cd regardless of .env files have already being created
cd complete/path/to/project
shell/env_config.sh

```

* Configure .env and data/postgres_mktdata.env with personal data (must replace PLEASE_FILL and fill@me.com example credentials)

* Install Docker: https://docs.docker.com/desktop/

* Install Makefile (optional):
    * Windows: https://medium.com/@samsorrahman/how-to-run-a-makefile-in-windows-b4d115d7c516
    * MacOS: https://wahyu-ehs.medium.com/makefile-on-mac-os-2ef0e67b0a15
    * Linux: https://stackoverflow.com/questions/3915067/what-are-makefiles-make-install-etc
    * Add to Git Bash path:
```bash
(bash)

# copy the path, following on export is a command with the default installation path
which mingw32-make
export PATH=$PATH:/c/MinGW/bin
mingw32-make --version

```

* Open Docker

* Check availability of Docker through CLI:

```bash
(bash)

docker --version
docker run hello-world
```

## Running the tests

* Build initial airflow env commands in order to look for possible issues in the bash files
```bash
(bash)

docker buildx build --debug --build-arg MAINTAINER=$(grep MAINTAINER airflow_mktdata.env | cut -d '=' -f2) -f airflow-env_dockerfile -t airflow-env .
# build with no cache, in order to force reconstruction
docker buildx build --no-cache --build-arg MAINTAINER=$(grep MAINTAINER airflow_mktdata.env | cut -d '=' -f2) -f airflow-env_dockerfile -t airflow-env .
docker run -d --name airflow-env airflow-env
```

* Connect to Airflow CLI

```bash
(bash)

docker ps
docker exec -it mktdata_scheduler-airflow-webserver-1 bash

```

* Checking for import errors

```bash

(bash)

# dags
airflow dags list

# import errors
airflow dags list-import-errors

# after correcting, restart dag - example:
airflow tasks clear -d -y up2data_b3
airflow dags trigger up2data_b3

```


## Deployment - With Makefile

* Preferable

* Running Docker composes:

```bash
(bash)

mingw32-make up

```

* Connecting to database through pgadmin:

    * access http://localhost:5433/ in your local machine
    * login with email address / unsername and password configured in data / postgres_mktdata.env
![alt text](data/img/login-pgadmin.png)
    * configure server:<br>
![alt text](data/img/configure-server-1.png)
![alt text](data/img/configure-server-2.png)
![alt text](data/img/configure-server-3.png)
![alt text](data/img/configure-server-4.png)

### Restarting All Services

* No cache mode:
```bash
(bash)

mingw32-make restart_no_cache

```

* Cache mode:
```bash
(bash)

mingw32-make restart

```


## Deployment - Without Makefile

* Running Docker composes:

```bash
(bash)

# mktdata database
docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml up -d
# mktdata scheduler
docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d
```

* Connecting to database through pgadmin:

    * access http://localhost:5433/ in your local machine
    * login with email address / unsername and password configured in data / postgres_mktdata.env
![alt text](data/img/login-pgadmin.png)
    * configure server:<br>
![alt text](data/img/configure-server-1.png)
![alt text](data/img/configure-server-2.png)
![alt text](data/img/configure-server-3.png)
![alt text](data/img/configure-server-4.png)

### Restarting All Services

* Droping all services:
```bash
(bash)

# dropping all services
docker compose -f data/postgres_docker-compose.yml down -v --remove-orphans
# docker rm airflow_init
docker compose -f airflow_docker-compose.yml down -v --remove-orphans
docker rm -f airflow-env
docker system prune --volumes --force
docker network prune -f
docker image prune -a -y
# printing docker compose config
docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml config

```

* Initiating docker composes:
```bash
(bash)

# mktdata database
docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml up -d
# mktdata scheduler
docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d
```


## Error Handling

* Saving logs:
```bash
(bash)

docker compose --env-file .env -f airflow_docker-compose.yml logs > "logs/misc/logs-airflow-docker-compose_$(date +'%Y-%m-%d_%H').txt"
```

* Checking network integration between containers:

```bash
(bash)

# check previously created data
docker network ls
docker ps
docker images
# inspect if both conteiners are integrated through network
docker network inspect postgres_compose_network
# check network connectivity
docker exec -it pgadmin_container ping postgres_container
```

* Remove container with desired name in use:
```bash
(bash)

docker rm -f airflow-env
```

* Checking for remaning errors:

```bash
(bash)

docker logs <CONTAINER_NAME>
```

* Granting permissions, in case is needed:

```bash
(bash)

# error: 
#   2025-01-24 07:25:43 creating configuration files ... ok
#   2025-01-24 07:25:43 2025-01-24 10:25:43.406 UTC [83] FATAL:  data directory "/var/lib/postgresql/data" has invalid permissions
#   2025-01-24 07:25:43 2025-01-24 10:25:43.406 UTC [83] DETAIL:  Permissions should be u=rwx (0700) or u=rwx,g=rx (0750).

chmod -R 0700 ./data
chown -R $(id -u):$(id -g) ./data

chmod -R 777 dags logs plugins

docker exec -it dcs-postgres bash
chmod 0700 /var/lib/postgresql/data
chmod 0700 ./data

docker run --rm -it -v $(pwd)/postgres:/var/lib/postgresql/data alpine sh
$ (sh) rm -rf /var/lib/postgresql/*
$ (sh) exit

# check for permission - ensure the output shows the correct permissions (drwx------ or 0700).
ls -ld ./data

# ! obs: relative path cah raise errors in windows, opt for absolute paths
```


## Built With

* [Airflow Docker Compose - General](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)
* [Airflow Docker Compose - 2.10.4](https://airflow.apache.org/docs/apache-airflow/2.10.4/docker-compose.yaml)


## Authors

**Guilherme Rodrigues** 
* [GitHub](https://github.com/guilhermegor)
* [LinkedIn](https://www.linkedin.com/in/guilhermegor/)


## Inspirations

* [Gist](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)