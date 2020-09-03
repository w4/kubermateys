{ pkgs ? import <nixpkgs> {} }:

with pkgs; dockerTools.buildImage {
  name = "deluged";

  runAsRoot = ''
    #!${stdenv.shell}
    ${dockerTools.shadowSetup}
    groupadd -g 1337 -r deluged
    useradd -r -u 1337 -g deluged -M deluged

    mkdir /config
    chown deluged:deluged /config

    mkdir /tmp
    chmod 1777 /tmp
  '';

  config = {
    Cmd = [ "${su-exec}/bin/su-exec" "deluged" "${deluge}/bin/deluged" "-c" "/config" "-p" "58846" "-d" ];
    ExposedPorts = {
      "58846/tcp" = {};
      "58946/tcp" = {};
      "58946/udp" = {};
    };
    Volumes = {
      "/config" = {};
      "/downloads" = {};
    };
  };
}
