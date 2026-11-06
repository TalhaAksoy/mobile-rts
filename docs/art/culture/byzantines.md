# Byzantines — art brief

Target period: c. 950–1200 (Middle Byzantine, Macedonian/Komnenian). Late Palaiologan items (to 1453) are allowed but flagged.

## 1. Palette

| Hex | Use |
|---|---|
| `#D9CDB4` | Limestone / marble blocks |
| `#A85A3C` | Thin red brick (the dominant wall material) |
| `#C9B9A0` | Thick lime mortar joints (wide, visible) |
| `#B05A3A` | Terracotta roof tiles |
| `#7E8A93` | Lead sheeting on major domes |
| `#6A2C5E` | Murex purple (imperial/elite trim only) |
| `#A7262B` | Madder red (military tunics, shields, banners) |
| `#2F4E8C` | Woad/indigo blue (tunics, shield fields) |
| `#E8DFC8` | Undyed linen / wool (villagers) |
| `#C8A23E` | Gold (mosaic tesserae, trim, crosses) |
| `#8E949A` | Iron (lamellar, mail, helmets) |
| `#5B4632` | Leather (lamellar lacing, belts, boots) |

## 2. Architecture

**Walls:** alternating bands: 3–5 courses of red brick, then a band of stone. Or cloisonné: each stone block framed by bricks. Mortar is thick and visible. Facades carry decorative brickwork: dogtooth friezes, meander keys, cross and chequer patterns. **Roofs:** terracotta tiles on low gabled roofs that follow the curves of the vaults. Domes sit on tall drums pierced by windows and carry a lead or tile cover, with a scalloped eaves line over the window arches. **Arches/windows:** round arches only. Use paired or tripled windows split by thin marble colonnettes, and blind arcades in recessed brick. **Gates:** tall arched gateways flanked by square or polygonal towers. **Ornament:** small cross finials, marble slab panels, gold mosaic icons in lunettes over doors. **Props:** amphorae, olive and cypress trees, marble column fragments, cisterns and wells, icon shrines.

- **town_center:** cross-in-square church with a central dome on a tall drum and four smaller corner domes, joined to a three-storey palace block with polychrome brick (Tekfur Saray-type).
- **house:** two-storey; the ground floor is stone/brick and the upper floor is timber with a wooden balcony. Low tiled roof and small arched windows.
- **barracks:** long two-storey banded brick-and-stone block, arched ground-floor arcade, shield rack, red banner.
- **archery_range:** walled courtyard with straw butts and a covered arcade.
- **stable:** long single-storey brick building with round-arched doors and a tiled gable roof; water trough.
- **castle:** Theodosian-walls style: tall square and polygonal towers with banded brick-stone, crenellated, an inner keep, a moat wall in front.
- **watch_tower:** square banded tower with a crenellated top and a beacon brazier.
- **blacksmith:** brick workshop with an open arcade, forge chimney, anvil, rack of spears.
- **lumber_camp:** timber shed on stone footings, tiled roof, log stacks.
- **mining_camp:** timber shaft frame, ore carts; marble-quarry blocks fit too.
- **mill:** watermill with a vertical wooden wheel on a stone-and-brick mill house (Byzantine watermills are well attested; skip windmills).
- **market:** colonnaded street stoa: marble columns, tiled lean-to roof, stalls with awnings.
- **stone_wall:** brick/stone banding, square merlons.

## 3. Units

- **villager:** knee-length belted tunic (*chiton*) in undyed or brown, with a coloured hem band; leggings, low boots; felt cap or bare head; beard common. Women wear a veil.
- **swordsman (skoutatos):** conical iron helmet with mail aventail, *or* the padded **phakeolion** turban-wrap. Mail shirt (*lorikion*) or lamellar *klibanion* over a padded *kavadion*. **Large kite/teardrop shield** (kite shape common from c. 1000), painted red or blue with a white border, a cross, or radial bands. Straight double-edged *spathion*. Reads as: big kite shield + sword.
- **spearman:** same kit with a long spear (*kontarion*). Elite *menavlatoi* carried the thick *menavlion*. The shield can be round. Reads as: spear + round shield.
- **archer (toxotes):** no metal armour, just a padded *kavadion*, often in faded red; phakeolion or felt cap; composite bow, a large quiver on the back or hip, a small buckler at most. Beard. Reads as: no shield, padded coat.
- **cataphract:** iron helmet with **mail face-veil hiding the face**; lamellar klibanion with a hanging skirt and arm guards, sometimes a cloth surcoat (*epilorikion*); lance or **iron mace** (*siderorabdion*); small round or kite shield. **Horse:** large Anatolian/Cappadocian type with full **felt or lamellar barding** down to the knees, eyes exposed, in red or blue. Reads as: armoured horse + faceless rider.


**People (physique).** Average stature and build. Skin: olive, light and tanned tones (an empire from the Balkans to Anatolia and Syria). Hair black or dark brown; full beards were the norm for grown men. Tones, hair colours and the roles that get each are set in `art_source/blender/units/unitstyle.py` (PHYSIQUE) and mirrored in `art_source/aseprite/physique.lua`. Facial features (eyes, nose, cheekbones) are deliberately the same for every civ: varying them reads as caricature in this style.

## 4. Heraldry and emblems

- **Safest:** a simple Christian **cross** or **Chi-Rho** on a red, blue or white field. The radial and geometric shield patterns are period-correct.
- **Cross with four "B"s / firesteels (tetragrammatic cross):** gold on red. It is attested in the 14th century (Pseudo-Kodinos), so it is Palaiologan.
- **Double-headed eagle:** a Palaiologan (late 13th century+) dynastic device, gold on red. Use it sparingly, for the castle or town center flag, not on unit shields. Scholars dispute whether it was ever a "state flag".

## 5. Common mistakes

- Roman legionary kit (segmented armour, rectangular *scutum*) or Greek hoplite helmets.
- Onion domes (Russian), pointed Gothic arches, or all-stone walls with no brick.
- Double-headed eagles on every shield.
- Gold domes. Use lead grey or tile.
- Cataphracts drawn as Western knights with great helms and heraldic surcoats.

## 6. Sources

- https://en.wikipedia.org/wiki/Klivanion
- https://en.wikipedia.org/wiki/Skoutatoi
- https://byzantinemilitary.blogspot.com/2022/08
