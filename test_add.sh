#!/bin/bash

# MemOS Add Memory API 测试脚本
# 适用于 Ubuntu 终端直接执行

# 配置参数
API_URL="http://localhost:8000/product/add"
USER_ID="user-001"
MEM_CUBE_ID="cube-001"

# 检查服务是否运行
if ! curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo "错误：MemOS 服务未在 localhost:8000 上运行"
    echo "请先启动服务"
    exit 1
fi

# 函数：添加记忆
add_memory() {
    local content="$1"
    echo "=========================================="
    echo "添加记忆: '$content'"
    echo "=========================================="

    curl -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"user_id\": \"$USER_ID\",
        \"mem_cube_id\": \"$MEM_CUBE_ID\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$content\"}],
        \"async_mode\": \"sync\"
      }" | python3 -m json.tool 2>/dev/null || cat

    echo ""
    echo ""
}

# 如果没有参数，添加默认测试数据
if [ $# -eq 0 ]; then
    echo "添加默认测试记忆..."
    echo ""

    add_memory "我喜欢蓝色，天空的那种蓝色"
    add_memory "我喜欢吃草莓味的冰淇淋"
    add_memory "我周末喜欢去公园跑步"
    add_memory "我的宠物是一只金毛犬，叫豆豆"

    echo "=========================================="
    echo "默认记忆添加完成"
    echo "=========================================="
    echo ""
    echo "现在可以用 test_search.sh 搜索这些记忆:"
    echo "  ./test_search.sh '我喜欢什么颜色'"
    echo "  ./test_search.sh '我喜欢吃什么'"
    echo "  ./test_search.sh '我的宠物叫什么名字'"
else
    # 使用命令行参数作为记忆内容
    add_memory "$1"
fi
