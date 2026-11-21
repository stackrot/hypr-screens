# hypr-screens

hypr-screens is a Waybar menu for turning Hyprland monitors on and off. On
monitors that support it, it can also set the volume over DDC/CI, which
still works while the monitor is showing another input such as a console.

## What it does

- Lists the monitors from `hyprland.lua`, numbered left to right by their
  configured position. A screen keeps its number while it's off or
  unplugged.
- Turns screens on and off, or leaves just one on.
- Closes the gap left by a screen that's off, so the cursor can cross
  between its neighbours. This needs an explicit `position` on every
  monitor.
- Moves workspaces off a screen you turn off onto the remaining screen
  nearest the middle, then focuses it and makes it the XWayland primary.
- Adds a volume and mute submenu for each monitor with DDC/CI volume.

Nothing is written to the Hyprland config, so a config reload or restart
turns every screen back on.

## Requirements

- Hyprland 0.55 or newer with a `hyprland.lua` config. Monitors have to be
  set with plain `hl.monitor({ ... })` calls. Rules built in a loop or from
  variables aren't picked up.
- Waybar and Python 3.
- A Nerd Font for the bar icon.
- `ddcutil` for the volume controls (optional). `ddcutil detect` should
  find your monitors without sudo.
- `xrandr` to set the XWayland primary (optional).

Only one setup has been tested: CachyOS with Hyprland 0.57.2, Waybar
0.16.0, ddcutil 3.0.2 and Python 3.14, and three monitors (two DisplayPort,
one HDMI) on an AMD GPU.

## Install

```
git clone https://github.com/stackrot/hypr-screens.git
cd hypr-screens
./install.sh
```

Run it from inside Hyprland. It:

- copies `hypr-screens` to `~/.local/bin`
- writes the menu and module to `~/.config/waybar/hypr-screens/`
- adds the module to your Waybar config with `include`, and puts
  `custom/screens` at the start of `modules-right`
- imports the module's stylesheet at the top of `style.css`

The config and stylesheet are saved as `.bak` before they're changed. Run
`./install.sh` again after adding or removing a monitor in the Hyprland
config, and after a `git pull` to update.

## Usage

Click the screens icon in Waybar. The same actions work from a terminal,
where screen 1 is the leftmost:

| Command | Effect |
| --- | --- |
| `hypr-screens all` | Turn every screen on |
| `hypr-screens only N` | Leave only screen N on |
| `hypr-screens toggle N` | Turn screen N on or off |
| `hypr-screens volume N LEVEL` | Set screen N's volume |
| `hypr-screens mute N` | Mute or unmute screen N |

`hypr-screens` on its own opens a TUI. Arrow keys or `j`/`k` pick a screen,
Space or Enter toggles it, `1` to `9` toggle a screen by number, `a` turns
them all on and `q` quits.

## Licence

MIT.
