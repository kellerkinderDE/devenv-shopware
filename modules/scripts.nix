{ pkgs, config, inputs, lib, ... }:

let
  cfg = config.kellerkinder;

  entryScript = pkgs.writeScript "entryScript" ''
    set -euo pipefail

    if [ ! -f $DEVENV_PROFILE/bin/mysqladmin ]; then
      echo -e "mysqladmin missing, skips further entryscript processing"
      ${pkgs.coreutils}/bin/sleep infinity
    fi

    while ! $DEVENV_PROFILE/bin/mysqladmin ping --silent; do
      ${pkgs.coreutils}/bin/sleep 1
    done

    while ! [[ $($DEVENV_PROFILE/bin/mysql shopware -s -N -e 'SHOW DATABASES LIKE "shopware";') ]] ; do
      ${pkgs.coreutils}/bin/sleep 1
    done

    TABLE=$(mysql shopware -s -N -e 'SHOW TABLES LIKE "system_config";')

    if [[ $TABLE == "" ]]; then
      echo "Table system_config is missing. Run >updateSystemConfig< manually to ensure the dev status of your setup!"
      ${pkgs.coreutils}/bin/sleep infinity
    fi

    ${scriptUpdateConfig}

    echo -e "Startup completed"
    ${pkgs.coreutils}/bin/sleep infinity
  '';

  systemConfigEntries = lib.mapAttrsToList (name: value: { inherit name value; }) cfg.systemConfig;

  scriptUpdateConfig = pkgs.writeScript "scriptUpdateConfig" ''
    VENDOR=${config.env.DEVENV_ROOT}/vendor/autoload.php
    CONSOLE=${config.env.DEVENV_ROOT}/bin/console

    echo "Updating system config"

    if [ ! -f "$VENDOR" ] || [ ! -f "$CONSOLE" ]; then
      echo "Vendor folder or console not found. Please run composer install."
      exit 1
    fi

    # additional config
    ${lib.concatMapStrings ({ name, value }: ''
      $CONSOLE system:config:set ${name} ${value} || exit 1
      echo "System config ${name} set to ${value}"
    '') systemConfigEntries}

    # default config
    $CONSOLE system:config:set core.mailerSettings.emailAgent "" || exit 1
    echo "System config core.mailerSettings.emailAgent set to '''"
  '';

  importDbHelper = pkgs.writeScript "importDbHelper" ''
    if [[ "$1" == "" ]]; then
      echo "Please set devenv configuration for kellerkinder.importDatabaseDumps"
      exit
    fi

    if ! $DEVENV_PROFILE/bin/mysqladmin ping > /dev/null 2>&1; then
      echo "MySQL server is dead or has gone away! devenv up?"
      exit
    fi

    TARGETFOLDER="${config.env.DEVENV_STATE}/importdb"

    rm -rf "$TARGETFOLDER"
    set -e

    if [[ "$1" == *.sql ]]; then
      ${pkgs.curl}/bin/curl -s --create-dirs "$1" --output "$TARGETFOLDER/latest.sql"
    elif [[ "$1" == *.gz ]]; then
      ${pkgs.curl}/bin/curl -s --create-dirs "$1" --output "$TARGETFOLDER/latest.sql.gz"
      ${pkgs.gzip}/bin/gunzip -q -c "$TARGETFOLDER/latest.sql.gz" > "$TARGETFOLDER/dump.sql"
    elif [[ "$1" == *.zip ]]; then
      ${pkgs.curl}/bin/curl -s --create-dirs "$1" --output "$TARGETFOLDER/latest.sql.zip"
      ${pkgs.unzip}/bin/unzip -qq -j -o "$TARGETFOLDER/latest.sql.zip" '*.sql' -d "$TARGETFOLDER"
    else
      echo "Unsupported file type for file at $1"
      exit
    fi

    rm -f "$TARGETFOLDER/latest.sql.*"

    SQL_FILE=$(find "$TARGETFOLDER" -name "*.sql" | head -n 1)

    if [[ "$SQL_FILE" == "" ]]; then
      echo "No SQL file found"
      exit
    fi

    LANG=C LC_CTYPE=C LC_ALL=C ${pkgs.gnused}/bin/sed -i -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' "$SQL_FILE"
    LANG=C LC_CTYPE=C LC_ALL=C ${pkgs.gnused}/bin/sed -i 's/NO_AUTO_CREATE_USER//' "$SQL_FILE"

    $DEVENV_PROFILE/bin/mysql shopware -f < "$SQL_FILE"

    echo "Import $1 finished!"
  '';
in {
  # Config related scripts
  scripts.updateSystemConfig.exec = ''
    ${scriptUpdateConfig}
  '';

  # Symfony related scripts
  scripts.cc.exec = ''
    CONSOLE=${config.env.DEVENV_ROOT}/bin/console

    if test -f "$CONSOLE"; then
      exec $CONSOLE cache:clear
    fi
  '';

  scripts.uuid.exec = ''
    ${pkgs.toybox}/bin/uuidgen | tr "[:upper:]" "[:lower:]" | sed 's/-//g'
  '';

  scripts.importdb.exec = ''
    echo "Are you sure you want to download SQL files and overwrite the existing database with their data (y/n)?"
    read answer

    if [[ "$answer" != "y" ]]; then
      echo "Alright, we will stop here."
      exit
    fi

    ${lib.concatMapStrings (dump: ''
       echo "Importing ${dump}"
       ${importDbHelper} ${dump}
    '') cfg.importDatabaseDumps}

    ${scriptUpdateConfig}
  '';

  scripts.debug.exec = ''
    XDEBUG_SESSION=1 ${phpXdebug}/bin/php "$@"
  '';

  # Processes
  processes.entryscript.exec = "${entryScript}";
}
