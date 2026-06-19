# Relevé RF — terrain (iDANCE2)

> ✅ **Étape 0 bouclée (2026-06-19) : radio identifiée.** Module **TRW-24G** (Wenshing / « RF.NET.TW »),
> puce **Nordic nRF2401** → **2,4 GHz GFSK ShockBurst**, 125 canaux (1 MHz), 250 kbps / 1 Mbps.
> Émetteur ≡ récepteur (même PCB). Suite technique : `../docs/transceiver-rf.md`.

## Relevés effectués

| Élément | Valeur | Photo |
|---|---|---|
| Module RF — marquage | **TRW-24G** (antenne) / **RF.NET.TW** (carte) → fabricant **Wenshing** | `module-trw24g-face-rf.jpeg` |
| Puce RF | **Nordic nRF2401** (QFN24) — 2,4 GHz GFSK ShockBurst | `module-trw24g-face-rf.jpeg` |
| Bande / modulation / débit | **2,4 GHz** (125 canaux, 1 MHz) / **GFSK** / **250 kbps ou 1 Mbps** | — |
| Antenne | **boucle PCB dorée** intégrée au module | `module-trw24g-face-rf.jpeg` |
| Brochage module (DuoCeiver) | DATA/DR1/DOUT2/DR2/VCC + CLK1/CS/CLK2/CE/G — rév. **1141 V2.01** | `module-trw24g-face-pads.jpeg` |
| MCU (tapis & récepteur) | **Atmel ATMEGA32L** (8AU, TQFP44), des deux côtés | `carte-principale-ftdi.jpeg` |
| Récepteur (dongle) | **même** module TRW-24G / nRF2401 (PCB identique) | `carte-principale-ftdi.jpeg` |
| DIP switches | **8 voies** = ID / canal | `tapis-carte-principale.jpeg` |

## Reste à relever (pour configurer le nRF24L01+)

- [ ] **Canal RF** (`RF_CH`) + **correspondance DIP → canal** (état des DIP + **n° affiché dans le jeu**).
- [ ] **Débit** (250 kbps ou 1 Mbps).
- [ ] **Adresse** (largeur + valeur).
- [ ] **Longueur de payload** (fixe).
- [ ] **Schéma CRC** (0 / 1 / 2 o).
- [ ] **Mapping payload → flèches** : marcher **1 flèche / 1 tapis à la fois** → bits ↔ flèches.

> Méthode déterministe pour les 5 premiers : **sniff du mot de config** (~15 o) écrit par l'ATMEGA32L au
> nRF2401 au boot, analyseur logique sur **CS / CLK1 / DATA**. Schéma de câblage : `cablage-analyseur.md`.
> Suite (config nRF24L01+) : `../docs/transceiver-rf.md`.

## Photos (dans ce dossier)
- `module-trw24g-face-rf.jpeg` — module RF, face antenne : « TRW-24G », puce nRF2401, « RF.NET.TW ». *(IMG_8033)*
- `module-trw24g-face-pads.jpeg` — module RF, face brochage DuoCeiver + rév. 1141 V2.01. *(IMG_8035)*
- `tapis-carte-principale.jpeg` — carte principale + batterie NiMH in situ dans le tapis. *(IMG_8022)*
- `carte-principale-ftdi.jpeg` — carte (design commun émetteur/récepteur), côté composants, FTDI branché. *(IMG_8026)*
