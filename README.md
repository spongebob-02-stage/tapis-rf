# tapis-rf

Reverse-engineering et lecture d'un **tapis à 4 boutons** émettant en **RF**, capté via un
**récepteur USB** sur une machine Windows. Ce repo sert de **doc de suivi partagée** entre les
machines de travail (PC Windows, serveur, Mac).

## État actuel (voir `docs/journal.md` pour le détail daté)

- ✅ Récepteur détecté et lu.
- ✅ Liaison série décodée : **COM5, 250000 bauds, 8N1**. Trame = **4 octets, délimiteur `FF`**.
  Heartbeat = `42 CE 4E FF` (~10 Hz) = **balise du récepteur**.
- ❌ **Les appuis ne passent PAS en écoute passive** (démontré 2026-06-17, A/B propre) : le flux est
  identique avec ou sans appui ; les écarts sont du bruit RF (flips d'1 bit).
- 🔑 **Compris** : le récepteur ne sort les boutons **qu'après un handshake** envoyé par le logiciel
  de la borne. DTR/RTS et commandes simples écartés → handshake non devinable à l'aveugle.
- 🔜 **Prochaine étape** : **sniffer matériel** (analyseur logique / 2ᵉ USB-TTL) du dialogue
  borne↔récepteur pendant que le jeu tourne → récupérer le handshake + les trames de boutons.

## Matériel

| Élément | Détail |
|---|---|
| Liaison hôte | câble **FTDI TTL232R** (USB↔TTL série) sur la carte réceptrice — `VID 0403:6001`, s/n `FTES44GZ` |
| Port (Windows) | **COM5** |
| Carte réceptrice | **custom** : MCU (QFP) + module radio sub-GHz ~916 MHz (type RFM) + quartz + batterie |
| Émetteur | Le tapis, **4 boutons** à capteurs de pression (haut/bas/gauche/droite) |
| Jeu | **borne clé en main** (auto-lancée au boot, pas copiable, pas open-source) |

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
docs/protocol.md   # format série + trame, ce qui est confirmé / à confirmer
docs/journal.md    # journal de suivi daté (multi-machines)
scripts/           # lecteurs / outils
```
