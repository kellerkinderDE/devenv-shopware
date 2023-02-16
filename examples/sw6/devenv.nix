{ pkgs, config, inputs, lib, ... }:

{
  kellerkinder.phpVersion = "php81";
  kellerkinder.additionalPhpConfig = ''
    memory_limit = 512M
  '';
  kellerkinder.additionalPhpExtensions = [ "mailparse" ];
  kellerkinder.enableRabbitMq = false;
  kellerkinder.enableElasticsearch = false;
}
