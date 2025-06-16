.DEFAULT_GOAL:= docker_airflow_up_no_cache

# project
bump_version:
	bash cli/bump_version.sh

env_build:
	bash cli/env_config.sh

# docker compose stack
check_docker:
	bash cli/docker_init.sh

docker_rm_rmi_airflow_env:
	@docker ps -a --filter "name=airflow-env" -q | grep -q . && docker rm airflow-env || true
	@docker rmi airflow-env:1.0 || true --force

docker_airflow_down_no_cache: docker_rm_rmi_airflow_env
	docker compose --env-file postgres_mktdata.env -f postgres_docker-compose.yml down -v --remove-orphans
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml down -v --remove-orphans
	docker system prune --volumes --force -a -f
	docker network prune -f
	docker volume prune -f
	docker builder prune -a --force
	docker image prune -a --force

docker_airflow_down:
	docker compose -f postgres_docker-compose.yml down
	docker compose -f airflow_docker-compose.yml down
	docker rm -f airflow-env:1.0

run_compose_stack:
	export DOCKER_BUILDKIT=1
	docker build --debug --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker run --rm -e AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@host.docker.internal/airflow airflow-env:1.0 airflow db migrate
	docker compose --env-file postgres_mktdata.env -f postgres_docker-compose.yml up -d
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d

run_compose_stack_no_cache: check_docker docker_airflow_down_no_cache
	export DOCKER_BUILDKIT=1
	bash cli/kill_pids_ports.sh 5432 5433
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file postgres_mktdata.env -f postgres_docker-compose.yml up -d
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml up -d || \
	(docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml logs airflow-apiserver && false)
	docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml logs

test_postgres_env:
	bash cli/test_postgres_env.sh

test_airflow_packages_installation:
	./cli/test_airflow_packages_installation.sh

# git
precommit_update:
	poetry run pre-commit install
	poetry run pre-commit install --hook-type commit-msg

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
