# to run these tests:
# nix-build lib/tests/nix-daemon.nix
# If it builds, all tests passed
{ pkgs ? import ../.. {}, lib ? pkgs.lib }:

let

  buildMachine1 = {
    hostName = "localhost";
    # todo move it to secrets
    # sshUser = "notroot";
    sshKey = "/home/groot/.ssh/id_rsa";
    system = "x86_64-linux";
    maxJobs = 2;
    speedFactor = 2;
    supportedFeatures = [ "big-parallel" "kvm" ];
    # mandatoryFeatures = [ "perf" ];
  };

  nixConfModule = { config, ... }: {

    buildMachines = buildMachine1;

  };

  finalConfig = let
      checkedAttrs = (lib.modules.evalModules {
        modules = [
          nixConfModule
          ({config,...}@args:  {
            options = {
              buildMachines = lib.mkOption {

                description = lib.mdDoc ''PlaceHolder'';
                type = lib.types.submodule (import ../../nixos/modules/services/misc/remote-builder.nix (args // { isNixAtLeastPre24 = true; }));
              };
            };
          })
        ];
      }).config;
  in checkedAttrs;
in
  pkgs.writeTextDir "nix-config"
    finalConfig.buildMachines.rendered

