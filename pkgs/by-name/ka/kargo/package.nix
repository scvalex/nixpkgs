{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  kargo,
  stdenv,
  testers,
  writableTmpDirAsHomeHook,
}:

buildGoModule rec {
  pname = "kargo";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "akuity";
    repo = "kargo";
    tag = "v${version}";
    hash = "sha256-I1mOEI9F8qQU9g4iKZC6iE0Or2UA25qM4z+H1z2juRY=";
  };

  vendorHash = "sha256-K7/18Qk1sEmBW+Nt5VpO/eMKijDuXXx1+fIlXB1lUUM=";

  subPackages = [ "cmd/cli" ];

  ldflags =
    let
      package_url = "github.com/akuity/kargo/pkg/x/version";
    in
    [
      "-s"
      "-w"
      "-X ${package_url}.version=${version}"
      "-X ${package_url}.buildDate=1970-01-01T00:00:00Z"
      "-X ${package_url}.gitCommit=${src.rev}"
      "-X ${package_url}.gitTreeState=clean"
    ];

  nativeBuildInputs = [
    installShellFiles
    writableTmpDirAsHomeHook
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 "$GOPATH/bin/cli" -T $out/bin/kargo
    runHook postInstall
  '';

  passthru.tests.version = testers.testVersion {
    package = kargo;
    command = "HOME=$TMPDIR ${meta.mainProgram} version --client";
  };

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd kargo \
      --bash <($out/bin/kargo completion bash) \
      --fish <($out/bin/kargo completion fish) \
      --zsh <($out/bin/kargo completion zsh)
  '';

  meta = {
    description = "Application lifecycle orchestration";
    mainProgram = "kargo";
    downloadPage = "https://github.com/akuity/kargo";
    homepage = "https://kargo.akuity.io";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      bbigras
    ];
  };
}
