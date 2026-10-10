{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  bc,
  nukeReferences,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "rtl8852bu";
  version = "${kernel.version}-unstable-2025-05-18.1";

  src = fetchFromGitHub {
    owner = "morrownr";
    repo = "rtl8852bu-20250826";
    rev = "b6a299b4fe95cb6a37eec27a6c3b21cbaa6abfa8";
    hash = "sha256-QgVDm7G3iVwNhRIfK+fLpx2P44XjX3Dny4cYFex5l70=";
  };

  nativeBuildInputs =
    [
      bc
      nukeReferences
    ]
    ++ kernel.moduleBuildDependencies;
  hardeningDisable = [
    "pic"
    "format"
  ];

  postPatch = ''
    substituteInPlace ./Makefile \
      --replace-fail /sbin/depmod \# \
      --replace-fail '$(MODDESTDIR)' "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/" \
      --replace-fail 'cp -f $(MODULE_NAME).conf /etc/modprobe.d' \
      'mkdir -p $out/etc/modprobe.d && cp -f $(MODULE_NAME).conf $out/etc/modprobe.d' \
      --replace-fail "sh edit-options.sh" ""
    substituteInPlace ./platform/i386_pc.mk \
      --replace-fail /lib/modules "${kernel.dev}/lib/modules"
  '';

  makeFlags =
    [
      "ARCH=${stdenv.hostPlatform.linuxArch}"
      ("CONFIG_PLATFORM_I386_PC="
        + (
          if stdenv.hostPlatform.isx86
          then "y"
          else "n"
        ))
      ("CONFIG_PLATFORM_ARM_RPI="
        + (
          if stdenv.hostPlatform.isAarch
          then "y"
          else "n"
        ))
    ]
    ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
      "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    ];

  preInstall = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
    mkdir -p "$out/usr/lib/systemd/system-sleep"
  '';

  postInstall = ''
    nuke-refs $out/lib/modules/*/kernel/net/wireless/*.ko
  '';

  env.NIX_CFLAGS_COMPILE = "-Wno-designated-init"; # Similar to 79c1cf6

  enableParallelBuilding = true;

  meta = {
    description = "Driver for Realtek rtl8852bu and rtl8832bu chipsets, provides the 8852bu mod";
    homepage = "https://github.com/morrownr/rtl8852bu-20250826";
    license = lib.licenses.gpl2Only;
    platforms = ["x86_64-linux"];
    broken = false; #kernel.kernelAtLeast "6.18"; # Similar to 79c1cf6
    maintainers = with lib.maintainers; [
      lonyelon
      thtrf
    ];
  };
})
