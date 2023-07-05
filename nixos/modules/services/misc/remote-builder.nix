{ config, lib, isNixAtLeastPre24, ... }:

with lib;

let
  mkRemoteBuilderDesc =
  # lib.traceSeq (machine)
    (concatStringsSep " " ([
        "${optionalString (config.sshUser != null) "${config.sshUser}@"}${config.hostName}"
        (if config.system != null then config.system else if config.systems != [ ] then concatStringsSep "," config.systems else "-")
        (if config.sshKey != null then config.sshKey else "-")
        (toString config.maxJobs)
        (toString config.speedFactor)
        (concatStringsSep "," (config.supportedFeatures ++ config.mandatoryFeatures))
        (concatStringsSep "," config.mandatoryFeatures)
      ]
      ++ optional isNixAtLeastPre24 (if config.publicHostKey != null then config.publicHostKey else "-")));

  # TODO rename into module one
  machineSubmodule = {
          options = {
            hostName = mkOption {
              type = types.str;
              example = "nixbuilder.example.org";
              description = lib.mdDoc ''
                The hostname of the build machine.
              '';
            };
            system = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "x86_64-linux";
              description = lib.mdDoc ''
                The system type the build machine can execute derivations on.
                Either this attribute or {var}`systems` must be
                present, where {var}`system` takes precedence if
                both are set.
              '';
            };
            systems = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "x86_64-linux" "aarch64-linux" ];
              description = lib.mdDoc ''
                The system types the build machine can execute derivations on.
                Either this attribute or {var}`system` must be
                present, where {var}`system` takes precedence if
                both are set.
              '';
            };
            sshUser = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "builder";
              description = lib.mdDoc ''
                The username to log in as on the remote host. This user must be
                able to log in and run nix commands non-interactively. It must
                also be privileged to build derivations, so must be included in
                {option}`nix.settings.trusted-users`.
              '';
            };
            sshKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/root/.ssh/id_buildhost_builduser";
              description = lib.mdDoc ''
                The path to the SSH private key with which to authenticate on
                the build machine. The private key must not have a passphrase.
                If null, the building user (root on NixOS machines) must have an
                appropriate ssh configuration to log in non-interactively.

                Note that for security reasons, this path must point to a file
                in the local filesystem, *not* to the nix store.
              '';
            };
            maxJobs = mkOption {
              type = types.int;
              default = 1;
              description = lib.mdDoc ''
                The number of concurrent jobs the build machine supports. The
                build machine will enforce its own limits, but this allows hydra
                to schedule better since there is no work-stealing between build
                machines.
              '';
            };
            speedFactor = mkOption {
              type = types.int;
              default = 1;
              description = lib.mdDoc ''
                The relative speed of this builder. This is an arbitrary integer
                that indicates the speed of this builder, relative to other
                builders. Higher is faster.
              '';
            };
            mandatoryFeatures = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "big-parallel" ];
              description = lib.mdDoc ''
                A list of features mandatory for this builder. The builder will
                be ignored for derivations that don't require all features in
                this list. All mandatory features are automatically included in
                {var}`supportedFeatures`.
              '';
            };
            supportedFeatures = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "kvm" "big-parallel" ];
              description = lib.mdDoc ''
                A list of features supported by this builder. The builder will
                be ignored for derivations that require features not in this
                list.
              '';
            };
            publicHostKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = lib.mdDoc ''
                The (base64-encoded) public host key of this builder. The field
                is calculated via {command}`base64 -w0 /etc/ssh/ssh_host_type_key.pub`.
                If null, SSH will use its regular known-hosts file when connecting.
              '';
            };
            rendered = mkOption {
              internal = true;
              readOnly = true;
              type = types.str;
              # apply =
                # x: "toto";
                # mkRemoteBuilderDesc config;
            };
          };

          config = {
            rendered = mkRemoteBuilderDesc config.config;

          };
        };
    in
      machineSubmodule
