# MemOS 部署与启动指南

本文档记录 MemOS 项目在虚拟环境中的完整部署流程，分为**首次安装**和**日常启动**两部分。

---

## 第一部分：从空环境开始部署（首次安装）

### 1. 前置条件

确保系统已安装以下软件：
- Python 3.11+
- Conda 或 Miniconda
- Neo4j Community Edition
- Qdrant
- RabbitMQ

### 2. 创建并激活虚拟环境

```bash
# 创建虚拟环境（Python 3.11）
conda create -n memos python=3.11 -y

# 激活虚拟环境
conda activate memos
```

### 3. 克隆项目并安装依赖

```bash
# 进入项目目录
cd /root/PycharmProjects/MemOS

# 安装依赖
pip install -r ./docker/requirements.txt
```

### 4. 配置环境变量

复制并编辑 `.env` 文件：

```bash
# 复制示例配置文件（如需要）
# cp docker/.env.example .env

# 编辑 .env 文件，确保以下关键配置正确
```

**关键配置项：**

```bash
# Neo4j 配置
NEO4J_BACKEND=neo4j-community
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=12345678          # 必须与Neo4j实际密码一致
NEO4J_DB_NAME=neo4j

# Qdrant 配置
QDRANT_HOST=localhost
QDRANT_PORT=6333

# RabbitMQ 配置
MEMSCHEDULER_RABBITMQ_HOST_NAME=localhost
MEMSCHEDULER_RABBITMQ_USER_NAME=memos
MEMSCHEDULER_RABBITMQ_PASSWORD=memos123
MEMSCHEDULER_RABBITMQ_VIRTUAL_HOST=memos
MEMSCHEDULER_RABBITMQ_PORT=5672

# LLM API 配置（使用 SiliconFlow）
OPENAI_API_KEY=token-abc123
OPENAI_API_BASE=http://localhost:8765/v1
MOS_CHAT_MODEL=/root/autodl-tmp/modelscope_cache/models/Qwen/Qwen3-4B
Context_Length=4096

# Embedding 配置
MOS_EMBEDDER_API_KEY=sk-xxx
MOS_EMBEDDER_API_BASE=https://api.siliconflow.cn/v1
MOS_EMBEDDER_MODEL=BAAI/bge-m3

# HuggingFace 镜像（解决国内访问问题）
export HF_ENDPOINT=https://hf-mirror.com
```

### 5. 配置数据库

#### 5.1 重置 Neo4j 密码

```bash
# 停止 Neo4j
neo4j stop

# 设置初始密码（仅首次需要）
neo4j-admin dbms set-initial-password 12345678

# 启动 Neo4j
neo4j start
```

#### 5.2 启动 Qdrant

```bash
# 进入 Qdrant 目录并启动（需在 /opt/qdrant 目录下运行）
cd /opt/qdrant
nohup ./qdrant > qdrant.log 2>&1 &
```

#### 5.3 安装并配置 RabbitMQ

```bash
# 安装 RabbitMQ（Ubuntu/Debian）
apt-get update
apt-get install -y rabbitmq-server

# 启动 RabbitMQ（无 systemd 环境）
rabbitmq-server -detached

# 创建虚拟主机
rabbitmqctl add_vhost memos

# 创建用户并授权
rabbitmqctl add_user memos memos123
rabbitmqctl set_user_tags memos administrator
rabbitmqctl set_permissions -p memos memos ".*" ".*" ".*"
```

### 6. 启动 MemOS 服务

```bash
# 进入源码目录
cd /root/PycharmProjects/MemOS/src

# 设置 HuggingFace 镜像并启动服务
HF_ENDPOINT=https://hf-mirror.com uvicorn memos.api.server_api:app --host 0.0.0.0 --port 8000 --workers 1
```

### 7. 验证安装

服务启动后，测试 API：

```bash
# 测试添加记忆
curl -X POST http://localhost:8000/product/add \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-001",
    "mem_cube_id": "test-cube-001",
    "messages": [{"role": "user", "content": "我喜欢吃草莓"}],
    "async_mode": "sync"
  }'

# 测试搜索记忆
curl -X POST http://localhost:8000/product/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "我喜欢什么",
    "user_id": "test-user-001",
    "mem_cube_id": "test-cube-001"
  }'
```

---

## 第二部分：日常启动（环境与软件已配置好）

机器重启后，按以下步骤启动整个 MemOS 环境：

### 1. 启动数据库服务

```bash
# 启动 Neo4j
neo4j start

# 启动 RabbitMQ（无 systemd 环境）
rabbitmq-server -detached

# 启动 Qdrant
cd /opt/qdrant && nohup ./qdrant > qdrant.log 2>&1 &

# 启动 vLLM
conda activate memos
nohup python -m vllm.entrypoints.openai.api_server --model /root/autodl-tmp/modelscope_cache/models/Qwen/Qwen3-4B --port 8765 --host 0.0.0.0 > /root/vllm.log 2>&1 &
```

### 2. 停止所有服务

```bash
# 停止 MemOS 服务
pkill -f "uvicorn.*server_api"

# 停止 vLLM 服务
pkill -f "vllm.entrypoints"

# 停止 Neo4j
neo4j stop

# 停止 RabbitMQ
rabbitmqctl stop

# 停止 Qdrant
pkill -f "/opt/qdrant/qdrant"
```

### 2. 激活虚拟环境

```bash
conda activate memos
```

### 3. 启动 MemOS 服务

```bash
cd /root/PycharmProjects/MemOS/src

# 前台运行（调试模式）
HF_ENDPOINT=https://hf-mirror.com uvicorn memos.api.server_api:app --host 0.0.0.0 --port 8000 --workers 1

# 或使用 nohup 后台运行
nohup HF_ENDPOINT=https://hf-mirror.com uvicorn memos.api.server_api:app --host 0.0.0.0 --port 8000 --workers 1 > memos.log 2>&1 &
```

### 4. 验证服务状态

```bash
# 检查所有服务端口
lsof -i :8000    # MemOS
lsof -i :8765    # vLLM
lsof -i :7687    # Neo4j
lsof -i :6333    # Qdrant
lsof -i :5672    # RabbitMQ

# 或使用 netstat/ss
ss -tlnp | grep -E '8000|8765|7687|6333|5672'

# 测试 API
curl -X POST http://localhost:8000/product/add \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user-001","mem_cube_id":"cube-001","messages":[{"role":"user","content":"测试"}],"async_mode":"sync"}'
```

---

## 附录：Windows 远程访问

### 通过 SSH 端口转发

在 Windows PowerShell 执行：

```powershell
ssh -p 26611 -L 8000:localhost:8000 root@connect.bjb2.seetacloud.com
```

然后 Windows 访问：
- API: `http://localhost:8000/product/add`
- 文档: `http://localhost:8000/docs`

### 常用 API 测试（Windows PowerShell）

```powershell
# 添加记忆
curl -X POST http://localhost:8000/product/add `
  -H "Content-Type: application/json" `
  -d '{\"user_id\":\"user-001\",\"mem_cube_id\":\"cube-001\",\"messages\":[{\"role\":\"user\",\"content\":\"我喜欢蓝色\"}],\"async_mode\":\"sync\"}'

# 搜索记忆
curl -X POST http://localhost:8000/product/search `
  -H "Content-Type: application/json" `
  -d '{\"query\":\"我喜欢什么颜色\",\"user_id\":\"user-001\",\"mem_cube_id\":\"cube-001\"}'
```

---

## 常见问题

### 1. Neo4j 认证失败
```bash
# 重置密码
neo4j stop
neo4j-admin dbms set-initial-password 12345678
neo4j start
```

### 2. HuggingFace 下载失败
```bash
# 使用镜像
export HF_ENDPOINT=https://hf-mirror.com
```

### 3. RabbitMQ 连接失败
```bash
# 检查 RabbitMQ 状态
rabbitmqctl status

# 重新创建用户（如需要）
rabbitmqctl add_user memos memos123
rabbitmqctl set_permissions -p memos memos ".*" ".*" ".*"
```

### 4. 查看服务日志
```bash
# MemOS 日志（如使用 nohup）
tail -f /root/PycharmProjects/MemOS/src/memos.log

# vLLM 日志
tail -f /root/vllm.log

# Neo4j 日志
tail -f /var/log/neo4j/debug.log

# RabbitMQ 日志
tail -f /var/log/rabbitmq/rabbit@*.log
```

---

## 服务端口一览

| 服务 | 端口 | 说明 |
|------|------|------|
| MemOS API | 8000 | 主服务端口 |
| vLLM | 8765 | 本地 LLM 服务 |
| Neo4j Bolt | 7687 | 图数据库 |
| Neo4j HTTP | 7474 | Neo4j 浏览器 |
| Qdrant | 6333 | 向量数据库 |
| Qdrant gRPC | 6334 | 向量数据库 gRPC |
| RabbitMQ | 5672 | 消息队列 |
| RabbitMQ Mgmt | 15672 | 管理界面（如启用）|

---

*文档生成时间：2026-03-25*
*MemOS 版本：2.0 Stardust*
