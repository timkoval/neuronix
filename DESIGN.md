# Neuronix Design Guide

System-wide visual language for the Neuronix desktop. All UI components should follow these tokens to maintain consistency across niri windows, quickshell widgets, notifications, launchers, and future enhancements.

## Color System

### Source: Stylix (base16)

Colors are generated system-wide by **Stylix** from a base16 scheme defined in `modules/base.nix`:

```nix
stylix = {
  base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-light-medium.yaml";
  polarity = "light";
};
```

Stylix injects colors into most apps at build time via `config.lib.stylix.colors.withHashtag`.

### Base16 Palette (Gruvbox Light Medium)

| Token    | Hex       | Role                         |
| -------- | --------- | ---------------------------- |
| `base00` | `#fbf1c7` | Background                   |
| `base01` | `#ebdbb2` | Surface / mantle             |
| `base02` | `#d5c4a1` | Borders / selection          |
| `base03` | `#bdae93` | Comments / subtle UI         |
| `base04` | `#665c54` | Muted text                   |
| `base05` | `#504945` | Primary text                 |
| `base06` | `#3c3836` | Strong text                  |
| `base07` | `#282828` | Strongest contrast           |
| `base08` | `#9d0006` | Red (error, danger)          |
| `base09` | `#af3a03` | Orange (warnings, peach)     |
| `base0A` | `#b57614` | Yellow (caution, MPD)        |
| `base0B` | `#79740e` | Green (success, charging)    |
| `base0C` | `#427b58` | Cyan (teal, sapphire)        |
| `base0D` | `#076678` | Blue (primary accent, links) |
| `base0E` | `#8f3f71` | Purple (mauve, secondary)    |
| `base0F` | `#d65d0e` | Brown (maroon, tertiary)     |

### Quickshell Color Bridge

Quickshell reads colors at runtime from `/tmp/qs_colors.json`. This file is generated at Nix build time in `home/linux/desktop/wayland/mako.nix` and copied to `/tmp` on startup. It maps base16 tokens to Catppuccin-style property names that `MatugenColors.qml` expects:

```
base00 -> base       base04 -> overlay0    base08 -> red      base0C -> teal, sapphire
base01 -> mantle     base05 -> text        base09 -> peach    base0D -> blue
base02 -> surface1   base06 -> subtext0    base0A -> yellow   base0E -> mauve, pink
base03 -> surface2   base07 -> overlay1/2  base0B -> green    base0F -> maroon
```

### Future: Dynamic Theming

The infrastructure for runtime color changes is already in place:

- `MatugenColors.qml` polls `/tmp/qs_colors.json` every second
- Matugen can regenerate this file from a wallpaper image
- All quickshell color properties use `Behavior on color { ColorAnimation {} }` for smooth transitions

To enable dynamic wallpaper-based theming, the pipeline would be:

1. Wallpaper changes (via WallpaperPicker or swww)
2. Matugen extracts a palette from the wallpaper
3. Palette is written to `/tmp/qs_colors.json` in the expected format
4. Quickshell picks it up within 1 second and transitions smoothly
5. Other apps (mako, walker, kitty, etc.) would need their own reload hooks

## Corner Radius

Two tiers based on visual hierarchy:

| Layer                | Radius | Components                                       |
| -------------------- | ------ | ------------------------------------------------ |
| **Workspace**        | `4px`  | Niri windows, quickshell (TopBar + popups), Mako |
| **Floating overlay** | `8px`  | Walker launcher, wlogout                         |

### Implementation

- **Niri windows**: `geometry-corner-radius 4 4 4 4` in `niri.kdl`
- **Quickshell**: `radius: s(4)` (responsive) — uses `window.s(4)`, `root.s(4)`, or `barWindow.s(4)` depending on the QML file's scaler prefix
- **Mako**: `border-radius=4` in mako config
- **Walker**: `border-radius: 8px` in walker CSS
- **Wlogout**: `border-radius: 20px` (unchanged, full-screen overlay with large buttons)

## Typography

| Role       | Font                    | Weight  | Size      |
| ---------- | ----------------------- | ------- | --------- |
| Monospace  | JetBrainsMono Nerd Font | Bold    | Varies    |
| Icons      | Iosevka Nerd Font       | Regular | s(18-24)  |
| Sans-serif | Noto Sans               | Regular | System UI |
| Serif      | Source Han Serif SC     | Regular | Documents |

Defined in Stylix `fonts` config (`modules/base.nix`). Quickshell uses `Font.Bold` weight throughout (not `Font.Black`).

## Borders

| Context         | Width | Color                                |
| --------------- | ----- | ------------------------------------ |
| Main containers | `2px` | `surface1` (base02)                  |
| Inner elements  | `1px` | `surface2` (base03)                  |
| Hover state     | `2px` | `surface2` or accent color           |
| Mako            | `2px` | `base02` (normal), `base08` (urgent) |

## Backgrounds

Flat, solid colors from the Stylix palette. No gradients, no semi-transparent overlays.

| Role          | Color      | Base16    |
| ------------- | ---------- | --------- |
| Primary bg    | `base`     | base00    |
| Card / panel  | `mantle`   | base01    |
| Inset / track | `surface1` | base02    |
| Active fill   | Accent     | base08-0F |

## Animation

Functional transitions only. No decorative effects (ambient blobs, breathing, orbital, wave fills).

| Type              | Duration                    | Easing           |
| ----------------- | --------------------------- | ---------------- |
| Entry (opacity)   | 400ms                       | `OutQuart`       |
| Entry (staggered) | 400ms + 50ms delay per item | `OutQuart`       |
| Exit              | 300ms                       | `InQuart`        |
| Hover color       | 150-200ms                   | `ColorAnimation` |
| Slider/value      | 200ms                       | `OutQuint`       |
| Widget morph      | 500ms                       | `InOutCubic`     |

No `OutBack` or `overshoot` easing. No `SequentialAnimation` loops for pulsing/breathing.

## Responsive Scaling

All quickshell sizes use the `Scaler.qml` system:

- Base reference: 1920px width
- Scale factor: `Math.pow(width / 1920, 0.85)`
- Access: `s(value)` function in each QML file
- Minimum scale: 0.35

## File Reference

| What               | Where                                              |
| ------------------ | -------------------------------------------------- |
| Stylix config      | `modules/base.nix`                                 |
| Color bridge (Nix) | `home/linux/desktop/wayland/mako.nix`              |
| Color bridge (QML) | `quickshell/MatugenColors.qml`                     |
| Mako notifications | `home/linux/desktop/wayland/mako.nix`              |
| Walker launcher    | `home/linux/desktop/wayland/walker.nix`            |
| Wlogout            | `home/linux/desktop/wayland/wlogout.nix`           |
| Niri window rules  | `home/linux/desktop/niri/conf/niri.kdl`            |
| Quickshell widgets | `home/linux/desktop/niri/conf/scripts/quickshell/` |
| Scaler             | `quickshell/Scaler.qml`                            |
| Window registry    | `quickshell/WindowRegistry.js`                     |
