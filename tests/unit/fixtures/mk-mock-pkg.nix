# Mock derivation helper shared by the test suites.
#
# Shaped for lib.getExe (type + meta.mainProgram) and lib.getBin (bin).
# The fake outPath does not exist on disk; realpath(1) resolves existing
# components and leaves missing ones verbatim, so the IFD returns the
# input path unchanged and expectations can use the mock paths literally.
#
# Store hashes must be 32-char nix32 strings, like real store paths.
{
  pname,
  outPath,
  mainProgram ? pname,
  name ? "${pname}-1.0",
  # Store path of the `bin` output; defaults to the top-level outPath, which is
  # what a single-output package looks like. Set it to model a package whose
  # executables live in a '<name>-bin' directory.
  binOutPath ? outPath,
}:
{
  type = "derivation";
  inherit outPath pname name;
  meta = {
    inherit mainProgram;
  };
  bin = {
    outPath = binOutPath;
    inherit pname;
    meta = {
      inherit mainProgram;
    };
  };
}
