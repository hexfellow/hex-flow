# Hex Flow

A [Zenoh](https://zenoh.io/)-based robot node launcher for managing hexfellow robot process lifecycles and communication.

[中文文档](./README_cn.md)

## Install

```bash
cargo install --path .
```

Requires `zenohd` to be available in PATH.

## Usage

### Launch Nodes

```bash
# Start router + nodes from a config file
hexflow run launch.yml
```

What happens on `run`:
1. Checks if `zenohd` is already running; starts one if not
2. Spawns each node with `HEX_FLOW_NODE_NAME` and `HEX_FLOW_REMAP` env vars injected
3. Enters a TUI (can be disabled) showing live stdout/stderr of all nodes
4. On Ctrl-C or any required node exit, shuts down all processes in reverse order (SIGTERM, then SIGKILL after 5s)

### Build Nodes

```bash
hexflow build launch.yml
```

Runs the `build` command for each node sequentially.

### Monitor Topics

```bash
# Connect to local router
hexflow monitor
```

Live TUI showing all topics with their publishers and subscribers.

## Configuration

See [demo-launch.yml](./demo-launch.yml) for a full example:

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
    build: "pip install my_package"   # optional
    run: my-node-binary               # required
    required: true                     # optional, default false
    hidden: false                      # optional, default false (hides in TUI)
    remap:                             # optional, topic remapping
      local_topic: global_topic
    env:                               # optional, extra env vars
      HOST: 192.168.1.1
```

### Reserved Naming

- Env var prefix `HEX_FLOW_` is reserved by the launcher; cannot be used in `env`
- Node name `metadata` is reserved for internal use

## TUI Keybindings

| Key                | Action                                    |
| ------------------ | ----------------------------------------- |
| `Ctrl+C`           | Quit                                      |
| `Ctrl+B`           | Enter prefix mode                         |
| `Ctrl+B` → `Space` | Cycle layout (vertical/horizontal/matrix) |
| `Ctrl+B` → `↑/↓`   | Switch focus between panels               |
| `Ctrl+B` → `z`     | Zoom focused panel                        |
| `Ctrl+B` → `h`     | Toggle hidden panels                      |
| `Ctrl+B` → `[`     | Enter scroll mode                         |
| `Ctrl+B` → `?`     | Help                                      |

## License

HexFellow — [hexfellow.com](https://hexfellow.com)
