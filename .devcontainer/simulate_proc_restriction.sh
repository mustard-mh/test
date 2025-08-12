#!/bin/bash
set -e

echo "🔒 Simulating Enterprise Runner /proc Access Restrictions"
echo "=========================================================="

# 这个脚本尝试通过多种方法模拟企业版运行器的 /proc 访问限制

# 1. 创建一个自定义的 /proc 访问包装器
echo "📝 Setting up /proc access restrictions..."

# 备份原始的一些工具
if [ ! -f /tmp/orig_ls ]; then
    cp /bin/ls /tmp/orig_ls
fi

# 创建一个受限的 ls 命令用于 /proc
sudo tee /usr/local/bin/restricted_proc_ls > /dev/null << 'EOF'
#!/bin/bash
# 模拟 hidepid=2 行为：只能看到自己的进程

if [[ "$*" == *"/proc/"*[0-9]*"/"* ]]; then
    # 如果尝试访问 /proc/[数字]/任何文件
    CURRENT_UID=$(id -u)
    
    # 提取 PID
    if [[ "$*" =~ /proc/([0-9]+) ]]; then
        TARGET_PID="${BASH_REMATCH[1]}"
        
        # 检查该进程是否属于当前用户
        if [ -r "/proc/$TARGET_PID/status" ]; then
            PROC_UID=$(awk '/^Uid:/ {print $2}' "/proc/$TARGET_PID/status" 2>/dev/null || echo "9999")
            
            if [ "$CURRENT_UID" != "$PROC_UID" ] && [ "$CURRENT_UID" != "0" ]; then
                echo "ls: cannot access '$*': Permission denied" >&2
                exit 1
            fi
        fi
    fi
fi

# 否则执行正常的 ls
exec /tmp/orig_ls "$@"
EOF

chmod +x /usr/local/bin/restricted_proc_ls

# 2. 创建受限的 cat 命令用于 /proc
sudo tee /usr/local/bin/restricted_proc_cat > /dev/null << 'EOF'  
#!/bin/bash
# 模拟对 /proc/*/cmdline 的访问限制

if [[ "$1" == "/proc/"*"/cmdline" ]]; then
    CURRENT_UID=$(id -u)
    
    if [[ "$1" =~ /proc/([0-9]+)/cmdline ]]; then
        TARGET_PID="${BASH_REMATCH[1]}"
        
        if [ -r "/proc/$TARGET_PID/status" ]; then
            PROC_UID=$(awk '/^Uid:/ {print $2}' "/proc/$TARGET_PID/status" 2>/dev/null || echo "9999")
            
            if [ "$CURRENT_UID" != "$PROC_UID" ] && [ "$CURRENT_UID" != "0" ]; then
                echo "cat: /proc/$TARGET_PID/cmdline: Permission denied" >&2
                exit 1
            fi
        fi
    fi
fi

# 执行正常的 cat
exec /bin/cat "$@"  
EOF

chmod +x /usr/local/bin/restricted_proc_cat

# 3. 创建测试脚本来验证限制效果
tee /tmp/test_proc_restrictions.sh > /dev/null << 'EOF'
#!/bin/bash

echo "🧪 Testing /proc access restrictions..."
echo ""

# 启动一些测试进程
echo "Starting test processes..."
python3 -c "import time; time.sleep(30)" &
TEST_PID1=$!

python3 -c "import socket, time; s=socket.socket(); s.bind(('',9876)); s.listen(1); time.sleep(30)" &  
TEST_PID2=$!

sleep 1

echo "Test processes started: $TEST_PID1, $TEST_PID2"
echo ""

# 测试进程信息访问
echo "=== Testing process access (should be restricted for non-root) ==="

ACCESSIBLE=0
RESTRICTED=0

for pid in $TEST_PID1 $TEST_PID2; do
    echo -n "Testing access to process $pid: "
    
    if /usr/local/bin/restricted_proc_cat "/proc/$pid/cmdline" >/dev/null 2>&1; then
        echo "✅ Accessible"
        ACCESSIBLE=$((ACCESSIBLE + 1))
    else
        echo "❌ Restricted (simulated hidepid)"
        RESTRICTED=$((RESTRICTED + 1))
    fi
done

echo ""
echo "Result: $ACCESSIBLE accessible, $RESTRICTED restricted"

# 测试 sudo 效果
echo ""
echo "=== Testing sudo effect ==="
echo "Running: sudo /usr/local/bin/restricted_proc_cat /proc/$TEST_PID1/cmdline"

if sudo /usr/local/bin/restricted_proc_cat "/proc/$TEST_PID1/cmdline"; then
    echo "✅ sudo allows access (simulating permission refresh)"
else
    echo "❌ even sudo fails"
fi

# 清理测试进程
kill $TEST_PID1 $TEST_PID2 2>/dev/null || true

echo ""
echo "=== Summary ==="
echo "This simulates how enterprise runners might restrict /proc access"
echo "causing VS Code port forwarding to show 'missing detail'"
EOF

chmod +x /tmp/test_proc_restrictions.sh

# 4. 创建 VS Code 端口扫描模拟器
tee /tmp/simulate_vscode_port_scan.sh > /dev/null << 'EOF'
#!/bin/bash

echo "🔍 Simulating VS Code port scanning behavior..."
echo ""

# 启动测试服务器
echo "Starting test servers..."
python3 -c "import socket, time; s=socket.socket(); s.bind(('',8801)); s.listen(1); print('Server on 8801'); time.sleep(60)" &
SERVER1_PID=$!

python3 -c "import socket, time; s=socket.socket(); s.bind(('',8802)); s.listen(1); print('Server on 8802'); time.sleep(60)" &  
SERVER2_PID=$!

node -e "require('http').createServer().listen(8803, () => console.log('Server on 8803')); setTimeout(() => {}, 60000)" &
SERVER3_PID=$!

sleep 2
echo "Test servers started on ports 8801, 8802, 8803"
echo ""

# 模拟 VS Code 的端口发现过程
echo "=== Simulating VS Code port discovery ==="

# 1. 扫描网络连接 (这部分通常成功)
echo "📡 Scanning network connections..."
netstat -tlnp 2>/dev/null | grep -E ":(8801|8802|8803)" | head -3

echo ""

# 2. 尝试获取进程详细信息 (这里会失败)
echo "📋 Attempting to get process details..."

for port in 8801 8802 8803; do
    echo -n "Port $port: "
    
    # 获取 PID (这通常成功)
    PID=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1)
    
    if [ -n "$PID" ] && [ "$PID" != "-" ]; then
        echo -n "PID=$PID, "
        
        # 尝试读取 cmdline (这在企业版中失败)
        if /usr/local/bin/restricted_proc_cat "/proc/$PID/cmdline" 2>/dev/null | tr '\0' ' '; then
            echo "✅ Command line accessible"
        else
            echo "❌ MISSING DETAIL - Cannot read process command line"
        fi
    else
        echo "❌ No PID found"
    fi
done

echo ""
echo "=== Testing sudo fix ==="
echo "After running sudo command..."

# 模拟 sudo 刷新权限
sudo echo "Permission refresh triggered" > /dev/null

for port in 8801 8802 8803; do
    echo -n "Port $port after sudo: "
    
    PID=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1)
    
    if [ -n "$PID" ] && [ "$PID" != "-" ]; then
        echo -n "PID=$PID, "
        
        # 用 sudo 尝试读取 (现在应该成功)
        if sudo /usr/local/bin/restricted_proc_cat "/proc/$PID/cmdline" 2>/dev/null | tr '\0' ' '; then
            echo "✅ Command line now accessible with elevated privileges"
        else
            echo "❌ Still restricted"  
        fi
    else
        echo "❌ No PID found"
    fi
done

# 清理
echo ""
echo "Cleaning up test servers..."
kill $SERVER1_PID $SERVER2_PID $SERVER3_PID 2>/dev/null || true
echo "Done!"
EOF

chmod +x /tmp/simulate_vscode_port_scan.sh

echo ""
echo "✅ Enterprise /proc restriction simulation setup complete!"
echo ""
echo "Available test scripts:"
echo "  /tmp/test_proc_restrictions.sh       - Test basic /proc access restrictions"
echo "  /tmp/simulate_vscode_port_scan.sh     - Simulate VS Code port scanning behavior"
echo ""
echo "To test the issue:"
echo "  1. Run: /tmp/simulate_vscode_port_scan.sh"
echo "  2. Observe 'MISSING DETAIL' messages"
echo "  3. See how sudo fixes the issue"
echo ""

# 运行初始演示
echo "🚀 Running initial demonstration..."
/tmp/test_proc_restrictions.sh