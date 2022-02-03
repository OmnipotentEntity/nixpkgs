{ config, lib, pkgs, ... }:
with lib;
let
# Processes the source in the option
# Returns either the path passed in if it's a string, or a new path to the
# wordlist constructed from the various paths and strings.
processSource = name: source:
  if builtins.typeOf source == "string"
  then
    source
  else # typeOf source is list of tagged data
    builtins.toString (makeFileFromList name source);

# Concatenate a list of sources (paths or strings) into a single file and
# return the path to that file.
makeFileFromList = name: sources:
  pkgs.writeText name (lib.foldl (acc: source: acc + processOne source) "" sources);

# Processes a single source from inside the list
# Returns the contents of the wordlist if passed in a path, otherwise joins the
# list of strings with newlines
processOne = source:
  if source ? file
  then
    builtins.readFile source.file
  else
    lib.foldl (acc: word: acc + word + "\n") "" source.words;

specType = types.submodule {
  options = {
    envVar = mkOption {
      type = types.nonEmptyStr;
    };

    source = mkOption {
      type = types.oneOf [
        types.str
        (types.nonEmptyListOf (types.oneOf [
          taggedSourceFileType
          taggedLiteralStringType
        ]))
      ];
    };
  };
};

taggedSourceFileType = types.submodule {
  options = {
    file = mkOption {
      type = types.str;
    };
  };
};

taggedLiteralStringType = types.submodule {
  options = {
    words = mkOption {
      type = (types.nonEmptyListOf types.str);
    };
  };
};

in
{
  options = {
    environment.wordlist = {
      enable = mkEnableOption "wordlist environment variables.";

      lists = mkOption {
        type = (types.nonEmptyListOf specType);

        default = [
          {
            envVar = "WORDLIST";
            source = "${pkgs.scowl}/share/dict/words.txt";
          }
        ];

        defaultText = literalExpression ''[
          {
            envVar = "WORDLIST";
            source = "''${pkgs.scowl}/share/dict/words.txt";
          }
        ];
        '';

        description = ''
          A list of the environment variables and the word lists you'd like to
          associate.
        '';

        example = literalExpression ''lists = [
          {
            envVar = "WORDLIST";
            source = "''${pkgs.scowl}/share/dict/words.txt";
          }
          {
            envVar = "AUGMENTED_WORDLIST";
            source = [
              { file = "''${pkgs.scowl}/share/dict/words.txt"; }
              { words = [ "foo" "bar" "baz" ]; }
            ];
          }
        ];
        '';
      };
    };
  };

  config = mkIf config.environment.wordlist.enable {
    environment.variables =
      lib.foldl
        (attrs: x:
          attrs // { 
            "${x.envVar}" = processSource "wordlist-${x.envVar}" x.source;
          }
        )
        ({})
        config.environment.wordlist.lists;
  };
}
