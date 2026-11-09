---
  Step 1: Download the LG C9 EDID

  sudo mkdir -p /usr/lib/firmware/edid
curl -sL "<https://raw.githubusercontent.com/gjasny/v4l-utils/master/utils/edid-decode/data/lg-oled-c9-hdmi>" \
| sudo tee /usr/lib/firmware/edid/lg-oled-c9-hdmi > /dev/null

  Verify it downloaded correctly (should be 256 bytes):

  wc -c /usr/lib/firmware/edid/lg-oled-c9-hdmi

  Optionally decode it to confirm HDR10 and 1440p/4K modes:

  sudo pacman -S v4l-utils  # if edid-decode isn't installed
  edid-decode /usr/lib/firmware/edid/lg-oled-c9-hdmi

  Step 2: Add EDID to initramfs

  Edit /etc/mkinitcpio.conf, add to the FILES array:

  FILES=(/usr/lib/firmware/edid/lg-oled-c9-hdmi)

  Rebuild:

  sudo mkinitcpio -P

  Step 3: Add kernel parameters to Limine

  Find your Limine config (likely /boot/limine/limine.conf or /boot/limine.conf). Append these to the existing cmdline or kernel_cmdline for your CachyOS entry:

  drm.edid_firmware=HDMI-A-1:edid/lg-oled-c9-hdmi video=HDMI-A-1:e

  So it looks something like:

  /CachyOS
      protocol: linux
      cmdline: root=UUID=... rw quiet splash drm.edid_firmware=HDMI-A-1:edid/lg-oled-c9-hdmi video=HDMI-A-1:e
      ...

  Step 4: Reboot and verify the virtual display

# Should show "connected"

  cat /sys/class/drm/card1-HDMI-A-1/status

# Check available modes — should include 2560x1440 and 3840x2160

  cat /sys/class/drm/card1-HDMI-A-1/modes

  The display should appear in KDE System Settings > Display Configuration.

  Step 5: Configure the virtual display in KDE

  Via GUI or CLI:

# Enable the output

  kscreen-doctor output.HDMI-A-1.enable

# Set to 1440p (Sunshine/Moonlight will handle the resolution negotiation

# but this sets the desktop resolution on the virtual display)

  kscreen-doctor output.HDMI-A-1.mode.2560x1440@120

# Enable HDR and wide color gamut

  kscreen-doctor output.HDMI-A-1.hdr.enable
  kscreen-doctor output.HDMI-A-1.wcg.enable

  In KDE's HDR settings for the virtual display, set sRGB color intensity to 0% to avoid tone-mapping stacking (the C9 does its own).

  Step 6: Point Sunshine at the virtual display

  In the Sunshine web UI (<https://localhost:47990>) under Configuration:

- Output Name: change from DP-1 to HDMI-A-1
- Capture: portal (keep XDG Portal — it works and doesn't need cap_sys_admin)
- Encoder: vaapi (keep)

  Restart Sunshine. The log should now show:

  [wayland] Name: HDMI-A-1
  [pipewire] Color primaries: 9        (BT.2020)
  [pipewire] Transfer function: 15     (PQ/SMPTE ST 2084)
  Color coding: HDR (Rec. 2020)
  Color depth: 10-bit

  If color primaries and transfer function are still 0, HDR isn't being passed through — likely means KDE's HDR toggle didn't take on the virtual display.

  Step 7: Configure Moonlight on the Shield Pro

- Resolution: 2560x1440 (custom resolution — you may need to add it manually in Moonlight settings)
- FPS: 120
- Video codec: HEVC (H.265 — supports HDR, lower decode overhead than AV1 on the Shield's Tegra)
- HDR: Enabled
- Bitrate: start at 40-50 Mbps for 1440p@120Hz, adjust up if you see compression artifacts

  Step 8: Disable power management on the virtual display

  Prevent KDE from blanking the virtual display (causes unrecoverable CRTC shutdown):

  In KDE Settings > Energy Saving, set screen dimming and blanking to Never, or at minimum ensure the virtual display is excluded.

  Step 9 (optional): Create Sunshine HDR toggle profiles

  Create a "Desktop HDR" app in Sunshine with:

  Do command:
  kscreen-doctor output.HDMI-A-1.enable && kscreen-doctor output.HDMI-A-1.hdr.enable && kscreen-doctor output.HDMI-A-1.wcg.enable

  Undo command:
  kscreen-doctor output.HDMI-A-1.hdr.disable && kscreen-doctor output.HDMI-A-1.wcg.disable

  ---
  Summary of what changes from the current log state

  ┌───────────────────┬─────────────────────┬──────────────────────────┐
  │      Setting      │       Current       │          Target          │
  ├───────────────────┼─────────────────────┼──────────────────────────┤
  │ Output            │ DP-1 (Acer XB271HU) │ HDMI-A-1 (virtual LG C9) │
  ├───────────────────┼─────────────────────┼──────────────────────────┤
  │ Color primaries   │ 0 (unspecified/SDR) │ 9 (BT.2020)              │
  ├───────────────────┼─────────────────────┼──────────────────────────┤
  │ Transfer function │ 0 (unspecified)     │ 15 (PQ/ST 2084)          │
  ├───────────────────┼─────────────────────┼──────────────────────────┤
  │ Color coding      │ SDR (Rec. 601/709)  │ HDR (Rec. 2020)          │
  ├───────────────────┼─────────────────────┼──────────────────────────┤
  │ Color depth       │ 8-bit               │ 10-bit                   │
  ├───────────────────┼─────────────────────┼──────────────────────────┤
  │ Resolution        │ 2560x1440           │ 2560x1440                │
  ├───────────────────┼─────────────────────┼──────────────────────────┤
  │ Refresh           │ 60fps               │ 120fps                   │
  └───────────────────┴─────────────────────┴──────────────────────────┘
