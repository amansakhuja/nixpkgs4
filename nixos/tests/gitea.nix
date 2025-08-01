{ system ? builtins.currentSystem }:

with import ../lib/testing.nix { inherit system; };
with pkgs.lib;

{
  mysql = makeTest {
    name = "gitea-mysql";
    meta.maintainers = [ maintainers.aanderse ];

    machine =
      { config, pkgs, ... }:
      { services.mysql.enable = true;
        services.mysql.package = pkgs.mariadb;
        services.mysql.ensureDatabases = [ "gitea" ];
        services.mysql.ensureUsers = [
          { name = "gitea";
            ensurePermissions = { "gitea.*" = "ALL PRIVILEGES"; };
          }
        ];

        services.gitea.enable = true;
        services.gitea.database.type = "mysql";
        services.gitea.database.socket = "/run/mysqld/mysqld.sock";
      };

    testScript = ''
      startAll;

      $machine->waitForUnit('gitea.service');
      $machine->waitForOpenPort('3000');
      $machine->succeed("curl --fail http://localhost:3000/");
    '';
  };

  postgres = makeTest {
    name = "gitea-postgres";
    meta.maintainers = [ maintainers.aanderse ];

    machine =
      { config, pkgs, ... }:
      {
        services.gitea.enable = true;
        services.gitea.database.type = "postgres";
        services.gitea.database.passwordFile = pkgs.writeText "db-password" "secret";
      };

    testScript = ''
      startAll;

      $machine->waitForUnit('gitea.service');
      $machine->waitForOpenPort('3000');
      $machine->succeed("curl --fail http://localhost:3000/");
    '';
  };

  sqlite = makeTest {
    name = "gitea-sqlite";
    meta.maintainers = [ maintainers.aanderse ];

    machine =
      { config, pkgs, ... }:
      { services.gitea.enable = true;
      };

    testScript = ''
      startAll;

      $machine->waitForUnit('gitea.service');
      $machine->waitForOpenPort('3000');
      $machine->succeed("curl --fail http://localhost:3000/");
    '';
  };
}
