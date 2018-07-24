# macos-config-playbook

[![Build Status](https://travis-ci.org/pegasd/macos-config-playbook.svg?branch=master)](https://travis-ci.org/pegasd/macos-config-playbook)

## Installation

Pre-requisites:

- Xcode Command-Line Tools:

```bash
xcode-select --install
# This might only be needed on Mojave
open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg
```

- homebrew

```bash
# Looks scary, but seems to do the trick
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

- ansible

```bash
brew install ansible
```

## Running

To run the playbook:

```bash
ansible-playbook main.yaml
```

### dotfiles

This is configured to install and update the [following dotfiles repository](https://github.com/pegasd/dotfiles).

### defaults

Most of the `defaults` configuration is done through `tasks/osx_defaults.yaml`.

Unfortunately, Ansible is lacking `dict` and `dict-add` support (despite a well done [PR](https://github.com/ansible/ansible/issues/24028)) in its `osx_defaults` module, so there are a couple of scripts that can be ran manually:

```bash
files/other_defaults
files/spotlight
```

**files/other_defaults**

- Custom keyboard shortcuts require `dict-add`.
- Screenshot location (it has `~` in it) is expanded at runtime and is not idempotent.

**files/spotlight**

- Spotlight configuration removes all volumes but `/` from indexing configuration and re-builds index on `/`.
- I don't recommend running this often.

## Issues

This might be a Mojave Beta-only issue, but `defaults write` treats all passed values as strings (whether they should be booleans,
integers, or floats) in a construct like this:

```bash
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "{ enabled = 1; value = { type = standard; parameters = ( 32, 49, 1048576 ); }; }"
```

## Contributing

Feel free to submit issues, PRs, or just comment.
