.PHONY: setup dev stop test lint check migration db-push functions-deploy \
        infra-init-dev infra-plan-dev infra-apply-dev \
        infra-init-prod infra-plan-prod

# ── Local dev ──────────────────────────────────────────────────────────────────

setup: ## Install Flutter deps and start local Supabase
	flutter pub get
	supabase start

dev: ## Start local Supabase stack
	supabase start

stop: ## Stop local Supabase stack
	supabase stop

# ── Code quality ───────────────────────────────────────────────────────────────

lint: ## Run dart analyzer (fatal on infos)
	dart analyze --fatal-infos

test: ## Run Flutter tests with coverage
	flutter test --coverage

check: lint test ## Run lint + tests (use before pushing)

# ── Database ───────────────────────────────────────────────────────────────────

migration: ## Generate a new migration from local schema changes
	@read -p "Migration name (snake_case): " name; \
	supabase db diff -f $$name

db-push: ## Push migrations to the linked remote project
	supabase db push

db-reset: ## Reset local DB and re-run all migrations + seed
	supabase db reset

# ── Edge Functions ─────────────────────────────────────────────────────────────

functions-deploy: ## Deploy all Edge Functions to the linked remote project
	supabase functions deploy generate-bill-quiz
	supabase functions deploy aggregate-news

functions-serve: ## Serve Edge Functions locally for development
	supabase functions serve

# ── OpenTofu (dev) ─────────────────────────────────────────────────────────────

infra-init-dev: ## Init OpenTofu for dev environment
	cd infra/environments/dev && tofu init

infra-plan-dev: ## Plan OpenTofu changes for dev
	cd infra/environments/dev && tofu plan

infra-apply-dev: ## Apply OpenTofu changes to dev (maintainers only)
	cd infra/environments/dev && tofu apply

# ── OpenTofu (prod) ────────────────────────────────────────────────────────────
# Prod apply is CI/CD only. Plan is available for local review.

infra-init-prod: ## Init OpenTofu for prod environment
	cd infra/environments/prod && tofu init

infra-plan-prod: ## Plan OpenTofu changes for prod (review only — apply is CI/CD)
	cd infra/environments/prod && tofu plan

# ── Help ───────────────────────────────────────────────────────────────────────

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
