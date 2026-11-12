#!/usr/bin/env bash
#
# Bring a freshly installed Mac to the point where `ansible-playbook main.yaml`
# can run. Safe to re-run; dependency versions are not pinned.
#
set -euo pipefail

cd "$(dirname "$0")"

say() { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(uname -s)" = Darwin ] || { echo 'macOS only.' >&2; exit 1; }
[ "$(uname -m)" = arm64 ] || { echo 'Run natively on Apple silicon.' >&2; exit 1; }
macos_version=$(sw_vers -productVersion)
[ "${macos_version%%.*}" -ge 27 ] || { echo 'macOS 27 or later required.' >&2; exit 1; }

#
# Xcode Command-Line Tools
#
if xcode-select -p >/dev/null 2>&1; then
  say "Command-Line Tools already installed ($(xcode-select -p))"
else
  say 'Installing Xcode Command-Line Tools'
  xcode-select --install
  echo 'Finish the GUI installer, then re-run this script.'
  exit 0
fi

#
# Homebrew
#
if have brew; then
  BREW_BIN=$(command -v brew)
elif [ -x /opt/homebrew/bin/brew ]; then
  BREW_BIN=/opt/homebrew/bin/brew
else
  say 'Installing Homebrew'
  installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
  /bin/bash -c "$installer"
  BREW_BIN=/opt/homebrew/bin/brew
fi

say "Homebrew available ($("$BREW_BIN" --prefix))"
brew_shellenv=$("$BREW_BIN" shellenv)
eval "$brew_shellenv"

#
# Ansible + the collections the playbook uses
#
if have ansible-playbook; then
  say "Ansible already installed ($(ansible --version | sed -n '1p'))"
else
  say 'Installing Ansible'
  brew install ansible
fi

say 'Installing Ansible collections'
ansible-galaxy collection install -r requirements.yml

#
# App Store sign-in is a prerequisite for the `mas` tasks: `mas` can only
# install apps already attached to the account, and `mas signin` no longer
# works headlessly.
#
say 'Next steps'
cat <<'NEXT'
  1. Sign in to the App Store (Apple menu -> App Store -> Sign In).
  2. Add your SSH key before running the playbook -- it clones over SSH:
       see README -> Secrets and identity
  3. ansible-playbook main.yaml
NEXT
