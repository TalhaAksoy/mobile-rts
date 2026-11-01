# Logo and app icon

`render_logo.py` builds the Pocket Empires logo and icons in Blender and renders them to
`sample_project/assets/logo/`:

```
blender -b -P art_source/blender/logo/render_logo.py -- sample_project/assets/logo 128
```

The design is original. It follows the look of early-2000s console strategy box art, not any particular game:

- **Lettering:** chunky bevelled gold and steel letters. Their colour runs through a dark "horizon" band, which gives
  the classic chrome look.
- **Outline:** a dark iron outline with a thin gold hairline.
- **Emblem:** an enamel shield with a gold rim and cross, crossed steel swords and a jewelled crown.

## Outputs

| File | Used for |
|---|---|
| `logo.png` | The main menu, replacing the text title, and the boot splash |
| `icon_1024.png` | The project icon |
| `icon_192.png` | The Android legacy launcher icon |
| `icon_fg_432.png` | The Android adaptive icon foreground (`export_presets.cfg`) |
| `icon_bg_432.png` | The Android adaptive icon background (`export_presets.cfg`) |

## Font

`Cinzel-Black.ttf` is the weight-900 instance of the variable Cinzel font (`sample_project/assets/Cinzel.ttf`). Cinzel
is © The Cinzel Project Authors and licensed under the SIL Open Font License 1.1. The instance was made with:

```
fonttools varLib.instancer Cinzel.ttf wght=900
```

The default thin weight threw long spikes when its hairline serifs were bevelled.
