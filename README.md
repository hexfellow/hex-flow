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
# Start router + nodes from a YAML config
hexflow run launch.yml

# Or use a Python launch script that generates the YAML
hexflow run scripts/mycfg.launch.py
```

Config files can be `.yml`, `.yaml`, or `.launch.py`. A `.launch.py` file is executed with `python3` and must print the path to the generated YAML file to stdout. This replaces the common pattern `hexflow run $(python scripts/mycfg.launch.py)`.

What happens on `run`:
1. If the config is a `.launch.py` script, runs it with `python3` and reads the YAML path from its output
2. Checks if `zenohd` is already running; starts one if not
3. Spawns each node inside a **pseudo-terminal (PTY)** with `HEX_FLOW_NODE_NAME` and `HEX_FLOW_REMAP` env vars injected
4. Enters a TUI (can be disabled) showing live output of all nodes — each process sees a real TTY, so interactive programs (`vim`, `htop`, Python scripts using `curses`, etc.) work correctly
5. On Ctrl-C or any required node exit, shuts down all processes in reverse order (SIGTERM, then SIGKILL after 5s)

### Build Nodes

```bash
hexflow build launch.yml
hexflow build scripts/mycfg.launch.py
```

Runs the `build` command for each node sequentially. Accepts the same file types as `run`.

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
