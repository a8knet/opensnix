{ pkgs, utils }:
# Tests the builder script that lib/pkgs-utils.nix uses for its realpath IFD,
# as the exact string that runs in the builder (no mock): an unresolvable path
# must abort, a real symlink must resolve to its target. The script exits via
# 'exit 1', so each run is wrapped in a subshell.
pkgs.runCommand "opensnix-realpath-check" { inherit (utils) realpathScript; } ''
  tmp=$(mktemp)
  if ( export path=/does-not-exist out=$tmp; eval "$realpathScript" ); then
    echo "FAIL: unresolvable path did not abort the build"
    exit 1
  fi

  mkdir d
  echo target > d/real
  ln -s "$PWD/d/real" d/link
  ( export path="$PWD/d/link" out=$PWD/d/out; eval "$realpathScript" )
  if [ "$(cat d/out)" != "$(realpath "$PWD/d/real")" ]; then
    echo "FAIL: got '$(cat d/out)', expected '$(realpath "$PWD/d/real")'"
    exit 1
  fi

  touch $out
''
