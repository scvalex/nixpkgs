{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  setuptools,
  numpy,
  jaxlib,
  jax,
  torch,
  dask,
  sparse,
  array-api-strict,
  config,
  cudaSupport ? config.cudaSupport,
  cupy,
}:

buildPythonPackage rec {
  pname = "array-api-compat";
  version = "1.11.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "data-apis";
    repo = "array-api-compat";
    tag = version;
    hash = "sha256-qGf1XDhRx9hJJP0LcZF7lA8tl+LKYNCw0xTqGjsZYj8=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [
    pytestCheckHook
    numpy
    jaxlib
    jax
    torch
    dask
    sparse
    array-api-strict
  ]
  ++ lib.optionals cudaSupport [ cupy ];

  pythonImportsCheck = [ "array_api_compat" ];

  # CUDA (used via cupy) is not available in the testing sandbox
  disabledTests = [
    "cupy"
  ];

  meta = {
    homepage = "https://data-apis.org/array-api-compat";
    changelog = "https://github.com/data-apis/array-api-compat/releases/tag/${src.tag}";
    description = "Compatibility layer for NumPy to support the Python array API";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ berquist ];
  };
}
