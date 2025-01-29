.DEFAULT_GOAL:= up

### DEPLOYMENT COMMANDS ###
up:
	docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml up -d
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d

down_no_cache:
	docker compose -f data/postgres_docker-compose.yml down -v --remove-orphans
	docker compose -f airflow_docker-compose.yml down -v --remove-orphans
	docker rm -f airflow-env
	docker system prune --volumes --force
	docker network prune -f
	docker volume prune -f
	docker builder prune -a --force
	docker image prune -a --force

down:
	docker compose -f data/postgres_docker-compose.yml down
	docker compose -f airflow_docker-compose.yml down

restart_no_cache: down_no_cache up

restart: down up


### TESTING COMMANDS ###

# build/run docker custom image
test_airflow_env_build:
	docker buildx build --debug --build-arg MAINTAINER=$(grep MAINTAINER airflow_mktdata.env | cut -d '=' -f2) -f airflow-env_dockerfile -t airflow-env .

test_airflow_env_build_no_cache:
	docker buildx build --no-cache --build-arg MAINTAINER=$(grep MAINTAINER airflow_mktdata.env | cut -d '=' -f2) -f airflow-env_dockerfile -t airflow-env .

test_airflow_env_run: test_airflow_env_build
	docker run -d --name airflow-env airflow-env

test_airflow_env_run_no_cache: test_airflow_env_build_no_cache
	docker run -d --name airflow-env airflow-env
	docker rm airflow-env
	docker rmi airflow-env

# containers integrity
test_airflow_packages:
	./shell/test_airflow_packages.sh


### SYSTEM COMMANDS ###
check_docker:
	./shell/docker_init.sh