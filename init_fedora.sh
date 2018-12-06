#!/usr/bin/env bash
set -eu

sudo dnf -q -y update
sudo dnf -q -y install ansible fish git gnome-tweak-tool nano nodejs open-vm-tools-desktop ShellCheck wireshark
sudo dnf -q -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-29.noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-29.noarch.rpm
sudo dnf -q -y config-manager --set-enabled fedora-cisco-openh264
sudo dnf -q -y install gstreamer1-plugin-openh264 mozilla-openh264

# download nice fonts
wget -q https://github.com/tonsky/FiraCode/raw/master/distr/otf/FiraCode-Regular.otf -O ~/Downloads/fonts_firacode_regular.otf
wget -q https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Regular/complete/Fura%20Mono%20Regular%20Nerd%20Font%20Complete%20Mono.otf -O ~/Downloads/fonts_furacode_regular_mono.otf

# setup git
git config --global user.email "go.github@darker.red"
git config --global user.name "Denis Brodbeck"
git config --global core.autocrlf input

# install go
mkdir -p ~/code/go/bin
wget -q https://dl.google.com/go/go1.11.2.linux-amd64.tar.gz -O /tmp/setup_go.tgz
sudo tar -C /usr/local -xzf /tmp/setup_go.tgz
wget -q https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 -O ~/code/go/bin/dep
chmod 0755 ~/code/go/bin/dep

# install vs code
wget -q https://update.code.visualstudio.com/latest/linux-rpm-x64/stable -O /tmp/setup_code.rpm
sudo dnf -q -y install /tmp/setup_code.rpm
code --install-extension vscoss.vscode-ansible
code --install-extension davidanson.vscode-markdownlint
code --install-extension bungcip.better-toml
code --install-extension peterjausovec.vscode-docker
code --install-extension ms-vscode.go
code --install-extension ryu1kn.partial-diff
code --install-extension esbenp.prettier-vscode
code --install-extension editorconfig.editorconfig
echo '{
    "workbench.enableExperiments": false,
    "workbench.startupEditor": "newUntitledFile",
    "editor.fontFamily": "Fira Code",
    "editor.fontLigatures": true,
    "window.zoomLevel": 1,
    "files.eol": "\n",
    "files.insertFinalNewline": true,
    "files.trimTrailingWhitespace": true,
    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false,
    "explorer.openEditors.visible": 0,
    "extensions.ignoreRecommendations": true,
    "prettier.printWidth": 120
}' > ~/.config/Code/User/settings.json

# init fish shell
sudo usermod -s /usr/bin/fish denis
curl -L https://get.oh-my.fish | fish
omf install bobthefish
#wget -q https://get.oh-my.fish -O /tmp/setup_fish.fish
#fish /tmp/setup_fish.fish --noninteractive --yes
echo '# setup go
set -xg PATH $PATH /usr/local/go/bin
set -xg GOPATH $HOME/code/go
set -xg PATH $PATH (go env GOPATH)/bin
# misc stuff
set -xg DEFAULT_USER denis' > ~/.config/omf/init.fish

echo '
Setup completed...

Last steps:
  * install fonts at ~/Downloads
  * start `Tweaks`
    * `Appearance-->Applications` == Adwaita-dark
    * `Extensions-->Alternatetab` == ON
    * `Fonts-->Monospace Text` == FuraMono Nerd Font Mono Regular, Size 14
    * `Top Bar` Weekday ON, Date ON, Week Numbers ON
    * `Windows Titlebars` Maximize ON, Minimize ON, Placement RIGHT
  * configure Terminal
    * `Initial terminal size` 140 columns, 30 rows
    * `Terminal bell` OFF
  * Reboot
'
