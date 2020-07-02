#!/usr/bin/env bash

# Stop script on NZEC
set -e
# Stop script if unbound variable found (use ${var:-} if intentional)
set -u
# By default cmd1 | cmd2 returns exit code of cmd2 regardless of cmd1 success
# This is causing it to fail
set -o pipefail

# standard output may be used as a return value in the functions
# we need a way to write text on the screen in the functions so that
# it won't interfere with the return value.
# Exposing stream 3 as a pipe to standard output of the script itself
exec 3>&1

# Setup some colors to use. These need to work in fairly limited shells, like the Ubuntu Docker container where there are only 8 colors.
# See if stdout is a terminal
if [ -t 1 ] && command -v tput > /dev/null; then
    # see if it supports colors
    ncolors=$(tput colors)
    if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
        bold="$(tput bold       || echo)"
        normal="$(tput sgr0     || echo)"
        black="$(tput setaf 0   || echo)"
        red="$(tput setaf 1     || echo)"
        green="$(tput setaf 2   || echo)"
        yellow="$(tput setaf 3  || echo)"
        blue="$(tput setaf 4    || echo)"
        magenta="$(tput setaf 5 || echo)"
        cyan="$(tput setaf 6    || echo)"
        white="$(tput setaf 7   || echo)"
    fi
fi

say_warning() {
    printf "%b\n" "${yellow:-}init: Warning: $1${normal:-}"
}

say_err() {
    printf "%b\n" "${red:-}init: Error: $1${normal:-}" >&2
}

say_info() {
    printf "%b\n" "${green:-}init: Info: $1${normal:-}" >&2
}

say() {
    # using stream 3 (defined in the beginning) to not interfere with stdout of functions
    # which may be used as return value
    printf "%b\n" "${cyan:-}init:${normal:-} $1" >&3
}

say_verbose() {
    if [ "$verbose" = true ]; then
        say "$1"
    fi
}

say_info 'Configuring Fedora 32 for DEV environment'

say 'install packages'
sudo dnf -q -y update
sudo dnf -q -y install  fish nano gnome-tweaks open-vm-tools-desktop wireshark exa ripgrep tokei \
                        ansible ShellCheck \
                        git subversion \
                        gcc clang make cmake \
                        dotnet-sdk-3.1 \
                        python3 \
                        php-cli php-common php-gd php-pdo php-pgsql php-intl php-json php-xml php-sodium php-mbstring php-bcmath php-opcache
sudo dnf -q -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -q -y config-manager --set-enabled fedora-cisco-openh264
sudo dnf install "*openh264" ffmpeg

mkdir -p ~/.local/bin

# download nice fonts
say 'install fonts'
wget -q https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Regular/complete/Fira%20Mono%20Regular%20Nerd%20Font%20Complete.otf -P ~/.local/share/fonts/
wget -q https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Medium/complete/Fira%20Mono%20Medium%20Nerd%20Font%20Complete.otf -P ~/.local/share/fonts/
wget -q https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Bold/complete/Fira%20Mono%20Bold%20Nerd%20Font%20Complete.otf -P ~/.local/share/fonts/

# setup git
say 'setup git'
git config --global user.email "go.github@darker.red"
git config --global user.name "Denis Brodbeck"
git config --global core.autocrlf input
echo '[user]
	email = go.github@darker.red
	name = Denis Brodbeck
[core]
	autocrlf = input
[push]
	default = nothing # be explicit!
[color]
	ui = auto
[alias]
	st = status
	lol = log --graph --decorate --pretty=oneline --abbrev-commit
	lola = log --graph --decorate --pretty=oneline --abbrev-commit --all
' > ~/.gitconfig

# pre-init ssh
say 'secure ssh'
mkdir -p -m 0700 ~/.ssh && cd ~/.ssh
echo '# using modern ssh client config https://infosec.mozilla.org/guidelines/openssh.html#modern
# Ensure KnownHosts are unreadable if leaked - it is otherwise easier to know which hosts your keys have access to.
HashKnownHosts yes
# Host keys the client accepts - order here is honored by OpenSSH
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa,ecdsa-sha2-nistp521-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ecdsa-sha2-nistp256

KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

Host *
  ServerAliveInterval 60
Host github.com
  IdentityFile ~/.ssh/id_github
' > ./config
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBSzyc0Dqzw8DnzpwXR9oRq3NWgDGSgwztyF5HJmyUvr [ Denis Brodbeck | 2018-10-25 | github ]' > ./id_github.pub
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLLFzngDNkxLAam6+km1BBYU2Mvm6NxifQx0ajhUU+y [ Denis Brodbeck | 2018-10-27 | hosting ]' > ./id_hosting.pub
chmod 0644 ./config ./id_github.pub ./id_hosting.pub
say_warning 'Remember to copy your private ssh keys into ~/.ssh/ (using 0600 perm)'

cd /tmp/
# install composer using https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
say 'install php'
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    say_err 'Invalid composer installer checksum'
    rm composer-setup.php
    exit 1
fi
php composer-setup.php --install-dir=/home/denis/.local/bin --filename=composer --quiet || exit $?

# install latest stable go
say 'install go'
mkdir -p ~/.go/bin
wget -q "https://dl.google.com/go/$(curl -fsSL https://golang.org/VERSION?m=text).linux-amd64.tar.gz" -O /tmp/setup_go.tgz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/setup_go.tgz

# install latest stable nodejs
say 'install latest nodejs using fnm'
curl -fsSL https://github.com/Schniz/fnm/raw/master/.ci/install.sh | bash -s -- --skip-shell
CURRENT_SHELL=$(basename $SHELL)
if [ "$CURRENT_SHELL" == "bash" ]; then
    export PATH='"$INSTALL_DIR"':$PATH
    export PATH="$HOME/.fnm:$PATH"
    eval `fnm env --multi`
fi
fnm install latest-v14.x
fnm default latest-v14.x

# install latest stable rust
say 'install latest rust'
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -q -y
source ~/.cargo/env
# install rustup fish completions
mkdir -p ~/.config/fish/completions
rustup completions fish > ~/.config/fish/completions/rustup.fish

# install latest stable vs code
say 'install latest VS Code'
wget -q https://update.code.visualstudio.com/latest/linux-rpm-x64/stable -O /tmp/setup_code.rpm
sudo dnf -q -y install /tmp/setup_code.rpm
code --log warn --install-extension vscoss.vscode-ansible
code --log warn --install-extension aaron-bond.better-comments
code --log warn --install-extension bungcip.better-toml
code --log warn --install-extension coenraads.bracket-pair-colorizer-2
code --log warn --install-extension ms-dotnettools.csharp
code --log warn --install-extension vadimcn.vscode-lldb
code --log warn --install-extension mikestead.dotenv
code --log warn --install-extension editorconfig.editorconfig
code --log warn --install-extension usernamehw.errorlens
code --log warn --install-extension eamodio.gitlens
code --log warn --install-extension golang.go
code --log warn --install-extension bierner.lit-html
code --log warn --install-extension davidanson.vscode-markdownlint
code --log warn --install-extension felixfbecker.php-debug
code --log warn --install-extension neilbrayfield.php-docblocker
code --log warn --install-extension bmewburn.vscode-intelephense-client
code --log warn --install-extension mehedidracula.php-namespace-resolver
code --log warn --install-extension esbenp.prettier-vscode
code --log warn --install-extension ms-python.python
code --log warn --install-extension matklad.rust-analyzer
code --log warn --install-extension tabnine.tabnine-vscode
code --log warn --install-extension bradlc.vscode-tailwindcss

echo '{
    "editor.fontSize": 16,
    "editor.fontFamily": "FiraMono Nerd Font",
    "editor.fontLigatures": true,
    "editor.rulers": [
        120
    ],
    "editor.smoothScrolling": true,
    "editor.wordWrapColumn": 120,
    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false,
    "explorer.openEditors.visible": 0,
    "extensions.showRecommendationsOnlyOnDemand": true,
    "files.eol": "\n",
    "files.insertFinalNewline": true,
    "files.trimFinalNewlines": true,
    "files.trimTrailingWhitespace": true,
    "telemetry.enableTelemetry": false,
    "telemetry.enableCrashReporter": false,
    "window.zoomLevel": 0,
    "workbench.enableExperiments": false,
    "workbench.startupEditor": "newUntitledFile",
    "emmet.includeLanguages": {
        "markdown": "html",
        "vue-html": "html",
        "javascript": "javascriptreact",
        "nunjucks": "html",
        "njk": "html"
    },
    "gitlens.defaultDateFormat": "DD.MM.YYYY HH:mm",
    "gitlens.defaultDateShortFormat": "DD.MM.YYYY",
    "php.validate.executablePath": "/usr/bin/php",
    "prettier.printWidth": 120,
    "prettier.trailingComma": "es5",
    "go.useLanguageServer": true,
    "[go]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true,
        },
        // Optional: Disable snippets, as they conflict with completion ranking.
        "editor.snippetSuggestions": "none",
    },
    "[go.mod]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true,
        },
    },
    "gopls": {
        // Add parameter placeholders when completing a function.
        "usePlaceholders": true,
        // If true, enable additional analyses with staticcheck.
        // Warning: This will significantly increase memory usage.
        "staticcheck": true,
    },
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[html]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "terminal.integrated.rendererType": "dom",
    "[javascriptreact]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[jsonc]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "editor.renderControlCharacters": true,
    "tabnine.experimentalAutoImports": true
}
' > ~/.config/Code/User/settings.json

# init fish shell
say 'install oh-my-fish'
sudo usermod -s /usr/bin/fish denis
wget -q https://get.oh-my.fish -O /tmp/setup_fish.fish
fish /tmp/setup_fish.fish --noninteractive --yes
echo '# setup local bin
if test -d $HOME/.local/bin; and not contains $HOME/.local/bin $PATH
	set -p PATH $HOME/.local/bin
end
if test -d $HOME/bin; and not contains $HOME/bin $PATH
	set -p PATH $HOME/bin
end

# setup npm
if test -d $HOME/.npm; and not contains $HOME/.npm/bin $PATH
	set -xx NPM_CONFIG_PREFIX $HOME/.npm
	set -p PATH $HOME/.npm/bin
end
# setup fnm
if test -d $HOME/.fnm; and not contains $HOME/.fnm $PATH
	set -a PATH $HOME/.fnm
    fnm env --multi | source
end

# setup go
if test -d /usr/local/go/bin; and not contains /usr/local/go/bin $PATH
	set -a PATH /usr/local/go/bin
	set -xg GOPATH $HOME/.go
	set -p PATH (go env GOPATH)/bin
end

# setup rust
if test -d $HOME/.cargo; and not contains $HOME/.cargo/bin $PATH
	set -p PATH $HOME/.cargo/bin
end

# misc stuff
set -xg DEFAULT_USER denis
alias la="exa -lah"
alias ll="exa -la"
alias ld="exa -lah --group-directories-first"
' > ~/.config/omf/init.fish

say 'setup gnome/os'
# using https://askubuntu.com/a/971577
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing 'rgba'
gsettings set org.gnome.settings-daemon.plugins.xsettings hinting 'full'
gsettings set org.gnome.desktop.interface monospace-font-name 'FiraMono Nerd Font 14'
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:maximize,close'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop']"
# using https://gist.github.com/reavon/0bbe99150810baa5623e5f601aa93afc
dconf load /org/gnome/terminal/legacy/ <<EOF
[keybindings]
paste='<Primary>v'

[profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
audible-bell=false
background-transparency-percent=3
bold-is-bright=true
default-size-columns=120
default-size-rows=30
use-transparent-background=true
EOF
dconf load /org/gnome/desktop/wm/keybindings/ <<EOF
[/]
switch-applications=@as []
switch-applications-backward=@as []
switch-windows=['<Alt>Tab']
switch-windows-backward=['<Shift><Alt>Tab']
EOF

# clean up
say 'cleaning up'
rm -f /tmp/setup_*

say_info '
Setup completed...

Last steps:
  * enable h264 plugin in firefox
  * configure firefox
    * install extension `Redirector` (for Mozilla MDN and MS Docs)
    * install extension `uBlock Origin`
  * install fish theme
    * `fish`
    * `omf install bobthefish`
  * bring out shut down button with https://extensions.gnome.org/extension/2917/bring-out-submenu-of-power-offlogout-button/
    * install firefox extension
    * activate gnome extension
  * Reboot
'
