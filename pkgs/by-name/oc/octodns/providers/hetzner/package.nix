{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  octodns,
  hcloud,
  pytestCheckHook,
  pythonOlder,
  requests,
  requests-mock,
  setuptools,
}:

buildPythonPackage rec {
  pname = "octodns-hetzner";
  version = "1.0.0-hcloud";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "octodns";
    repo = "octodns-hetzner";
    # tag = "v${version}";
    rev = "3e994fc800ea8accd56a6087dd097f190bdfe8f4";
    hash = "sha256-wFOn9IEom5YeZwn4PXbzOryB4LfqYq5ZQBXW4lADFs8=";
  };

  propagatedBuildInputs = [
    hcloud
  ];

  build-system = [
    setuptools
  ];

  dependencies = [
    octodns
    requests
    hcloud
  ];

  pythonImportsCheck = [
    "octodns_hetzner"
    "hcloud"
  ];

  nativeCheckInputs = [
    pytestCheckHook
    requests-mock
  ];

  meta = {
    description = "Hetzner DNS provider for octoDNS";
    homepage = "https://github.com/octodns/octodns-hetzner/";
    changelog = "https://github.com/octodns/octodns-hetzner/blob/${src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    teams = [ lib.teams.octodns ];
  };
}
