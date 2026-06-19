# tapis-rf

Reverse-engineering et lecture des **tapis de danse iDANCE2** (Positive Gaming, gamme *Impact Dance
Platform*, variante **sans-fil**) : 4 flèches émises en **RF**, captées via un **récepteur USB** sur
le PC Windows d'origine. But final : lire les tapis depuis **notre** moteur de jeu (Godot 4 / web /
Python) au lieu de rester prisonnier du logiciel iDANCE2 propriétaire. Ce repo sert de **doc de suivi
partagée** entre les machines de travail (PC Windows, serveur, Mac).

## État actuel (voir `docs/journal.md` pour le détail daté)

- ✅ Récepteur détecté et lu.
- ✅ Liaison série décodée : **COM5, 250000 bauds, 8N1**. Trame = **4 octets, délimiteur `FF`**.
  Heartbeat = `42 CE 4E FF` (~10 Hz) = **balise du récepteur**.
- ✅ **Capteurs des tapis sains** : chaque flèche = **contact sec** (interrupteur NO), confirmé au
  multimètre — **pas** un FSR analogique (voir `docs/materiel.md`).
- ✅ **Chaîne RF d'origine prouvée fonctionnelle** : un tapis appairé s'affiche bien dans le jeu (tapis n°9).
- ❌ **Les appuis ne passent PAS en écoute passive** (démontré 2026-06-17, A/B propre) : le flux est
  identique avec ou sans appui ; les écarts sont du bruit RF (flips d'1 bit).
- 🔑 **Compris** : le récepteur ne sort les boutons **qu'après un handshake** envoyé par le logiciel
  de la borne. DTR/RTS et commandes simples écartés → handshake non devinable à l'aveugle.
- 🚫 **Sniff du handshake borne↔récepteur abandonné (2026-06-19)** : capture logicielle impossible
  (bureau Windows inatteignable, kiosque ; seul **F2 → BIOS** répond) — et inutile, on passe côté radio.
- ✅ **RADIO IDENTIFIÉE (2026-06-19)** : module **TRW-24G** / puce **Nordic nRF2401** → **2,4 GHz GFSK
  ShockBurst**, 125 canaux, 250 k/1 M. **Émetteur ≡ récepteur** (même PCB). Détail `docs/materiel.md`.
- 🔜 **Prochaine étape** : récepteur **nRF24L01+** (rétro-compatible, ~2 €, SPI/ESP32) → **lire les
  tapis sur l'air** (contourne le verrou série) **et émettre** des trames que le dongle accepte. Reste
  à relever les **5 params ShockBurst**. Montage : `docs/transceiver-rf.md`.

## Matériel

| Élément | Détail |
|---|---|
| Liaison hôte | câble **FTDI TTL232R** (USB↔TTL série) sur la carte réceptrice — `VID 0403:6001`, s/n `FTES44GZ` |
| Port (Windows) | **COM5** |
| Récepteur (dongle) | **même PCB** que l'émetteur : **ATMEGA32L** + module **TRW-24G (nRF2401)** + alim |
| Émetteur (tapis) | **ATMEGA32L** + module RF **TRW-24G** (**nRF2401**, 2,4 GHz GFSK ShockBurst) + antenne boucle PCB, quartz **FS8.000P (8 MHz)**, **DIP switches (8) = ID/canal**, pack **NiMH 4.8 V 1500 mAh** (~70 h). 4 flèches = **contacts secs** NO (haut/bas/gauche/droite) |
| Jeu | **iDANCE2** : PC Windows d'origine + logiciel **propriétaire** (auto-lancé au boot, pas copiable, pas open-source) |

> ℹ️ **Même module RF des deux côtés** : **TRW-24G** (puce **Nordic nRF2401**, 2,4 GHz ShockBurst),
> tapis comme dongle → système **symétrique à transceiver**. Détail dans `docs/materiel.md`.
> *(Les anciennes réfs « TRU-246 / TRH-?16 / ~916 MHz » étaient de mauvais déchiffrages.)*
>
> ⚠️ Le récepteur est branché physiquement sur le **PC Windows**. Les Claude du serveur et du Mac
> travaillent sur la doc et le code ; la **lecture série en direct** se fait sur le PC Windows
> (ou là où le dongle est branché).

## Outils (`scripts/`, PowerShell Windows)

```powershell
.\scripts\read_tapis.ps1            # écoute COM5 @250000, affiche les trames distinctes
.\scripts\capture_buttons.ps1 -Label haut   # capture guidée d'un bouton (logge tout ≠ heartbeat)
.\scripts\raw_dump.ps1 -Label haut  # dump brut + analyse (longueurs de trame, distinctes)
.\scripts\live_sensor.ps1           # visualiseur console temps réel (baseline + détection stable)
.\scripts\tapis_app.ps1             # app fenêtrée WPF : trame courante + historique + export CSV (lancer en -STA)
.\scripts\wake_probe.ps1            # sweep DTR/RTS pour tenter de réveiller le récepteur
.\scripts\wake_probe2.ps1           # envoi de commandes candidates de réveil
```

> ⚠️ Un seul programme à la fois sur COM5. Les `tapis_app.ps1` / `live_sensor.ps1` s'affichent en
> continu → à lancer dans une vraie fenêtre PowerShell.

Voir `docs/protocol.md` pour le format de trame et l'état du décodage.

## Organisation

```
docs/protocol.md       # format série + trame, ce qui est confirmé / à confirmer
docs/materiel.md       # fiche matériel : émetteur (tapis) vs récepteur, capteurs, appairage
docs/transceiver-rf.md # approche retenue (2026-06-19) : émuler un tapis en RF (émettre + recevoir)
docs/plan.md           # architecture cible : Plan A (HID) / B (sniff) / C (retrofit) / D (transceiver RF)
docs/journal.md        # journal de suivi daté (multi-machines)
captorisation/         # relevés terrain : check-list + photos/marquages RF à collecter
scripts/               # lecteurs / outils
```
