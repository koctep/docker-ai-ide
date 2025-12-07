from debian:stable

arg USERNAME
arg USERID

run apt update
run apt install -y wget curl iputils-ping iproute2 \
                  libglib2.0-0 libnss3 libdbus-1-3 libatk1.0-0 libatk-bridge2.0-0 \
                  libcups2 libgtk-3-0 libgbm1 libasound2 libx11-xcb1 \
                  strace mc xdg-utils git sudo chromium tzdata \
                  npm mesa-vulkan-drivers mesa-utils locales
run sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF8/' /etc/locale.gen
run dpkg-reconfigure locales
run apt upgrade -y

run wget -q http://apt.langed.org/67352D99.key -O /etc/apt/trusted.gpg.d/apt.langed.org.asc
run echo 'deb http://apt.langed.org ./' > /etc/apt/sources.list.d/aii.list
run apt update
run apt install -y aii-config-screen aii-config-vim aii-config-bash aii-config-less

run wget -O cursor.AppImage https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/
run chmod +x cursor.AppImage
run ./cursor.AppImage --appimage-extract
run ln -s /squashfs-root/usr/bin/cursor /bin/cursor

workdir /usr/local
run wget -O - $(curl https://zed.dev/api/releases/stable/latest/zed-linux-x86_64.tar.gz) | tar zxv
run mv zed.app zed
run ln -s /usr/local/zed/bin/zed /bin/zed

run npm install -g @google/gemini-cli
run npm install -g @anthropic-ai/claude-code
run npm install -g @openai/codex

run chown -R $USERID /home
run useradd -u $USERID $USERNAME
