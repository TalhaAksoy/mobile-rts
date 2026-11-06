# Ottomans — art brief

Target period: c. 1400–1550 (early Ottoman Bursa/Edirne style through early Istanbul). Janissary musket is 16th century.

## 1. Palette

| Hex | Use |
|---|---|
| `#E3D7BF` | Cut limestone / marble (mosque walls, castle ashlar) |
| `#A4553A` | Brick courses in "cloisonné" walls (stone framed by brick) |
| `#F1EDE3` | Whitewashed plaster (houses, upper storeys) |
| `#7D8790` | Lead sheeting on domes and minaret caps (blue-grey, not gold) |
| `#B4654A` | Terracotta pan tiles on houses, sheds |
| `#6B4A2E` | Timber frame, eaves, lattice shutters |
| `#1F4FA0` | Iznik cobalt (tiles, trim) |
| `#3BA6A4` | Iznik turquoise (tile accents, door panels) |
| `#B3202A` | Kermes crimson (sipahi kaftan, banners) |
| `#2D4C8C` | Janissary blue wool *dolama* |
| `#3D6B3A` | Green (sashes, religious banners) |
| `#C9A44A` | Brass/gilt (finials, tack fittings) |

## 2. Architecture

**Walls:** cut stone, or alternating bands — one course of stone framed by 2–3 thin brick courses (Bursa style). Houses: stone ground floor, timber-framed whitewashed upper floor that overhangs the street on brackets (*çıkma*). **Roofs:** shallow hipped terracotta tile on houses; public buildings get hemispherical lead-covered domes (low, never onion-shaped), often a main dome plus a row of small portico domes. **Towers:** slender cylindrical "pencil" minaret with one balcony (*şerefe*) and a sharp conical lead cap. **Arches/openings:** pointed arches, rectangular windows under a pointed relieving arch, wooden lattice shutters; portico of columns in front of a mosque. **Ornament:** brass crescent finial on domes (*alem*), muqarnas capitals and portal hood, tile lunettes over windows, carved stone crests. **Props:** marble fountain (*şadırvan*), cypress trees, carpets hung to air, copper pots, wooden carts, horsetail standard (*tuğ*) at gates.

- **town_center:** single-dome mosque with a 3–5 dome portico and one pencil minaret, low madrasa wing beside it (a *külliye*).
- **house:** two-storey; stone base, whitewashed timber upper floor jutting forward, red tile hip roof, lattice windows.
- **barracks:** janissary *oda*: long single-storey stone block with a row of small domes or chimneys, arcaded courtyard front, big copper cauldron (*kazan*) by the door.
- **archery_range:** open walled yard with stone marker pillars (*nişan taşı*, real Ottoman archery markers) and straw targets; small tiled shelter.
- **stable:** long stone/brick building, tile roof, arched doorways, hay and saddles outside.
- **castle:** Rumelihisarı-type: massive round towers with conical lead roofs, crenellated curtain walls, stone with brick bands.
- **watch_tower:** square stone tower, timber gallery on top, conical lead or tile cap.
- **blacksmith:** stone shed with tile roof, brick chimney, anvil and quench trough under an open timber awning.
- **lumber_camp:** open timber shed with tile roof, stacked logs, two-man saw trestle.
- **mining_camp:** timber head-frame over a shaft, ore baskets, donkey.
- **mill:** Aegean-type round stone windmill with conical roof and 8–12 triangular cloth sails (inland, horizontal watermills were more common; windmill chosen for readability).
- **market:** *bedesten*: rectangular stone hall with a grid of small lead domes, open stalls with awnings in front.
- **stone_wall:** ashlar with brick bands, rectangular merlons, occasional round tower.

## 3. Units

- **villager:** white or undyed *sarık* (small turban) or felt cap, full beard; loose *şalvar* trousers, knee-length *entari* in undyed/brown, coloured sash (*kuşak*), soft leather shoes. No armour.
- **swordsman (azab/levend):** small white turban over a padded cap or a *çiçak* helmet (pointed bowl, peak, sliding nasal); mail shirt over red kaftan; **round *kalkan* shield** (spiral cane-and-silk weave, central iron boss) in red/gold; curved *kılıç*. Reads as: round shield + sword.
- **spearman (azab):** like swordsman but plain brown/ochre coat, lighter mail or none, long spear, no shield or a small round one. Reads as: tall spear.
- **archer:** turban, no armour, mid-length kaftan tucked into sash; short, sharply recurved Turkish composite bow, quiver (*tirkeş*) and bow case on the hip, thumb ring. Reads as: no shield, bow.
- **janissary:** **tall white felt *börk* with a long flap hanging down the back** and a brass spoon-holder plate at the front; **moustache, no beard** (janissaries were forbidden beards); long blue *dolama* coat with skirts tucked up into the sash; long matchlock *tüfek* with a short butt; *yatağan* at the belt. No armour, no shield. Reads as: white hat tail + gun.
- **cavalry (sipahi):** turban wrapped round a pointed helmet, or *çiçak*; mail-and-plate (mail with small plates at chest), vambraces; crimson kaftan; round *kalkan*; lance with a small pennon, *kılıç*, bow case. **Horse:** lean Turkoman/Arab type, small head, long neck; deep saddle, short stirrups, colourful saddle cloth, tassels and brass plaques on the bridle, horsetail tassel under the neck. No barding for standard sipahi.


**People (physique).** Average stature, slightly sturdy (+2 % torso). Skin: light, olive and tanned tones (Anatolian, Balkan and Caucasian recruits). Hair black or dark brown, kept short or shaved under the turban; full beards, except the janissaries (moustache only). Tones, hair colours and the roles that get each are set in `art_source/blender/units/unitstyle.py` (PHYSIQUE) and mirrored in `art_source/aseprite/physique.lua`. Facial features (eyes, nose, cheekbones) are deliberately the same for every civ: varying them reads as caricature in this style.

## 4. Heraldry and emblems

- **Safest:** a **red field with a white crescent** (no star). Sources tie crescents to Ottoman standards from at least the late 15th century (Rhodes 1480, ships in 1487). A tradition that ties them to Orhan (1320s–60s) is weaker evidence.
- **Horsetail *tuğ*:** a pole with a gilt ball/crescent finial and hanging horsehair. This is the period symbol of command. It makes a good 5–9 px flag-pole silhouette.
- **Zülfikar (two-pointed sword) on red or green.** This is a war-flag device from the 16th century.
- **Do not use the star and crescent.** The star dates from the 18th century. The national flag was fixed in 1844.

## 5. Common mistakes

- Fez: it is 19th century. Use turbans and *börk*.
- Onion or gold domes: Ottoman domes are low, grey and leaded.
- Star-and-crescent flags.
- Iznik tomato red everywhere: that colour only appears after c. 1550. Stick to blue/turquoise/white.
- Bearded janissaries, or janissaries in plate armour.
- Arabian-Nights scimitars. Early swords are moderately curved.

## 6. Sources

- https://en.wikipedia.org/wiki/Flags_of_the_Ottoman_Empire
- https://en.wikipedia.org/wiki/Janissaries
- https://fiav.org/wp-content/uploads/2021/05/17-31-Martykan-HistoryOfOttomanMilitaryFlags.pdf
