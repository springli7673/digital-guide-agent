# 常用操作。Windows 上没有 make 的话，把下面的命令直接抄进 PowerShell 执行。
#
# 注意：Makefile 的文件名必须是这个名字，recipe 行首必须是 TAB。

.DEFAULT_GOAL := help
SHELL := /bin/bash

BACKEND := backend
MVN     := ./mvnw
# 没装 mvnw 时退回系统 mvn
ifeq (, $(wildcard $(BACKEND)/mvnw))
MVN := mvn
endif

.PHONY: help
help: ## 显示可用命令
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

.PHONY: up
up: ## 起依赖（pg + redis + ollama）
	docker compose up -d
	@echo "等 pg 就绪后，再执行 make seed"

.PHONY: down
down: ## 停依赖（保留数据）
	docker compose down

.PHONY: clean-data
clean-data: ## 停依赖并删除数据卷（危险）
	docker compose down -v

.PHONY: logs
logs: ## 看依赖日志
	docker compose logs -f --tail=100

.PHONY: models
models: ## 拉本地模型（bge-m3 必需；qwen3:8b 只在 AI_PROVIDER=ollama 时需要）
	docker compose exec ollama ollama pull bge-m3
	docker compose exec ollama ollama pull qwen3:8b

.PHONY: build
build: ## 编译（跳过测试）
	cd $(BACKEND) && $(MVN) -B -q -DskipTests compile

.PHONY: test
test: ## 跑单测（60 条，纯逻辑，不连库不连模型）
	cd $(BACKEND) && $(MVN) -B -q test

.PHONY: run
run: ## 本地起应用（需要 DEEPSEEK_API_KEY）
	cd $(BACKEND) && $(MVN) spring-boot:run

.PHONY: ingest
ingest: ## 把 resources/kb 下的语料灌进 pgvector
	curl -s -X POST http://127.0.0.1:8080/v1/kb/ingest
	@echo

.PHONY: health
health: ## 健康检查
	curl -s http://127.0.0.1:8080/healthz
	@echo

.PHONY: eval
eval: ## 跑评测（全量 40 条；需要服务和 key 都在）
	cd $(BACKEND) && $(MVN) -q exec:java -Dexec.mainClass=com.digitalguide.ai.eval.EvalMain

.PHONY: web
web: ## 起前端（:5173）
	cd web && node server.mjs
