{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;

  phpConfig = lib.strings.concatStrings [
    ''
      memory_limit = 2G
      pdo_mysql.default_socket = ''${MYSQL_UNIX_PORT}
      mysqli.default_socket = ''${MYSQL_UNIX_PORT}
      blackfire.agent_socket = "${config.services.blackfire.socket}";
      realpath_cache_ttl = 3600
      session.gc_probability = 0
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
    ''
    cfg.additionalPhpConfig
  ];

  phpVersion = if builtins.hasAttr "PHP_VERSION" config.env then config.env.PHP_VERSION else cfg.phpVersion;
  package = inputs.phps.packages.${builtins.currentSystem}.${phpVersion};

  phpPackage = package.buildEnv {
    extensions = { all, enabled }: with all; enabled
      ++ (lib.optional config.services.redis.enable redis)
      ++ (lib.optional config.services.blackfire.enable blackfire)
      ++ (lib.optional config.services.rabbitmq.enable amqp)
      ++ lib.attrsets.attrValues (lib.attrsets.getAttrs cfg.additionalPhpExtensions package.extensions);
    extraConfig = phpConfig;
  };

  phpXdebug = package.buildEnv {
    extensions = { all, enabled }: with all; enabled
      ++ [ xdebug ]
      ++ (lib.optional config.services.redis.enable redis)
      ++ (lib.optional config.services.rabbitmq.enable amqp)
      ++ lib.attrsets.attrValues (lib.attrsets.getAttrs cfg.additionalPhpExtensions package.extensions);
    extraConfig = phpConfig;
  };

  entryScript = pkgs.writeScript "entryScript" ''
    set -euo pipefail

    while ! $DEVENV_PROFILE/bin/mysqladmin ping --silent; do
      ${pkgs.coreutils}/bin/sleep 1
    done

    ${scriptUpdateConfig}

    echo -e "Startup completed"

    ${pkgs.coreutils}/bin/sleep infinity
  '';

  systemConfigEntries = lib.mapAttrsToList (name: value: { inherit name value; }) cfg.systemConfig;

  scriptUpdateConfig = pkgs.writeScript "scriptUpdateConfig" ''
    VENDOR=${config.env.DEVENV_ROOT}/vendor/autoload.php
    CONSOLE=${config.env.DEVENV_ROOT}/bin/console

    echo "Updating system config"

    if [ ! -f "$VENDOR" ] || [ ! -f "$CONSOLE" ];
    then
      echo "Vendor folder or console not found. Please run composer install."
      exit 1
    fi

    # additional config
    ${lib.concatMapStrings ({ name, value }: ''
      $CONSOLE system:config:set ${name} ${value} || exit 1
      echo "System config ${name} set to ${value}"
    '') systemConfigEntries}

    # default config
    $CONSOLE system:config:set core.mailerSettings.emailAgent "" || exit 1
    echo "System config core.mailerSettings.emailAgent set to ''''"
  '';

  importDbHelper = pkgs.writeScript "importDbHelper" ''
    if [[ "$1" == "" ]]; then
      echo "Please set devenv configuration for kellerkinder.importDatabaseDumps"
      exit
    fi

    if ! $DEVENV_PROFILE/bin/mysqladmin ping > /dev/null 2>&1; then
      echo "MySQL server is dead or has gone away! devenv up?"
      exit
    fi

    TARGETFOLDER="${config.env.DEVENV_STATE}/importdb"

    rm -rf "$TARGETFOLDER"
    set -e

    if [[ "$1" == *.sql ]]; then
      ${pkgs.curl}/bin/curl -s --create-dirs "$1" --output "$TARGETFOLDER/latest.sql"
    elif [[ "$1" == *.gz ]]; then
      ${pkgs.curl}/bin/curl -s --create-dirs "$1" --output "$TARGETFOLDER/latest.sql.gz"
      ${pkgs.gzip}/bin/gunzip -q -c "$TARGETFOLDER/latest.sql.gz" > "$TARGETFOLDER/dump.sql"
    elif [[ "$1" == *.zip ]]; then
      ${pkgs.curl}/bin/curl -s --create-dirs "$1" --output "$TARGETFOLDER/latest.sql.zip"
      ${pkgs.unzip}/bin/unzip -qq -j -o "$TARGETFOLDER/latest.sql.zip" '*.sql' -d "$TARGETFOLDER"
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

    LANG=C LC_CTYPE=C LC_ALL=C ${pkgs.gnused}/bin/sed -i -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' "$SQL_FILE"
    LANG=C LC_CTYPE=C LC_ALL=C ${pkgs.gnused}/bin/sed -i 's/NO_AUTO_CREATE_USER//' "$SQL_FILE"

    $DEVENV_PROFILE/bin/mysql shopware -f < "$SQL_FILE"

    echo "Import $1 finished!"
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
      example = [ "mailparse" ];
    };

    additionalVhostConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Additional vhost configuration";
    };

    additionalServerAlias = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Additional server alias";
      default = [ ];
      example = [ "example.com" ];
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
      description = ''Sets the matcher paths to be "ignored" by caddy'';
    };

    fallbackMediaUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''This url is called when the local media does not exist. Best for CDN purposes without downloading them.'';
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.jq
      pkgs.gnupatch
    ];

    languages.javascript = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.nodejs-16_x;
    };

    languages.php = {
      enable = lib.mkDefault true;
      package = lib.mkDefault phpPackage;

      fpm.pools.web = {
        settings = {
          "clear_env" = "no";
          "pm" = "dynamic";
          "pm.max_children" = 10;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 10;
        };
      };
      fpm.pools.web.phpPackage = lib.mkDefault phpPackage;

      fpm.pools.xdebug = {
        settings = {
          "clear_env" = "no";
          "pm" = "dynamic";
          "pm.max_children" = 10;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 10;
        };
      };
      fpm.pools.xdebug.phpPackage = lib.mkDefault phpXdebug;
    };

    services.caddy = {
      enable = lib.mkDefault true;
      config = ''
        {
          auto_https disable_redirects
        }
      '';
      virtualHosts."127.0.0.1:8000" = lib.mkDefault {
        serverAliases = cfg.additionalServerAlias;
        extraConfig = lib.strings.concatStrings [
          ''
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

            encode zstd gzip

            handle /media/* {
                ${lib.strings.optionalString (cfg.fallbackMediaUrl != "") ''
                @notStatic not file
                redir @notStatic ${cfg.fallbackMediaUrl}{path}
                ''}
                file_server
            }

            handle_errors {
                respond "{err.status_code} {err.status_text}"
            }

            handle {
                php_fastcgi @default unix/${config.languages.php.fpm.pools.web.socket} {
                  trusted_proxies private_ranges
                }

                php_fastcgi @debugger unix/${config.languages.php.fpm.pools.xdebug.socket} {
                  trusted_proxies private_ranges
                }

                file_server
            }

            log {
              output stderr
              format console
              level ERROR
            }
          ''
          cfg.additionalVhostConfig
        ];
      };
    };

    services.mysql = {
      enable = lib.mkDefault true;
      initialDatabases = lib.mkDefault [{ name = "shopware"; }];
      ensureUsers = lib.mkDefault [{
        name = "shopware";
        password = "shopware";
        ensurePermissions = { "*.*" = "ALL PRIVILEGES"; };
      }];
      settings = {
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
      ${pkgs.toybox}/bin/uuidgen | tr "[:upper:]" "[:lower:]" | sed 's/-//g'
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

      ${scriptUpdateConfig}
    '';
  };
}
