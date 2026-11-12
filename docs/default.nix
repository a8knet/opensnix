{
  lib,
  pkgs,
  self,
}:
let
  rootPrefix = toString ../. + "/";

  eval = lib.evalModules {
    modules = [
      ../modules/default.nix
      {
        config._module.args = {
          inherit pkgs self;
        };
        options = {
          warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            internal = true;
          };
          services.opensnitch = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              internal = true;
            };
            rules = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              internal = true;
            };
          };
        };
      }
    ];
  };

  allOptions = builtins.filter (opt: opt.visible && !opt.internal) (
    lib.optionAttrSetToDocList { inherit (eval.options) opensnix; }
  );

  validateOption =
    opt:
    let
      hasDesc = opt.description != null && opt.description != "";
      hasDecl = opt.declarations != [ ];
    in
    lib.throwIf (!hasDesc) "opensnix docs: option '${opt.name}' is missing a description." (
      lib.throwIf (!hasDecl) "opensnix docs: option '${opt.name}' has no declarations." opt
    );

  validatedOptions = map validateOption allOptions;

  longestFence = longestFence' "";

  longestFence' =
    prev: str:
    let
      groups = builtins.match "[^`]*(`+)(.*)" str;
      current = builtins.elemAt groups 0;
      remainingStr = builtins.elemAt groups 1;
      prevLen = builtins.stringLength prev;
      currLen = builtins.stringLength current;
      longest = if currLen > prevLen then current else prev;
    in
    if groups == null then prev else longestFence' longest remainingStr;

  renderValue =
    value:
    if lib.isType "literalMD" value then
      value.text
    else if lib.isType "literalExpression" value then
      let
        fence = longestFence value.text;
      in
      ''
        ${fence}```nix
        ${value.text}
        ${fence}```
      ''
    else
      builtins.throw "opensnix docs: unexpected value type: ${builtins.typeOf value}";

  declarationCommit = self.rev or "main";
  declarationPermalink = "https://github.com/a8knet/opensnix/blob/${declarationCommit}";

  renderDeclaration =
    declaration:
    let
      declarationString = toString declaration;
      subPath = lib.removePrefix rootPrefix declarationString;
    in
    lib.throwIfNot (lib.hasPrefix rootPrefix declarationString)
      "opensnix docs: declaration not in ${rootPrefix}: ${declarationString}"
      "- [${subPath}](${declarationPermalink}/${subPath})";

  markdownInHTML = markdown: "\n\n" + markdown + "\n\n";

  renderDetailsRow =
    name: value:
    lib.concatStrings [
      "<tr>"
      "<td>"
      (markdownInHTML name)
      "</td>"
      "<td>"
      (markdownInHTML value)
      "</td>"
      "</tr>"
    ];

  renderOption =
    option:
    let
      validated = validateOption option;
      defaultRow = lib.optional (validated ? default) (
        renderDetailsRow "Default" (renderValue validated.default)
      );
      exampleRow = lib.optional (validated ? example) (
        renderDetailsRow "Example" (renderValue validated.example)
      );
      sourceRow = lib.optional (validated ? declarations) (
        renderDetailsRow "Source" (lib.concatLines (map renderDeclaration validated.declarations))
      );
    in
    ''
      ### `${validated.name}`

      ${validated.description}

      ${lib.concatStrings (
        [
          "<table class=\"option-details\">"
          "<colgroup>"
          "<col span=\"1\">"
          "<col span=\"1\">"
          "</colgroup>"
          "<tbody>"
        ]
        ++ lib.optional (validated ? type) (renderDetailsRow "Type" validated.type)
        ++ defaultRow
        ++ exampleRow
        ++ sourceRow
        ++ [
          "</tbody>"
          "</table>"
        ]
      )}
    '';

  classifyOption =
    opt:
    let
      inherit (opt) loc;
      len = builtins.length loc;
      field = if len >= 4 then builtins.elemAt loc 3 else null;
    in
    if len == 2 then
      "module"
    else if
      len == 4
      && builtins.elem field [
        "allow"
        "deny"
        "reject"
        "precedence"
        "rules"
      ]
    then
      "structure"
    else if field == "package" then
      "package"
    else if
      len == 4
      && builtins.elem field [
        "users"
        "userNames"
        "userIds"
      ]
    then
      "arrays"
    else
      "conditions";

  groupedOptions = lib.groupBy classifyOption validatedOptions;

  sections = [
    {
      key = "module";
      title = "Module Options";
      intro = "Top-level options declared under `opensnix`.";
    }
    {
      key = "structure";
      title = "Rule Actions, Precedence & Grouping";
      intro = ''
        Action wrappers, priority evaluation, and nested group containers on each
        `opensnix.rules.<name>` entry.
      '';
    }
    {
      key = "package";
      title = "Package Resolution";
      intro = ''
        Options for resolving a Nix package into an OpenSnitch `process.path`
        condition.
      '';
    }
    {
      key = "conditions";
      title = "Network, Host & Process Conditions";
      intro = ''
        Condition keys accepted inside a rule fragment (either directly on
        `opensnix.rules.<name>` or inside an `allow`, `deny`, or `reject`
        wrapper).
      '';
    }
    {
      key = "arrays";
      title = "Multi-Rule Array Expansions";
      intro = ''
        Array fields that expand a single entry into one generated OpenSnitch
        rule per element.
      '';
    }
  ];

  renderSection =
    section:
    let
      opts = builtins.sort (a: b: a.name < b.name) (groupedOptions.${section.key} or [ ]);
    in
    ''
      ## ${section.title}

      ${section.intro}

      ${lib.concatLines (map renderOption opts)}
    '';

  optionsMarkdown = ''
    # Configuration Options

    This page is generated automatically from the option declarations in
    `modules/default.nix` and `lib/rules.nix`.

    ${lib.concatLines (map renderSection sections)}
  '';

  optionsFile = pkgs.writeText "options.md" optionsMarkdown;

  extraCSS = ''
    .option-details {
      width: 100%;
      table-layout: fixed;
    }
    .option-details col:first-child {
      width: 7.5em;
    }
    .option-details col:last-child {
      width: 100%;
      overflow-x: auto;
    }
    .option-details tr {
      background: inherit !important;
    }
    .option-details ol, .option-details ul {
      list-style: none;
      padding: unset;
    }
  '';
in
pkgs.stdenvNoCC.mkDerivation {
  name = "opensnix-docs";
  src = ./.;
  nativeBuildInputs = [ pkgs.mdbook ];

  inherit extraCSS;
  passAsFile = [ "extraCSS" ];

  patchPhase = ''
    install -D ${optionsFile} src/reference/options.md
    install -D $extraCSSPath custom.css
  '';

  buildPhase = ''
    runHook preBuild
    mdbook build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp --recursive book $out
    runHook postInstall
  '';
}
