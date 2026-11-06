# Japanese: culture brief (Kamakura to Sengoku, c. 1185-1570)

Target look: dark timber, white plaster, grey tile and thatch. The units wear lacquered lamellar armour laced in coloured cord, with nobori banners and asymmetric yumi.

The big tower-keep (tenshu) castle such as Himeji or Osaka begins only with Azuchi in 1576. A Muromachi lord's seat was a moated **yakata** (fortified mansion), and real castles were **yamajiro**: earthworks, palisades and wooden yagura on a hill. Use a small, early, wooden tenshu at most, and treat it as a stretch.

## 1. Palette

| Hex | Use |
|---|---|
| `#ECE6D6` | Shikkui white plaster |
| `#3A2E26` | Dark cedar and blackened wood, sumi-ita boards |
| `#5A5F66` | Grey kawara tile (temples, castles, gates) |
| `#7A5A3A` | Hinoki-bark (hiwada) and shingle roofs |
| `#B79A5E` | Thatch (kayabuki) and straw (sandals, sugegasa, tatami) |
| `#2B3D66` | Indigo (ai) cloth, commoners and ashigaru |
| `#C2382B` | Vermilion lacquer: shrine gates, armour lacing, saddles |
| `#1D1A19` | Black lacquer armour plates |
| `#D3A63A` | Gilt kuwagata, fittings |
| `#8A6E4B` | Persimmon-tannin (kakishibu) brown |
| `#6B7A4B` | Bamboo and pine green for props |

## 2. Architecture

- **Structure:** post-and-beam timber on stone footings, with white plaster panels framed by dark posts and raised floors with verandas (engawa).
- **Roofs:** deep overhanging gabled-hip roofs (irimoya), kawara tile on elite buildings and thatch or bark elsewhere. Ridge-end onigawara tiles. Gentle curves only, not the upswept Chinese corners.
- **Defences:** earth and stone-faced embankments, dry or wet moats, wooden palisades and **yagura** (timber towers with plastered walls and small windows). Gates are a yagura-mon (gate under a tower) or a roofed kabuki-mon.
- **Ornament:** mon crests on gable boards and curtains (maku). Shachihoko are Azuchi-Momoyama and later, so they are optional on the castle only.
- **Props:** maku war-curtains, nobori banners, stone lanterns, rice-straw bales, bamboo fences and a torii only near a shrine.

**Buildings**
- **town_center:** a **buke yakata**. A moated square compound with an earth wall, a yagura-mon gate and a large irimoya-roofed main hall with a veranda.
- **house:** a minka farmhouse. A steep thick thatch roof, dark timber walls with plaster panels and an earth-floored entry.
- **barracks:** a long timber hall (nagaya) with a tile roof, weapon racks of yari and nobori banners.
- **archery_range:** a covered shooting shed (iba) facing round straw-and-paper targets (mato) on an earth bank.
- **stable:** an open-fronted timber stable (umaya) with a thatched or bark roof and horses tethered in stalls.
- **castle:** a hill fort with stone-faced earth terraces, a wooden palisade, several two-storey yagura and a gate tower. A small two- or three-storey wooden keep may be used as a late-Sengoku touch.
- **watch_tower:** an open timber yagura on four posts with a small tiled or shingle roof and a drum.
- **blacksmith:** a swordsmith's forge with a dark timber shed, a clay furnace, a bellows and a sacred rope (shimenawa) over the forge.
- **lumber_camp:** cedar logs, a bamboo fence and a thatched shed.
- **mining_camp:** a timber-framed shaft mouth, straw baskets and a stone heap.
- **mill:** a **watermill** (mizuguruma, a wooden wheel feeding a rice-pounding hut). Windmills were not used.
- **market:** a row of open stalls under shingle roofs with noren curtains.
- **stone_wall:** a stone-faced earth embankment with a white plaster wall on top, a small tile cap and rectangular and triangular gun and arrow ports.

## 3. Units

- **villager:** a short kosode or hitatare jacket and short hakama or tied trousers, straw waraji and a **sugegasa** conical straw hat or a headband. Indigo and brown. Topknot, beard often.
- **swordsman:** a foot retainer in a **dō-maru** cuirass with a hachimaki headband or a simple kabuto without crest. He carries an **uchigatana** worn edge-up through the belt, and may use a two-handed **nodachi** for the "big blade" silhouette. He has no shield.
- **spearman:** an **ashigaru** with a **yari**. The long nagae-yari reached up to 5-6 m; the sprite can use 1.5x body height. The naginata was a samurai and warrior-monk weapon, falling out of use by the Sengoku period, so yari fits ashigaru. He wears a conical **jingasa**, a simple dō (okegawa-dō late) and an indigo uniform with a small mon on the chest.
- **archer:** an asymmetric **yumi**, very long (about 2.2 m) with the grip a third from the bottom, an ebira quiver at the hip, a jingasa or hachimaki and light armour.
- **samurai:** the elite unit. A **kabuto** with gilt **kuwagata** horns, a menpō face mask, lamellar **dō-maru/haramaki** or ō-yoroi laced in bright **odoshi** cord (red or blue), large shoulder plates (sode) and a katana. A **sashimono** back-flag is mid-Sengoku and later; keep it optional.
- **cavalry:** a mounted samurai in **ō-yoroi**, the box-like lamellar armour of the mounted archer. He carries a yumi or a yari, with a horo cape optional.
  - **Horse:** a **small, stocky native horse** with a thick mane, about pony height to European eyes. It has a lacquered wooden saddle, slipper-shaped abumi stirrups and red silk crupper tassels (shirigai), and **no barding**.


**People (physique).** The shortest people in the game (-4 %, about 157-160 cm: the medieval Japanese average), slightly slender. Skin: warm, honey and light tones. Hair black in the **chonmage**: the pate shaved (sakayaki), the queue tied and folded forward over the top; thin moustache. Tones, hair colours and the roles that get each are set in `art_source/blender/units/unitstyle.py` (PHYSIQUE) and mirrored in `art_source/aseprite/physique.lua`. Facial features (eyes, nose, cheekbones) are deliberately the same for every civ: varying them reads as caricature in this style.

## 4. Heraldry

Use **mon**, simple circular crests, in black or white on a contrasting field.

- **Default emblem:** the **mitsudomoe** (three commas in a circle). It was used by many warrior houses and is linked to Hachiman, the war deity. At 5-9 px use a white circle with three black commas, or a black circle.
- **Alternative:** the Minamoto gentian (sasarindō).
- **Flags:** nobori, tall vertical banners with the mon at the top.

## 5. Avoid

- The rising-sun flag with rays, which is a modern military symbol.
- The 16-petal imperial chrysanthemum.
- Himeji-style white tenshu as the default.
- Ninja costumes.
- Chinese upswept roof corners and red-and-gold Chinese palaces.
- Big European horses and shields carried by samurai.
- The katana slung edge-down. That is the tachi, mounted only.

## 6. Sources

- https://en.wikipedia.org/wiki/Japanese_armour
- https://en.wikipedia.org/wiki/Ashigaru
- https://projects.mcah.columbia.edu/jaanus/record/yakatajiro
- https://web-japan.org/atlas/architecture/arc13.html
