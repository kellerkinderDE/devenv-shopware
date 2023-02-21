{ pkgs, config, inputs, lib, ... }:

{
  kellerkinder.phpVersion = "php74";
  kellerkinder.additionalPhpConfig = ''
    memory_limit = 200M
  '';
  kellerkinder.additionalPhpExtensions = [ "mailparse" ];
  kellerkinder.enableRabbitMq = false;
  kellerkinder.enableElasticsearch = false;
  kellerkinder.documentRoot = ".";
  kellerkinder.staticFilePaths = "/files/* /media/*";
}
