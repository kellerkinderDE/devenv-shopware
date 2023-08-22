# Updates

## v1.0.0
* You have to remove `http`, `https` and the ports (eg. `8000`) from `kellerkinder.additionalServerAlias`
* You have to adjust your `devenv.yaml` to
  ```yml
    ...
    kellerkinder:
      url: git+https://github.com/kellerkinderDE/devenv-shopware?ref=v1.0.0
      flake: false
    ...
  ```
