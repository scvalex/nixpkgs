{
  lib,
  stdenv,
  fetchgit,
  coreutils,
  gawk,
  gnugrep,
  iproute2,
  makeWrapper,
  net-tools,
  openresolv,
  systemd,
  withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd,
}:

stdenv.mkDerivation {
  pname = "vpnc-scripts";
  version = "unstable-2023-01-03";

  src = fetchgit {
    url = "https://gitlab.com/openconnect/vpnc-scripts.git";
    rev = "22756827315bc875303190abb3756b5b1dd147ce";
    hash = "sha256-EWrDyXg47Ur9mFutaG8+oYOCAW9AZowzwwJp3YbogIY=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp vpnc-script $out/bin
  '';

  preFixup = ''
    substituteInPlace $out/bin/vpnc-script \
      --replace "which" "type -P"
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    substituteInPlace $out/bin/vpnc-script \
      --replace "/sbin/resolvconf" "${openresolv}/bin/resolvconf"
  ''
  + lib.optionalString withSystemd ''
    substituteInPlace $out/bin/vpnc-script \
      --replace "/usr/bin/resolvectl" "${systemd}/bin/resolvectl"
  ''
  + ''
    wrapProgram $out/bin/vpnc-script \
      --prefix PATH : "${
        lib.makeBinPath (
          [
            net-tools
            gawk
            coreutils
            gnugrep
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            openresolv
            iproute2
          ]
        )
      }"
  '';

  meta = with lib; {
    homepage = "https://www.infradead.org/openconnect/";
    description = "Script for vpnc to configure the network routing and name service";
    mainProgram = "vpnc-script";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ jerith666 ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
