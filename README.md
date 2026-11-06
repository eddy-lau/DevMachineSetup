# Dev Machine Setup

Setup notes for my primary development machine. Sections document the machine as it
actually runs today; [`Brewfile`](Brewfile) restores every Homebrew package, cask, VS
Code extension, and global npm/uv tool.

| | |
|---|---|
| Model | Mac mini (`Mac16,11`) |
| Chip | Apple M4 Pro, 14 cores (10 performance / 4 efficiency) |
| Memory | 48 GB |
| OS | macOS 27.0.1 (build 26A434) |
| Architecture | arm64 (Apple Silicon) |
| Homebrew prefix | `/opt/homebrew` |
| Shell | zsh |

## Contents

1. [Base OS setup](#1-base-os-setup)
2. [Bootstrap](#2-bootstrap)
3. [Shell layout](#3-shell-layout)
4. [Xcode](#4-xcode)
5. [Runtimes](#5-runtimes)
6. [CLI toolset](#6-cli-toolset)
7. [GUI applications](#7-gui-applications)
8. [Cloud and remote access](#8-cloud-and-remote-access)
9. [Identity and keys](#9-identity-and-keys)
10. [Restore from Brewfile](#10-restore-from-brewfile)
11. [OpenCode](#11-opencode)
12. [Maintenance](#12-maintenance)

## 1. Base OS setup

1. Clean install the latest macOS, then run updates until none remain:

   ```bash
   softwareupdate --install --all --restart
   ```

2. Install the Command Line Tools:

   ```bash
   xcode-select --install
   ```

3. System settings on this machine:

   | Setting | Value |
   |---|---|
   | FileVault | On |
   | Firewall | Off (intentional; endpoint firewall handled elsewhere) |
   | Dock position | Left |
   | Dock icon size | 53 |
   | Desktop icons | 96×96 |

4. Optional preferences (not currently enabled on this build):

   - Wallpaper rotation every 30 minutes, random order
   - Scheduled startup/shutdown under **Energy Saver** (`pmset repeat`)

## 2. Bootstrap

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Verify: `brew --version` → 7.0.11, `brew --prefix` → `/opt/homebrew`.

Then install everything from the Brewfile — see [section 10](#10-restore-from-brewfile).

## 3. Shell layout

| File | Responsibility |
|---|---|
| `~/.zprofile` | Homebrew `shellenv`, tool installer pre/post blocks |
| `~/.zshenv` | Cargo environment (`~/.cargo/env`) |
| `~/.zshrc` | PATH additions, nvm/pyenv/jenv init, gcloud, aliases |

Load order is `.zshenv` → `.zprofile` → `.zshrc`. Keep the version-manager inits in
`.zshrc` after all PATH exports, otherwise `pyenv`/`jenv` shims lose priority.

Essential entries:

```bash
# Homebrew (in .zprofile)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Xcode SDK path — fixes missing extension point errors
export SDKROOT=$(xcrun -sdk macosx --show-sdk-path)

# Node
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Java
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# Ruby
export PATH="$PATH:$HOME/.rvm/bin"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin"

# Flutter
export PATH="$PATH:$HOME/SDKs/flutter/bin"
```

Aliases kept for convenience:

```bash
alias androidstudio='open -a "Android Studio"'
alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'
alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
alias zcode='open -a ZCode'
```

**No credentials in shell files.** API keys and tokens live in 1Password and are
exported per-session (or injected by the tool), never committed or written to
`~/.zshrc`.

## 4. Xcode

- Active toolchain: **Xcode 27.2** (build 27B52) at `/Applications/Xcode.app`
- `xcode-select -p` → `/Applications/Xcode.app/Contents/Developer`
- Side-by-side installs kept: `Xcode-26.6.app`, `Xcode-27.1.app`

```bash
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
```

Signing setup:

1. Export certificates and provisioning profiles from another Mac (Keychain Access →
   export `.p12`).
2. Import on this machine, then verify with `security find-identity -v -p codesigning`.
3. Sign in with the Apple ID used for the developer team in Xcode → Settings → Accounts.

Apple Silicon runs arm64 natively. Rosetta is only needed for legacy Intel tooling:

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

## 5. Runtimes

### 5.1 Node

| Item | Version |
|---|---|
| nvm-managed default | Node 24.20.0 |
| Retained versions | Node 22.20.0, Node 20.19.5 |
| npm | 11.19.0 |
| bun | 1.4.3 |

```bash
nvm install 24
nvm alias default 24
npm install -g @openai/codex clawhub corepack firebase-tools freebuff mcporter pinchtab pptxgenjs yarn
```

### 5.2 Ruby

| Item | Version |
|---|---|
| RVM default | Ruby 3.2.2 |
| Retained | Ruby 2.7.5, Ruby 2.7.7 |
| CocoaPods | 1.16.2 |
| xcpretty | 0.4.1 |
| Fastlane | 2.234.0 |

```bash
rvm install 3.2
rvm --default use 3.2
gem install cocoapods xcpretty fastlane
```

### 5.3 Python

| Item | Version |
|---|---|
| pyenv default | Python 3.12.7 |
| Retained | 3.11.10, 3.10.18, 3.10.17, 3.10.4, 3.10.0, 2.7.18 |
| uv | 0.9.24 |
| Homebrew pythons | python@3.11, python@3.12, python@3.13, python-tk@3.13 |

```bash
pyenv install 3.12
pyenv global 3.12.7
uv tool install graphifyy tavily-cli
```

### 5.4 Java

| Item | Version |
|---|---|
| jenv active | 17.0.14 |
| Also installed | 11.0.26 |

```bash
brew install openjdk@11 openjdk@17 jenv
jenv add /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home
jenv add /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
jenv global 17.0.14
```

### 5.5 Mobile and graphics SDKs

| SDK | Location | Version |
|---|---|---|
| Flutter | `~/SDKs/flutter` | 3.35.4 (stable) |
| Emscripten | `~/SDKs/emsdk` | current |
| Android SDK | `~/Library/Android/sdk` | platforms 26–36, build-tools 28.0.3–36.0.0 |
| Android NDK | `~/Library/Android/sdk/ndk` | 26.1.10909125, 27.x, 28.0.12674087, 29.0.13113456 |
| Android CMake | `~/Library/Android/sdk/cmake` | 3.10.2, 3.18.1, 3.22.1, 3.31.0 |

Install NDK and CMake through Android Studio → SDK Manager. `xcodegen`, `ios-deploy`,
`swift-sh`, and `watchman` come from the Brewfile.

### 5.6 Docker

Docker Desktop 29.1.3, with the `docker` CLI cask installed alongside.

## 6. CLI toolset

Installed with Homebrew (52 formulae, top-level only — see `Brewfile`).

<details>
<summary>Full list by category</summary>

**Version control and GitHub**

`git-filter-repo`, `gh`

**Languages and build tools**

`node`, `bun`, `ruby` (unlinked; RVM owns `ruby`), `pyenv-virtualenv`,
`python@3.11`, `python@3.12`, `python-tk@3.13`, `openjdk@11`, `openjdk@17`, `jenv`,
`gradle`, `cmake`, `automake`, `binutils`, `patchelf`, `zlib`, `libngtcp2`, `swift-sh`

**Apple and mobile**

`xcodegen`, `ios-deploy`, `watchman`, `librsvg`

**Media and documents**

`ffmpeg`, `imagemagick`, `poppler`, `ghostscript`, `pandoc`, `yt-dlp`, `qrencode`,
`abcm2ps`

**Network and remote**

`openconnect`, `cloudflared`, `socat`, `sshpass`, `wget`, `ngrok` (cask)

**Terminal and productivity**

`neovim`, `tmux`, `yazi`, `ripgrep`, `tree`, `btop`, `mactop`, `mole`, `cliclick`

**AI and local inference**

`llama.cpp`, `whisper.cpp`, `llmfit`, `rtk`, `kapitsa` (nace-ai/tap), LM Studio (cask)

**Cloud**

`awscli`, `gcloud-cli` + `google-cloud-sdk` (casks)

**Typesetting**

`basictex` (cask)

</details>

## 7. GUI applications

### Development

| App | Source |
|---|---|
| Xcode 27.2, Xcode 26.6, Xcode 27.1 | App Store (27.2), DMG |
| Android Studio | DMG |
| Visual Studio Code | DMG |
| Cursor | DMG |
| Antigravity | DMG |
| Ghostty | Homebrew cask |
| iTerm2 | DMG |
| Sourcetree | DMG |
| Docker Desktop | Homebrew cask |
| ZCode, OpenCode, OpenChamber, CodexBar, Freebuff | DMG |
| OpenCode Bar | Homebrew cask (opgginc/tap) |
| BBEdit, Figma | DMG |

### Browsers

| App | Source |
|---|---|
| Safari | System |
| Firefox, Google Chrome, Zen | DMG |

### Communication

| App | Source |
|---|---|
| Microsoft Teams, Outlook | DMG |
| Zoom, Telegram, QQ | DMG |
| WhatsApp | DMG |
| LINE, WeChat | App Store |

### Productivity and office

| App | Source |
|---|---|
| Microsoft Word, Excel, PowerPoint, OneNote | DMG |
| LibreOffice | Homebrew cask |
| Google Drive, Docs, Sheets, Slides | DMG |
| Dropbox | DMG |
| OneDrive | App Store |
| Goodnotes | App Store |
| calibre, iMovie, VLC, GIMP, Audacity | mixed |
| Audio Hijack | DMG |
| Yahoo! KeyKey 2 (Cangjie/Simplex input) | Homebrew cask (teddychan/tap) |

### Remote access and networking

| App | Source |
|---|---|
| AnyDesk | DMG |
| Jump Desktop, Jump Desktop Connect | App Store / DMG |
| Tailscale | App Store |
| Cloudflare WARP | DMG |
| ProtonVPN, Shadowrocket, VPN cat, Nextin, 一云梯机场 | mixed |
| Finicky | DMG |
| Steam Link | App Store |
| ngrok | Homebrew cask |

### AI and local models

| App | Source |
|---|---|
| LM Studio | Homebrew cask |
| Ollama, oMLX, ChatGPT, QClaw, Thor Launcher, SpokeLatch | DMG / App Store |

### Utilities

| App | Source |
|---|---|
| Raycast | DMG |
| Magnet, DaisyDisk, Dropover, The Unarchiver, TestFlight | App Store |
| BetterDisplay, DisplayWidget Center, AmorphousDiskMark, Blackmagic Disk Speed Test | mixed |
| CleanMyMac X, BuhoCleaner | DMG |
| logioptionsplus | DMG |
| Yam Air Desk, Yam Display | App Store / DMG |

Fonts installed via Homebrew: JetBrains Mono, JetBrains Mono Nerd Font, Sarasa Gothic.

## 8. Cloud and remote access

| Tool | Version / notes |
|---|---|
| AWS CLI | 2.36.49 (source install, arm64) |
| Google Cloud SDK | 504.0.1 |
| Docker | 29.1.3 |
| Tailscale | App Store app + CLI alias |
| AnyDesk | Unattended access with ACL |
| Jump Desktop | Remote desktop client |
| ngrok | Tunnel client |

Configure AWS with SSO or short-lived credentials — never store long-lived access keys:

```bash
aws configure sso
aws sso login --profile <profile>
```

## 9. Identity and keys

| Item | Value |
|---|---|
| Git name | Eddie Lau |
| Git email | `eddie@touchutility.com` |
| GitHub CLI | authenticated as `eddy-lau` (HTTPS, keyring) |
| SSH key | `~/.ssh/id_ed25519` |
| Git protocol | HTTPS via `gh` credential helper |

```bash
git config --global user.name "Eddie Lau"
git config --global user.email "eddie@touchutility.com"
gh auth login
ssh-keygen -t ed25519 -C "eddie@touchutility.com"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Restore SSH and signing material from an encrypted backup (1Password or an encrypted
disk image). Certificates and private keys are never stored in this repository.

## 10. Restore from Brewfile

```bash
git clone git@github.com:eddy-lau/DevMachineSetup.git
cd DevMachineSetup
brew bundle install --file=Brewfile
```

Check what is missing without changing anything:

```bash
brew bundle check --file=Brewfile --verbose
```

Refresh the Brewfile after installing new tools:

```bash
brew bundle dump --file=Brewfile --force
```

## 11. OpenCode

Portable global OpenCode configuration for the MacBook Air lives in
[`opencode/`](opencode/README.md): V2 config, TUI settings, global instructions, and an
install script.

```bash
git clone git@github.com:eddy-lau/DevMachineSetup.git
cd DevMachineSetup/opencode
./install.sh
```

Secrets stay out of the repo: run `opencode auth login` and export the provider keys
listed in `opencode/env.example`. See [`opencode/README.md`](opencode/README.md) for
what is included, what is excluded, and troubleshooting.

The office **Panoptic LLM** (`panoptic/qwen3.8-27b` for chat,
`panoptic/qwen-image-2.1` for images) is also configured there. It reaches the gateway
over Tailscale, so it works on the office LAN and off-site; chat and image generation
share VRAM, so generating an image evicts the chat model for ~150 s.

The mini also has a machine-local `/zcode` bridge: OpenCode drives the ZCode desktop
app through Chrome DevTools MCP and spends the free ZCode Start Plan quota. Chrome
runs headless, so there is no visible automation window. It needs the ZCode Remote
Control tab open in the dedicated Chrome profile; see
[`opencode/README.md`](opencode/README.md#zcode-remote-worker-start-plan).

The same MCP Chrome profile carries a machine-local `/teams` helper for Microsoft
Teams personal, also headless. Graph does not support personal Microsoft accounts,
so OpenCode drives `teams.live.com` through Chrome DevTools MCP; see
[`opencode/README.md`](opencode/README.md#teams-personal-web-client). ZCode has the
same `/teams` command, backed by a separate headless Chrome profile.

## 12. Maintenance

```bash
brew update && brew upgrade
brew cleanup --prune=all
brew bundle check --file=Brewfile
nvm install --lts --reinstall-packages-from=default
gem update cocoapods fastlane
uv self update
```

Review this README whenever a runtime major version changes, and bump the corresponding
section plus the Brewfile in the same commit.
