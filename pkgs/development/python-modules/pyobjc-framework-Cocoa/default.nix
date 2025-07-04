{
  buildPythonPackage,
  darwin,
  fetchFromGitHub,
  lib,
  pyobjc-core,
  setuptools,
  xcbuild,
}:

buildPythonPackage rec {
  pname = "pyobjc-framework-Cocoa";
  version = "11.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ronaldoussoren";
    repo = "pyobjc";
    tag = "v${version}";
    hash = "sha256-2qPGJ/1hXf3k8AqVLr02fVIM9ziVG9NMrm3hN1de1Us=";
  };

  sourceRoot = "${src.name}/pyobjc-framework-Cocoa";

  build-system = [ setuptools ];

  buildInputs = [
    darwin.libffi
    darwin.DarwinTools
    xcbuild
  ];

  nativeBuildInputs = [
    darwin.DarwinTools # sw_vers
    xcbuild
  ];

  # See https://github.com/ronaldoussoren/pyobjc/pull/641. Unfortunately, we
  # cannot just pull that diff with fetchpatch due to https://discourse.nixos.org/t/how-to-apply-patches-with-sourceroot/59727.
  postPatch = ''
    substituteInPlace pyobjc_setup.py \
      --replace-fail "-buildversion" "-buildVersion" \
      --replace-fail "-productversion" "-productVersion" \
      --replace-fail "/usr/bin/sw_vers" "${darwin.DarwinTools}/bin/sw_vers" \
      --replace-fail '"sw_vers"' '"${darwin.DarwinTools}/bin/sw_vers"' \
      --replace-fail "/usr/bin/xcrun" "${xcbuild.xcrun}/bin/xcrun"
  '';

  dependencies = [ pyobjc-core ];

  env.NIX_CFLAGS_COMPILE = toString [
    "-I${darwin.libffi.dev}/include"
    "-Wno-error=unused-command-line-argument"
  ];

  pythonImportsCheck = [ "Cocoa" ];

  meta = with lib; {
    description = "PyObjC wrappers for the Cocoa frameworks on macOS";
    homepage = "https://github.com/ronaldoussoren/pyobjc";
    license = licenses.mit;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ samuela ];
  };
}
