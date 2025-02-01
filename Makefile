.DEFAULT_GOAL:= docker_airflow_up


### DEPLOYMENT COMMANDS ###
docker_rm_rmi_airflow_env:
	@docker ps -a --filter "name=airflow-env" -q | grep -q . && docker rm airflow-env || true
	@docker rmi airflow-env:1.0 || true --force

docker_airflow_up_no_cache: docker_rm_rmi_airflow_env
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml up -d
	# docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d --no-deps --build airflow-webserver airflow-scheduler
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d --build airflow-webserver airflow-scheduler

docker_airflow_up:
	docker build -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml up -d
	# docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d --no-deps --build airflow-webserver airflow-scheduler
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d --build airflow-webserver airflow-scheduler

docker_airflow_down_no_cache: docker_rm_rmi_airflow_env
	docker compose -f data/postgres_docker-compose.yml down -v --remove-orphans
	docker compose -f airflow_docker-compose.yml down -v --remove-orphans
	docker system prune --volumes --force
	docker network prune -f
	docker volume prune -f
	docker builder prune -a --force
	docker image prune -a --force

docker_airflow_down:
	docker compose -f data/postgres_docker-compose.yml down
	docker compose -f airflow_docker-compose.yml down
	docker rm -f airflow-env:1.0

docker_airflow_restart_no_cache: docker_airflow_down_no_cache docker_airflow_up

docker_airflow_restart: docker_airflow_down docker_airflow_up


### TESTING COMMANDS ###

# build/run docker custom image
test_airflow_env_build:
	docker build --debug -f airflow-env_dockerfile -t airflow-env:1.0 \
		--build-arg USER=$(grep USER airflow_mktdata.env | cut -d '=' -f2) \
		--build-arg AIRFLOW_UID=$(grep AIRFLOW_UID airflow_mktdata.env | cut -d '=' -f2) .

test_airflow_env_build_no_cache: docker_rm_rmi_airflow_env
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 \
		--build-arg USER=$(grep USER airflow_mktdata.env | cut -d '=' -f2) \
		--build-arg AIRFLOW_UID=$(grep AIRFLOW_UID airflow_mktdata.env | cut -d '=' -f2) .

test_airflow_env_build_run: test_airflow_env_build
	docker run -d --name airflow-env airflow-env:1.0

test_airflow_env_build_run_no_cache: test_airflow_env_build_no_cache
	docker run -d --name airflow-env airflow-env:1.0

# packages
test_airflow_packages_installation:
	./tests/airflow_packages_installation.sh


### SYSTEM COMMANDS ###
check_docker:
	./shell/docker_init.sh