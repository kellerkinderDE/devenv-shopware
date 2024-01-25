# kellerkinder.phpVersion
Allows to define the used PHP Version. For supported versions, see [Different PHP versions](Home.md#different-php-versions)

*_Example_*
```
kellerkinder.phpVersion = "php80";
```

# kellerkinder.systemConfig
Define shopware system config values.

*_Example_*
```
kellerkinder.systemConfig = {
    "foo.bar.testString" = "false";
};
```

# kellerkinder.additionalPhpConfig
Define additional php.ini settings, which are used for php-fpm and php-cli.

*_Example_*
```
kellerkinder.additionalPhpConfig = ''
    memory_limit = 200M
'';
```

# kellerkinder.additionalPhpExtensions
Define additional PHP extensions that are included in php-fpm and php-cli.

*_Example_*
```
kellerkinder.additionalPhpExtensions = [
   "mailparse"
];
```

# kellerkinder.additionalServerAlias
Define additional server aliases that are added to caddy.

*_Example_*
```
kellerkinder.additionalServerAlias = [
   "example.com"
];
```

# kellerkinder.additionalVhostConfig
Define additional vhost configurations that are appended to the general vhost configuration.

*_Example_*
```
kellerkinder.additionalVhostConfig = ''
  tls internal
'';
```

# kellerkinder.enableRabbitMq
Enables the RabbitMQ message broker and amqp PHP extension. Can be used for the Symfony message queue.

*_Example_*
```
kellerkinder.enableRabbitMq = true;
```

# kellerkinder.enableElasticsearch
Enables the Elasticsearch service and configures Shopware to use Elasticsearch in addition to the default MySQL search.
Only one of kellerkinder.enableElasticsearch or kellerkinder.enableOpenSearch should be enabled.

*_Example_*
```
kellerkinder.enableElasticsearch = true;
```

# kellerkinder.enableOpenSearch
Enables the OpenSearch service and configures Shopware to use OpenSearch in addition to the default MySQL search.
Only one of kellerkinder.enableElasticsearch or kellerkinder.enableOpenSearch should be enabled.

*_Example_*
```
kellerkinder.enableOpenSearch = true;
```

# kellerkinder.importDatabaseDumps

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

# kellerkinder.documentRoot
Changes the default document root (`public`) of caddy to the specified value

*_Example for the current folder_*
```
kellerkinder.documentRoot = ".";
```

# kellerkinder.projectRoot
Changes the default root of the project to the specified value (no `/` as pre- or suffix required)

*_Example for a `project` folder inside the current folder_*
```
kellerkinder.projectRoot = "project";
```

# kellerkinder.indexFile
Sets the caddy index file for the document root

*_Example_*
```
kellerkinder.indexFile = "shopware.php";
```

# kellerkinder.staticFilePaths
Adjusts the defined matcher paths for caddy. You might want to adjust those to access/handle `*.php` files.

**NOTE**: The path can not be empty!

*_Example_*
```
kellerkinder.staticFilePaths = "myCustomFolder/*";
```

# kellerkinder.fallbackMediaUrl
Fallback redirect URL for media not found on local storage. Best for CDN purposes without downloading them.

*_Example_*
```
kellerkinder.fallbackMediaUrl = "https://my-cool-cdn-in-public-staging.example-cdn.com";
```

# kellerkinder.fallbackMediaPaths
Sets the paths to be redirected to the fallbackMediaUrl.

*_Example_*
```
kellerkinder.fallbackMediaPaths = "/media/* /thumbnail/*";
```

# kellerkinder.additionalPackages
Define packages that should be installed additionally.

*_Example_*
```
kellerkinder.additionalPackages = [ pkgs.jpegoptim pkgs.optipng pkgs.gifsicle ];
```

# kellerkinder.enableMysqlBinLog
Enables the MySQL Binary Log and adds configuration for it.

*_Example_*
```
kellerkinder.enableMysqlBinLog = false;
```

# kellerkinder.httpPort
Sets the http port for caddy.

_This has to be an int_

*_Example_*
```
kellerkinder.httpPort = 8080;
```

# kellerkinder.httpsPort
Sets the https port for caddy.

_This has to be an int_

*_Example_*
```
kellerkinder.httpsPort = 8443;
```

# kellerkinder.mysqlPort
Sets the MySQL port.

_This has to be an int_

*_Example_*
```
kellerkinder.mysqlPort = 3307;
```

# kellerkinder.adminerPort
Sets the Adminer port.

_This has to be an int_

*_Example_*
```
kellerkinder.adminerPort = 8010;
```

# kellerkinder.mailhogApiPort
Sets the Mailhog API port.

_This has to be an int_

*_Example_*
```
kellerkinder.mailhogApiPort = 8025;
```

# kellerkinder.mailhogSmtpPort
Sets the Mailhog SMTP port.

_This has to be an int_

*_Example_*
```
kellerkinder.mailhogSmtpPort = 1025;
```

# kellerkinder.mailhogUiPort
Sets the Mailhog Web UI port.

_This has to be an int_

*_Example_*
```
kellerkinder.mailhogUiPort = 8025;
```

# kellerkinder.redisPort
Sets the Redis port.

_This has to be an int_

*_Example_*
```
kellerkinder.redisPort = 6379;
```

# kellerkinder.elasticsearchPort
Sets the Elasticsearch/OpenSearch port.

_This has to be an int_

*_Example_*
```
kellerkinder.elasticsearchPort = 9200;
```

# kellerkinder.elasticsearchTcpPort
Sets the Elasticsearch/OpenSearch TCP port.

_This has to be an int_

*_Example_*
```
kellerkinder.elasticsearchTcpPort = 9300;
```

# kellerkinder.rabbitMqPort
Sets the RabbitMQ port.

_This has to be an int_

*_Example_*
```
kellerkinder.rabbitMqPort = 5672;
```

# kellerkinder.rabbitMqManagementPluginPort
Sets the RabbitMQ management plugin port.

_This has to be an int_

*_Example_*
```
kellerkinder.rabbitMqManagementPluginPort = 15672;
```
