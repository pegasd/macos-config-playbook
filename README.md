# macos-config-playbook

Ansible playbook that takes a freshly installed Mac to a working machine.

Targets macOS 26 (Tahoe) and later on Apple silicon.

## Clean install, start to finish

```bash
git clone git@github.com:pegasd/macos-config-playbook.git
cd macos-config-playbook
./bootstrap.sh          # CLT, Rosetta 2, Homebrew, Ansible, collections
ansible-playbook main.yaml
```

`bootstrap.sh` is idempotent -- re-run it as often as you like. It stops and
tells you what to do next if a step needs the GUI (the Command-Line Tools
installer, App Store sign-in).

Two things must be in place **before** `ansible-playbook`:

- **Signed into the App Store**, or every `mas` task is skipped. `mas` only
  installs apps already attached to the account.
- **An SSH key in the agent**, or the dotfiles and repository clones fail.
  See [Secrets and identity](#secrets-and-identity).

Passwordless sudo is no longer required: nothing in the playbook uses
`become` any more.

## Tags

| Tag | What it does |
| --- | --- |
| `osx_defaults` | `defaults write` settings, plus the iTerm profile |
| `iterm` | iTerm dynamic profile and preferences only |
| `applications` | Homebrew taps/formulae/casks, MAS apps, dotfiles |
| `mas` | Mac App Store apps only |
| `dotfiles` | Dotfiles repo and vim plugins only |
| `fonts` | Font casks only |
| `repos` | Clone personal repositories into `~/Developer` |

```bash
ansible-playbook main.yaml --tags applications
ansible-playbook main.yaml --skip-tags mas
```

## Secrets and identity

Nothing secret lives in this repository, and the playbook will not create any
of it for you. Restore these from Bitwarden or a backup before the first run:

| Path | Notes |
| --- | --- |
| `~/.ssh/id_ed25519{,.pub}` | Needed by the dotfiles and `repos` tasks |
| `~/.ssh/config` | Host aliases |
| `~/.ssh/authorized_keys` | Inbound SSH |
| `~/.ssh/google_compute_engine{,.pub}` | GCE |
| `~/.gitconfig_local` | `user.name` / `user.email`, `includeIf` for work |
| `~/.gitconfig_iow` | Work identity, included conditionally |
| `~/.netrc` | |

`~/.gitconfig` itself ships in the dotfiles repo and only `include`s the two
local files above.

## What is managed where

- **Packages, casks, App Store apps, fonts** -- var lists at the top of
  `main.yaml`.
- **`defaults`** -- `tasks/osx_defaults.yaml`, plus two scripts that Ansible's
  `osx_defaults` module cannot express (see below).
- **Dotfiles** -- cloned from [pegasd/dotfiles](https://github.com/pegasd/dotfiles)
  into `~/.dotfiles` and rsynced over `~`.
- **Repositories** -- `dev_repos` in `main.yaml`, cloned into `~/Developer`.
  Clone-only: an existing checkout is never touched.

App Store IDs must be checked against the **live** store, not against what is
installed -- Apple relists apps under new IDs and the old ones stop working:

```bash
mas list                  # what is installed, with its ID
mas info <id>             # "No apps found" means the ID is dead
```

Pages, Numbers and Keynote all moved to unified iOS/macOS listings; the
Mac-only IDs this repo used to carry (`409201541`, `409203825`, `409183694`)
are delisted and `mas install` fails on them.

### Scripts

`osx_defaults` has no `dict-add`, so a couple of things are shell scripts and
are **not** run by the playbook:

```bash
files/other_defaults   # custom keyboard shortcuts, screenshot location, Chrome keys
files/spotlight        # Spotlight categories and index rebuild -- slow, run rarely
```

## Manual steps

Things macOS no longer lets a script do, in rough order of annoyance:

- **Accessibility** (`com.apple.universalaccess`): scroll-to-zoom, zoom
  modifier, Reduce Motion. This domain is TCC-protected -- writes need Full
  Disk Access and are only re-read by the accessibility daemon at login, so
  they were silently doing nothing. Set them in System Settings.
- **Keyboard**: Caps Lock -> Control, Control -> Escape.
- **v2RayTun** -- has been pulled from the App Store, so `mas` cannot
  reinstall it. Keep a copy of the `.app`, or find a replacement.
- **Untapped.gg Companion** -- no cask; download it, and re-add it as a login
  item.
- **Blizzard games** (StarCraft, StarCraft II, Diablo III, Hearthstone,
  Warcraft III) -- installed through the `battle-net` cask once it is running.
- **Steam / Epic / GOG libraries** -- the launchers are casks, the games are not.
- **Xcode** -- only install it if you actually need it. The Command-Line Tools
  that `bootstrap.sh` installs are enough for Homebrew and everything here.

## Contributing

Feel free to submit issues, PRs, or just comment.
