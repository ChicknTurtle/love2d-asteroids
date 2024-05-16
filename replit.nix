{ pkgs }: {
  deps = [
    pkgs.nodePackages_latest.http-server
    pkgs.zip
    pkgs.lua-language-server
  ];
}