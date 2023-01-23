# Kellerkinder devenv



## Setup
Copy all files from the example folder into a project and enter it (assuming you have direnv installed). Run `direnv allow` if it asks you to.

Make sure to run `cachix use devenv ; cachix use fossar ; cachix use shopware`, to speed the startup process.

Add the following files to the project .gitignore file:
- .devenv*
- devenv.local.nix

## Different PHP versions

If you want to use a specific PHP version you can set the following versions in the project devenv.nix file. The php.ini configuration is >php80 specific
needs to be adjusted when using a lower version.

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
