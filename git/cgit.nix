{ pkgs ? import <nixpkgs> {} }:

let
  syntectCgit = pkgs.rustPlatform.buildRustPackage rec {
    pname = "syntect-cgit";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "w4";
      repo = "syntect-cgit";
      rev = "aa8a4c15006dd99adf33f82897d6398641ec4b2a";
      sha256 = "1qy0v3ff0lsxv41rcbpj8djln965kzdz3a5cdlsqv1d91nx7a7n8";
    };
    cargoSha256 = "0zg1yp9wdkgd19b5clmmxqips21gc9vcc48blykn8dalm0m00x8z";

    LIBCLANG_PATH="${pkgs.llvmPackages.libclang}/lib";
  };

  caddy2-with-cgi = pkgs.buildGoModule rec {
    pname = "caddy";
    version = "2.1.1";

    subPackages = [ "./main" ];

    src = pkgs.fetchFromGitHub {
      owner = "caddyserver";
      repo = pname;
      rev = "v${version}";
      sha256 = "0c682zrivkawsxlps5hlx8js5zp4ddahg0zi5cr0861gnllbdll0";
    };
    vendorSha256 = "1yf5cr0mqhdfhwdy2jgs15x81gfyb6rprdd16zwn7yi89kijy6rw";

    preBuild = ''
      sed -i 's#require (#require (\n\tgithub.com/aksdb/caddy-cgi v1.11.5-0.20200628123622-b1c7929388ff#' go.mod
      sed -i 's#github.com/smallstep/nosql v0.3.0#github.com/smallstep/nosql v0.3.1#' go.mod

      mkdir main
      cat <<EOF > main/main.go
        package main
        import (
            caddycmd "github.com/caddyserver/caddy/v2/cmd"
            _ "github.com/caddyserver/caddy/v2/modules/standard"
            _ "github.com/aksdb/caddy-cgi"
        )
        func main() {
            caddycmd.Main()
        }
      EOF
    '';
  };

  caddy-config = pkgs.writeTextFile {
    name = "Caddyfile";
    text = ''
      :8333

      root * ${pkgs.cgit}/cgit

      @static path /cgit.css /cgit.png /favicon.ico /robots.txt
      file_server @static

      @cgi not path /cgit.css /cgit.png /favicon.ico /robots.txt
      route { cgi @cgi ${pkgs.cgit}/cgit/cgit.cgi }
    '';
  };

  cgitrc = pkgs.writeTextFile {
    name = "cgitrc";
    text = ''
      virtual-root=/
      cache-size=1000
      cache-root=/run/cgit

      source-filter=${syntectCgit}/bin/syntect-cgit
      about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
      email-filter=${pkgs.cgit}/lib/cgit/filters/email-gravatar.py
      readme=:README.md 
      readme=:README.txt
      readme=:README
      enable-http-clone=1
      scan-path=/data
    '';
  };
in
with pkgs; dockerTools.buildImage {
  name = "cgit";

  runAsRoot = ''
    #!${stdenv.shell}
    ${dockerTools.shadowSetup}
    groupadd -r cgit
    useradd -r -g cgit -M cgit

    mkdir -p /run/cgit
    chown cgit:cgit /run/cgit

    ln -s ${cgitrc} /etc/cgitrc
  '';

  config = {
    Cmd = [ "${su-exec}/bin/su-exec" "cgit" "${caddy2-with-cgi}/bin/main" "run" "-config" "${caddy-config}" "-adapter" "caddyfile" ];
    ExposedPorts = {
      "8333/tcp" = {};
    };
  };
}
