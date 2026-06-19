# Matériel — tapis de danse iDANCE2

Produit : **Positive Gaming**, gamme *Impact Dance Platform* (plateformes rigides polycarbonate
honeycomb, ~9 kg), système **iDANCE2** variante **sans-fil**. Chaîne d'origine :
tapis (émetteur RF sur batterie) → **récepteur USB** → **PC Windows** + logiciel propriétaire.

> ✅ **Radio identifiée (2026-06-19)** : module **TRW-24G** (Wenshing, sérigraphie carte « RF.NET.TW »),
> puce **Nordic nRF2401** → **2,4 GHz GFSK ShockBurst**. Les anciennes réfs « TRU-246 / TRH-?16 » et la
> piste « ~916 MHz » étaient de **mauvais déchiffrages** — à oublier.
>
> **Émetteur (tapis) et récepteur (dongle) partagent le MÊME PCB** → système **symétrique à
> transceiver**. Un tapis de spare = **émulateur 1:1** garanti compatible.

## Émetteur — la carte dans le tapis

| Élément | Détail |
|---|---|
| MCU | **Atmel ATMEGA32L** (« ATMEGA32L 8AU », TQFP44) — AVR 8 bits basse tension |
| Horloge MCU | quartz **FS8.000P** (8 MHz) |
| Module RF | **TRW-24G** (Wenshing / « RF.NET.TW »), antenne **boucle PCB dorée** |
| Puce RF | **Nordic nRF2401** (QFN24) — transceiver **2,4 GHz GFSK ShockBurst** |
| Config | **DIP switches (8 voies)** = **ID / canal** du tapis |
| Alim | pack **NiMH AA 4.8 V 1500 mAh** (4 accus), autonomie ~70 h |
| Étage charge | 2× optocoupleurs **NEC PS2811-4**, shunt **R075F** (0,075 Ω), self **CDRH104**, LED tricolore |

Photos : `../captorisation/tapis-carte-principale.jpeg` (carte + batterie in situ).

### Module RF TRW-24G (nRF2401) — détail
- Sous-carte enfichable : **antenne boucle dorée** d'un côté (face « TRW-24G »), **carte bleue RF** de
  l'autre (puce nRF2401 + SAW). Rév. module **1141, V2.01**.
- **Brochage** (face pads, interface *DuoCeiver* du nRF2401) :
  - Colonne 1 : **DATA · DR1 · DOUT2 · DR2 · VCC**
  - Colonne 2 : **CLK1 · CS · CLK2 · CE · G**
- Config 3 fils : **CS + CLK1 + DATA**. TX ShockBurst : **CE + CLK1 + DATA**. RX : DR1/CLK1/DATA
  (canal 1) et DR2/CLK2/DOUT2 (canal 2).
- nRF2401 : **2,4 GHz**, **125 canaux** (1 MHz, canal 0 = 2400 MHz), **250 kbps ou 1 Mbps**, paquet
  **ShockBurst** = préambule + adresse (1–5 o) + payload + CRC (0/1/2 o), géré **en matériel**.
- Photos : `../captorisation/module-trw24g-face-rf.jpeg`, `../captorisation/module-trw24g-face-pads.jpeg`.

### Appairage
- Interrupteur **on/off** sur le tapis, puis **marcher sur la flèche HAUT** pour connecter au système.
- Cohabitation multi-systèmes via **canaux différents** → chaque tapis = un **ID/canal** (DIP switches).
- ⚠️ HAUT est la flèche **spéciale** (appairage + validation menu) : qu'elle réponde prouve seulement
  que le tapis **se connecte**, pas qu'une chanson lit les 4 pas.

## Capteurs de pas — contact sec (NO), confirmé

**Conclusion : simple fermeture de contact, PAS un capteur analogique (FSR)** (malgré le terme
marketing « pressure sensor » de Positive Gaming).

- Chaque flèche (UP / DOWN / LEFT / RIGHT) = un **interrupteur normalement ouvert** (2 fils).
- Mécanique : **deux plaques métalliques** par panneau ; marcher dessus les met en contact → circuit fermé.
- Câblage : panneaux → **PCB capteurs central** (connecteurs **JST blancs 2 broches**
  UP/DOWN/LEFT/RIGHT) → carte principale via un **câble type RJ**.

### Test de continuité (multimètre)
| Action | Mesure attendue |
|---|---|
| Repos | circuit **ouvert** (1 / pas de bip) |
| Appui | **bip** / ~0 Ω |
| Relâché | **réouverture** nette |

## Récepteur — le dongle sur le PC

**Même design de PCB que l'émetteur** (ATMEGA32L + module TRW-24G/nRF2401 + alim) — 2 cartes vues,
codes date **0941** vs **1129**.

| Élément | Détail |
|---|---|
| Carte | **custom**, identique à l'émetteur : **ATMEGA32L** + **TRW-24G (nRF2401)** + alim |
| Sérigraphie | BUTTON, TEMP, PWR-CHRG, STATUS, BAT, RF, OPTION, ISP, USB |
| Liaison hôte | câble **FTDI TTL232R** (USB↔TTL série), header 6 broches |
| Identité USB | `VID 0403:6001`, s/n `FTES44GZ` → **COM5** (Windows) |

> Le verrou « boutons absents en écoute passive COM5 » est un problème **MCU↔USB du dongle**,
> **indépendant de la radio** → on le **contourne** en lisant les tapis **directement sur l'air**
> (voir `transceiver-rf.md`). Détail du lien série + décodage : `protocol.md`.

## Photos (`../captorisation/`)
- `module-trw24g-face-rf.jpeg` — module RF, face antenne (« TRW-24G », puce nRF2401, « RF.NET.TW »). *(IMG_8033)*
- `module-trw24g-face-pads.jpeg` — module RF, face brochage DuoCeiver + rév. 1141 V2.01. *(IMG_8035)*
- `tapis-carte-principale.jpeg` — carte principale + batterie NiMH in situ dans le tapis. *(IMG_8022)*
- `carte-principale-ftdi.jpeg` — carte (design commun émetteur/récepteur), côté composants, FTDI branché. *(IMG_8026)*
