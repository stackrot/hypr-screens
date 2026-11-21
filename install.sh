#!/usr/bin/env bash
# Install the hypr-screens Waybar module for the current user. Run it
# again after adding or removing monitors in the Hyprland config, so the
# menu lists the right screens.
set -euo pipefail

src="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
bin="$HOME/.local/bin/hypr-screens"
waybar_dir="$config_home/waybar"
dest="$waybar_dir/hypr-screens"

die()
{
	echo "install.sh: $*" >&2
	exit 1
}

for cmd in hyprctl python3 waybar; do
	command -v "$cmd" >/dev/null || die "$cmd is not installed"
done
[[ -f $config_home/hypr/hyprland.lua ]] ||
	die "needs Hyprland 0.55 or later with a hyprland.lua config"
hyprctl monitors >/dev/null 2>&1 || die "run this from inside Hyprland"

config=""
for name in config.jsonc config config.json; do
	if [[ -f $waybar_dir/$name ]]; then
		config="$waybar_dir/$name"
		break
	fi
done
[[ -n $config ]] || die "no Waybar config found in $waybar_dir"

install -Dm755 "$src/hypr-screens" "$bin"
mkdir -p "$dest"
command -v ddcutil >/dev/null ||
	echo "ddcutil is not installed, so there are no volume controls."
"$bin" waybar-install "$dest"
install -m644 "$src/style.css" "$dest/style.css"

# Hook the module into the existing config and stylesheet, leaving
# everything else as it is. Originals are kept as *.bak.
python3 - "$config" "$waybar_dir/style.css" "$dest" <<'EOF'
import re
import shutil
import sys
from pathlib import Path

config, style, dest = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
module = '"custom/screens"'
include = f'"{dest}/module.json"'
manual = []


def save(path, text):
	shutil.copy2(path, f"{path}.bak")
	path.write_text(text)


def insert(text, at, item):
	rest = text[at:].lstrip()
	sep = "" if rest.startswith("]") else ", "
	return text[:at] + item + sep + text[at:]


def patch_config(text):
	bar = re.match(r"(?:\s+|//[^\n]*|/\*.*?\*/)*([{\[])", text, re.S)
	if not bar or bar[1] != "{":
		manual.append(f"{config}: add {module} to a modules list and "
		              f"{include} to \"include\"")
		return text
	if include not in text:
		inc = re.search(r'"include"\s*:\s*\[', text)
		if inc:
			text = insert(text, inc.end(), include)
		else:
			at = bar.end()
			indent = re.match(r"\s*?\n([ \t]*)", text[at:])
			indent = indent[1] if indent else "\t"
			line = f'\n{indent}"include": [{include}],'
			text = text[:at] + line + text[at:]
	if module not in text:
		mods = re.search(r'"modules-right"\s*:\s*\[', text)
		if mods:
			text = insert(text, mods.end(), module)
		else:
			step = f"{config}: add {module} to a modules list"
			manual.append(step)
	return text


text = config.read_text()
patched = patch_config(text)
if patched != text:
	save(config, patched)

line = '@import url("hypr-screens/style.css");\n'
if not style.exists():
	manual.append(f"{style}: add {line.strip()}")
elif line not in style.read_text():
	save(style, line + style.read_text())

for step in manual:
	print(f"Do this by hand: {step}")
EOF

pkill -USR2 -x waybar || true
echo "Installed. Click the screens icon in Waybar, or run hypr-screens."
