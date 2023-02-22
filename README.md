# Kellerkinder devenv

devenv provides a reproducible and declarative local development environment for our [Shopware](https://www.shopware.com) projects.
It uses the [Nix package system](https://nixos.org/) to provide native packages for all our required services. This environment is
tightly tailored to the needs of our team members working on various projects with Shopware 6.

## Notable Features:
- Overrides Shopware's default mailer configuration to use [MailHog](https://github.com/mailhog/MailHog)
- Provides helper functions to clear caches
- Enables XDebug without a performance impact when not using it
- Easily configurable PHP Version
- Inherits all default devenv features and services

## More Information:
- https://devenv.sh/
- https://developer.shopware.com/docs/guides/installation/devenv

## Setup
Copy all files from the example folder into a project and enter it (assuming you have direnv installed). Run `direnv allow` if it asks you to.

Make sure to run the following command to accelerate the startup process:
```bash
cachix use devenv ; cachix use fossar ; cachix use shopware
```
Add the following files to the project .gitignore file:
- .devenv*
- devenv.local.nix

## Options

### kellerkinder.phpVersion
Allows to define the used PHP Version. For supported versions see [Different PHP versions](#different-php-versions)

*_Example_*
```
kellerkinder.phpVersion = "php80";
```

### kellerkinder.systemConfig
Define shopware systemconfig values.

*_Example_*
```
kellerkinder.systemConfig = {
    "foo.bar.testString" = "false";
};
```

### kellerkinder.additionalPhpConfig
Define additional php.ini settings which are used for php-fpm and php-cli.

*_Example_*
```
kellerkinder.additionalPhpConfig = ''
    memory_limit = 200M
'';
```

### kellerkinder.additionalPhpExtensions
Define additional PHP extensions that are included in php-fpm and php-cli.

*_Example_*
```
kellerkinder.additionalPhpExtensions = [
   "mailparse"
];
```

### kellerkinder.additionalServerAlias
Define additional server aliases that are added to caddy.

*_Example_*
```
kellerkinder.additionalServerAlias = [
   "example.com"
];
```

### kellerkinder.additionalVhostConfig
Define additional vhost configurations that are appended to the general vhost configuration.

*_Example_*
```
kellerkinder.additionalVhostConfig = ''
  tls internal
'';
```

### kellerkinder.enableRabbitMq
Enables the RabbitMQ message broker and amqp PHP extension. Can be used for the Symfony message queue.

*_Example_*
```
kellerkinder.enableRabbitMq = true;
```

### kellerkinder.enableElasticsearch
Enables the Elasticsearch service and configures Shopware to use Elasticsearch in addition to the default
MySQL search.

*_Example_*
```
kellerkinder.enableElasticsearch = true;
```

### kellerkinder.importDatabaseDumps

You can import a list of links of database dumps by using the command `importdb`.
Define a list of links like in the example below.

Supported files:
- *.sql
- *.gz
- *.zip

*_Example_*
```
kellerkinder.importDatabaseDumps = [
    "http://localhost/dump.sql.gz"
    "http://localhost/admin_logins.sql"
];
```

### kellerkinder.documentRoot
Changes the default document root (`public`) of caddy to the specified value

*_Example for the current folder_*
```
kellerkinder.documentRoot = ".";
```
### kellerkinder.staticFilePaths
Adjusts the defined matcher paths for caddy. You might want to adjust those to access/handle `*.php` files.

**NOTE**: The path can not be empty!

*_Example_*
```
kellerkinder.staticFilePaths = "myCustomFolder/*";
```

## Different PHP versions

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

## License
MIT
