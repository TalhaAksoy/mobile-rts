# Saracens (Ayyubid/Mamluk Egypt–Syria) — art brief

Target period: c. 1170–1500 (Saladin's Ayyubids to late Mamluk Cairo/Damascus/Aleppo).

## 1. Palette

| Hex | Use |
|---|---|
| `#DCC79E` | Egyptian limestone (main wall colour, warm sandy) |
| `#B04A32` | Red stone for *ablaq* striping |
| `#2B2A2A` | Black basalt (Syrian ablaq, thresholds) |
| `#F4EEDF` | White marble / plaster |
| `#9C7A50` | Mud brick (houses, sheds) |
| `#6A4428` | Dark wood (mashrabiya screens, doors, beams) |
| `#D6A62B` | Sultanic yellow (Mamluk banners, elite silk) |
| `#A82A2A` | Madder red (kalawta caps, coats) |
| `#E9E3D3` | White cotton/linen (turbans, villagers) |
| `#2A5E8C` | Indigo (common robes) |
| `#C8963E` | Brass/tinned copper (inlaid metalwork, finials) |
| `#8B9196` | Steel (mail, helmets) |

## 2. Architecture

**Walls:** big smooth limestone ashlar. Facades have **ablaq**, horizontal stripes of light and red (or black basalt in Syria) masonry, especially around portals. Houses are mud brick or rubble with plaster. **Roofs:** flat with parapets. Many houses have a slanted **wind-catcher** (*malqaf*) on top. **Domes:** stone domes on a tall drum, often **carved all over** with chevron, zigzag or star-arabesque relief (Qaitbay style). Older and smaller domes are ribbed or plain brick plastered white. **Minarets:** three stacked stages, square, then octagonal, then a round shaft with a small open pavilion and a bulb top (*mabkhara* or bulb finial). They are never Ottoman pencil minarets. **Doors/arches:** tall recessed portal under a **muqarnas** hood (stalactite niche), **joggled interlocking voussoirs** over doors, pointed (keel) arches. **Windows:** wooden **mashrabiya** lattice bays; stucco grilles. **Crenellations:** stepped or trefoil "fleur" crenellations along the roofline. **Props:** water fountain (*sabil*) with a bronze grille, palm trees, clay jars, camel saddles, carpets, rope-tied bales, a sāqiya ox-wheel.

- **town_center:** madrasa-mausoleum complex (Qalawun / Sultan Hasan type): high ablaq facade, muqarnas portal, carved dome and a three-tier minaret.
- **house:** two-storey plastered mud brick, flat roof with a wind-catcher, a projecting mashrabiya bay, plain wooden door.
- **barracks:** *tibaq* (Mamluk barracks of the Cairo citadel): multi-storey plain stone block with small windows, arcade at the base, yellow banner.
- **archery_range:** open *maydan* with a target pole topped by a gourd (*qabaq*), the real Mamluk archery target, plus a shaded stone bench.
- **stable:** long stone stable (*istabl*) with pointed-arch doors, flat roof, hay and saddles, a water trough.
- **castle:** Cairo/Aleppo Citadel style: massive square and round towers with stone ashlar and a sloping glacis base, a stepped crenellation crown, and a bridge-ramp gate.
- **watch_tower:** square stone tower with stepped crenellations and a flag on top.
- **blacksmith:** vaulted stone workshop open to the street, forge, bellows, swords hung on the wall.
- **lumber_camp:** palm-trunk and reed shelter, stacked imported timber and palm logs.
- **mining_camp:** stone quarry face with a timber hoist, baskets, donkey.
- **mill:** **Hama-style noria** (giant wooden water wheel on a stone aqueduct arch). Note that norias lift water. Real grain mills were animal-powered (*tahuna*), so add a small ox-turned millstone beside it if space allows.
- **market:** *khan/wakala*: two-storey courtyard building with an arched gateway and shops under arches; awnings, sacks, spice cones.
- **stone_wall:** ashlar with stepped crenellations and a thin ablaq band.

## 3. Units

- **villager:** white/indigo cotton *thawb* (ankle-length shirt), small white turban, full beard; may carry a palm-fibre basket. Bare feet or sandals.
- **swordsman:** Turkic-style crossover coat (*qaba*) in red or blue, padded mail (*kazaghand*, mail sewn between cloth so it looks like a quilted coat); round steel helmet wrapped in a turban; **small round shield** (wood or cane, painted with a single colour and a boss); straight or slightly curved sword (sabres became common from the 14th century). Reads as: round shield + sword, coloured coat.
- **spearman:** padded jacket (*jubba*) or leather lamellar, simple bowl helmet or turban, long spear, large round or oblong wooden shield. Represents militia and *halqa* foot. Reads as: plain browns + spear.
- **archer:** turban, no armour, composite bow, a cylindrical quiver at the hip, thumb ring; bright sash. Reads as: no shield, bow.
- **mamluk (camel):** elite Turkic/Circassian slave-soldier. **Red or yellow *kalawta* cap with a white turban wound round it**, or a fluted steel helmet with a mail aventail; full beard; mail or lamellar (*jawshan*) under a coloured *qaba*; bow case **and** quiver, a lance, a sword, and a mace at the saddle. **Camel:** a single-hump dromedary, light tan, with a saddle frame on the hump, coloured tassels, a woven saddle bag, and a rope bridle with a nose peg. *Historical note: Mamluks fought on horseback and camels were for Bedouin auxiliaries and transport. So keep the rider pure mamluk and the tack Bedouin.* Reads as: tall silhouette + yellow/red cap.


**People (physique).** Average stature (-1 %), lean build (-4 % torso). Skin: tanned, olive and brown tones (Egypt and Syria; the mamluks were Turkic and Circassian recruits). Hair black or dark brown; full beards. Tones, hair colours and the roles that get each are set in `art_source/blender/units/unitstyle.py` (PHYSIQUE) and mirrored in `art_source/aseprite/physique.lua`. Facial features (eyes, nose, cheekbones) are deliberately the same for every civ: varying them reads as caricature in this style.

## 4. Heraldry and emblems

- **Mamluk blazon** (well documented): a roundel (circle), simple undivided in the Bahri period (pre-1382), later split into three fields. Office emblems: **cup** (cup-bearer), **pen box** (secretary), **two crossed polo sticks** (polo master), **napkin rhombus** (robe master), sword, bow, and the **lion of Baybars**, a walking lion. For 5–9 px: a **red cup on a yellow band** in a white roundel.
- **Sultanic yellow banner** with a white or black inscription band reads well and is defensible.
- Ayyubid flags are poorly documented. The "Saladin eagle" is a modern Arab-nationalist use, so avoid it.

## 5. Common mistakes

- Ottoman pencil minarets or lead domes; Moroccan horseshoe arches and zellij tile.
- Crescent flags (not Mamluk).
- Bedouin keffiyeh look for professional soldiers.
- Huge curved scimitars.
- Turquoise-tiled everything. Mamluk Cairo is stone, stucco and wood.

## 6. Sources

- https://seshat-db.com/wf/laminar_armors_all (Nicolle, *Mamluk Askar* 1250–1517 data)
- https://exhibitions.kelsey.lsa.umich.edu/pearls/objects/blazon2.html
- https://82nd-and-fifth.metmuseum.org/toah/works-of-art/1972.120.3
- https://qspace.qu.edu.qa/handle/10576/28934?show=full
