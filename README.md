# macos-config-playbook

## Installation

> I haven't tested a clean install of this yet.

You'll probably need at least the following:

- Xcode Command-Line Tools:
```bash
xcode-select --install
```
- homebrew
```bash
# Looks scary, but seems to do the trick
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

## Running

### dotfiles

This is configured to install and update the [following dotfiles repository](https://github.com/pegasd/dotfiles).

### defaults

Most of the `defaults` configuration is done through `tasks/osx_defaults.yaml`.

Unfortunately, Ansible is lacking `dict` and `dict-add` support (despite a well done [PR](https://github.com/ansible/ansible/issues/24028)) in its `osx_defaults` module, so there are a couple of scripts that can be ran manually.

**files/other_defaults**

- Custom keyboard shortcuts require `dict-add`.
- Screenshot location (it has `~` in it) is expanded at runtime and is not idempotent.

**files/spotlight**

Spotlight configuration removes all volumes but `/` from indexing configuration and re-builds index on `/`.

I don't recommend running this often.

This might be a Mojave Beta-only issue, but `defaults` read all values (inside an array of dicts) as strings
(whether they were booleans, integers, or floats).

## Issues

## Contributing

Feel free to submit issues, PRs, or just comment.
