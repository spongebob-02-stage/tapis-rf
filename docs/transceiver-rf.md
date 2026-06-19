# Transceiver RF — récepteur nRF24L01+ (lire + émettre, émuler un tapis)

But : se mettre sur la **radio des tapis** avec un transceiver **identique en protocole**. **Recevoir**
ce qu'un vrai tapis émet (ID + flèches) pour notre moteur, et pouvoir **émettre** des trames que le
**dongle d'origine accepte** (injection dans le jeu de base).

> ✅ **Étape 0 résolue (2026-06-19).** Radio = module **TRW-24G** / puce **Nordic nRF2401** →
> **2,4 GHz GFSK ShockBurst**, 125 canaux (1 MHz), 250 kbps ou 1 Mbps. Émetteur ≡ récepteur (même PCB).
> Détail : `materiel.md` + `../captorisation/releve-rf.md`. **Rayés : SDR, CC1101, 433/868/916 MHz.**

## Pourquoi cette voie

- **Contourne le verrou série.** Le blocage « le récepteur ne sort les boutons qu'après un handshake de
  la borne » est un problème **MCU↔USB du dongle**, pas la radio. En lisant **directement sur l'air**,
  on l'ignore complètement (voir `protocol.md`).
- **Dongle + borne intacts → jeu de base jouable EN PARALLÈLE.** On ne débranche rien, on ne soude rien.
- **Sert le but final.** Réception RF directe → lire les tapis dans **notre** moteur (Godot 4 / web / Python).

## Matériel à sourcer

- **nRF24L01+** (×1–2, ~2 € pièce) — successeur **rétro-compatible** du nRF2401 en ShockBurst (non-Enhanced).
  ⚠️ **Bien prendre la variante « + »** : seule à faire le **250 kbps** (le nRF2401 d'origine peut l'utiliser).
- **ESP32** (déjà au projet) — pilote le nRF24L01+ en **SPI** + fait le pont vers le moteur.
- **Analyseur logique 8 voies** (~10 €) — pour la voie déterministe ci-dessous (fortement conseillé).
- ❌ Plus besoin de **RTL-SDR / CC1101**.

## Les 5 paramètres ShockBurst à relever

ShockBurst **classique** = récepteur **pré-configuré** (pas de payload dynamique). Pour capter un tapis,
il faut : **canal `RF_CH`**, **débit `RF_DR`**, **adresse (largeur + valeur)**, **longueur de payload
fixe**, **schéma CRC**.

- **Voie 1 — déterministe (recommandée)** : sniffer le **mot de config (~15 o)** que l'**ATMEGA32L**
  écrit au nRF2401 **au boot**. Analyseur logique sur **CS / CLK1 / DATA** (+ CE). Alimenter le tapis →
  capturer la rafale (CS haut) → décoder selon les registres nRF2401 : canal, débit, adresses, largeur
  d'adresse, longueur payload, CRC, RX/TX. **Donne aussi l'ADRESSE exacte** (indispensable pour filtrer
  le bruit 2,4 GHz). **Câblage détaillé (schéma) : `../captorisation/cablage-analyseur.md`.**
- **Voie 2 — sniff aveugle** : nRF24L01+ en **promiscuous** (méthode Goodspeed / Mousejack) — largeur
  d'adresse 2 o, « adresse » = motif de préambule (`0x00AA` / `0x0055`), CRC off, **balayage des 125
  canaux** → reconstruire l'adresse. Plus lent et bruité.

> ⚠️ **Bruit 2,4 GHz** : le nRF2401 est hypersensible et la bande est saturée (WiFi / BT / micro-ondes).
> **Toujours filtrer par adresse + CRC** → d'où l'intérêt de la **voie 1**.

## Configurer le nRF24L01+ pour recevoir un nRF2401

Régler le nRF24L01+ **à l'identique** et **désactiver l'Enhanced ShockBurst** :
- même **canal** (`RF_CH`), même **débit** (`RF_DR`), même **largeur + valeur d'adresse** (`SETUP_AW`,
  `RX_ADDR_P0`), même **longueur de payload fixe** (`RX_PW_Px`, **pas de DPL**), même **CRC**
  (`EN_CRC` / `CRCO`), **`EN_AA = 0`**, **`DYNPD = 0`**.
- Le **même module** peut aussi **émettre** des trames ShockBurst forgées (injection) et **lire** les tapis.

## Procédure

1. **Acquérir les 5 params** (voie 1 : sniff du mot de config).
2. **Configurer** le nRF24L01+ → capter les trames d'un vrai tapis.
3. **Décoder le payload** : marcher **1 flèche / 1 tapis à la fois** → **ID (DIP) + bitmask flèches + CRC**.
4. **Exposer** `{tapis, flèche, appui}` vers le moteur (ESP-NOW / WebSocket → Godot/web, ou direct Python).
5. **Option** : **émettre** une trame forgée → vérifier qu'elle **s'affiche dans le jeu** (dongle d'origine).

## Réversibilité — non négociable

- **Aucune modif du dongle / de la borne** : on n'agit que par les ondes (réception) ou par injection RF.
- **Aucune soudure** : sniff de config = analyseur **clipé** sur les pads, sur un **tapis de spare** (on en a > 4).
- À tout moment : **vrais tapis + dongle d'origine** → **jeu de base jouable**.

## À faire

- [ ] Commander **nRF24L01+** (bien le « + ») + **analyseur logique 8 voies**.
- [ ] **Voie 1** : sniffer le mot de config (CS/CLK1/DATA) → `RF_CH`, `RF_DR`, adresse, payload, CRC.
- [ ] **Relever DIP → canal** (+ n° affiché dans le jeu) pour la table d'ID.
- [ ] Configurer le nRF24L01+ → **capter** un tapis ; **décoder** payload → flèches.
- [ ] **Reader** + pont **ESP-NOW / WebSocket** → Godot ; option **injection** d'une trame forgée.
