#!/usr/bin/env bash
#
# Bring a freshly installed Mac to the point where `ansible-playbook main.yaml`
# can run. Safe to re-run: every step is a no-op once satisfied.
#
set -euo pipefail

say() { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(uname -s)" = Darwin ] || { echo 'macOS only.' >&2; exit 1; }

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
# Rosetta 2 -- still needed by a few Intel-only apps (Battle.net games, CrossOver bottles)
#
if [ "$(uname -m)" = arm64 ]; then
  if /usr/bin/pgrep -q oahd; then
    say 'Rosetta 2 already installed'
  else
    say 'Installing Rosetta 2'
    softwareupdate --install-rosetta --agree-to-license
  fi
fi

#
# Homebrew
#
if have brew; then
  say "Homebrew already installed ($(brew --prefix))"
else
  say 'Installing Homebrew'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_PREFIX=$(/opt/homebrew/bin/brew --prefix 2>/dev/null || /usr/local/bin/brew --prefix)
eval "$("${BREW_PREFIX}/bin/brew" shellenv)"

#
# Ansible + the collections the playbook uses
#
if have ansible-playbook; then
  say "Ansible already installed ($(ansible --version | head -1))"
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
