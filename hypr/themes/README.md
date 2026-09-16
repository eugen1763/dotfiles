# Desktop themes

Open the preview picker with **Super + Shift + T**, click **◈** in Waybar,
or run `~/.config/hypr/scripts/desktop-theme`. Use the arrow keys and Enter to select;
Escape cancels. Right-click the Waybar button to cycle to the next theme.
The picker shows six previews per page. Use Page Up/Page Down or scroll to
browse, or type part of a theme name to search all twelve entries.

| Theme ID | Wallpaper and accent |
| --- | --- |
| `original` | Your original coral-cloud photograph and Ice HUD cyan |
| `rose-dawn` | Teal sky, peach clouds, warm coral accents |
| `lavender-dusk` | Lavender sky, pink clouds, lilac accents |
| `blue-hour` | Moonlit blue clouds, midnight sky, pale blue accents |
| `amber-tide` | Golden sunset clouds with honey and amber accents |
| `mint-horizon` | Sea-glass sunrise clouds with soft mint accents |
| `aurora-drift` | Arctic aurora and still water with jade accents |
| `lunar-garden` | A flowering tree on a floating island with orchid accents |
| `desert-mirage` | Terracotta dunes at dusk with warm apricot accents |
| `biolume-bay` | Glowing coastal surf with luminous turquoise accents |
| `velvet-eclipse` | A copper eclipse above dark clouds with rose accents |
| `sakura-mist` | Cherry blossoms over a misty lake with dusty pink accents |

The three new `wallpaper.png` files were generated using the built-in GPT Image
tool with `../wallpaper.jpeg` as a style reference. Full prompts and generation
asset paths are in [prompts.json](prompts.json). The original image is intact.
Eight additional backgrounds were made with the same built-in GPT Image tool.
Their full prompts, palettes and asset paths are in
[prompts-expansion.json](prompts-expansion.json). Amber Tide and Mint Horizon
use the original wallpaper as a loose reference; the other six are new scenes.

Each theme directory contains its wallpaper, Waybar colours, Hyprland borders,
Hyprlock configuration, and picker colours. `current` is an atomically updated
symlink to the selected directory. Hyprland, Hyprpaper, Waybar and Hyprlock read
that selection at startup. Both Lua and legacy Hyprland configurations include
the selected border theme. The switcher updates every connected monitor and
sets the fallback wallpaper for newly connected monitors.

Commands:

```sh
~/.config/hypr/scripts/desktop-theme list
~/.config/hypr/scripts/desktop-theme current
~/.config/hypr/scripts/desktop-theme blue-hour
~/.config/hypr/scripts/desktop-theme next
~/.config/hypr/scripts/desktop-theme original
```

Changing themes reloads Hyprland configuration and Waybar. Live application
requires the running Hyprland session and Hyprpaper. Failures restore the
previous saved selection and attempt to restore the live theme. Theme switches
are serialized to avoid partially written state. The switcher uses Python 3,
Rofi, Hyprctl, Hyprpaper and Waybar from the desktop setup; no API key is needed.

To adjust colours, edit that theme's `colors.css`, `hyprland.lua`,
`hyprland.conf`, `hyprlock.conf` and `picker.rasi`, then reapply it. The original
lock configuration is also saved as `hyprlock.template.conf` for reference.

On the original machine, configs are in the untracked `backup-20260916-232935/`. To fully uninstall, restore
its four Hyprland/Hyprpaper/Hyprlock files to `~/.config/hypr/` and its three
Waybar files to `~/.config/waybar/`, then reload Hyprland and Waybar. Keep the
backup if you subsequently customize these files.

Validation: opened and visually inspected the real preview picker; selected
Lavender Dusk using keyboard search and Enter; verified Escape cancellation;
applied all four themes and checked live Hyprpaper paths and border colours;
checked persistence across config reload and rejection of an unknown ID;
confirmed the shortcut is registered and Hyprland reports no config errors.
Lock-screen file selection was checked without locking the live session.
The eight additional themes also passed live wallpaper and border checks;
keyboard search successfully selected the twelfth entry, Sakura Mist.

Implementation references: [Hyprpaper IPC](https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/)
and [Hyprland Lua dispatchers](https://wiki.hypr.land/configuring/core/dispatchers/).
