{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation {
  name = "sandbox";

  src = ./.;

  buildCommand = ''
    mkdir -p $out/bin
    cp $src/sandbox.sh $out/bin/sandbox
    chmod +x $out/bin/sandbox
  '';
}
