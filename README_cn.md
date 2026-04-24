# Hex Flow

基于 [Zenoh](https://zenoh.io/) 的机器人节点启动器，用于管理 hexfellow 机器人进程的生命周期和通信。

[English](./README.md)

## 安装

```bash
cargo install --path .
```

需要 `zenohd` 在 PATH 中可用。

## 用法

### 启动节点

```bash
# 按 YAML 配置启动 router + 节点
hexflow run launch.yml

# 或使用会生成 YAML 的 Python 启动脚本
hexflow run scripts/mycfg.launch.py
```

配置文件可以是 `.yml`、`.yaml` 或 `.launch.py`。`.launch.py` 由 `python3` 执行，且须将生成的 YAML 文件路径打印到 stdout。这替代了常见写法 `hexflow run $(python scripts/mycfg.launch.py)`。

执行 `run` 时的流程：
1. 若配置为 `.launch.py` 脚本，则用 `python3` 运行并从其输出读取 YAML 路径
2. 检测本机是否已有 `zenohd` 运行，若无则启动
3. 在**伪终端 (PTY)** 中启动各节点，注入 `HEX_FLOW_NODE_NAME` 与 `HEX_FLOW_REMAP` 环境变量
4. 进入 TUI（可通过配置关闭），显示各节点实时输出 — 每个进程拥有真实 TTY，交互式程序（`vim`、`htop`、使用 `curses` 的 Python 脚本等）可正常工作
5. 收到 Ctrl-C 或任一 required 节点退出后，按逆序关闭所有进程（先 SIGTERM，5 秒后再 SIGKILL）

### 构建节点

```bash
hexflow build launch.yml
hexflow build scripts/mycfg.launch.py
```

按顺序执行各节点的 `build` 命令。接受的文件类型与 `run` 相同。

### 监控 Topic

```bash
# 连接本机 router
hexflow monitor
```

TUI 实时显示所有 topic 及其 publisher 与 subscriber。

## 配置文件

完整示例见 [demo-launch.yml](./demo-launch.yml)：

```yaml
router:
  multicast:
    address: "ff02::1"
    interface: "eth0"

launcher:
  disable-tui: false
  tui-log-to-file: false

nodes:
  - name: my_node
    build: "pip install my_package"   # 可选
    run: my-node-binary               # 必填
    required: true                     # 可选，默认 false
    hidden: false                      # 可选，默认 false，TUI 中隐藏
    remap:                             # 可选，topic 重映射
      local_topic: global_topic
    env:                               # 可选，额外环境变量
      HOST: 192.168.1.1
```

### 保留命名

- 环境变量前缀 `HEX_FLOW_` 由启动器保留，不得在 `env` 中使用
- 节点名 `metadata` 为内部保留

## TUI 快捷键

| 快捷键             | 功能                           |
| ------------------ | ------------------------------ |
| `Ctrl+C`           | 退出                           |
| `Ctrl+B`           | 进入前缀模式                   |
| `Ctrl+B` → `Space` | 切换布局（竖直 / 水平 / 矩阵） |
| `Ctrl+B` → `↑/↓`   | 在面板间切换焦点               |
| `Ctrl+B` → `z`     | 缩放当前聚焦面板               |
| `Ctrl+B` → `h`     | 切换隐藏面板显示               |
| `Ctrl+B` → `[`     | 进入滚动模式                   |
| `Ctrl+B` → `?`     | 帮助                           |

## License

HexFellow — [hexfellow.com](https://hexfellow.com)
