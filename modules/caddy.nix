{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;

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

      root * ${cfg.projectRoot}/${cfg.documentRoot}

      encode zstd gzip

      @fallbackMediaPaths {
        path ${cfg.fallbackMediaPaths}
      }

      handle @fallbackMediaPaths {
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
          index ${cfg.indexFile}
          trusted_proxies private_ranges
        }

        php_fastcgi @debugger unix/${config.languages.php.fpm.pools.xdebug.socket} {
          index ${cfg.indexFile}
          trusted_proxies private_ranges
        }

        file_server

        encode zstd gzip
      }

      log {
        output stderr
        format console
        level ERROR
      }
    ''
    cfg.additionalVhostConfig
  ];

  vhostConfigTls = lib.strings.concatStrings [
    ''
      tls internal
    ''
    vhostConfig
  ];

  vhostDomains = cfg.additionalServerAlias ++ [ "127.0.0.1" "localhost" ];

  caddyHostConfig = (lib.mkMerge
    (lib.forEach vhostDomains (domain: {
      "http://${toString domain}" = {
        extraConfig = vhostConfig;
      };
      "https://${toString domain}" = {
        extraConfig = vhostConfigTls;
      };
      "https://${toString domain}:8000" = {
        extraConfig = vhostConfigTls;
      };
    }))
  );
in {
  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = lib.mkDefault true;
      config = ''
        {
          auto_https disable_redirects
        }
      '';
      virtualHosts = caddyHostConfig;
    };
  };
}
