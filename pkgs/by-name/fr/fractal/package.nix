{
  stdenv,
  lib,
  fetchFromGitLab,
  nix-update-script,
  cargo,
  meson,
  ninja,
  rustPlatform,
  rustc,
  pkg-config,
  glib,
  gtk4,
  gtksourceview5,
  libadwaita,
  gst_all_1,
  desktop-file-utils,
  appstream-glib,
  openssl,
  pipewire,
  libshumate,
  wrapGAppsHook4,
  sqlite,
  xdg-desktop-portal,
  libseccomp,
  glycin-loaders,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fractal";
  version = "9";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "World";
    repo = "fractal";
    rev = "refs/tags/${finalAttrs.version}";
    hash = "sha256-3UI727LUYw7wUKbGRCtgpkF9NNw4XuZ3tl3KV3Ku9r4=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-Kec31bted9qdwSzvx6UsYybavdRaNtk1tvg67xadpjQ=";
  };

  nativeBuildInputs = [
    glib
    gtk4
    meson
    ninja
    pkg-config
    rustPlatform.bindgenHook
    rustPlatform.cargoSetupHook
    cargo
    rustc
    desktop-file-utils
    appstream-glib
    wrapGAppsHook4
    glycin-loaders.patchHook
  ];

  buildInputs =
    [
      glib
      gtk4
      gtksourceview5
      libadwaita
      openssl
      pipewire
      libshumate
      sqlite
      xdg-desktop-portal
      libseccomp
    ]
    ++ (with gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-bad
      gst-plugins-good
    ]);

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Matrix group messaging app";
    homepage = "https://gitlab.gnome.org/GNOME/fractal";
    changelog = "https://gitlab.gnome.org/World/fractal/-/releases/${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    maintainers = lib.teams.gnome.members;
    platforms = lib.platforms.linux;
    mainProgram = "fractal";
  };
})
