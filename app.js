const http = require('http');
const { exec, execSync } = require('child_process');
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;
const webCommand = process.env.WEB_COMMAND || './web.js -c config.json';
const webPort = process.env.WEB_PORT || 3001;
const websocketPath = process.env.WEBSOCKET_PATH || '/ws-vless';
const websocketRoute = process.env.WEBSOCKET_ROUTE || '/ws';

// 自动检测并运行 Web.js
function checkAndRunWeb() {
  try {
    const output = execSync(`pgrep -f "${webCommand}"`).toString();
    if (output) {
      console.log('Web.js 已经在运行中。');
      return;
    }
  } catch (err) {
    console.log('Web.js 未运行，正在启动...');
    exec(webCommand, (error) => {
      if (error) {
        console.error(`启动 Web.js 失败: ${error.message}`);
      } else {
        console.log('Web.js 已启动。');
      }
    });
  }
}
checkAndRunWeb();

// 配置静态文件夹
app.use('/', express.static('public'));

// 代理 WebSocket 请求到 Web.js 的 WebSocket 服务
app.use(websocketRoute, createProxyMiddleware({
  target: `http://127.0.0.1:${webPort}${websocketPath}`,
  ws: true,
  changeOrigin: true,
  pathRewrite: {
    [`^${websocketRoute}`]: '' // 移除 WebSocket 路由前缀以正确映射到 Web.js 的路径
  }
}));

// 重启用户所有进程
app.get('/restart', (req, res) => {
  exec('killall -u $USER', (error) => {
    if (error) {
      res.status(500).send(`重启失败: ${error.message}`);
      return;
    }
    res.send('用户进程已重启。');
  });
});

// 启动服务
app.listen(port, () => {
  console.log(`应用正在监听 http://localhost:${port}`);
});
