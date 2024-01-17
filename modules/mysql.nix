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
        mysqld = lib.mkMerge [
          (lib.mkIf cfg.enable {
            group_concat_max_len = 32000;
            key_buffer_size = 16777216;
            max_allowed_packet = 134217728;
            table_open_cache = 1024;
            sql_mode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION";
          })
          (lib.mkIf (cfg.enableMysqlBinLog) {
            sync_binlog = 0;
            log_bin_trust_function_creators = 1;
          })
          (lib.mkIf (!cfg.enableMysqlBinLog) {
            skip_log_bin = 1;
          })
        ];
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
