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

# clean compose stack
check_docker:
	bash cli/docker_init.sh

docker_rm_rmi_airflow_env:
	@docker ps -a --filter "name=airflow-xpn" -q | grep -q . && docker rm airflow-xpn || true
	@docker rmi airflow-xpn:1.0 || true --force

docker_airflow_down_no_cache: docker_rm_rmi_airflow_env
	docker compose --env-file .env -f airflow_docker-compose.yml down -v --remove-orphans
	docker system prune --volumes --force -a -f
	docker network prune -f
	docker volume prune -f
	docker builder prune -a --force
	docker image prune -a --force

docker_airflow_down:
	docker compose -f postgres_docker-compose.yml down
	docker compose -f airflow_docker-compose.yml down
	docker rm -f airflow-xpn:1.0

docker_postgres_down:
	docker compose -f postgres_docker-compose.yml down -v
	rm -rf ~/Downloads/mktdata_storage

clean_ports:
	bash cli/kill_pids_ports.sh 5432 5433

# run services
run_db:
	bash cli/run_postgres.sh

check_db_creation:
	docker exec -it postgres_mktdata psql -U postgres -c "\l"
	docker exec -it postgres_mktdata psql -U postgres -d mktdata_collector -c "\dn+"

run_scheduler: check_docker
	export DOCKER_BUILDKIT=1
	docker build --no-cache -f airflow-env_dockerfile -t airflow-xpn:1.0 .
	docker compose --env-file .env -f airflow_docker-compose.yml up -d

run_scheduler_no_cache: check_docker docker_airflow_down_no_cache
	export DOCKER_BUILDKIT=1
	docker build --no-cache -f airflow-env_dockerfile -t airflow-xpn:1.0 .
	docker compose --env-file .env -f airflow_docker-compose.yml up -d

run_scheduler_no_cache_logs: check_docker docker_airflow_down_no_cache
	export DOCKER_BUILDKIT=1
	docker build --no-cache -f airflow-env_dockerfile -t airflow-xpn:1.0 .
	docker compose --env-file .env -f airflow_docker-compose.yml up -d || \
	( \
	  echo "=== INITIALIZATION LOGS ===" && \
	  docker compose --env-file .env -f airflow_docker-compose.yml logs airflow-init && \
	  echo "=== API SERVER LOGS ===" && \
	  docker compose --env-file .env -f airflow_docker-compose.yml logs airflow-apiserver && \
	  echo "=== ALL SERVICES LOGS ===" && \
	  docker compose --env-file .env -f airflow_docker-compose.yml logs && \
	  false \
	)
	@echo "\n=== Checking /opt/airflow directory contents ==="
	@SCHEDULER_CONTAINER=$$(docker ps --filter "name=airflow-scheduler" --format "{{.Names}}") && \
	if [ -n "$$SCHEDULER_CONTAINER" ]; then \
		echo "Found scheduler container: $$SCHEDULER_CONTAINER"; \
		echo "Directory listing of /opt/airflow:"; \
		docker exec $$SCHEDULER_CONTAINER ls -la /opt/airflow; \
		echo "\n=== Checking .env file ==="; \
		docker exec $$SCHEDULER_CONTAINER ls -la /opt/airflow/.env || echo ".env file not found"; \
		echo "\n=== Checking environment variables ==="; \
		docker exec $$SCHEDULER_CONTAINER printenv | grep -E "POSTGRES|AIRFLOW"; \
		echo "\n=== Checking stpstone version ==="; \
		docker exec $$SCHEDULER_CONTAINER python -c "import stpstone; print(f'stpstone version: {stpstone.__version__}')" || \
		(echo "Failed to check stpstone version in container $$SCHEDULER_CONTAINER"; exit 1); \
	else \
		echo "Could not find running airflow-scheduler container"; \
		echo "Current running containers:"; \
		docker ps --format "table {{.Names}}\t{{.Status}}"; \
		exit 1; \
	fi

run_stack_no_cache_logs: docker_airflow_down_no_cache docker_postgres_down clean_ports run_db run_scheduler_no_cache_logs

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
