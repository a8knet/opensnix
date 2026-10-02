{ pkgs }:
{
  inherit (pkgs) writeTextDir;

  # Resolve a symlink to its target path.
  # Uses runCommand to call realpath on the host system.
  realpath =
    path:
    builtins.readFile (
      pkgs.runCommand "path-realpath" { inherit path; } "echo -n $(realpath $path) > $out"
    );
}
