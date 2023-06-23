{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;
in {
  config = lib.mkIf cfg.enable {
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

            root * ${cfg.projectRoot}/${cfg.documentRoot}

            encode zstd gzip

            handle /media/* {
              ${lib.strings.optionalString (cfg.fallbackRedirectMediaUrl != "") ''
              @notStatic not file
              redir @notStatic ${lib.strings.removeSuffix "/" cfg.fallbackRedirectMediaUrl}{path}
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
  };
}
