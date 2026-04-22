# Hex Flow

基于 [Zenoh](https://zenoh.io/) 的机器人节点启动器，用于管理 hexfellow 机器人进程的生命周期和通信。

## 安装

```bash
cargo install --path .
```

需要 `zenohd` 在 PATH 中可用。

## 用法

### 启动节点

```bash
# 按配置文件启动 router + 节点
hexflow run launch.yml
```

启动流程：
1. 检测本机是否已有 `zenohd` 运行，若无则自动启动
2. 按 YAML 配置依次启动各节点，注入 `HEX_FLOW_NODE_NAME` 和 `HEX_FLOW_REMAP` 环境变量
3. 进入 TUI 界面（可通过配置关闭），显示各节点实时输出
4. 收到 Ctrl-C 或任一 required 节点退出后，按逆序 SIGTERM → SIGKILL 关闭所有进程

### 构建节点

```bash
hexflow build launch.yml
```

依次执行各节点配置中的 `build` 命令。

### 监控 Topic

```bash
# 连接本机 router
hexflow monitor
```

TUI 界面实时显示当前 topic 及其 publisher / subscriber。

## 配置文件

参考 [demo-launch.yml](./demo-launch.yml)：

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

| 快捷键             | 功能                      |
| ------------------ | ------------------------- |
| `Ctrl+C`           | 退出                      |
| `Ctrl+B`           | 进入命令模式              |
| `Ctrl+B` → `Space` | 切换布局 (竖直/水平/矩阵) |
| `Ctrl+B` → `↑/↓`   | 切换焦点面板              |
| `Ctrl+B` → `z`     | 缩放聚焦面板              |
| `Ctrl+B` → `h`     | 显示/隐藏 hidden 面板     |
| `Ctrl+B` → `[`     | 进入滚动模式              |
| `Ctrl+B` → `?`     | 帮助                      |

## License

HexFellow — [hexfellow.com](https://hexfellow.com)
