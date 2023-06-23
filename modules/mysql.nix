{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;
in {
  config = lib.mkIf cfg.enable {
    services.mysql = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.mysql80;
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
  };
}
