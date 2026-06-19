# Transceiver RF — émuler un tapis (émettre + recevoir directement)

But : au lieu d'espionner le lien série récepteur↔borne, on **se met sur la radio** avec notre propre
transceiver sub-GHz. On **reçoit** ce qu'un vrai tapis émet (décoder ID + flèches) **et** on **émet**
des trames forgées que le **récepteur d'origine** accepte comme venant d'un tapis.

> **Décision 2026-06-19.** La capture logicielle USB (USBPcap/Wireshark) sur la borne est **écartée**
> (bureau Windows inatteignable — voir `journal.md`). Plutôt que de courir après le handshake
> borne↔récepteur (sniff UART, replay), on agit **côté radio**, **en amont du récepteur**.

## Pourquoi cette voie

- **Contourne le handshake.** Le blocage connu (« le récepteur ne sort les boutons qu'après un
  handshake de la borne », voir `protocol.md`) ne concerne que la lecture sur COM5. En **émettant en
  RF**, c'est la **borne réelle** (avec son vrai handshake) qui pilote le récepteur d'origine ; lui
  fait son travail normal et relaie nos trames vers le jeu.
- **Récepteur d'origine intact, jeu de base jouable EN PARALLÈLE.** On ne débranche rien, on ne soude
  rien, on ne coupe aucun fil. Les vrais tapis continuent de marcher en même temps que notre émetteur.
- **Sert le but final.** En réception RF directe, on lit les tapis depuis **notre** moteur de jeu
  (Godot 4 / web / Python) sans dépendre du récepteur ni du logiciel iDANCE2.

## Matériel à sourcer

Cible : un **transceiver sub-GHz** sur la **même bande** que la chaîne d'origine — récepteur
**TRH-?16 ~916 MHz**, émetteur tapis **TRU-246** (bande/modulation exactes **à confirmer**, voir
`materiel.md`).

- **Étape 0 — identifier la radio d'origine (bloquant)** : relever les réfs exactes des modules
  **TRU-246** (tapis) et **TRH-?16** (récepteur), retrouver l'**IC RF** (souvent un CC1101 / Si4432 /
  RFMxx) et la **bande** + **modulation** (probable GFSK/ASK sub-GHz). Sans ça, impossible d'accorder
  le transceiver ni de forger une trame valide.
- **Transceiver retenu (sous réserve de l'étape 0)** : un module **CC1101 868/915 MHz** (~3-5 €, large
  gamme de bandes/modulations, piloté en **SPI** par un ESP32/Pico) **ou** un module **identique au
  TRU-246** récupéré sur un **tapis de spare** (émulation 1:1, la plus sûre).
- Pour la **recon** initiale, un **RTL-SDR** (~25 €) — ou un récepteur du même IC — aide à confirmer
  bande/modulation **avant** achat ferme.
- + MCU hôte (**ESP32** ou **Pico**, déjà au projet) pour piloter le transceiver et faire le pont USB↔PC.

> ⚠️ Tant que bande/modulation/format ne sont pas confirmés, **ne pas commander à l'aveugle** : un
> CC1101 couvre large, mais un module incompatible avec le TRU-246 ne sera pas accepté par le récepteur.

## Contrainte non négociable — réversibilité

- **Aucune modif du récepteur d'origine** ni de la borne : on n'agit que **par les ondes**.
- **Aucune soudure** sur les cartes d'origine ; pour l'émulation 1:1 on **réutilise un tapis de spare**
  (on en a > 4) ou un module neuf — **jamais** le matériel de référence.
- À tout moment on doit pouvoir **jouer au jeu de base** : vrais tapis + récepteur d'origine, intacts.

## Procédure

1. **Recon** : transceiver (ou SDR) accordé sur la bande, capturer ce qu'émet un **vrai tapis** appairé
   en marchant **une flèche à la fois, un tapis à la fois** → isoler **header / ID tapis (DIP switches)
   / bitmask des 4 flèches / checksum**.
2. **Décodage** : reconstituer le format de trame RF (recouper avec `protocol.md`, côté série).
3. **Émission** : forger une trame « flèche X du tapis N » et l'émettre → vérifier qu'elle **s'affiche
   dans le jeu** via le récepteur d'origine (jeu de base toujours actif).
4. **Lecture directe** : en parallèle, exposer les flèches décodées en `{tapis, flèche, appui}` vers
   notre moteur (WebSocket → Godot/web, ou direct en Python).

## À faire

- [ ] **(bloquant)** Relever les réfs **TRU-246 / TRH-?16** → IC RF + **bande** + **modulation** (GFSK/ASK ?).
- [ ] Choisir/commander le transceiver (CC1101 sub-GHz **ou** module identique au TRU-246) + MCU hôte.
- [ ] **Recon RF** : capturer un vrai tapis (1 flèche / 1 tapis à la fois) → ID + bitmask + checksum.
- [ ] **Émettre** une trame forgée → validée si elle **s'affiche dans le jeu** (récepteur d'origine intact).
- [ ] **Reader** côté PC : sortie `{tapis, flèche, appui}` + pont WebSocket vers le moteur de jeu.
- [ ] Vérifier en fin de séance que **vrais tapis + récepteur d'origine** rejouent au **jeu de base**.
