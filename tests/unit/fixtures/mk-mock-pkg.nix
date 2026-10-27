# Mock derivation helper shared by the test suites.
#
# Shaped for lib.getExe (type + meta.mainProgram) and lib.getBin (bin).
# The fake outPath does not exist on disk; realpath(1) resolves existing
# components and leaves missing ones verbatim, so the IFD returns the
# input path unchanged and expectations can use the mock paths literally.
{
  pname,
  outPath,
  mainProgram ? pname,
  name ? "${pname}-1.0",
}:
{
  type = "derivation";
  inherit outPath pname name;
  meta = {
    inherit mainProgram;
  };
  bin = {
    inherit outPath pname;
    meta = {
      inherit mainProgram;
    };
  };
}
