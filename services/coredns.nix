{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.kellerkinder;

  configJSON = ''
    test {
      template IN A  {
          answer "{{ .Name }} 0 IN A 127.0.0.1"
      }
    }
  '';

  configFile = pkgs.writeText "Corefile" (builtins.concatStringsSep "\n"
    ([ configJSON ]));


  zoneData= ''
    $ORIGIN test.
    @	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
            2017042745 ; serial
            7200       ; refresh (2 hours)
            3600       ; retry (1 hour)
            1209600    ; expire (2 weeks)
            3600       ; minimum (1 hour)
            )

      3600 IN NS a.iana-servers.net.
      3600 IN NS b.iana-servers.net.

    www     IN A     127.0.0.1
            IN A     127.0.0.1
            IN AAAA  ::1
    '';

  zoneDataFile = pkgs.writeText "zonefile.test" (builtins.concatStringsSep "\n"
    ([ zoneData ]));

  resolverData = ''
  nameserver 127.0.0.1
  port 1053
  '';

# TODO: check for functionality und and dynamic domain handling

  resolverFile = pkgs.writeText "resolver.test" (builtins.concatStringsSep "\n"
      ([ zoneData ]));

  installPhase = ''
    mkdir $out
    cp $zoneDataFile $out/$zoneDataFile
    mkdir -p /etc/resolver && cp $resolverFile /etc/resolver/test
  '';
in
{
  options.services.coredns = {
    enable = mkEnableOption "Caddy web server";

    config = mkOption {
      default = "";
      example = ''
        example.com {
          encode gzip
          log
          root /srv/http
        }
      '';
      type = types.lines;
      description = ''
        Verbatim Caddyfile to use.
        Caddy v2 supports multiple config formats via adapters (see [`services.caddy.adapter`](#servicescaddyconfig)).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
      packages = [
        pkgs.coredns
      ];




    processes.coredns.exec = ''coredns -dns.port=1053 -conf ${configFile}'';
  };
}
