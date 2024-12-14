{
  stdenv,
  lib,
  fetchurl,
  cargo,
  desktop-file-utils,
  itstool,
  meson,
  ninja,
  pkg-config,
  jq,
  moreutils,
  rustc,
  wrapGAppsHook4,
  gtk4,
  lcms2,
  libadwaita,
  libgweather,
  libseccomp,
  glycin-loaders,
  gnome,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "loupe";
  version = "47.2";

  src = fetchurl {
    url = "mirror://gnome/sources/loupe/${lib.versions.major finalAttrs.version}/loupe-${finalAttrs.version}.tar.xz";
    hash = "sha256-bgRu/k965X7idI1S0dBzVsdEnSBKPTHQtCNnqAGXShU=";
  };

  nativeBuildInputs = [
    cargo
    desktop-file-utils
    itstool
    meson
    ninja
    pkg-config
    jq
    moreutils
    rustc
    wrapGAppsHook4
    glycin-loaders.patchHook
  ];

  buildInputs = [
    gtk4
    lcms2
    libadwaita
    libgweather
    libseccomp
  ];

  passthru.updateScript = gnome.updateScript {
    packageName = "loupe";
  };

  meta = {
    homepage = "https://gitlab.gnome.org/GNOME/loupe";
    changelog = "https://gitlab.gnome.org/GNOME/loupe/-/blob/${finalAttrs.version}/NEWS?ref_type=tags";
    description = "Simple image viewer application written with GTK4 and Rust";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jk ] ++ lib.teams.gnome.members;
    platforms = lib.platforms.unix;
    mainProgram = "loupe";
  };
})
