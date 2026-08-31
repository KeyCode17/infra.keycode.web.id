{
  pkgs,
  username,
  ...
}:
{
  # Reverse-engineering toolchain. Kept out of homebrew on purpose: the homebrew
  # module runs with `onActivation.cleanup = "zap"`, so anything installed by
  # hand with `brew install` is removed again on the next `darwin-rebuild switch`.
  home-manager.users.${username}.home.packages = with pkgs; [
    # Disassembly / static analysis
    ghidra # ships bin/ghidra plus Ghidra.app, linked by mac-app-util
    radare2

    # Binary inspection and manipulation
    binwalk
    upx
    patchelf # ELF only — no effect on Mach-O, for Linux targets

    # Debuggers
    lldb # native debugger on macOS
    gdb # upstream has no native arm64-darwin target and macOS needs a signed
    # binary to attach, so this is for remote / Linux targets, not local mac ones

    # Android and Java
    apktool # bundles its own JRE
    jadx # dex -> java decompiler; `jad` is unmaintained and not in nixpkgs

    # Android emulator route. Android Studio itself is a homebrew cask (nixpkgs
    # only builds it for Linux); it manages the emulator and arm64 system images
    # under ~/Library/Android/sdk. On Apple Silicon those run natively, so an
    # arm64 .so loads without translation. These are the host-side CLI helpers.
    objection # frida wrapper with anti-detection / anti-root-check helpers
    scrcpy # mirror and drive the emulator/device from the host

    # Mach-O tooling. macOS ships these with the Xcode command line tools, but
    # pinning them here keeps them available regardless of the Xcode install.
    cctools # install_name_tool, otool, lipo, codesign_allocate

    # Dynamic instrumentation. frida-server itself is not shipped here: it has to
    # match the target device's architecture and is pushed onto the device.
    frida-tools # frida, frida-trace, frida-ps, frida-ls-devices, ...

    # Support. `lief` and `capstone` ship no binaries, so they are only usable
    # through this interpreter rather than as separate top-level packages.
    (python3.withPackages (
      ps: with ps; [
        lief # parse and patch ELF/Mach-O programmatically
        capstone # disassembly engine
        unicorn # CPU emulation, for running obfuscated code in isolation
        keystone-engine # assembler, for writing patches back
      ]
    ))
    unzip
    libffi # library + headers only, ships no binaries
  ];
}
