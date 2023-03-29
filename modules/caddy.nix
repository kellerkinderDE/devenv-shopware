{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;

  mappedHosts = lib.mapAttrsToList (name: value: { inherit name; }) cfg.domains;

  vhostDomains = cfg.domains ++ [ "127.0.0.1" ];

  vhostConfig = lib.strings.concatStrings [
    ''
      @default {
        not path ${cfg.staticFilePaths}
        not expression header_regexp('xdebug', 'Cookie', 'XDEBUG_SESSION') || query({'XDEBUG_SESSION': '*'})
      }
      @debugger {
        not path ${cfg.staticFilePaths}
        expression header_regexp('xdebug', 'Cookie', 'XDEBUG_SESSION') || query({'XDEBUG_SESSION': '*'})
      }

      root * ${cfg.documentRoot}

      encode zstd gzip

      handle /media/* {
        ${lib.strings.optionalString (cfg.fallbackMediaUrl != "") ''
        @notStatic not file
        redir @notStatic ${lib.strings.removeSuffix "/" cfg.fallbackMediaUrl}{path}
        ''}
        file_server
      }

      handle_errors {
        respond "{err.status_code} {err.status_text}"
      }

      handle {
        php_fastcgi @default unix/${config.languages.php.fpm.pools.web.socket} {
          trusted_proxies private_ranges
          index shopware.php index.php
        }

        php_fastcgi @debugger unix/${config.languages.php.fpm.pools.xdebug.socket} {
          trusted_proxies private_ranges
          index shopware.php index.php
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

  vhostConfigSSL = lib.strings.concatStrings [
    ''
      tls ${config.env.DEVENV_STATE}/mkcert/%DOMAIN%.pem ${config.env.DEVENV_STATE}/mkcert/%DOMAIN%-key.pem
    ''
    vhostConfig
  ];
in {
  config = lib.mkIf cfg.enable {
    hosts = {
      "example.com" = "127.0.0.1";
    };

    certificates = [ "127.0.0.1" ] ++ cfg.domains;

    services.caddy = {
      enable = lib.mkDefault true;
      virtualHosts = lib.mkMerge [
        (lib.concatMapStrings
          (domain: {
            "${domain}:80" = lib.mkDefault {
              enable = true;
              extraConfig = vhostConfig;
            };
          })
          vhostDomains
        )
        (lib.concatMapStrings
          (domain: {
            "${domain}:443" = lib.mkDefault {
              enable = true;
              extraConfig = lib.replaceStrings [ "%DOMAIN%" domain ] vhostConfigSSL;
            };
          })
          vhostDomains
        )
      ];
    };
  };
}
