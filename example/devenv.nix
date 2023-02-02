{ pkgs, config, inputs, lib, ... }:

{
  kellerkinder.phpVersion = "php80";
  service.elasticserach.enable = true;
}
