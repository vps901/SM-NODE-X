# SM-NODE-X

抄袭`k0baya/X-for-serv00`的脚本，但是抄的不彻底

## 项目特色
 非常节省serv00服务器的资源，服务器24小时自动关闭没有被访问的nodejs网站，这需要你用一个保活服务，这非常的不方便。但是`k0baya`的另外一个脚本可以实现访问即保活，我根据实际情况修改了这个项目。现在，只要你有一个客户端与部署在`serv00`上的Xray服务端连接，那就永远不用担心会被服务期结束了。除非服务器重启，或者你断开连接超过了24小时，不然不会被结束进程的。被结束了也没事，打开客户端PING两三次就行了。而且也能正常通过cloudflare的CDN，目前也只能使用加入了cloudflarecdn的域名。

## 如何安装

1. 登录`serv00`的SSH
2. 输入`devil www add 你将要做节点的域名 nodejs /usr/local/bin/node production`添加一个nodejs网站。
3. 进入cloudflare控制台，把域名解析到你所在的serv00服务器的IP上面，记得小黄云要打开。
   查看IP: 输入`devil vhost list`，除了s开头的都可以解析。
4. 回到控制台，输入 `cd ~/domains/你要做节点的域名 && rm -rf public_nodejs && git clone https://github.com/vps901/SM-NODE-X public_nodejs &&cd public_nodejs`
5. 输入`devil port add tcp random &&  devil port list`添加随机的TCP端口并且记下来。如果你已经有了TCP端口并且没有被占用，可以跳过此步骤。
6. 执行`bash install.sh`按照提示进行操作即可。
7. https://访问你要做节点的域名/list，可以看到一个VLESS链接，复制它，接着加入你的客户端，进行一次PING应该就可以开始使用了。

## 许可协议
`UNLICENSED`

## 其它

大家自行补充，会用的用，不会用的不用。搞这个项目原先就是想备份ChatGPT生成的代码，仅此而已，不必要做过多的解释，有BUG会改的提个PR，不会的用别的项目。我用这个脚本只是让serv00和其它的PaaS服务帮忙代理一下一些支持WireGuard协议的VPN而已。
