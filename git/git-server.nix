{ pkgs ? import <nixpkgs> {} }:

let
  link-git-server-commands = pkgs.lib.concatStringsSep "\n" (map (v: "ln -s ${v} /data/git-shell-commands/$(basename ${v})") (import ./git-shell-commands.nix { inherit pkgs; }));

  sshd-config = pkgs.writeTextFile {
    name = "sshd-config";
    text = ''
      Port 2222
      PermitRootLogin no
      PasswordAuthentication no

      AuthorizedKeysFile .ssh/authorized_keys

      KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com

      # modes are broken since the rewrite.. fix it!!
      StrictModes no
    '';
  };
in
with pkgs; dockerTools.buildImage {
  name = "git-server";

  runAsRoot = ''
    #!${stdenv.shell}
    ${dockerTools.shadowSetup}

    # privsep stuff
    useradd sshd
    mkdir -p /var/empty

    # ssh setup
    mkdir -p /etc/ssh
    ln -s ${sshd-config} /etc/ssh/sshd_config

    # todo: mount these into the container instead
    ${pkgs.openssh}/bin/ssh-keygen -A

    # setup ssh user
    groupadd -g 1337 -r git
    useradd -r -u 1337 -g git -d /data -M git
    usermod -p '*' git # set (invalid) password to only allow pubkey auth
    chsh -s ${pkgs.git}/bin/git-shell git

    # create home dir for repo storage
    mkdir /data

    # setup ssh user auth
    mkdir -p /data/.ssh
    touch /data/.ssh/authorized_keys
    chmod go-w /data/
    chmod 700 /data/.ssh
    chmod 600 /data/.ssh/authorized_keys

    chown -R git:git /data

    # link commands that should be available in the git shell
    mkdir /data/git-shell-commands
    ${link-git-server-commands}
  '';

  config = {
    Cmd = [ "${pkgs.openssh}/bin/sshd" "-D" ];
    ExposedPorts = {
      "2222/tcp" = {};
    };
  };
}
