import ./make-test-python.nix ({ pkgs, ... }:
  let
    mkServer = testText: { config, pkgs, nodes, ... }: {
      networking.firewall.allowedTCPPorts = [ 80 ];
      networking.defaultGateway = nodes.lb.config.networking.primaryIPAddress;
      services.nginx = {
        enable = true;
        virtualHosts."example.com" = {
          root = pkgs.runCommand "testdir" { } ''
            mkdir "$out"
            echo "${testText}" > "$out/index.html"
          '';
        };
      };
    };
    internalInterface = "eth1";
    internalIpSubnet = "192.168.1.0/24";
  in
  {
    name = "ipvs";

    nodes = {
      client = { config, pkgs, ... }: {
        environment.systemPackages = with pkgs; [ netcat-gnu ];
      };

      lb = { config, pkgs, nodes, ... }: {
        # TODO Remove this
        environment.systemPackages = with pkgs; [ nftables ];

        # TODO Do some of this automatically.
        networking.nat = {
          enable = true;
          internalIPs = [ internalIpSubnet ];
        };

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 80 ];
          # Accept packets from the internal servers. Without this,
          # reply packets from the internal servers get dropped.
          trustedInterfaces = [ internalInterface ];
        };

        networking.ipvs = {
          enable = true;
          services = {
            webserver = {
              address = "${config.networking.primaryIPAddress}:80";
              servers = [
                { address = "${nodes.server1.config.networking.primaryIPAddress}:80"; }
                # { address = "${nodes.server2.config.networking.primaryIPAddress}:80"; }
              ];
            };
          };
        };
      };

      server1 = mkServer "Server 1";

      server2 = mkServer "Server 2";
    };

    testScript = ''
      import re

      start_all()
      server1.wait_for_open_port(80)
      # server2.wait_for_open_port(80)
      # lb doesn't ever "open" port 80. It just redirects packets.

      # TODO Remove this.
      print(lb.succeed("nft list ruleset"))

      # TODO Remove this.
      print(lb.succeed("ipvsadm -Ln"))

      def connectExpect(target, expectStr, source = client):
          resp = source.succeed(f"curl -v -H 'Host: example.com' {target}").strip()
          if not re.match(expectStr, resp):
             raise Exception(f"Unexpected response from {target}. Expected: /{expectStr}/. Got: '{resp}'")

      # Ensure that the servers are running
      connectExpect("server1", "Server 1")
      # connectExpect("server2", "Server 2")

      # Check that connections work from the load-balancer machine.  This should work even
      # if the forwarding rules are setup incorrectly.
      connectExpect("lb", "Server (1|2)", source = lb)

      print(server1.succeed("curl server2"))

      connectExpect("lb", "Server (1|2)", source = client)
    '';
  })
