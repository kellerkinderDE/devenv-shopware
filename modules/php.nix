{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;

  phpConfig = lib.strings.concatStrings [
    ''
      memory_limit = -1
      pdo_mysql.default_socket = ''${MYSQL_UNIX_PORT}
      mysqli.default_socket = ''${MYSQL_UNIX_PORT}
      blackfire.agent_socket = "${config.services.blackfire.socket}";
      realpath_cache_ttl = 3600
      session.gc_probability = 0
      display_errors = On
      display_startup_errors = true
      error_reporting = E_ALL
      html_errors = true
      max_execution_time = 60
      max_input_time = 60
      assert.active = 0
      zend.detect_unicode = 0
      opcache.memory_consumption = 256M
      opcache.interned_strings_buffer = 20
      opcache.enable_cli = 1
      opcache.enable = 1
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
  package = inputs.phps.packages.${pkgs.stdenv.system}.${phpVersion};

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
in {
  config = lib.mkIf cfg.enable {
    languages.php = {
      enable = lib.mkDefault true;
      package = lib.mkDefault phpPackage;

      fpm = {
        phpOptions = ''
          memory_limit = "2G"
        '';

        pools = {
          web = {
            phpPackage = lib.mkDefault phpPackage;
            settings = {
              "clear_env" = "no";
              "pm" = "dynamic";
              "pm.max_children" = 10;
              "pm.start_servers" = 2;
              "pm.min_spare_servers" = 1;
              "pm.max_spare_servers" = 10;
            };
          };

          xdebug = {
            phpPackage = lib.mkDefault phpXdebug;
            settings = {
              "clear_env" = "no";
              "pm" = "dynamic";
              "pm.max_children" = 10;
              "pm.start_servers" = 2;
              "pm.min_spare_servers" = 1;
              "pm.max_spare_servers" = 10;
            };
          };
        };
      };
    };

    scripts.debug.exec = ''
      XDEBUG_SESSION=1 ${phpXdebug}/bin/php "$@"
    '';
  };
}
