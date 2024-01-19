{ pkgs, config, inputs, lib, ... }:
let
in {
  options.kellerkinder = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enables the Kellerkinder devenv environment";
      default = true;
    };

    phpVersion = lib.mkOption {
      type = lib.types.str;
      description = "PHP Version";
      default = "php81";
    };

    systemConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "shopware system config settings";
      default = { };
      example = {
        "foo.bar.testString" = "false";
      };
    };

    additionalPhpConfig = lib.mkOption {
      type = lib.types.str;
      description = "Additional php.ini configuration";
      default = "";
      example = ''
        memory_limit = 0
      '';
    };

    additionalPhpExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Additional PHP extensions";
      default = [ ];
      example = [ "mailparse" ];
    };

    additionalVhostConfig = lib.mkOption {
      type = lib.types.str;
      description = "Additional vhost configuration";
      default = "";
    };

    additionalServerAlias = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Additional server alias";
      default = [ ];
      example = [ "example.com" ];
    };

    enableElasticsearch = lib.mkOption {
      type = lib.types.bool;
      description = "Enables Elasticsearch";
      default = false;
    };

    enableOpenSearch = lib.mkOption {
      type = lib.types.bool;
      description = "Enables OpenSearch";
      default = false;
    };

    enableRabbitMq = lib.mkOption {
      type = lib.types.bool;
      description = "Enables RabbitMQ";
      default = false;
    };

    importDatabaseDumps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of links to be imported with command importdb";
      default = [ ];
      example = [
        "http://localhost/dump.sql.gz"
        "http://localhost/dump.sql"
      ];
    };

    documentRoot = lib.mkOption {
      type = lib.types.str;
      description = "Sets the docroot of caddy";
      default = "public";
    };

    indexFile = lib.mkOption {
      type = lib.types.str;
      description = "Sets the caddy index file for the document root";
      default = "index.php";
    };

    projectRoot = lib.mkOption {
      type = lib.types.str;
      description = "Root of the project as path from the file devenv.nix";
      default = ".";
      example = "project";
    };

    staticFilePaths = lib.mkOption {
      type = lib.types.str;
      description = ''Sets the matcher paths to be "ignored" by caddy'';
      default = "/theme/* /media/* /thumbnail/* /bundles/* /css/* /fonts/* /js/* /recovery/* /sitemap/*";
    };

    fallbackMediaUrl = lib.mkOption {
      type = lib.types.str;
      description = ''Fallback URL for media not found on local storage. Best for CDN purposes without downloading them.'';
      default = "";
    };

    fallbackMediaPaths = lib.mkOption {
      type = lib.types.str;
      description = ''Sets the paths to be redirected to the fallbackMediaUrl.'';
      default = "/media/* /thumbnail/*";
    };

    additionalPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      description = "Additional packages to be installed";
      default = [ ];
      example = [ pkgs.jpegoptim pkgs.optipng pkgs.gifsicle ];
    };

    enableMysqlBinLog = lib.mkOption {
      type = lib.types.bool;
      description = ''Enables MySQL binary logs'';
      default = false;
    };

    httpPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the HTTP port'';
      default = 80;
    };

    httpsPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the HTTPS port'';
      default = 443;
    };

    mysqlPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the MySQL port'';
      default = 3306;
    };

    adminerPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the Adminer port'';
      default = 8010;
    };

    mailhogApiPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the Mailhog API port'';
      default = 8025;
    };

    mailhogSmtpPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the Mailhog SMTP port'';
      default = 1025;
    };

    mailhogUiPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the Mailhog Web UI port'';
      default = 8025;
    };

    redisPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the Redis port'';
      default = 6379;
    };

    elasticsearchPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the Elasticsearch/OpenSearch port'';
      default = 9200;
    };

    elasticsearchTcpPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the Elasticsearch/OpenSearch TCP port'';
      default = 9300;
    };

    rabbitMqPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the RabbitMQ port'';
      default = 5672;
    };

    rabbitMqManagementPluginPort = lib.mkOption {
      type = lib.types.int;
      description = ''Sets the RabbitMQ management plugin port'';
      default = 15672;
    };
  };
}
