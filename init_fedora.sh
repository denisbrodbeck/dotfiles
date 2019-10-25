#!/usr/bin/env bash
set -eu

echo 'Configuring Fedora 31 for DEV'

sudo dnf -q -y update
sudo dnf -q -y install fish nano gnome-tweak-tool open-vm-tools-desktop wireshark \
                        git nodejs ansible ShellCheck \
                        php-cli php-common php-gd php-pdo php-pgsql php-intl php-json php-xml php-sodium php-mbstring
# sudo dnf -q -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-29.noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-29.noarch.rpm
# sudo dnf -q -y config-manager --set-enabled fedora-cisco-openh264
# sudo dnf -q -y install gstreamer1-plugin-openh264 mozilla-openh264

# download nice fonts
wget -q https://github.com/tonsky/FiraCode/raw/master/distr/otf/FiraCode-Regular.otf -O ~/Downloads/fonts_firacode_regular.otf
wget -q https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Regular/complete/Fura%20Mono%20Regular%20Nerd%20Font%20Complete%20Mono.otf -O ~/Downloads/fonts_furacode_regular_mono.otf

# setup git
git config --global user.email "go.github@darker.red"
git config --global user.name "Denis Brodbeck"
git config --global core.autocrlf input

# pre-init ssh
mkdir -p -m 0700 ~/.ssh
echo '# see https://infosec.mozilla.org/guidelines/openssh.html#modern
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
' > ~/.ssh/config

# install composer
cd /tmp/
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'a5c698ffe4b8e849a443b120cd5ba38043260d5c4023dbf93e1558871f1f07f58274fc6f4c93bcfd858c6bd0775cd8d1') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --filename=composer --install-dir=/usr/local/bin
php -r "unlink('composer-setup.php');"

# install go
mkdir -p ~/code/go/bin
wget -q https://dl.google.com/go/go1.13.3.linux-amd64.tar.gz -O /tmp/setup_go.tgz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/setup_go.tgz

# install vs code
wget -q https://update.code.visualstudio.com/latest/linux-rpm-x64/stable -O /tmp/setup_code.rpm
sudo dnf -q -y install /tmp/setup_code.rpm
code --install-extension vscoss.vscode-ansible
code --install-extension bungcip.better-toml
code --install-extension ms-vscode.csharp
code --install-extension ms-vscode.go
code --install-extension eamodio.gitlens
code --install-extension editorconfig.editorconfig
code --install-extension esbenp.prettier-vscode
code --install-extension davidanson.vscode-markdownlint
echo '{
    "editor.fontSize": 16,
    "editor.fontFamily": "FuraMono Nerd Font Mono",
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
    "window.zoomLevel": 0.2,
    "workbench.enableExperiments": false,
    "workbench.startupEditor": "newUntitledFile",
    "emmet.includeLanguages": {
        "vue-html": "html",
        "javascript": "javascriptreact",
        "nunjucks": "html"
    },
    "gitlens.defaultDateFormat": "DD.MM.YYYY HH:mm",
    "gitlens.defaultDateShortFormat": "DD.MM.YYYY",
    "php.validate.executablePath": "/usr/bin/php",
    "prettier.printWidth": 120,
    "prettier.trailingComma": "es5",
    "go.useLanguageServer": true,
    "[go]": {
        "editor.snippetSuggestions": "none",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true,
        },
        "editor.codeActionsOnSaveTimeout": 1500
    },
    "gopls": {
        "usePlaceholders": true, // add parameter placeholders when completing a function
        // ----- Experimental settings -----
        "completeUnimported": true, // autocomplete unimported packages
        "watchChangedFiles": true, // watch file changes outside of the editor
        "deepComplete": true, // deep completion
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
    }
}
' > ~/.config/Code/User/settings.json

# init fish shell
sudo usermod -s /usr/bin/fish denis
wget -q https://get.oh-my.fish -O /tmp/setup_fish.fish
fish /tmp/setup_fish.fish --noninteractive --yes
echo '#setup npm
set -xg NPM_CONFIG_PREFIX $HOME/.npm-global
set -xg PATH $HOME/.npm-global/bin $PATH
# setup go
set -xg PATH $PATH /usr/local/go/bin
set -xg GOPATH $HOME/code/go
set -xg PATH (go env GOPATH)/bin $PATH
# misc stuff
set -xg DEFAULT_USER denis' > ~/.config/omf/init.fish

# clean up
rm -f /tmp/setup_*

echo '
Setup completed...

Last steps:
  * install fonts from ~/Downloads
  * enable h264 plugin in firefox
  * configure firefox
  * start `Tweaks`
    * `Appearance-->Applications` == Adwaita-dark
    * `Extensions-->Alternatetab` == ON
    * `Fonts-->Monospace Text` == FuraMono Nerd Font Mono Regular, Size 14
    * `Top Bar` Weekday ON, Date ON, Week Numbers ON
    * `Windows Titlebars` Maximize ON, Minimize ON, Placement RIGHT
  * configure Terminal
    * `Initial terminal size` 140 columns, 30 rows
    * `Terminal bell` OFF
  * install fish theme
    * `fish`
    * `omf install bobthefish`
  * Reboot
'
