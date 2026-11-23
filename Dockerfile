from debian:stable

arg USERNAME
arg USERID
arg ARCH
# The Makefile turns AGENTS and NOX into one true/false flag per app and agent.
arg APP_CHROMIUM=true
arg APP_VSCODE=true
arg APP_CURSOR=true
arg APP_ZED=true
arg AGENT_CURSOR=true
arg AGENT_AGY=true
arg AGENT_CLAUDE=true
arg AGENT_CODEX=true
arg AGENT_QWEN=true

run apt update \
 && apt install -y wget curl iputils-ping iproute2 ripgrep \
                  strace mc git sudo tzdata \
                  python3-venv npm openssh-server \
                  locales \
 && apt upgrade -y \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*
run sed -i \
      -e 's/^# \(en_US.UTF-8 UTF-8\)/\1/' \
      -e 's/^# \(ru_RU.UTF-8 UTF-8\)/\1/' \
      /etc/locale.gen
run dpkg-reconfigure locales

run wget -q http://apt.langed.org/67352D99.key -O /etc/apt/trusted.gpg.d/apt.langed.org.asc \
 && echo 'deb [trusted=true] http://apt.langed.org ./' > /etc/apt/sources.list.d/aii.list \
 && apt update \
 && apt install -y aii-config-screen aii-config-vim aii-config-bash aii-config-less aii-config-git \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Libraries shared by every graphical app.
run if [ "$APP_CHROMIUM" = "true" ] || [ "$APP_VSCODE" = "true" ] \
   || [ "$APP_CURSOR" = "true" ] || [ "$APP_ZED" = "true" ]; then \
  apt update \
  && apt install -y libglib2.0-0 libnss3 libdbus-1-3 libatk1.0-0 libatk-bridge2.0-0 \
                    libcups2 libgtk-3-0 libgbm1 libasound2 libx11-xcb1 \
                    xdg-utils \
                    mesa-vulkan-drivers mesa-utils \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*; \
 fi

run if [ "$APP_CHROMIUM" = "true" ]; then \
  apt update \
  && apt install -y chromium \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*; \
 fi

run if [ "$APP_VSCODE" = "true" ]; then \
  wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$ARCH" \
  && apt update \
  && (dpkg -i vscode.deb || apt install -f -y) \
  && rm -f vscode.deb /etc/apt/sources.list.d/vscode.sources \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*; \
 fi

run if [ "$APP_CURSOR" = "true" ]; then \
  wget -O cursor.AppImage https://api2.cursor.sh/updates/download/golden/linux-$ARCH/cursor/ \
  && chmod +x cursor.AppImage \
  && ./cursor.AppImage --appimage-extract \
  && rm -f cursor.AppImage \
  && ln -s /squashfs-root/usr/bin/cursor /bin/cursor; \
 fi

arg CURSOR_CLI_VERSION
run if [ "$AGENT_CURSOR" = "true" ]; then \
  if [ -z "$CURSOR_CLI_VERSION" ]; then \
    echo "CURSOR_CLI_VERSION is required to install the Cursor agent" >&2; \
    exit 1; \
  fi; \
  mkdir -p /usr/local/cursor-agent \
  && curl -fsSL "https://downloads.cursor.com/lab/${CURSOR_CLI_VERSION}/linux/${ARCH}/agent-cli-package.tar.gz" \
   | tar --strip-components=1 -xz -C /usr/local/cursor-agent \
  && ln -sf /usr/local/cursor-agent/cursor-agent /usr/local/bin/agent \
  && ln -sf /usr/local/cursor-agent/cursor-agent /usr/local/bin/cursor-agent; \
 fi

workdir /usr/local
run if [ "$APP_ZED" = "true" ]; then \
  wget -O - $(curl https://zed.dev/api/releases/stable/latest/zed-linux-$(uname -m).tar.gz) | tar zx \
  && mv zed.app zed \
  && ln -s /usr/local/zed/bin/zed /bin/zed; \
 fi

run if [ "$AGENT_AGY" = "true" ]; then \
  curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin \
  && rm -rf /root/.cache/antigravity; \
 fi
run pkgs=""; \
 if [ "$AGENT_CLAUDE" = "true" ]; then pkgs="$pkgs @anthropic-ai/claude-code @zed-industries/claude-agent-acp"; fi; \
 if [ "$AGENT_CODEX" = "true" ]; then pkgs="$pkgs @openai/codex @zed-industries/codex-acp"; fi; \
 if [ -n "$pkgs" ]; then \
   npm install -g $pkgs \
   && npm cache clean --force; \
 fi; \
 rm -rf /root/.npm /tmp/*

# Standalone archive bundles Node.js 22. Debian's npm is too old for
# @qwen-code/qwen-code, and /home is replaced by the profile at runtime,
# so the install has to live under /usr/local.
run if [ "$AGENT_QWEN" = "true" ]; then \
  curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen-standalone.sh \
  | QWEN_INSTALL_LIB_DIR=/usr/local/lib/qwen-code \
    QWEN_INSTALL_BIN_DIR=/usr/local/bin \
    bash -s -- --method standalone --no-modify-path \
  && mkdir -p /etc/qwen-code \
  && rm -rf /root/.qwen /tmp/*; \
 fi

copy --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

copy sshd/ai-ide.conf /etc/ssh/sshd_config.d/ai-ide.conf

run chown -R $USERID /home
run useradd -M -d /home -s /bin/bash -u $USERID -g 44 $USERNAME
