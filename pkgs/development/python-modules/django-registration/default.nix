{
  lib,
  buildPythonPackage,
  confusable-homoglyphs,
  coverage,
  django,
  fetchFromGitHub,
  nix-update-script,
  nox,
  pdm-backend,
  pythonAtLeast,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "django-registration";
  version = "5.1.0";
  pyproject = true;

  disabled = pythonOlder "3.9" || pythonAtLeast "3.13";

  src = fetchFromGitHub {
    owner = "ubernostrum";
    repo = "django-registration";
    tag = version;
    hash = "sha256-02kAZXxzTdLBvgff+WNUww2k/yGqxIG5gv8gXy9z7KE=";
  };

  build-system = [ pdm-backend ];

  dependencies = [
    confusable-homoglyphs
    django
  ];

  nativeCheckInputs = [
    coverage
    django
    nox
  ];

  pythonImportsCheck = [ "django_registration" ];

  meta = {
    changelog = "https://github.com/ubernostrum/django-registration/blob/${version}/docs/changelog.rst";
    description = "User registration app for Django";
    downloadPage = "https://github.com/ubernostrum/django-registration";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.l0b0 ];
  };
}
