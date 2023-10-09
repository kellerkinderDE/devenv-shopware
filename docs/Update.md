# Updates

## v1.0.0
* You have to remove `http`, `https` and the ports (e.g. `8000`) from `kellerkinder.additionalServerAlias`
* You have to adjust your `devenv.yaml` to
  ```yml
    ...
    kellerkinder:
      url: git+https://github.com/kellerkinderDE/devenv-shopware?ref=v1.0.0
      flake: false
    ...
  ```
* If your shopware version is below `6.5.x` you might want to add `languages.javascript.package = pkgs.nodejs-16_x;` to your `devenv.nix` due to compatibility.
