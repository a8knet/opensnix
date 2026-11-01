{ pkgs }:
rec {
  inherit (pkgs) writeTextDir;

  # Builder for realpath: reads $path, writes the resolved target to $out.
  # -e makes any unresolvable component fail the build, not write empty $out.
  realpathScript = ''
    resolved=$(realpath -e -- "$path") || exit 1
    printf %s "$resolved" > "$out"
  '';

  # Resolve a symlink to its target path.
  # Uses runCommand to call realpath on the host system.
  realpath =
    path: builtins.readFile (pkgs.runCommand "path-realpath" { inherit path; } realpathScript);
}
