{ pkgs, config, inputs, lib, ... }:

{
  kellerkinder.phpVersion = "php80";
  services.elasticsearch.enable = true;
}
