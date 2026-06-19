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
- 🚫 **Sniff du handshake borne↔récepteur abandonné (2026-06-19)** : capture logicielle sur la borne
  impossible (bureau Windows inatteignable, kiosque plein écran ; seul **F2 → BIOS** répond), et inutile
  de courir après le handshake — voir ci-dessous. Détail `docs/journal.md`.
- 🔜 **Prochaine étape** : **transceiver RF (émuler un tapis)** — on passe **côté radio** : **émettre**
  des trames vers le récepteur d'origine (laissé branché → **jeu de base jouable en parallèle**) **et
  recevoir** les tapis directement. **Contourne le handshake.** Montage : `docs/transceiver-rf.md`.

## Matériel

| Élément | Détail |
|---|---|
| Liaison hôte | câble **FTDI TTL232R** (USB↔TTL série) sur la carte réceptrice — `VID 0403:6001`, s/n `FTES44GZ` |
| Port (Windows) | **COM5** |
| Récepteur (carte custom) | MCU (QFP) + module radio sub-GHz ~916 MHz **« TRH-?16 »** (type RFM) + quartz + batterie |
| Émetteur (tapis) | MCU + module RF doré **« TRU-246 »** + antenne PCB, quartz **FS8.000P (8 MHz)**, **DIP switches = ID/canal**, pack **NiMH 4.8 V 1500 mAh** (~70 h). 4 flèches = **contacts secs** NO (haut/bas/gauche/droite) |
| Jeu | **iDANCE2** : PC Windows d'origine + logiciel **propriétaire** (auto-lancé au boot, pas copiable, pas open-source) |

> ℹ️ **Deux modules RF distincts** : **TRU-246** côté émetteur (tapis), **TRH-?16 ~916 MHz** côté
> récepteur. Ne pas confondre les réfs — détail dans `docs/materiel.md`.
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
scripts/               # lecteurs / outils
```
