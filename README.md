# macos-config-playbook

Ansible playbook that takes a freshly installed Mac to a working machine.

Targets macOS 27 and later on Apple silicon.

[Rosetta remains supported through macOS 27](https://support.apple.com/en-gb/102527).
General-purpose Intel app support ends with macOS 28. This playbook does not
install Rosetta or manage CrossOver, Wine bottles, or GOG Galaxy; some games
installed through the launchers may still require Rosetta.

## Clean install, start to finish

```bash
git clone git@github.com:pegasd/macos-config-playbook.git
cd macos-config-playbook
./bootstrap.sh          # CLT, Homebrew, Ansible, collections
ansible-playbook main.yaml
```

`bootstrap.sh` is idempotent -- re-run it as often as you like. It stops and
tells you what to do next if a step needs the GUI (the Command-Line Tools
installer, App Store sign-in).

Two things must be in place **before** `ansible-playbook`:

- **Signed into the App Store**, or missing App Store apps fail to install.
  `mas install` installs apps already attached to the account.
- **An SSH key in the agent**, or the dotfiles and repository clones fail.
  See [Secrets and identity](#secrets-and-identity).

The playbook does not use `become`. Homebrew cask installers and
[`mas install`](https://github.com/mas-cli/mas#commands) can still require sudo
credentials; run interactively and authenticate when requested.

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
- **Steam library** -- the launcher is a cask, the games are not.
- **Epic Games library** -- the launcher is managed by the `epic-games` cask;
  install games through the launcher.
- **Xcode** -- only install it if you actually need it. The Command-Line Tools
  that `bootstrap.sh` installs are enough for Homebrew and everything here.

## Secrets and identity

Create or restore your SSH key, add its public key to the Git hosting accounts,
and load it into the agent before cloning private repositories:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
ssh -T git@github.com
```

Use your actual key path. Verify host fingerprints before accepting new hosts.
Restore `~/.gitconfig_local` and other private configuration separately; keep
secrets out of this repository.

## Verification

```bash
ansible-playbook main.yaml --syntax-check
ansible-playbook main.yaml --check --diff --skip-tags applications,mas,dotfiles,repos
```

The second command previews preferences and fonts without applying them.
Review diffs locally: they may include personal configuration. Package and
clone tasks are excluded because they can need network access or prerequisites
that are missing on a fresh machine.

### Continuous integration

GitHub Actions runs on pushes, pull requests, and manual dispatches. It checks
shell, JSON, and playbook syntax, then applies the `osx_defaults` tag (including
the iTerm profile) twice and requires zero changes on the second run.

CI uses GitHub's [macOS 27 ARM runner](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md),
currently available under the `xcode-27` preview label. It does not run
`bootstrap.sh`, install applications or fonts, access the App Store, sync
dotfiles, or clone personal repositories. Those steps require separate
verification on a provisioned Mac.

## Contributing

Feel free to submit issues, PRs, or just comment.
