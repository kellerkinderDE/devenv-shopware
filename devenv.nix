{ pkgs, config, inputs, lib, ... }:
let
  cfg = config.kellerkinder;

  currentVersion = "v2.1.1";

  listEntries = path:
    map (name: path + "/${name}") (builtins.attrNames (builtins.readDir path));

  shopwareCliPackage = if builtins.hasAttr "froshpkgs" inputs
      then inputs.froshpkgs.packages.${pkgs.system}.shopware-cli
      else pkgs.shopware-cli;
in {
  imports = (listEntries ./modules);

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.jq
      pkgs.gnupatch
      shopwareCliPackage
    ] ++ cfg.additionalPackages;

    languages.javascript = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.nodejs-18_x;
    };

    services.redis.enable = lib.mkDefault true;
    services.redis.port = cfg.redisPort;

    services.adminer.enable = lib.mkDefault true;
    services.adminer.listen = lib.mkDefault "127.0.0.1:${toString cfg.adminerPort}";

    services.mailhog.enable = true;
    services.mailhog.apiListenAddress = lib.mkDefault "127.0.0.1:${toString cfg.mailhogApiPort}";
    services.mailhog.smtpListenAddress = lib.mkDefault "127.0.0.1:${toString cfg.mailhogSmtpPort}";
    services.mailhog.uiListenAddress = lib.mkDefault "127.0.0.1:${toString cfg.mailhogUiPort}";

    services.elasticsearch.enable = cfg.enableElasticsearch;
    services.elasticsearch.port = cfg.elasticsearchPort;
    services.elasticsearch.tcp_port = cfg.elasticsearchTcpPort;

    services.opensearch.enable = cfg.enableOpenSearch;
    services.opensearch.settings."http.port" = cfg.elasticsearchPort;
    services.opensearch.settings."transport.port" = cfg.elasticsearchTcpPort;

    services.rabbitmq.enable = cfg.enableRabbitMq;
    services.rabbitmq.managementPlugin.enable = cfg.enableRabbitMq;
    services.rabbitmq.port = cfg.rabbitMqPort;
    services.rabbitmq.managementPlugin.port= cfg.rabbitMqManagementPluginPort;

    dotenv.disableHint = true;

    scripts.versionCheck.exec = ''
      AVAILABLE=$(${pkgs.curl}/bin/curl --silent "https://api.github.com/repos/kellerkinderDE/devenv-shopware/releases/latest" | ${pkgs.jq}/bin/jq -r .tag_name)

      echo ""

      if [ "$AVAILABLE" = "${currentVersion}" ]; then
        echo -e "\e[32mYou are running the latest version of devenv-shopware\e[0m"
      else
        echo -e "\e[31mThere is a new version of devenv-shopware available: $AVAILABLE\e[0m"
        echo -e "Please see https://github.com/kellerkinderDE/devenv-shopware/wiki/Update for further information"
      fi

      echo ""
    '';

    enterShell = ''
      versionCheck
    '';

    # Environment variables
    env = lib.mkMerge [
      (lib.mkIf cfg.enable {
        DATABASE_URL = lib.mkDefault "mysql://shopware:shopware@127.0.0.1:${toString cfg.mysqlPort}/shopware";
        MAILER_URL = lib.mkDefault "smtp://127.0.0.1:${toString cfg.mailhogSmtpPort}?encryption=&auth_mode=";
        MAILER_DSN = lib.mkDefault "smtp://127.0.0.1:${toString cfg.mailhogSmtpPort}?encryption=&auth_mode=";

        APP_URL = lib.mkDefault "http://127.0.0.1:${toString cfg.httpPort}";
        CYPRESS_baseUrl = lib.mkDefault "http://127.0.0.1:${toString cfg.httpPort}";

        SQL_SET_DEFAULT_SESSION_VARIABLES = lib.mkDefault "0";

        APP_SECRET = lib.mkDefault "devsecret";

        PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = true;
        DISABLE_ADMIN_COMPILATION_TYPECHECK = true;

        SHOPWARE_CACHE_ID = "dev";

        NODE_OPTIONS = "--openssl-legacy-provider --max-old-space-size=2000";
        NPM_CONFIG_ENGINE_STRICT = "false"; # hotfix for npm10
      })
      (lib.mkIf (config.services.elasticsearch.enable || config.services.opensearch.enable) {
        SHOPWARE_ES_ENABLED = "1";
        SHOPWARE_ES_INDEXING_ENABLED = "1";
        SHOPWARE_ES_HOSTS = "127.0.0.1:${toString cfg.elasticsearchPort}";
        SHOPWARE_ES_THROW_EXCEPTION = "1";
      })
      (lib.mkIf config.services.rabbitmq.enable {
        RABBITMQ_NODENAME = "rabbit@localhost"; # 127.0.0.1 can't be used as rabbitmq can't set short node name
        RABBITMQ_NODE_PORT = "${toString cfg.rabbitMqPort}";
      })
      (lib.mkIf config.services.redis.enable {
        REDIS_DSN = "redis://127.0.0.1:${toString cfg.redisPort}";
      })
    ];
  };
}
