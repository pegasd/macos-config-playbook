# macos-config-playbook

Ansible playbook that takes a freshly installed Mac to a working machine.

Targets macOS 27 on Apple silicon. Later releases need fresh verification.

[Rosetta remains supported through macOS 27](https://support.apple.com/en-gb/102527).
General-purpose Intel app support ends with macOS 28. This playbook does not
install Rosetta or manage CrossOver, Wine bottles, or GOG Galaxy; some games
installed through the launchers may still require Rosetta.

## Clean install, start to finish

On a fresh Mac, run `xcode-select --install` and finish the Command-Line Tools
installer before cloning: Apple's `git` needs those tools too.

```bash
git clone https://github.com/pegasd/macos-config-playbook.git
cd macos-config-playbook
./bootstrap.sh          # CLT, Homebrew, Ansible, collections
ansible-playbook main.yaml
```

`bootstrap.sh` is idempotent. It installs missing prerequisites and collections;
versions are unpinned and fresh setups may pick up newer releases. It stops if
the Command-Line Tools need installation and prints the remaining App Store and
SSH steps.
Homebrew must be on your shell's `PATH` when running Ansible. On a fresh shell,
run `eval "$(/opt/homebrew/bin/brew shellenv)"` if needed.

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
  into `~/.dotfiles` and rsynced over `~`. With the default
  `update_dotfiles: true`, the checkout is forcibly updated, discarding local
  edits, and matching files in your home directory can be overwritten. Review
  and back up local changes first. `-e update_dotfiles=false` preserves the
  checkout revision; it still copies its contents into your home directory.
- **Repositories** -- `dev_repos` in `main.yaml`, cloned into `~/Developer`.
  Clone-only: an existing checkout is never touched.

Check App Store IDs against the **live** store as well as installed receipts:
apps can be relisted under new IDs. Availability also depends on your account's
storefront; a failed lookup alone does not prove worldwide delisting.

```bash
mas list                  # what is installed, with its ID
mas lookup <id>           # live details; `info` is an alias
```

The four configured IDs were verified against the US storefront on 2026-11-12.
[`mas` depends on Spotlight indexing](https://github.com/mas-cli/mas#spotlight)
to detect installed apps. If `mas list` hangs or misses an app, check its
indexing before retrying; the playbook does not rebuild the index automatically.

### Scripts

`osx_defaults` has no `dict-add`, so a couple of things are shell scripts and
are **not** run by the playbook:

```bash
files/other_defaults   # custom keyboard shortcuts, screenshot location, Chrome keys
files/spotlight        # Spotlight categories and index rebuild -- slow, run rarely
```

`other_defaults` merges Chrome's tab shortcuts into existing app shortcuts.
If they do not appear, add Chrome in System Settings > Keyboard > Keyboard
Shortcuts > App Shortcuts. Restart Chrome or log out/in to reload preferences.

`spotlight` writes legacy `orderedItems` preferences whose effect must be
verified in System Settings on current macOS, then enables indexing and requests
a rebuild of the startup volume. Configure excluded disks through
[Spotlight > Search Privacy](https://support.apple.com/guide/mac-help/mchl1bb43b84/mac).
The script does not configure exclusions for future mounted volumes.

## Manual steps

Setup that the playbook leaves to you:

- **Accessibility** (`com.apple.universalaccess`): scroll-to-zoom, zoom
  modifier, Reduce Motion. Direct preference writes can be blocked by privacy
  protections or fail to affect the running service. Set them in System Settings.
- **Keyboard**: Caps Lock -> Control, Control -> Escape.
- **Screen lock** -- in System Settings > Lock Screen, set "Require password
  after screen saver begins or display is turned off" to five seconds or
  immediately. Check the active policy with `sysadminctl -screenLock status`.
  The old `com.apple.screensaver` user defaults can disagree with the active
  policy and are no longer managed here.
- **v2RayTun** -- not managed by the playbook. Check availability in your App
  Store storefront before relying on a reinstall; retain your existing copy.
- **Untapped.gg Companion** -- no cask; download it, and re-add it as a login
  item.
- **Blizzard games** (StarCraft, StarCraft II, Diablo III, Hearthstone,
  Warcraft III) -- installed through the `battle-net` cask once it is running.
- **Steam library** -- the launcher is a cask, the games are not.
- **Epic Games library** -- the launcher is managed by the `epic-games` cask;
  install games through the launcher.
- **Xcode** -- only install it if you actually need it. The Command-Line Tools
  are enough for this playbook and normal Homebrew bottle installs; building
  some packages from source can require full Xcode.
- **Containers** -- run `colima start` before using Docker. For Buildx, merge
  `"cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]` into
  `~/.docker/config.json`, preserving any existing settings, as required by
  [Homebrew's docker-buildx package](https://formulae.brew.sh/formula/docker-buildx).
- **IntelliJ IDEA CE** -- discontinued and listed for removal by the playbook.
  No replacement IDE is installed.

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

These checks validate the stored values, not whether macOS or an application
still honours every preference. Some keys are undocumented or retained for
older applications. Verify keyboard, login security, Dock, and app behaviour
after applying, and restart affected apps or log out/in when needed.

The iTerm tasks use current window placement, tab style, close-button, and
Control-key preferences. The dynamic profile sets `Title Components: 1`
(session name) instead of the old global job/profile-name switches. The
`BM Growl` profile key remains the current notification setting despite its name.

### Continuous integration

GitHub Actions runs on pushes, pull requests, and manual dispatches. It checks
shell, JSON, and playbook syntax and runs ShellCheck, then applies the
`osx_defaults` tag (including the iTerm profile) twice and requires zero changes
on the second run.

CI uses GitHub's [macOS 27 ARM runner](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md),
currently available under the `xcode-27` preview label. It does not run
`bootstrap.sh`, install applications or fonts, access the App Store, sync
dotfiles, or clone personal repositories. Those steps require separate
verification on a provisioned Mac.

Ansible and collection versions are unpinned, so CI also checks compatibility
with current releases. Passing CI does not validate package availability or
App Store access.

## Contributing

Feel free to submit issues, PRs, or just comment.
