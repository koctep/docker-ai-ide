# AI IDE Container Environment

## Project Goal

Create an environment for working safely with files using agentic systems. The
environment guarantees that an agent can access only the files in the directory
from which the agent application was launched, plus any additional files and
directories explicitly authorized by the user. The rest of the host filesystem
remains inaccessible to the agent.

A containerized development environment that provides AI-powered code editors (Cursor and Zed) along with popular AI CLI tools in an isolated Docker container with GUI support.

## Features

- **Multiple AI Editors**: Pre-configured Cursor and Zed editors
- **AI CLI Tools**: Integrated Cursor Agent (`agent`), Google Antigravity (`agy`), Anthropic Claude, and OpenAI Codex command-line interfaces
- **GUI Support**: Full X11 forwarding for native desktop experience
- **SSH server mode**: OpenSSH inside the container for Cursor, VS Code, and other Remote-SSH IDEs
- **Profile Management**: Isolated development environments using profiles
- **Hardware Acceleration**: GPU and video device access for optimal performance
- **Debian Base**: Stable Debian foundation with essential development tools

## Prerequisites

- Docker installed and running
- X11 server (for GUI applications)
- Linux system with video/render group access
- Internet connection for downloading editors and dependencies

## Quick Start

1. **Set up your profile environment variable:**
   ```bash
   export AI_PROFILE="my-project"
   ```

2. **Build the container:**
   ```bash
   make build
   ```

3. **Launch Cursor IDE:**
   ```bash
   ./cursor.ide
   ```

4. **Launch Zed editor:**
   ```bash
   ./zed.ide
   ```

5. **Launch with custom command:**
   ```bash
   ./ai.ide bash
   ```

6. **SSH server for Remote-SSH (Cursor / VS Code):**
   ```bash
   ./ai.ide --ssh
   ```

## Installation

### Building the Container

Full build with GUI editors (VSCode, Cursor, Zed):

```bash
make build
```

CLI-only build without GUI editors (Chromium and all CLI tools are still installed):

```bash
make build-nox
# or
make build NOX=true
```

Skipped in `NOX=true` mode: VSCode, Cursor AppImage, Zed.

Always installed: Chromium, OpenSSH server, Cursor Agent CLI (`agent`), Antigravity (`agy`), Claude Code, Codex, and ACP adapters.

The default build downloads Cursor 1.6.27. To use a different version:

```bash
make build APPURL=https://downloads.cursor.com/production/[hash]/linux/x64/Cursor-[version]-x86_64.AppImage
```

### Profile Setup

Profiles create isolated environments for different projects:

```bash
export AI_PROFILE="project-name"
```

Profile data is stored in `~/.local/share/ai-ide/${AI_PROFILE}/` and includes:
- Editor configurations
- Project files
- User settings

## Usage

### Available Editors

| Script | Editor | Description |
|--------|--------|-------------|
| `cursor.ide` | Cursor | AI-powered VS Code fork |
| `zed.ide` | Zed | High-performance collaborative editor |
| `ai.ide` | Custom | Run any command or default to bash |
| `ai.ide --ssh` | SSH | OpenSSH server for Remote-SSH IDEs |

### SSH server mode

Run the sandbox as an SSH remote so Cursor, VS Code, or any SSH-capable IDE
connects with Remote-SSH. The IDE GUI stays on the host; files and tools stay
in the container. Rebuild the image (`make build` or `make build-nox`) so
OpenSSH is installed. SSH mode also works with a `NOX=true` image.

```bash
./ai.ide --ssh
# optional:
./ai.ide --ssh --ssh-port 2223 --ssh-bind 0.0.0.0
# or:
AI_SSH_PORT=2223 AI_SSH_BIND=0.0.0.0 ./ai.ide --ssh
```

Defaults: listen on `127.0.0.1:2222`, key-only auth, no root login, no
passwords. Binding `0.0.0.0` exposes the sandbox on the network.

On the first SSH-mode start, if the profile has no `.ssh` directory, the
launcher creates it and writes `authorized_keys` from `~/.ssh/id_rsa.pub`.
If that public key is missing, the launcher exits without starting sshd.
A host key `ssh_host_ed25519_key` is generated in the profile `.ssh` if it
is missing. Later starts leave an existing profile `authorized_keys` unchanged.
`$PROFILE_DIR/.ssh` is then bind-mounted on `/home/.ssh` read-only.

Connect as the container user (the username used at `make build`) with
`~/.ssh/id_rsa`, then open `/home/src`. The launcher writes a Host block to
`$CACHE_DIR/ssh/config` and prints an `Include` line for `~/.ssh/config`.

`~/.cursor-server` and `~/.vscode-server` live in the profile
(`PROFILE_DIR` → `/home`).

### AI CLI Tools

The container includes these AI command-line interfaces:

```bash
# Cursor Agent CLI
agent "Your prompt here"

# Google Antigravity
agy "Your prompt here"

# Anthropic Claude  
claude-code "Your code question"

# OpenAI Codex
codex "Your coding request"
```

### File Structure

```
~/.local/share/ai-ide/
├── [profile-name]/          # Profile-specific data, mounted as /home
│   ├── .ssh/                # Created on first --ssh if missing; mounted read-only
│   ├── .claude/             # Agent state and configuration
│   ├── .codex/              # ... one directory per agent
│   └── ...                  # Other user data
├── shared/                  # Optional, mounted as /home/shared
└── tmp/<pid>/               # Per-session /tmp, deleted when the launcher exits
```

## Configuration

Three host directories are involved, all of them derived from the profile name
and the project directory name (`PRJ` below is `$(basename $PWD)`):

| Shorthand | Host path | Holds |
|-----------|-----------|-------|
| `PROFILE_DIR` | `~/.local/share/ai-ide/$AI_PROFILE` | the container home, persistent between runs |
| `CONFIG_DIR` | `~/.config/ai-ide/$AI_PROFILE/$PRJ` | what you write: agent configs, `.env`, `.exports`, `mcp.json` |
| `CACHE_DIR` | `~/.cache/ai-ide/$AI_PROFILE/$PRJ` | what the launcher generates |

### What is mounted where

| Host | Container | Mode |
|------|-----------|------|
| `PROFILE_DIR` | `/home` | rw |
| `PROFILE_DIR/.ssh` (if it exists) | `/home/.ssh` | ro |
| `~/.local/share/ai-ide/shared` (if it exists) | `/home/shared` | rw |
| `~/.local/share/ai-ide/tmp/<pid>` — launcher PID, removed on exit | `/tmp` | rw |
| `$PWD` — the project | `/home/src` (working directory) | rw |
| `CONFIG_DIR/<any-other-file>` | `/home/<same-relative-path>` | ro |
| `CONFIG_DIR/mcp.json` | `/home/.mcp.json`, `/home/.cursor/mcp.json`, `/home/.agents/mcp_config.json`, `/home/.gemini/config/mcp_config.json` | ro |
| `CACHE_DIR/managed_config.toml` — generated from `mcp.json` and `CONFIG_DIR/config.toml` | `/etc/codex/managed_config.toml` | ro |
| every skill from `AGENT_SKILLS` | `/home/.agents/skills/<name>`, `/home/.claude/skills/<name>`, `/home/.cursor/skills/<name>`, `/home/.gemini/skills/<name>`, `/home/.gemini/antigravity-cli/skills/<name>` | ro |
| X11 socket and dbus (Linux) `/tmp/.X11-unix`, `/run/dbus`, `/run/user/$UID/bus` | same paths | rw |
| X11 cookie (macOS) `/tmp/.docker.xauth.$$` | `/root/.Xauthority` | rw |

Not mounted at all:

| Host | Why |
|------|-----|
| `CONFIG_DIR/.env` | sourced by the launcher itself, on the host |
| `CONFIG_DIR/.exports` | turned into `docker run -e` arguments |
| `CONFIG_DIR/config.toml` | used as the base of the generated codex config |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AI_PROFILE` | Profile name (required) | None |
| `AI_SSH` | Non-empty value starts SSH server mode | None |
| `AI_SSH_PORT` | Host port published to container port 22 | `2222` |
| `AI_SSH_BIND` | Address to bind the published SSH port | `127.0.0.1` |
| `AGENT_SKILLS` | List of skills mounted read-only, separated by colons, spaces or newlines | None |
| `AGENT_SKILLS_TARGETS` | Skill directories inside the container (relative to `/home`) | `.agents/skills .claude/skills .cursor/skills .gemini/skills .gemini/antigravity-cli/skills` |
| `AGENT_MCP_TARGETS` | Paths `mcp.json` is mounted to (relative to `/home`) | `.mcp.json .cursor/mcp.json .agents/mcp_config.json .gemini/config/mcp_config.json` |
| `DISPLAY` | X11 display | Current display |
| `APPURL` | Cursor download URL | Latest stable |

### Per-project configuration

Files in `~/.config/ai-ide/$AI_PROFILE/$(basename $PWD)/` are mounted read-only
into the container home, keeping project specific agent configs outside of the
repository.

The `.env` file in that directory is special: it is *sourced by the launcher*
(plain shell syntax) before the container is started, so it can set any variable
this script understands, for example `AGENT_SKILLS` or `AI_USE_PROXY`:

```bash
# ~/.config/ai-ide/my-project/ai-ide/.env
AGENT_SKILLS="$HOME/skills:$HOME/work/pdf-report"
AI_USE_PROXY=1
```

It is neither mounted into the container nor passed to it as environment
variables — earlier versions turned every line of `.env` into a `docker run -e`
argument, that job now belongs to `.exports`:

```bash
# ~/.config/ai-ide/my-project/ai-ide/.exports
# NAME=value sets the variable inside the container
ANTHROPIC_API_KEY=sk-ant-...
# a bare NAME forwards the value from the host environment
SSH_AUTH_SOCK
```

Empty lines and lines starting with `#` are ignored.

### MCP servers

`mcp.json` in the same directory describes the MCP servers once, in the usual
`{"mcpServers": {...}}` format, and is mounted read-only under every name the
agents look for:

| Agent | Path | Content |
|-------|------|---------|
| Claude Code | `/home/.mcp.json` | `mcp.json` as is |
| Cursor | `/home/.cursor/mcp.json` | `mcp.json` as is |
| Antigravity (`agy`) | `/home/.gemini/config/mcp_config.json` | `mcp.json` as is |
| — | `/home/.agents/mcp_config.json` | `mcp.json` as is |
| Codex | `/etc/codex/managed_config.toml` | generated |

Codex is the only one that needs a conversion: it reads TOML, so
`managed_config.toml` with the `[mcp_servers.*]` tables is generated into
`CACHE_DIR` and mounted read-only. If `CONFIG_DIR/config.toml` exists, it is used
as the base and the tables are appended to it. The conversion runs on the host
`python3` when available, otherwise inside the image.

It goes to the managed config on purpose: `~/.codex/config.toml` has to stay
writable, codex persists the directory trust into it and fails with
`failed to persist config` when that file is a read-only mount.

The target list can be changed with `AGENT_MCP_TARGETS` (space separated paths
relative to `/home`).

`.env`, `.exports`, `mcp.json` and `config.toml` are handled specially by the
rules above; every other file of the directory is mounted read-only into the
container home as is.

### Skills

`AGENT_SKILLS` is a list of skills to mount, and they may live in unrelated
places. Entries are separated by colons, spaces or newlines, `~` and shell globs
are expanded:

```bash
# individual skills from different projects
AGENT_SKILLS="~/src/one/.agents/skills/jira-create-issue:~/src/two/skills/pdf-report"
# same thing with globs and a whole directory of skills
AGENT_SKILLS="~/src/one/.agents/skills/jira-* ~/src/two/skills"
```

An entry is a skill when it contains a `SKILL.md`; a directory of skills is
expanded to every subdirectory that has one.

Every skill is mounted read-only into the skill directory of each agent shipped
in the image, so the same set of skills is available regardless of which agent is
used:

| Agent | Skill directory |
|-------|-----------------|
| Codex | `/home/.agents/skills/<skill-name>` |
| Claude Code | `/home/.claude/skills/<skill-name>` |
| Cursor | `/home/.cursor/skills/<skill-name>` |
| Antigravity (`agy`), shared | `/home/.gemini/skills/<skill-name>` |
| Antigravity (`agy`), global | `/home/.gemini/antigravity-cli/skills/<skill-name>` |

Nothing is mounted into `/home/src`: the project directory stays as it is on the
host. `agy` also reads `.agents/skills` of the workspace, but mounting there
would litter the project with empty `.agents/skills/<skill-name>` directories,
so its two home located roots are used instead — the ones its `/skills` command
calls global and shared.

The mounts are read-only, so agents can read the skills but cannot modify the
originals. Skills whose names collide are skipped after the first one, and
entries without a `SKILL.md` are ignored with a warning.

When a new agent is added to the image, extend the target list with
`AGENT_SKILLS_TARGETS` (space separated paths relative to `/home`) or change its
default in `ai.ide`.

### Docker Build Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `APPURL` | Cursor AppImage URL | Latest from Makefile |
| `USERNAME` | Container username | Current user |
| `USERID` | Container user ID | Current UID |

## Development

### Project Structure

```
src/
├── Dockerfile              # Container definition
├── Makefile               # Build automation
├── ai.ide                 # Universal launcher script
├── sshd/ai-ide.conf       # OpenSSH server config drop-in
└── README.md             # This file
```

### Customization

To add new editors or tools:

1. Modify the `Dockerfile` to install additional software
2. Update the `ai.ide` script to handle new editor types
3. Rebuild the container

Example for adding VS Code:
```dockerfile
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
RUN echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
RUN apt update && apt install -y code
```

## Troubleshooting

### Common Issues

**"no profile defined" error:**
```bash
export AI_PROFILE="your-profile-name"
```

**GUI applications won't start:**
```bash
# Allow X11 connections
xhost +local:docker
```

**Permission issues:**
```bash
# Ensure your user is in video/render groups
sudo usermod -aG video,render $USER
# Logout and login again
```

**Container won't start:**
```bash
# Clean up existing containers
docker container prune
# Check if container exists
docker inspect ${AI_PROFILE}-ai-ide
```

**SSH mode: missing `id_rsa.pub`:**
```bash
# The first --ssh run copies ~/.ssh/id_rsa.pub into the profile.
# Create an RSA key, or copy another public key into the profile yourself:
ls ~/.ssh/id_rsa.pub
```

### GPU Access Issues

If you encounter GPU-related problems:

```bash
# Install Mesa drivers
sudo apt-get install mesa-vulkan-drivers mesa-utils

# Verify GPU access
docker run --rm --device=/dev/dri ai-ide glxinfo | grep renderer
```

## Security Considerations

- The container runs with your user ID to maintain file permissions
- X11 forwarding exposes your display - use only on trusted networks  
- SSH mode binds `127.0.0.1` by default; `AI_SSH_BIND=0.0.0.0` exposes the sandbox to the network
- AI CLI tools may send code to external services - review their privacy policies
- Container has SYS_ADMIN capability for some operations

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note:** This license applies to the container configuration and scripts only. Please check the licenses of included software (Cursor, Zed, AI CLI tools) for their respective terms.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with different profiles
5. Submit a pull request

For bug reports, please include:
- Your OS and Docker version
- The exact error message
- Steps to reproduce
- Your `AI_PROFILE` and any custom configuration
