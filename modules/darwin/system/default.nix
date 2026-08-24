{ username, ... }:
{
  system.stateVersion = 5;

  # Disable memory compression — eliminates CPU overhead from compressor and
  # decompression latency; swap remains enabled as OOM safety net.
  # Requires reboot to take effect.
  launchd.daemons.set-boot-args = {
    serviceConfig = {
      Label = "com.local.set-boot-args";
      ProgramArguments = [
        "/usr/sbin/nvram"
        "boot-args=-arm64e_preview_abi vm_compressor=2"
      ];
      RunAtLoad = true;
    };
  };

  # Swap Escape <-> Caps Lock (both directions). HID usage IDs:
  #   Caps Lock = 0x700000039 (30064771129), Escape = 0x700000029 (30064771113)
  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      {
        HIDKeyboardModifierMappingSrc = 30064771129; # Caps Lock
        HIDKeyboardModifierMappingDst = 30064771113; # -> Escape
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771113; # Escape
        HIDKeyboardModifierMappingDst = 30064771129; # -> Caps Lock
      }
    ];
  };

  # AC: sleep after 30min; Battery: 10min — managed per-source by pmset-performance daemon
  power.sleep.computer = 30;
  power.sleep.display = 10;
  power.sleep.harddisk = 10;
  system.primaryUser = username;
}
