.DEFAULT_GOAL:= docker_airflow_up_no_cache

# project
bump_version:
	bash cli/bump_version.sh

env_build:
	bash cli/env_config.sh

airflow_change_tag:
	@if [ -z "$(AIRFLOW_VERSION)" ]; then \
		echo "Error: AIRFLOW_VERSION must be set"; \
		echo "Usage: make airflow_change_tag AIRFLOW_VERSION=x.y.z"; \
		exit 1; \
	fi
	bash cli/airflow_change_tag.sh $(AIRFLOW_VERSION)

airflow_matrix_test_versions:
	bash cli/airflow_matrix_test_versions.sh

# docker compose stack
check_docker:
	bash cli/docker_init.sh

docker_rm_rmi_airflow_env:
	@docker ps -a --filter "name=airflow-env" -q | grep -q . && docker rm airflow-env || true
	@docker rmi airflow-env:1.0 || true --force

docker_airflow_down_no_cache: docker_rm_rmi_airflow_env
	docker compose --env-file scheduler_mktdata.env -f airflow_docker-compose.yml down -v --remove-orphans
	docker system prune --volumes --force -a -f
	docker network prune -f
	docker volume prune -f
	docker builder prune -a --force
	docker image prune -a --force

docker_airflow_down:
	docker compose -f postgres_docker-compose.yml down
	docker compose -f airflow_docker-compose.yml down
	docker rm -f airflow-env:1.0

# run services
run_postgres:
	bash cli/run_postgres.sh

run_scheduler:  check_docker
	export DOCKER_BUILDKIT=1
	bash cli/kill_pids_ports.sh 5432 5433
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file scheduler_mktdata.env -f airflow_docker-compose.yml up -d

run_scheduler_no_cache: check_docker docker_airflow_down_no_cache
	export DOCKER_BUILDKIT=1
	bash cli/kill_pids_ports.sh 5432 5433
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file scheduler_mktdata.env -f airflow_docker-compose.yml up -d

run_scheduler_no_cache_logs: check_docker docker_airflow_down_no_cache
	export DOCKER_BUILDKIT=1
	bash cli/kill_pids_ports.sh 5432 5433
	docker build --no-cache -f airflow-env_dockerfile -t airflow-env:1.0 .
	docker compose --env-file scheduler_mktdata.env -f airflow_docker-compose.yml up -d || \
	( \
	  echo "=== INITIALIZATION LOGS ===" && \
	  docker compose --env-file scheduler_mktdata.env -f airflow_docker-compose.yml logs airflow-init && \
	  echo "=== API SERVER LOGS ===" && \
	  docker compose --env-file scheduler_mktdata.env -f airflow_docker-compose.yml logs airflow-apiserver && \
	  echo "=== ALL SERVICES LOGS ===" && \
	  docker compose --env-file scheduler_mktdata.env -f airflow_docker-compose.yml logs && \
	  false \
	)

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
