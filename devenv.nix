{ pkgs, config, inputs, lib, ... }:

let
  phpVersion = config.env.PHP_VERSION;

  phpConfig = ''
    date.timezone = Europe/Berlin
    memory_limit = 2G
    pdo_mysql.default_socket = ''${MYSQL_UNIX_PORT}
    mysqli.default_socket = ''${MYSQL_UNIX_PORT}
    blackfire.agent_socket = "${config.services.blackfire.socket}";
    realpath_cache_ttl = 3600
    session.gc_probability = 0
    session.save_handler = redis
    session.save_path = "tcp://127.0.0.1:6379/0"
    redis.session.locking_enabled = 1
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
    zend.detect_unicode = 0
    xdebug.mode = "debug"
    xdebug.start_with_request = "trigger"
    xdebug.discover_client_host = 1
    xdebug.var_display_max_depth = -1
    xdebug.var_display_max_data = -1
    xdebug.var_display_max_children = -1
  '';

  phpPackage = inputs.phps.packages.${builtins.currentSystem}.${phpVersion}.buildEnv {
    extensions = { all, enabled }: with all; enabled ++ [ redis ];
    extraConfig = phpConfig;
  };

  phpXdebug = inputs.phps.packages.${builtins.currentSystem}.${phpVersion}.buildEnv {
    extensions = { all, enabled }: with all; enabled ++ [ redis xdebug ];
    extraConfig = phpConfig;
  };

  entryScript = pkgs.writeScript "entryScript" ''
    PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"

    while ! ${pkgs.mysql}/bin/mysqladmin ping -u shopware -pshopware --silent; do
      sleep 1
    done

    ${updateConfig} core.mailerSettings.emailAgent ""

    echo -e "\nStartup completed"

    sleep infinity
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

  uuidHelper = pkgs.writeScript "uuid" ''
    #!/usr/bin/env php
    <?php declare(strict_types=1);

    class Uuid
    {
      public static function randomHex(): string
      {
        $hex = bin2hex(random_bytes(16));
        $timeHi = self::applyVersion(mb_substr($hex, 12, 4), 4);
        $clockSeqHi = self::applyVariant(hexdec(mb_substr($hex, 16, 2)));
        return sprintf(
          "%08s%04s%04s%02s%02s%012s",
          // time low
          mb_substr($hex, 0, 8),
          // time mid
          mb_substr($hex, 8, 4),
          // time high and version
          str_pad(dechex($timeHi), 4, "0", STR_PAD_LEFT),
          // clk_seq_hi_res
          str_pad(dechex($clockSeqHi), 2, "0", STR_PAD_LEFT),
          // clock_seq_low
          mb_substr($hex, 18, 2),
          // node
          mb_substr($hex, 20, 12)
        );
      }
      private static function applyVersion(string $timeHi, int $version): int
      {
        $timeHi = hexdec($timeHi) & 0x0fff;
        $timeHi &= ~(0xf000);
        $timeHi |= $version << 12;
        return $timeHi;
      }
      private static function applyVariant(int $clockSeqHi): int
      {
        // Set the variant to RFC 4122
        $clockSeqHi &= 0x3f;
        $clockSeqHi &= ~(0xc0);
        $clockSeqHi |= 0x80;
        return $clockSeqHi;
      }
    }

    echo Uuid::randomHex();
  '';
in {
  env.PHP_VERSION = lib.mkDefault "php81";

  packages = [
    pkgs.jq
    pkgs.gnupatch
  ];

  languages.javascript.enable = true;
  languages.javascript.package = lib.mkDefault pkgs.nodejs-18_x;
  env.NODE_OPTIONS = "--openssl-legacy-provider --max-old-space-size=2000";

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
  services.caddy.config = "{
    auto_https disable_redirects
  }";
  services.caddy.virtualHosts."127.0.0.1:8000" = {
    extraConfig = ''
      @default {
        not path /theme/* /media/* /thumbnail/* /bundles/* /css/* /fonts/* /js/* /recovery/* /sitemap/*
        not expression header_regexp('xdebug', 'Cookie', 'XDEBUG_SESSION') || query({'XDEBUG_SESSION': '*'})
      }

      @debugger {
        not path /theme/* /media/* /thumbnail/* /bundles/* /css/* /fonts/* /js/* /recovery/* /sitemap/*
        expression header_regexp('xdebug', 'Cookie', 'XDEBUG_SESSION') || query({'XDEBUG_SESSION': '*'})
      }

      tls internal

      root * public

      php_fastcgi @default unix/${config.languages.php.fpm.pools.web.socket}
      php_fastcgi @debugger unix/${config.languages.php.fpm.pools.xdebug.socket}

      encode zstd gzip

      file_server

      log {
        output stderr
        format console
        level ERROR
      }
    '';
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
    mysql = {
      user = "shopware";
      password = "shopware";
    };
    mysqldump = {
      user = "shopware";
      password = "shopware";
    };
    mysqladmin = {
      user = "shopware";
      password = "shopware";
    };
  };

  services.redis.enable = true;

  services.adminer.enable = lib.mkDefault true;
  services.adminer.listen = lib.mkDefault "127.0.0.1:8010";

  services.mailhog.enable = true;
  services.mailhog.uiListenAddress = lib.mkDefault "127.0.0.1:8025";

  # services.elasticsearch.enable = true;
  # services.rabbitmq.enable = true;
  # services.rabbitmq.managementPlugin.enable = true;

  # Environment variables
  env.DATABASE_URL = lib.mkDefault "mysql://shopware:shopware@127.0.0.1:3306/shopware";
  env.MAILER_URL = lib.mkDefault "smtp://127.0.0.1:1025?encryption=&auth_mode=";
  env.MAILER_DSN = lib.mkDefault "smtp://127.0.0.1:1025?encryption=&auth_mode=";
  env.APP_URL = lib.mkDefault "https://127.0.0.1:8000";
  env.APP_SECRET = lib.mkDefault "devsecret";
  env.CYPRESS_baseUrl = lib.mkDefault "https://127.0.0.1:8000";
  env.PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = true;
  env.DISABLE_ADMIN_COMPILATION_TYPECHECK = true;

  # Processes
  processes.entryscript.exec = "${entryScript}";

  # Symfony related scripts
  scripts.cc.exec = ''
    CONSOLE=${config.env.DEVENV_ROOT}/bin/console

    if test -f "$CONSOLE"; then
        exec $CONSOLE cache:clear
    fi
  '';

  scripts.uuid.exec = "${uuidHelper}";

  scripts.debug.exec = ''
    XDEBUG_SESSION=1 ${phpXdebug}/bin/php $1
  '';
}
