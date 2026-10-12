# 图库清道夫官网

https://gallerycleaner.oxoz.cn 的源代码。纯 PHP，无数据库、无框架、无第三方依赖。

## 页面

| 文件 | 内容 |
| --- | --- |
| `index.php` | 首页：介绍、首屏在线体验、三步说明、功能、截图、FAQ、下载 |
| `guide.php` | 使用指南：授权、手势、标记与撤销、确认删除、找回误删、按月清理、视频与实况、设置、小技巧 |
| `demo.php` | 全屏在线体验，带键盘和按钮操作 |
| `privacy.php` / `terms.php` | 隐私政策 / 用户协议（与 App 内文本一致） |
| `404.php` | 404 页面 |

## 目录

```
website/
├── includes/          # 公共代码，不对外访问
│   ├── config.php     # 站点信息、下载链接、演示照片列表 ← 常改的都在这里
│   ├── header.php / footer.php
│   ├── simulator.php  # 在线体验的手机外壳
│   ├── legal.php      # 隐私政策、用户协议正文
│   └── icons.php
├── assets/
│   ├── css/site.css
│   ├── js/sim.js      # 在线体验：还原 App 的滑动、标记、确认、删除流程
│   ├── js/guide.js
│   ├── demo/          # 在线体验用的演示照片（插画）
│   └── img/           # 图标、App 截图
└── tools/
    └── generate_demo_photos.swift   # 重新生成演示照片
```

## 常见修改

- **App Store 上架后**：在 `includes/config.php` 填写 `IOS_DOWNLOAD_URL`，首页按钮会自动变成可点击。
- **Android 下载地址**：`ANDROID_DOWNLOAD_URL`，默认指向 GitHub Releases 的最新版本。
- **版本号**：`APP_VERSION`。
- **更换截图**：替换 `assets/img/screens/` 下同名的 jpg（宽 640px 即可）。
- **隐私政策 / 用户协议**：改 `includes/legal.php`，并同步修改 App 里的 `lib/pages/about_pages.dart`。

CSS、JS、图片的地址会自动带上文件修改时间作为版本号，更新后无需手动清缓存。

## 本地预览

需要 PHP 8.0 或更高版本：

```bash
php -S 127.0.0.1:8080 -t website
```

然后打开 http://127.0.0.1:8080 。

## 部署

把 `website/` 目录里的所有内容上传到站点根目录即可（`tools/` 和本 README 可以不传）。

**Apache**：自带的 `.htaccess` 已经配置好 404 页面、缓存、压缩，并禁止访问 `includes/` 和 `tools/`。

**Nginx** 参考配置：

```nginx
server {
    server_name gallerycleaner.oxoz.cn;
    root /var/www/gallerycleaner;
    index index.php;

    error_page 404 /404.php;

    location ~ ^/(includes|tools)/ { return 404; }

    location ~* \.(css|js|jpg|png|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location ~ \.php$ {
        try_files $uri =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/run/php/php-fpm.sock;   # 按服务器实际路径修改
    }
}
```

HTTPS 证书可以用 Let's Encrypt（`certbot --nginx -d gallerycleaner.oxoz.cn`）。
