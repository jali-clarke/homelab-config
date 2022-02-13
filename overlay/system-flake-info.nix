{ pkgs, hostname, selfSourceInfo }:
let
  flakeVersion = import ../lib/flake-version.nix { inherit pkgs hostname selfSourceInfo; };
in
pkgs.writeShellScriptBin "system_flake_version" ''
  USAGE="$0 [-i ssh_key_path --update flake_rev[#attr]] [--show] [--dry-run] [-h]"

  DRY_RUN=
  FLAKE_REV=
  PRINT_REV=
  SSH_KEY_PATH=

  if [[ "$#" -eq 0 ]]; then
    echo "$USAGE" >&2
    exit 1
  fi

  while [[ "$#" -ne 0 ]]; do
    case "$1" in
      -i)
        SSH_KEY_PATH="$2"
        shift 2
        ;;
      --update)
        FLAKE_REV="$2"
        shift 2
        ;;
      --show)
        PRINT_REV=true
        shift 1
        ;;
      --dry-run)
        DRY_RUN=true
        shift 1
        ;;
      -h)
        echo "$USAGE" >&2
        exit 0
        ;;
      *)
        echo "$USAGE" >&2
        exit 1
        ;;
    esac
  done

  if [[ "$PRINT_REV" == true ]]; then
    echo "${flakeVersion.versionedFlakeURI} (rev date: ${flakeVersion.lastModifiedFormatted})"
    exit 0
  fi

  CMD='eval `ssh-agent` && ssh-add "'"$SSH_KEY_PATH"'" && nixos-rebuild switch --flake "'"${flakeVersion.thisRepoURI}/$FLAKE_REV"'"'

  if [[ -z "$SSH_KEY_PATH" ]] || [[ -z "$FLAKE_REV" ]]; then
    echo "$USAGE" >&2
    exit 1
  elif [[ "$DRY_RUN" == true ]]; then
    echo "--dry-run used; would have done the following:"
    echo "$CMD"
  else
    eval "$CMD"
  fi
''
