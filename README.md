# sc.sh

[![CI](https://github.com/cylee0909/sc.sh/actions/workflows/ci.yml/badge.svg)](https://github.com/cylee0909/sc.sh/actions/workflows/ci.yml)

`sc.sh` 是一个面向 macOS 的 Android 桌面应用启动器。它基于 [scrcpy](https://github.com/Genymobile/scrcpy) 的虚拟显示能力，为键鼠操作、中文输入法以及部分手机应用的横竖屏行为提供了更适合桌面的默认配置。

## 特性

- 通过中文名、英文别名、完整应用名或包名启动应用
- 默认创建 `1600x900` 桌面虚拟显示器，微信自动使用竖屏布局
- 使用 UHID 键盘和鼠标，降低 Android 应用与桌面输入习惯之间的差异
- 自动检查依赖、ADB 连接状态和目标应用
- 临时切换输入法与 Android 兼容性选项，退出时恢复原始状态
- 支持多设备选择、编码器覆盖、诊断及 dry-run
- 原样透传额外的 scrcpy 参数

## 系统要求

- macOS 与 `zsh`
- Android Platform Tools（`adb`）
- 支持虚拟显示相关参数的较新版本 `scrcpy`（可通过 `sc --doctor` 验证）
- 一台已开启 USB 调试并完成 ADB 授权的 Android 设备

使用 Homebrew 安装依赖：

```sh
brew install android-platform-tools scrcpy
```

连接设备后可先确认状态：

```sh
adb devices
```

## 安装

```sh
git clone https://github.com/cylee0909/sc.sh.git
cd sc.sh
make install
```

默认安装为 `/usr/local/bin/sc`。可以通过 `PREFIX` 修改安装目录：

```sh
make install PREFIX="$HOME/.local"
```

确保对应的 `bin` 目录位于 `PATH` 中。卸载命令：

```sh
make uninstall
```

也可以不安装，直接运行 `./sc.sh`。

## 快速开始

```sh
# 默认启动飞书
sc

# 使用内置别名
sc 微信
sc weread
sc douyin

# 使用 Android 包名
sc com.example.app

# 精确匹配 scrcpy --list-apps 中的应用名称
sc "Example App"

# 透传 scrcpy 参数
sc 微信 --no-audio
sc com.example.app --max-fps=30
```

内置别名如下：

| 名称 | 包名 |
| --- | --- |
| `飞书`、`lark`、`feishu` | `com.ss.android.lark` |
| `微信`、`wechat` | `com.tencent.mm` |
| `微信读书`、`weread` | `com.tencent.weread` |
| `抖音`、`douyin` | `com.ss.android.ugc.aweme` |

## 命令行选项

```text
-s, --serial SERIAL       选择指定的 ADB 设备
    --display SIZE        设置虚拟显示尺寸
    --ime COMPONENT       临时选择 Android 输入法
    --no-ime              不切换 Android 输入法
    --encoder NAME        指定 scrcpy 视频编码器
    --no-compat           禁用应用专用的 Android 兼容性修复
    --list-apps           列出已安装应用
    --doctor              检查依赖和设备连接
    --dry-run             仅输出最终命令，不修改设备
-h, --help                显示帮助
-V, --version             显示版本
```

脚本自身的选项应放在应用名之前；应用名后的内容会全部传给 scrcpy：

```sh
sc --serial 192.168.1.10:5555 --no-ime 微信 --no-audio
```

如果只需要把参数传给 scrcpy，可以省略应用名：

```sh
sc -- --no-audio
```

## 配置

可通过环境变量覆盖默认值：

| 环境变量 | 默认值 | 用途 |
| --- | --- | --- |
| `SC_DISPLAY_SIZE` | `1600x900/220` | 横屏虚拟显示尺寸 |
| `SC_PORTRAIT_DISPLAY_SIZE` | `900x1600/220` | 微信竖屏虚拟显示尺寸 |
| `SC_IME` | `com.sohu.inputmethod.sogou.xiaomi/.SogouIME` | 启动期间使用的输入法 |
| `SC_VIDEO_ENCODER` | 空 | 指定视频编码器；为空时由 scrcpy 自动选择 |

示例：

```sh
SC_IME="com.example.ime/.ImeService" sc 飞书
SC_VIDEO_ENCODER="c2.qti.avc.encoder" sc 微信
```

输入法不存在时，脚本会给出警告并继续使用当前输入法。可用编码器可通过以下命令查询：

```sh
scrcpy --list-encoders
```

## 可靠性说明

脚本只在 scrcpy 运行期间修改以下设备状态，并在正常退出或收到终止信号后恢复：

- `show_ime_with_hard_keyboard` 设置
- 当前输入法（仅当配置的输入法已经安装）
- 飞书所需的包级 Android 兼容性变更

进程被强制执行 `SIGKILL` 时，任何程序都无法运行清理逻辑。如果发生这种情况，再次正常启动和退出脚本，或手动恢复相关设置。

## 开发

```sh
make check
```

检查包括 zsh 语法验证和基于模拟 ADB/scrcpy 的命令行回归测试。

## License

本项目暂未指定开源许可证。
