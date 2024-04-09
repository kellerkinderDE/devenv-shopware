# Kellerkinder devenv
[![GitHub Release](https://img.shields.io/github/v/release/kellerkinderDE/devenv-shopware.svg?style=flat)](https://github.com/kellerkinderDE/devenv-shopware/releases)
[![Tests](https://github.com/kellerkinderDE/devenv-shopware/actions/workflows/test_examples.yml/badge.svg)](https://github.com/kellerkinderDE/devenv-shopware/actions/workflows/test_examples.yml)

devenv provides a reproducible and declarative local development environment for our [Shopware](https://www.shopware.com) projects.
It uses the [Nix package system](https://nixos.org/) to provide native packages for all our required services. This environment is
tightly tailored to the needs of our team members working on various projects with Shopware 6.

## Notable Features:
- Overrides Shopware's default mailer configuration to use [MailHog](https://github.com/mailhog/MailHog)
- Provides helper functions to clear caches
- Enables Xdebug without a performance impact when not using it
- Easily configurable PHP Version
- Inherits all default devenv features and services
- Pre-installed [shopware-cli](https://sw-cli.fos.gg/)

## Requirements
* devenv: `v1.0.3` or higher

## Setup & Usage
A description about the setup and usage can be found in the [Wiki](https://github.com/kellerkinderDE/devenv-shopware/wiki).

### Multiple Projects
If you want to run multiple projects at same time, you may need to choose a different `process.implementation` instead of `process-compose`.
This would be possible by adding `process.implementation = "honcho";` to your `devenv.nix`.

A complete list of possible options can be found [here](https://devenv.sh/reference/options/#processimplementation)

### Update
To update your devenv config to the latest version, simply follow the update instructions for the new version in the [Wiki](https://github.com/kellerkinderDE/devenv-shopware/wiki/Update)

### Default values
#### MySQL
The default values for MySQL are:

| Type          | Value      |
|---------------|------------|
| User          | `shopware` |
| Password      | `shopware` |
| Database name | `shopware` |

## More Information:
- https://devenv.sh/
- https://developer.shopware.com/docs/guides/installation/devenv

## License
MIT
