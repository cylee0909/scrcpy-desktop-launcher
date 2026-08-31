# sc.sh

一个面向 macOS 的 `scrcpy` 启动脚本，用独立的桌面尺寸虚拟显示器运行 Android 应用，并针对键鼠操作、输入法和部分竖屏应用做了适配。

## 功能

- 默认启动飞书，支持通过应用名称或包名启动其他应用
- 使用 UHID 键盘和鼠标，改善桌面端操作体验
- 创建 `1600x900` 虚拟显示器，并以全屏窗口运行
- 微信自动改用 `900x1600` 竖屏虚拟显示器
- 为飞书临时启用 Android 兼容性设置，退出后自动恢复
- 额外的 `scrcpy` 参数可直接透传

## 依赖

- macOS
- `zsh`
- Android Platform Tools（`adb`）
- 支持 `--new-display`、`--start-app` 等选项的较新版本 `scrcpy`
- 已通过 `adb devices` 连接并授权的 Android 设备

可使用 Homebrew 安装主要依赖：

```sh
brew install android-platform-tools scrcpy
```

## 安装

```sh
git clone git@github.com:cylee0909/sc.sh.git
cd sc.sh
chmod +x sc.sh
```

如需在任意目录调用，可以建立符号链接：

```sh
ln -s "$PWD/sc.sh" /usr/local/bin/sc
```

## 使用

不传参数时默认启动飞书：

```sh
./sc.sh
```

使用内置中文名称：

```sh
./sc.sh 微信
./sc.sh 微信读书
./sc.sh 飞书
./sc.sh 抖音
```

直接传入 Android 包名：

```sh
./sc.sh com.example.app
```

对于其他应用，也可以传入 `scrcpy --list-apps` 显示的完整应用名称。名称必须完全匹配。

额外参数会继续传给 `scrcpy`：

```sh
./sc.sh 微信 --no-audio
./sc.sh com.example.app --max-fps=30
```

## 设备相关配置

脚本目前会切换到小米版搜狗输入法：

```text
com.sohu.inputmethod.sogou.xiaomi/.SogouIME
```

同时固定使用高通 H.264 编码器：

```text
c2.qti.avc.encoder
```

如果设备未安装该输入法，或不提供这个编码器，请在 `sc.sh` 中替换相应配置。可通过以下命令查看设备支持的编码器：

```sh
scrcpy --list-encoders
```

## License

本项目暂未指定开源许可证。
