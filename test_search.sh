#!/bin/bash

# MemOS Search API 测试脚本
# 适用于 Ubuntu 终端直接执行

# 配置参数
API_URL="http://localhost:8000/product/search"
USER_ID="user-001"
MEM_CUBE_ID="cube-001"

# 检查服务是否运行
if ! curl -s http://localhost:8000/healthz > /dev/null 2>&1 && ! curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo "错误：MemOS 服务未在 localhost:8000 上运行"
    echo "请先启动服务："
    echo "  cd /root/PycharmProjects/MemOS/src && HF_ENDPOINT=https://hf-mirror.com uvicorn memos.api.server_api:app --host 0.0.0.0 --port 8000 --workers 1"
    exit 1
fi

# 测试 1：简单搜索测试
echo "=========================================="
echo "测试 1：搜索 '我喜欢什么颜色'"
echo "=========================================="

curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"我喜欢什么颜色\",
    \"user_id\": \"$USER_ID\",
    \"mem_cube_id\": \"$MEM_CUBE_ID\"
  }" | python3 -m json.tool 2>/dev/null || cat

echo ""
echo ""

# 测试 2：自定义查询（从命令行参数读取）
if [ -n "$1" ]; then
    echo "=========================================="
    echo "测试 2：自定义搜索 '$1'"
    echo "=========================================="

    curl -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"query\": \"$1\",
        \"user_id\": \"$USER_ID\",
        \"mem_cube_id\": \"$MEM_CUBE_ID\"
      }" | python3 -m json.tool 2>/dev/null || cat

    echo ""
fi

echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "使用说明："
echo "  ./test_search.sh           # 运行默认测试"
echo "  ./test_search.sh '你的问题' # 自定义搜索内容"
