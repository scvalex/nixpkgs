{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  wrapQtAppsHook,
  qt6,
}:

stdenv.mkDerivation rec {
  pname = "tytools";
  version = "0.9.9";

  src = fetchFromGitHub {
    owner = "Koromix";
    repo = "rygel";
    rev = "tytools/${version}";
    sha256 = "sha256-nQZaNYOTkx79UC0RHencKIQFSYUnQ9resdmmWTmgQxA=";
  };

  nativeBuildInputs = [
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
  ];

  buildPhase = ''
    ./bootstrap.sh
    ./felix tyuploader
  '';

  meta = with lib; {
    description = "Collection of tools to manage Teensy boards";
    homepage = "https://koromix.dev/tytools";
    license = licenses.unlicense;
    platforms = platforms.unix;
    maintainers = with maintainers; [ ahuzik ];
  };
}
