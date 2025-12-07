# AI IDE Container Environment

A containerized development environment that provides AI-powered code editors (Cursor and Zed) along with popular AI CLI tools in an isolated Docker container with GUI support.

## Features

- **Multiple AI Editors**: Pre-configured Cursor and Zed editors
- **AI CLI Tools**: Integrated Google Gemini, Anthropic Claude, and OpenAI Codex command-line interfaces
- **GUI Support**: Full X11 forwarding for native desktop experience
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

## Installation

### Building the Container

The default build downloads Cursor 1.6.27. To use a different version:

```bash
make build APPURL=https://downloads.cursor.com/production/[hash]/linux/x64/Cursor-[version]-x86_64.AppImage
```

### Profile Setup

Profiles create isolated environments for different projects:

```bash
export AI_PROFILE="project-name"
```

Profile data is stored in `~/ai-ide/${AI_PROFILE}/` and includes:
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

### AI CLI Tools

The container includes these AI command-line interfaces:

```bash
# Google Gemini
gemini-cli "Your prompt here"

# Anthropic Claude  
claude-code "Your code question"

# OpenAI Codex
codex "Your coding request"
```

### File Structure

```
~/ai-ide/
├── [profile-name]/           # Profile-specific data
│   ├── src/                 # Your project source code (mounted from host)
│   ├── .config/             # Editor configurations
│   └── ...                  # Other user data
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AI_PROFILE` | Profile name (required) | None |
| `DISPLAY` | X11 display | Current display |
| `APPURL` | Cursor download URL | Latest stable |

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