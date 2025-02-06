#!/bin/bash

# 获取用户输入
read -p "请输入端口号: " user_port
read -p "请输入你的邮箱: " user_email
read -p "请输入你的ws路径: " ws_path
read -p "请输入你的域名: " domain

# 生成UUID
uuid=$(uuidgen)

# 创建 config.json 文件
cat <<EOF > config.json
{
  "log": {
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": $user_port,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "level": 0,
            "email": "$user_email"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/$ws_path"
        }
      }
    }
  ],
  "outbounds": []
}
EOF

# 创建 App.js 文件
cat <<EOF > App.js
const http = require('http');
const { exec, execSync } = require('child_process');
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;
const webCommand = './web.js -c config.json';
const webPort = $user_port;

// 自动检测并运行 Web.js
function checkAndRunWeb() {
  try {
    const output = execSync(\`pgrep -f "\${webCommand}"\`).toString();
    if (output) {
      console.log('Web.js 已经在运行中。');
      return;
    }
  } catch (err) {
    console.log('Web.js 未运行，正在启动...');
    exec(webCommand, (error) => {
      if (error) {
        console.error(\`启动 Web.js 失败: \${error.message}\`);
      } else {
        console.log('Web.js 已启动。');
      }
    });
  }
}
checkAndRunWeb();

// 配置静态文件夹
app.use('/', express.static('public'));

// 读取 vless.txt 和 clash.txt 文件
const vlessFilePath = path.join(__dirname, 'vless.txt');
const clashFilePath = path.join(__dirname, 'clash.txt');

let vlessAddress = '';
let clashConfig = '';

try {
  vlessAddress = fs.readFileSync(vlessFilePath, 'utf-8').trim();
} catch (err) {
  console.error(\`读取 vless.txt 失败: \${err.message}\`);
}

try {
  clashConfig = fs.readFileSync(clashFilePath, 'utf-8').trim();
} catch (err) {
  console.error(\`读取 clash.txt 失败: \${err.message}\`);
}

// 检查是否成功读取文件内容
if (!vlessAddress || !clashConfig) {
  console.error('读取配置文件失败，请重新运行 install.sh 脚本。');
  process.exit(1);
}

// 访问 /list 返回文本文档
app.get('/list', (req, res) => {
  if (!vlessAddress) {
    res.status(500).send('读取配置文件失败，请重新运行 install.sh 脚本。');
    return;
  }
  const responseText = \`VLESS连接\\n\\n\${vlessAddress}\\n\\nCLASH订阅访问 /sub\`;
  res.type('text/plain').send(responseText);
});

// 代理 WebSocket 请求到 Web.js 的 WebSocket 服务
app.use('/$ws_path', createProxyMiddleware({
  target: \`http://127.0.0.1:\${webPort}/$ws_path\`,
  ws: true,
  changeOrigin: true,
  pathRewrite: {
    '^/$ws_path': '' // 移除 /$ws_path 前缀以正确映射到 Web.js 的路径
  }
}));

// 打印当前进程状态
app.get('/status', (req, res) => {
  exec('ps -aux', (error, stdout, stderr) => {
    if (error) {
      res.status(500).send(\`执行失败: \${error.message}\`);
      return;
    }
    res.type('text/plain').send(stdout);
  });
});

// 重启用户所有进程
app.get('/restart', (req, res) => {
  exec('killall -u $USER', (error) => {
    if (error) {
      res.status(500).send(\`重启失败: \${error.message}\`);
      return;
    }
    res.send('用户进程已重启。');
  });
});

// Clash 订阅
app.get('/sub', (req, res) => {
  if (!clashConfig) {
    res.status(500).send('读取配置文件失败，请重新运行 install.sh 脚本。');
    return;
  }
  res.type('text/plain').send(clashConfig);
});

// 启动服务
app.listen(port, () => {
  console.log(\`应用正在监听 http://localhost:\${port}\`);
});
EOF

# 创建 vless.txt 文件
cat <<EOF > vless.txt
vless://$uuid@$domain:443?allowInsecure=false&alpn=h2%2Chttp%2F1.1&fp=chrome&host=$domain&path=%2F$ws_path&security=tls&sni=$domain&type=ws#pl-warp-cf-vl
EOF

# 创建 clash.txt 文件
cat <<EOF > clash.txt
port: 7890
socks-port: 7891
allow-lan: true
mode: rule
log-level: info
proxies:
  - name: "PL-VLESS-CFWARP"
    type: vless
    server: $domain
    port: 443
    uuid: $uuid
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: false
    servername: $domain
    network: ws
    ws-opts:
      path: /$ws_path
      headers:
        Host: $domain
EOF

# 运行npm测试
npm run test

echo "安装完成，访问 http://$domain/list 获得信息。"
