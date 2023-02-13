{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;

  phpConfig = lib.strings.concatStrings [''
    memory_limit = 2G
    pdo_mysql.default_socket = ''${MYSQL_UNIX_PORT}
    mysqli.default_socket = ''${MYSQL_UNIX_PORT}
    blackfire.agent_socket = "${config.services.blackfire.socket}";
    realpath_cache_ttl = 3600
    session.gc_probability = 0
    ${lib.strings.optionalString config.services.redis.enable ''
    session.save_handler = redis
    session.save_path = "tcp://127.0.0.1:6379/0"
    redis.session.locking_enabled = 1
    ''}
    display_errors = On
    display_startup_errors = true
    error_reporting = E_ALL
    html_errors = true
    assert.active = 0
    zend.detect_unicode = 0
    opcache.memory_consumption = 256M
    opcache.interned_strings_buffer = 20
    opcache.enable_file_override = 1
    opcache.enable_cli = 1
    opcache.enabled = 1
    zend.assertions = 0
    short_open_tag = 0
    xdebug.mode = "debug"
    xdebug.start_with_request = "trigger"
    xdebug.discover_client_host = 1
    xdebug.var_display_max_depth = -1
    xdebug.var_display_max_data = -1
    xdebug.var_display_max_children = -1
  '' cfg.additionalPhpConfig];

  phpVersion = if builtins.hasAttr "PHP_VERSION" config.env then config.env.PHP_VERSION else cfg.phpVersion;
  package = inputs.phps.packages.${builtins.currentSystem}.${phpVersion};

  phpPackage = package.buildEnv {
    extensions = { all, enabled }: with all; enabled
      ++ (lib.optional config.services.redis.enable redis)
      ++ (lib.optional config.services.blackfire.enable blackfire)
      ++ (lib.optional config.services.rabbitmq.enable amqp)
      ++ lib.attrsets.attrValues (lib.attrsets.getAttrs cfg.additionalPhpExtensions package.extensions );
    extraConfig = phpConfig;
  };

  phpXdebug = package.buildEnv {
    extensions = { all, enabled }: with all; enabled ++ [ xdebug ]
      ++ (lib.optional config.services.redis.enable redis)
      ++ (lib.optional config.services.rabbitmq.enable amqp)
      ++ lib.attrsets.attrValues (lib.attrsets.getAttrs cfg.additionalPhpExtensions package.extensions );
    extraConfig = phpConfig;
  };

  entryScript = pkgs.writeScript "entryScript" ''
    PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"

    while ! ${pkgs.mysql}/bin/mysqladmin ping -u shopware -pshopware --silent; do
      sleep 1
    done

    ${scriptUpdateConfig}

    echo -e "Startup completed"

    sleep infinity
  '';

  systemConfigEntries = lib.mapAttrsToList (name: value: { inherit name value; }) cfg.systemConfig;

  scriptUpdateConfig = pkgs.writeScript "scriptUpdateConfig" ''
    # additional config
    ${lib.concatMapStrings ({ name, value }: ''
      ${updateConfig} ${name} "${lib.escapeShellArg value}"
    '') systemConfigEntries}

    # default config
    ${updateConfig} core.mailerSettings.emailAgent ""
  '';

  updateConfig = pkgs.writeScript "updateConfig" ''
    #!/usr/bin/env php
    <?php declare(strict_types=1);

    $parts = parse_url(getenv('DATABASE_URL'));

    if (empty($parts) || empty(trim(implode("", $parts)))) {
      die("missing configuration");
    }

    $dsn = sprintf("mysql:host=%s:%s;dbname=%s", $parts['host'], $parts['port'], str_replace("/", "", $parts['path']));

    try {
      $pdo = new PDO($dsn, $parts['user'], $parts['pass']);
      $pdo->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
      $pdo->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);
    } catch (\Throwable $exception) {
      die("database connection failed");
    }

    $table = $pdo->query(sprintf("SHOW TABLES LIKE '%s';", 'system_config'))->fetchColumn();

    if ($table === false) {
        die("system_config table is missing, please restart devenv");
    }

    if (empty($argv[1])) {
        die("no configuration key provided");
    }

    $key = (string) $argv[1];
    $value = sprintf('{"_value": "%s"}', $argv[2] ?? "");

    $pdo->prepare("UPDATE system_config SET `configuration_value` = :value  WHERE configuration_key = :key")->execute([
        'value' => $value,
        'key' => $key,
    ]);

    echo sprintf("Configuration %s set to %s\n", $key, empty($argv[2]) ? "empty" : $argv[2]);

    exit(0);
  '';

  importDbHelper = pkgs.writeScript "importDbHelper" ''
    PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"

    if [[ "$1" == "" ]]; then
        echo "Please set devenv configuration for kellerkinder.importDatabaseDumps"
        exit
    fi

    if ! ${config.services.mysql.package}/bin/mysqladmin ping > /dev/null 2>&1; then
        echo "MySQL server is dead or has gone away! devenv up?"
        exit
    fi

    TARGETFOLDER="${config.env.DEVENV_STATE}/importdb"

    rm -rf "$TARGETFOLDER"

    set -e

    if [[ "$1" == *.sql ]]; then
        curl --create-dirs "$1" --output "$TARGETFOLDER/dump.sql"
    elif [[ "$1" == *.gz ]]; then
        curl --create-dirs "$1" --output "$TARGETFOLDER/latest.sql.gz"
        gunzip -c "$TARGETFOLDER/latest.sql.gz" > "$TARGETFOLDER/dump.sql"
    elif [[ "$1" == *.zip ]]; then
        curl --create-dirs "$1" --output "$TARGETFOLDER/latest.sql.zip"
        unzip -j -o "$TARGETFOLDER/latest.sql.zip" '*.sql' -d "$TARGETFOLDER"
    else
        echo "Unsupported file type for file at $1"
        exit
    fi

    rm -f "$TARGETFOLDER/latest.sql.*"

    SQL_FILE=$(find "$TARGETFOLDER" -name "*.sql" | head -n 1)

    if [[ "$SQL_FILE" == "" ]]; then
        echo "No SQL file found"
        exit
    fi

    LANG=C LC_CTYPE=C LC_ALL=C sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' "$SQL_FILE"
    LANG=C LC_CTYPE=C LC_ALL=C sed 's/NO_AUTO_CREATE_USER//' "$SQL_FILE"

    MYSQL_PWD="" ${config.services.mysql.package}/bin/mysql shopware -f < "$SQL_FILE"

    ${scriptUpdateConfig}

    echo "Finished!"
  '';
in {
  options.kellerkinder = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enables the Kellerkinder devenv environment";
    };

    phpVersion = lib.mkOption {
      type = lib.types.str;
      default = "php81";
      description = "PHP Version";
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
      default = "";
      description = "Additional php.ini configuration";
      example = ''
        memory_limit = 0
      '';
    };

    additionalPhpExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Additional PHP extensions";
      default = [ ];
      example = [
        "mailparse"
      ];
    };

    additionalCaddyVhostConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Additional caddy vhost configuration";
    };

    enableElasticsearch = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enables Elasticsearch";
    };

    enableRabbitMq = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enables RabbitMQ";
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
      default = "public";
      description = "Sets the docroot of caddy";
    };

    staticFilePaths = lib.mkOption {
      type = lib.types.str;
      default = "/theme/* /media/* /thumbnail/* /bundles/* /css/* /fonts/* /js/* /recovery/* /sitemap/*";
      description = "Sets the matcher paths to be \"ignored\" by caddy";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.jq
      pkgs.gnupatch
    ];

    languages.javascript.enable = true;
    languages.javascript.package = lib.mkDefault pkgs.nodejs-16_x;

    languages.php.enable = true;
    languages.php.package = lib.mkDefault phpPackage;

    languages.php.fpm.pools.web = {
      settings = {
        "clear_env" = "no";
        "pm" = "dynamic";
        "pm.max_children" = 10;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 10;
      };
    };
    languages.php.fpm.pools.web.phpPackage = lib.mkDefault phpPackage;

    languages.php.fpm.pools.xdebug = {
      settings = {
        "clear_env" = "no";
        "pm" = "dynamic";
        "pm.max_children" = 10;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 10;
      };
    };
    languages.php.fpm.pools.xdebug.phpPackage = lib.mkDefault phpXdebug;

    services.caddy.enable = true;
    services.caddy.package = pkgs.caddy.overrideAttrs (previousAttrs: {
      name = "caddy-next";
      src = pkgs.fetchFromGitHub {
        owner = "caddyserver";
        repo = "caddy";
        rev = "90798f3eea6b7a219a9bb55f680919c0504263e3";
        hash = "sha256-YH+lo6gKqmhu1/3HZdWXnxTXaUwC8To+OCmGpji6i3k=";
      };
    });
    services.caddy.config = "{
      auto_https disable_redirects
    }";
    services.caddy.virtualHosts."127.0.0.1:8000" = lib.mkDefault {
      extraConfig = lib.strings.concatStrings [''
        @default {
          not path ${cfg.staticFilePaths}
          not expression header_regexp('xdebug', 'Cookie', 'XDEBUG_SESSION') || query({'XDEBUG_SESSION': '*'})
        }
        @debugger {
          not path ${cfg.staticFilePaths}
          expression header_regexp('xdebug', 'Cookie', 'XDEBUG_SESSION') || query({'XDEBUG_SESSION': '*'})
        }

        tls internal

        root * ${cfg.documentRoot}

        php_fastcgi @default unix/${config.languages.php.fpm.pools.web.socket}
        php_fastcgi @debugger unix/${config.languages.php.fpm.pools.xdebug.socket}

        encode zstd gzip

        file_server

        log {
          output stderr
          format console
          level ERROR
        }
      '' cfg.additionalCaddyVhostConfig];
    };

    services.mysql.enable = true;
    services.mysql.initialDatabases = lib.mkDefault [{ name = "shopware"; }];
    services.mysql.ensureUsers = lib.mkDefault [
      {
        name = "shopware";
        password = "shopware";
        ensurePermissions = { "*.*" = "ALL PRIVILEGES"; };
      }
    ];
    services.mysql.settings = {
      mysqld = {
        group_concat_max_len = 2048;
        key_buffer_size = 16777216;
        max_allowed_packet = 134217728;
        sync_binlog = 0;
        table_open_cache = 1024;
        log_bin_trust_function_creators = 1;
      };
      mysql = {
        user = "shopware";
        password = "shopware";
        host = "127.0.0.1";
      };
      mysqldump = {
        user = "shopware";
        password = "shopware";
        host = "127.0.0.1";
      };
      mysqladmin = {
        user = "shopware";
        password = "shopware";
        host = "127.0.0.1";
      };
    };

    services.redis.enable = lib.mkDefault true;

    services.adminer.enable = lib.mkDefault true;
    services.adminer.listen = lib.mkDefault "127.0.0.1:8010";

    services.mailhog.enable = true;

    services.elasticsearch.enable = cfg.enableElasticsearch;

    services.rabbitmq.enable = cfg.enableRabbitMq;
    services.rabbitmq.managementPlugin.enable = cfg.enableRabbitMq;

    # Environment variables
    env = lib.mkMerge [
      (lib.mkIf cfg.enable {
        DATABASE_URL = lib.mkDefault "mysql://shopware:shopware@127.0.0.1:3306/shopware";
        MAILER_URL = lib.mkDefault "smtp://127.0.0.1:1025?encryption=&auth_mode=";
        MAILER_DSN = lib.mkDefault "smtp://127.0.0.1:1025?encryption=&auth_mode=";

        APP_URL = lib.mkDefault "https://127.0.0.1:8000";
        CYPRESS_baseUrl = lib.mkDefault "https://127.0.0.1:8000";

        APP_SECRET = lib.mkDefault "devsecret";

        PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = true;
        DISABLE_ADMIN_COMPILATION_TYPECHECK = true;

        SHOPWARE_CACHE_ID = "dev";

        NODE_OPTIONS = "--openssl-legacy-provider --max-old-space-size=2000";
      })
      (lib.mkIf config.services.elasticsearch.enable {
        SHOPWARE_ES_ENABLED = "1";
        SHOPWARE_ES_INDEXING_ENABLED = "1";
        SHOPWARE_ES_HOSTS = "127.0.0.1";
        SHOPWARE_ES_THROW_EXCEPTION = "1";
      })
    ];

    # Processes
    processes.entryscript.exec = "${entryScript}";

    # Symfony related scripts
    scripts.cc.exec = ''
      CONSOLE=${config.env.DEVENV_ROOT}/bin/console

      if test -f "$CONSOLE"; then
          exec $CONSOLE cache:clear
      fi
    '';

    scripts.uuid.exec = ''
      uuidgen | tr "[:upper:]" "[:lower:]" | sed 's/-//g'
    '';

    scripts.debug.exec = ''
      XDEBUG_SESSION=1 ${phpXdebug}/bin/php "$@"
    '';

    scripts.importdb.exec = ''
      echo "Are you sure you want to download SQL files and overwrite the existing database with their data (y/n)?"
      read answer

      if [[ "$answer" != "y" ]]; then
          echo "Alright, we will stop here."
          exit
      fi

      ${lib.concatMapStrings (dump: ''
         echo "Importing ${dump}"
         ${importDbHelper} ${dump}
      '') cfg.importDatabaseDumps}
    '';
  };
}
