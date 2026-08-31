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

    # Support
    python3
    unzip
    libffi # library + headers only, ships no binaries
  ];
}
