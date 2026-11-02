# Homebrew Bundle — Mac mini (Mac16,11), macOS 27.0.1, arm64
#
# Install:  brew bundle install --file=Brewfile
# Verify:   brew bundle check  --file=Brewfile --verbose
# Refresh:  brew bundle dump   --file=Brewfile --force
#
# Generated from the live machine; keep in sync with README.md section 5-8.

# ---------------------------------------------------------------------------
# Taps
# ---------------------------------------------------------------------------

tap "nace-ai/tap"
tap "opgginc/tap"
tap "teddychan/tap"

# ---------------------------------------------------------------------------
# Command-line tools
# ---------------------------------------------------------------------------

# Version control and GitHub
brew "git-filter-repo"
brew "gh"

# Languages and build toolchain
brew "node"
brew "bun"
brew "ruby", link: false # RVM owns the `ruby` on PATH
brew "pyenv-virtualenv"
brew "python@3.11"
brew "python@3.12"
brew "python-tk@3.13"
brew "openjdk@11"
brew "openjdk@17"
brew "jenv"
brew "gradle"
brew "cmake"
brew "automake"
brew "binutils"
brew "patchelf"
brew "zlib"
brew "libngtcp2"
brew "swift-sh"

# Apple and mobile
brew "xcodegen"
brew "ios-deploy"
brew "watchman"
brew "librsvg"

# Media and documents
brew "ffmpeg"
brew "imagemagick"
brew "poppler"
brew "ghostscript"
brew "pandoc"
brew "yt-dlp"
brew "qrencode"
brew "abcm2ps"

# Network and remote
brew "openconnect"
brew "cloudflared"
brew "socat"
brew "sshpass"
brew "wget"

# Terminal and system utilities
brew "neovim"
brew "tmux"
brew "yazi"
brew "ripgrep"
brew "tree"
brew "btop"
brew "mactop"
brew "mole"
brew "cliclick"

# AI and local inference
brew "llama.cpp"
brew "whisper.cpp"
brew "llmfit"
brew "rtk"
brew "nace-ai/tap/kapitsa", trusted: true

# Cloud
brew "awscli"

# ---------------------------------------------------------------------------
# Applications (casks)
# ---------------------------------------------------------------------------

cask "basictex"
cask "docker-desktop"
cask "font-jetbrains-mono"
cask "font-jetbrains-mono-nerd-font"
cask "font-sarasa-gothic"
cask "gcloud-cli"
cask "ghostty"
cask "libreoffice"
cask "lm-studio"
cask "ngrok"
cask "opgginc/tap/opencode-bar", trusted: true
cask "teddychan/tap/yahoo-keykey-2", trusted: true

# ---------------------------------------------------------------------------
# Visual Studio Code extensions
# ---------------------------------------------------------------------------

vscode "amazonwebservices.amazon-q-vscode"
vscode "antfu.browse-lite"
vscode "antfu.vite"
vscode "arcanis.vscode-zipfs"
vscode "continue.continue"
vscode "dart-code.dart-code"
vscode "dart-code.flutter"
vscode "davidanson.vscode-markdownlint"
vscode "dbaeumer.vscode-eslint"
vscode "esbenp.prettier-vscode"
vscode "fittentech.fitten-code"
vscode "github.vscode-github-actions"
vscode "jock.svg"
vscode "llvm-vs-code-extensions.lldb-dap"
vscode "mathiasfrohlich.kotlin"
vscode "mermaidchart.vscode-mermaid-chart"
vscode "ms-azuretools.vscode-containers"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-toolsai.jupyter"
vscode "ms-toolsai.jupyter-keymap"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-toolsai.vscode-jupyter-cell-tags"
vscode "ms-toolsai.vscode-jupyter-slideshow"
vscode "ms-vscode-remote.remote-containers"
vscode "octref.vetur"
vscode "philnash.ngrok-for-vscode"
vscode "redhat.vscode-yaml"
vscode "saoudrizwan.claude-dev"
vscode "sst-dev.opencode"
vscode "swiftlang.swift-vscode"
vscode "sysoev.language-stylus"
vscode "tomoki1207.pdf"
vscode "vue.volar"
vscode "wassimdev.wassimdev-vscode-deepseek"
vscode "yzhang.markdown-all-in-one"

# ---------------------------------------------------------------------------
# Global npm packages (Node 24)
# ---------------------------------------------------------------------------

npm "@openai/codex"
npm "clawhub"
npm "corepack"
npm "firebase-tools"
npm "freebuff"
npm "mcporter"
npm "pinchtab"
npm "pptxgenjs"
npm "yarn"

# ---------------------------------------------------------------------------
# Global uv tools (Python 3.12)
# ---------------------------------------------------------------------------

uv "graphifyy"
uv "tavily-cli"
