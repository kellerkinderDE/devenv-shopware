# Setup
Copy all files from the example folder into a project and enter it (assuming you have direnv installed). Run `direnv allow` if it asks you to.

Make sure to run the following command to accelerate the startup process:
```bash
cachix use devenv ; cachix use fossar ; cachix use shopware
```
Add the following files to the project `.gitignore` file:
- `.devenv*`
- `devenv.local.nix`

# Options
A full list of options can be found [here](Options.md).

# Different PHP versions
If you want to use a specific PHP version, you can set the following versions
in your project `devenv.nix` file. The php.ini configuration is >php80 specific
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

# PHP debugging
As mentioned in the features section, devenv is shipped with Xdebug. You need to activate it to actually debug something. For the Frontend, you can use the [Xdebug helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc?gl=US&hl=en) extension when using Chrome. Alternatively, you can simply add a query parameter to the URL you want to debug. Like this: `https://127.0.0.1:8000/?XDEBUG_SESSION=1`
This also works great when having to debug API requests, e.g. in Insomnia.

For the CLI, you can use the integrated debug helper `debug` by simply adding it before your CLI commands, e.g. `debug bin/console`.
