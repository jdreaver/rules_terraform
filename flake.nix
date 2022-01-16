{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs-unstable }:
    let
      pkgs = import nixpkgs-unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    in {
      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = with pkgs; [
          bazel_4
          jdk11 # Needed to run some bazel commands
          graphviz # To visualize bazel graph output

          # Downloaded go binaries from rules_go don't work on NixOS
          # (https://github.com/bazelbuild/rules_go/issues/1376)
          go
        ];
      };
    };
}
