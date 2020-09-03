{ pkgs ? import <nixpkgs> {} }:

with pkgs; dockerTools.buildImage {
  name = "deluge-web";

  runAsRoot = ''
    #!${stdenv.shell}
    ${dockerTools.shadowSetup}
    groupadd -g 1337 -r deluge-web
    useradd -r -u 1337 -g deluge-web -M deluge-web

    mkdir /config
    chown deluge-web:deluge-web /config

    mkdir /tmp
    chmod 1777 /tmp
  '';

  config = {
    Cmd = [ "${su-exec}/bin/su-exec" "deluge-web" "${deluge}/bin/deluge-web" "-c" "/config" "-p" "8112" "-d" ];
    ExposedPorts = {
      "8112/tcp" = {};
    };
    Volumes = {
      "/config" = {};
    };
  };
}
