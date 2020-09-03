{ pkgs, ... }:

pkgs.lib.mapAttrsToList (name: dev: "${dev}/bin/${name}") {

  list = pkgs.writeShellScriptBin "list" ''
    echo "Public repos:"
    for repo in $(${pkgs.busybox}/bin/ls -d pub/*.git); do
      if [[ "$repo" != ".git" ]]; then
        echo $(${pkgs.busybox}/bin/basename $repo .git)
      fi
    done

    echo
    echo "Private repos:"

    for repo in $(${pkgs.busybox}/bin/ls -d private/*.git); do
      if [[ "$repo" != ".git" ]]; then
        echo $(${pkgs.busybox}/bin/basename $repo .git)
      fi
    done
  '';

  create = pkgs.writeShellScriptBin "create" ''
    # If no project name is given
    if [ $# -eq 0 ]; then
      # Display usage and stop
      echo "Usage: create <path/to/project.git>"
      exit 1
    fi

    # Set the project name, adding .git if necessary
    project=$(echo "$*" | ${pkgs.gnused}/bin/sed 's/\.git$\|$/.git/i')

    # Create and initialise the project
    ${pkgs.busybox}/bin/mkdir -p "$project"
    cd "$project"
    ${pkgs.git}/bin/git --bare init
  '';

  clone = pkgs.writeShellScriptBin "clone" ''
    if [ $# -ne 2 ]; then
      echo "Usage: clone <project.git> <pub/private>"
      exit 1
    fi

    case "$2" in
      pub|private)
        ;;
      *)
        echo "Usage: clone <path/to/project.git> <pub/private>"
        exit 1
    esac

    cd "$2"
    ${pkgs.git}/bin/git clone --bare "$1"
  '';

  mv = pkgs.busybox;

  description = pkgs.writeShellScriptBin "description" ''
    if [ $# -ne 2 ]; then
      echo "Usage: description <path/to/project.git> \"my cool description\""
      exit 1
    fi

    project=$(echo "$1" | ${pkgs.gnused}/bin/sed 's/\.git$\|$/.git/i')

    cd "$project" || (echo "Project $1 does not exist"; exit 1)
    echo "$2" > description
  '';

  sync-remote = pkgs.writeShellScriptBin "sync-remote" ''
    if [ $# -ne 1 ]; then
      echo "Usage: sync-remote <remote name>"
      exit 1
    fi

    CWD="$(pwd)"
    export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

    for dir in pub/*; do
      cd "$CWD/$dir"
      echo "$dir:"
      RET=$(${pkgs.git}/bin/git remote get-url "$1" > /dev/null; echo $?)
      if [[ $RET -ne 0 ]]; then
        continue
      fi
      ${pkgs.git}/bin/git push --all --follow-tags "$1"
    done

    echo "$CWD"
  '';

  add-remote = pkgs.writeShellScriptBin "add-remote" ''
    if [ $# -ne 3 ]; then
      echo "Usage: add-remote <public-project.git> <remote name> <remote url>"
      exit 1
    fi

    CWD="$(pwd)"

    # Set the project name, adding .git if necessary
    project=$(echo "$1" | ${pkgs.gnused}/bin/sed 's/\.git$\|$/.git/i')

    cd "pub/$project"
    ${pkgs.git}/bin/git remote add "$2" "$3"
    cd "$CWD"
  '';

  remove-remote = pkgs.writeShellScriptBin "remove-remote" ''
    if [ $# -ne 2 ]; then
      echo "Usage: remove-remote <public-project.git> <remote name>"
      exit 1
    fi

    CWD="$(pwd)"

    # Set the project name, adding .git if necessary
    project=$(echo "$1" | ${pkgs.gnused}/bin/sed 's/\.git$\|$/.git/i')

    cd "pub/$project"
    ${pkgs.git}/bin/git remote remove "$2"
    cd "$CWD"
  '';
}
