.DEFAULT_GOAL:= docker_airflow_up_no_cache

# project
bump_version:
	bash cli/bump_version.sh

# docker
docker_rm_rmi_airflow_env:
	@docker ps -a --filter "name=airflow-env" -q | grep -q . && docker rm airflow-env || true
	@docker rmi airflow-env:1.0 || true --force

docker_airflow_up_no_cache: docker_rm_rmi_airflow_env
	export DOCKER_BUILDKIT=1
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml up -d
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d --no-deps --build airflow-webserver airflow-scheduler

docker_airflow_up:
	export DOCKER_BUILDKIT=1
	docker build --debug -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file data/postgres_mktdata.env -f data/postgres_docker-compose.yml up -d
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d --no-deps --build airflow-webserver airflow-scheduler

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

docker_airflow_restart_no_cache: docker_airflow_down_no_cache docker_airflow_up_no_cache

docker_airflow_restart: docker_airflow_down docker_airflow_up

# build/run docker custom image
test_airflow_env_build_no_cache: docker_rm_rmi_airflow_env
	export DOCKER_BUILDKIT=1
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .

test_airflow_env_build:
	export DOCKER_BUILDKIT=1
	docker build --debug -f airflow-env_dockerfile -t airflow-env:1.0 .

# packages
test_airflow_packages_installation:
	./tests/airflow_packages_installation.sh

# system commands
check_docker:
	./shell/docker_init.sh

# git
git_pull_force:
	bash cli/git_pull_force.sh

git_create_branch_from_main:
	bash cli/git_create_branch_from_main.sh

# github
gh_status:
	bash cli/gh_status.sh

gh_protect_main: gh_status
	bash cli/gh_protect_main.sh

# requirements - dev
vscode_setup:
	bash cli/vscode_setup.sh