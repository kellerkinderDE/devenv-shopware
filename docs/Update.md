# Updates

## v2.0.0
* You have to use the default ports (`80` and `443`) from now on.
  * If you want to use custom ports, you might want to check `kellerkinder.httpPort` and `kellerkinder.httpsPort`
* You have to adjust your `devenv.yaml` to
  ```yml
    ...
    kellerkinder:
      url: github:kellerkinderDE/devenv-shopware?ref=v2.0.0
      flake: false
    ...
  ```
## v1.0.0
* You have to update to devenv version `0.6.3` or higher
* You have to remove `http`, `https` and the ports (e.g. `8000`) from `kellerkinder.additionalServerAlias`
* You have to adjust your `devenv.yaml` to
  ```yml
    ...
    kellerkinder:
      url: github:kellerkinderDE/devenv-shopware?ref=v1.0.0
      flake: false
    ...
  ```
* If your shopware version is below `6.5.x` you might want to add `languages.javascript.package = pkgs.nodejs-16_x;` to your `devenv.nix` due to compatibility.
