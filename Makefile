COMPOSE = docker compose -p ct-apt-dev -f apt_repository/codebase/compose.yml

.PHONY: build up down verify
build:
	$(COMPOSE) build
up:
	$(COMPOSE) up -d --wait
down:
	$(COMPOSE) down
verify:
	bash scripts/verify.sh
