from debian:stable

arg USERNAME
arg USERID
arg ARCH

run apt update \
 && apt install -y wget curl iputils-ping iproute2 ripgrep \
                  libglib2.0-0 libnss3 libdbus-1-3 libatk1.0-0 libatk-bridge2.0-0 \
                  libcups2 libgtk-3-0 libgbm1 libasound2 libx11-xcb1 \
                  strace mc xdg-utils git sudo chromium tzdata \
                  python3-venv npm \
                  mesa-vulkan-drivers mesa-utils locales \
 && apt upgrade -y \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*
run sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF8/' /etc/locale.gen
run dpkg-reconfigure locales

run wget -q http://apt.langed.org/67352D99.key -O /etc/apt/trusted.gpg.d/apt.langed.org.asc \
 && echo 'deb [trusted=true] http://apt.langed.org ./' > /etc/apt/sources.list.d/aii.list \
 && apt update \
 && apt install -y aii-config-screen aii-config-vim aii-config-bash aii-config-less \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

run wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$ARCH" \
 && apt update \
 && (dpkg -i vscode.deb || apt install -f -y) \
 && rm -f vscode.deb /etc/apt/sources.list.d/vscode.sources \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

run wget -O cursor.AppImage https://api2.cursor.sh/updates/download/golden/linux-$ARCH/cursor/ \
 && chmod +x cursor.AppImage \
 && ./cursor.AppImage --appimage-extract \
 && rm -f cursor.AppImage \
 && ln -s /squashfs-root/usr/bin/cursor /bin/cursor

arg CURSOR_CLI_VERSION
run mkdir -p /usr/local/cursor-agent \
 && curl -fsSL "https://downloads.cursor.com/lab/${CURSOR_CLI_VERSION}/linux/${ARCH}/agent-cli-package.tar.gz" \
  | tar --strip-components=1 -xz -C /usr/local/cursor-agent \
 && ln -sf /usr/local/cursor-agent/cursor-agent /usr/local/bin/agent \
 && ln -sf /usr/local/cursor-agent/cursor-agent /usr/local/bin/cursor-agent

workdir /usr/local
run wget -O - $(curl https://zed.dev/api/releases/stable/latest/zed-linux-$(uname -m).tar.gz) | tar zx \
 && mv zed.app zed \
 && ln -s /usr/local/zed/bin/zed /bin/zed

run curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin \
 && rm -rf /root/.cache/antigravity
run npm install -g @anthropic-ai/claude-code \
                   @openai/codex \
                   @zed-industries/codex-acp \
                   @zed-industries/claude-agent-acp \
 && npm cache clean --force \
 && rm -rf /root/.npm /tmp/*

run chown -R $USERID /home
run useradd -u $USERID $USERNAME
