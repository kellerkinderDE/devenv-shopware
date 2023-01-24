# Kellerkinder devenv

devenv provides a reproducible and declarative local development environment for our [Shopware](https://www.shopware.com) projects.
It uses the [Nix package system](https://nixos.org/) to provide native packages for all our required services. This environment is
tightly tailored to the needs of our team members working on various projects with Shopware 6.

### Notable Features:
- Overrides Shopware's default mailer configuration to use [MailHog](https://github.com/mailhog/MailHog)
- Provides helper functions to clear caches
- Enables XDebug without a performance impact when not using it
- Easily configurable PHP Version
- Inherits all default devenv features and services

### More Information:
- https://devenv.sh/
- https://developer.shopware.com/docs/guides/installation/devenv

### Setup
Copy all files from the example folder into a project and enter it (assuming you have direnv installed). Run `direnv allow` if it asks you to.

Make sure to run `cachix use devenv ; cachix use fossar ; cachix use shopware`, to speed the startup process.

Add the following files to the project .gitignore file:
- .devenv*
- devenv.local.nix

### Different PHP versions

If you want to use a specific PHP version, you can set the following versions 
in your project devenv.nix file. The php.ini configuration is >php80 specific
and needs to be adjusted when using a lower version. 

- php56
- php70
- php71
- php72
- php73
- php74
- php80
- php81
- php82

## License
MIT
