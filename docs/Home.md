# Setup
Copy all files from the example folder into a project and enter it (assuming you have direnv installed). Run `direnv allow` if it asks you to.

Make sure to run the following command to accelerate the startup process:
```bash
cachix use devenv ; cachix use fossar ; cachix use shopware
```
Add the following files to the project `.gitignore` file:
- `.devenv*`
- `devenv.local.nix`
- `.direnv`

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

# MySQL Configuration

The configuration is based on recommendations from Shopware. You can find the documentation [here](https://developer.shopware.com/docs/guides/hosting/performance/performance-tweaks.html#mysql-configuration).
By default, we change the following configurations:

| Setting              | Value                                                                                              | description                                                                                                                 |
|----------------------|----------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| group_concat_max_len | 32000                                                                                              | Shopware highly uses GROUP_CONCAT functions within the Database. This setting ensures, that all queries will run correctly. |
| key_buffer_size      | 16777216                                                                                           | Defines, how many index buffers can be held in memory                                                                       |
| max_allowed_packet   | 134217728                                                                                          | Defines, how much data can be send within one request before the server blocks it.                                          |
| table_open_cache     | 1024                                                                                               | Shopware uses many tables, This settings allows the server to keep more tables open                                         |
| sql_mode             | STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION | the default from MySQL, but without ONLY_FULL_GROUP_BY                                                                      |

# Built in Commands

| Command       | Description                                                                      |
|---------------|----------------------------------------------------------------------------------|
| `cc`          | Runs the shopware cache:clear comamnd - works in every subdirectory              |
| `uuid`        | Generates a valid uuid v4 and displays it                                        |                                                                                                                 |
| `caddy-trust` | Trusts the current SSL certificates from caddy to prevent certification warnings |    
| `debug`       | Runs the following php command with xdebug enabled: `debug bin/console test`     |    

# Environment variables

We're setting some environment variables as default.
As example, we're setting SQL_SET_DEFAULT_SESSION_VARIABLES default to `O`, since we're having the shopware recommended configuration for the database.
