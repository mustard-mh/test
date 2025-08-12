#!/bin/bash
set -e

echo "🔧 Setting up Enterprise Permission Simulation..."

# 简单的权限检查脚本
tee /tmp/check_permissions.sh > /dev/null << 'EOF'
#!/bin/bash
echo "=== Permission Status ==="
echo "User: $(whoami) ($(id -u))"
echo "Groups: $(groups)"

# 检查进程访问
ACCESSIBLE=0
for pid in $(ps -eo pid --no-headers | head -5); do
    if [ -r "/proc/$pid/cmdline" ] 2>/dev/null; then
        ACCESSIBLE=$((ACCESSIBLE + 1))
    fi
done

echo "Accessible processes: $ACCESSIBLE/5"
[ $ACCESSIBLE -eq 0 ] && echo "❌ NO ACCESS - Will cause missing detail" || echo "✅ Has access"
EOF

# 快速测试脚本
tee /tmp/test_port_forwarding.sh > /dev/null << 'EOF'  
#!/bin/bash
echo "🚀 Testing Port Forwarding Issue..."

# 启动测试服务器
python3 -c "import socket,time; s=socket.socket(); s.bind(('',8888)); s.listen(1); print('Server on 8888 started'); time.sleep(3)" &
SERVER_PID=$!

sleep 1

echo ""
echo "=== Before sudo ==="
/tmp/check_permissions.sh

echo ""
echo "Port 8888 process info:"
PID=$(lsof -ti :8888 2>/dev/null | head -1)
if [ -n "$PID" ]; then
    echo -n "PID $PID cmdline: "
    if cat "/proc/$PID/cmdline" 2>/dev/null; then
        echo "✅ Readable"
    else
        echo "❌ Permission denied (missing detail)"
    fi
fi

echo ""
echo "Running: sudo ls /proc > /dev/null"
sudo ls /proc > /dev/null

echo ""
echo "=== After sudo ==="
/tmp/check_permissions.sh

if [ -n "$PID" ]; then
    echo -n "PID $PID cmdline: "
    if cat "/proc/$PID/cmdline" 2>/dev/null; then
        echo "✅ Now readable - sudo fixed it!"
    else
        echo "❌ Still denied"
    fi
fi

kill $SERVER_PID 2>/dev/null || true
EOF

chmod +x /tmp/check_permissions.sh /tmp/test_port_forwarding.sh

echo "✅ Setup complete!"
echo ""
echo "Test scripts:"
echo "  /tmp/test_port_forwarding.sh  - Main test"
echo "  /tmp/check_permissions.sh     - Check permissions"
echo ""
echo "Run: /tmp/test_port_forwarding.sh"