{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking.ipvs;
  ipvsScript = pkgs.writeText "ipvs-start"
    (concatStringsSep "\n" (mapAttrsToList
      (_: serviceCfg:
        concatStringsSep "\n"
          ([ "--add-service --${serviceCfg.protocol}-service ${serviceCfg.address} --scheduler ${serviceCfg.scheduler}" ]
            ++ (map
            (serverCfg:
              "--add-server --${serviceCfg.protocol}-service ${serviceCfg.address} --real-server ${serverCfg.address} --${serverCfg.forwardingMethod}"
            )
            serviceCfg.servers)))
      cfg.services));
in
{
  imports = [ ];

  options = {
    networking.ipvs = {
      enable = mkEnableOption "Linux Virtual Server support";

      services = mkOption {
        description = "List of virtual services";
        default = { };
        type = with types; attrsOf
          (submodule {
            options = {
              address = mkOption {
                description = ''
                  Address of the virtual server. May be an IP address or a hostname, and
                  may have a port or service name.
                '';
                example = "10.20.0.1:80";
                type = str;
              };
              protocol = mkOption {
                description = "Protocol to use.";
                default = "tcp";
                type = enum [ "tcp" "udp" "sctp" ];
              };
              scheduler = mkOption {
                description = ''
                  Algorithm for allocating connections to real servers. See:
                  <citerefentry><refentrytitle>ipvs</refentrytitle>
                  <manvolnum>8</manvolnum></citerefentry>
                '';
                default = "rr";
                type = enum [ "rr" "wrr" "lc" "wlc" "lblc" "lblcr" "dh" "sh" "sed" "nq" "fo" "ovf" "mh" ];
              };
              servers = mkOption {
                description = ''
                  List of real servers that may be associated with a connection to the
                  virtual service.
                '';
                type = listOf
                  (submodule {
                    options = {
                      address = mkOption {
                        description = ''
                          Address of the real server.  May be an IP address or a hostname,
                          and may have a port or service name.
                        '';
                        example = "10.10.0.10:5080";
                        type = str;
                      };
                      forwardingMethod = mkOption {
                        description = ''
                          How the virtual service should redirect packets to the real
                          servers.
                        '';
                        default = "masquerading";
                        type = enum [ "gatewaying" "ipip" "masquerading" ];
                      };
                    };
                  });
              };
            };
          });
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ipvsadm ];

    boot.kernelModules = [ "ip_vs" ];

    # TODO Enable masquerading if needed: echo "1" > /proc/sys/net/ipv4/ip_forward
    #
    # I don't have this on my laptop, and masquerading seems to work.
    # I guess this is only needed when both ends of the connection are
    # not on localhost.

    # TODO Expose the option to protect CIDRs during clear.

    systemd.services.ipvs = {
      after = [ "network-online.target" ];
      before = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writers.writeBash "ipvs-start" ''
          ${pkgs.ipvsadm}/bin/ipvsadm --restore <${ipvsScript}
        '';
        ExecStop = "${pkgs.ipvsadm}/bin/ipvsadm --clear";
        RemainAfterExit = "true";
      };
    };
  };
}
