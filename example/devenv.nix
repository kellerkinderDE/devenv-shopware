{ pkgs, config, inputs, lib, ... }:

let
  phpVersion = config.env.PHP_VERSION;
in
{
  env.PHP_VERSION = "php74";
}
