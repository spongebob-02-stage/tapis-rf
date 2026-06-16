# tapis-rf

Reverse-engineering et lecture d'un **tapis à 4 boutons** émettant en **RF**, capté via un
**récepteur USB** sur une machine Windows. Ce repo sert de **doc de suivi partagée** entre les
machines de travail (PC Windows, serveur, Mac).

## État actuel (voir `docs/journal.md` pour le détail daté)

- ✅ Récepteur détecté et lu.
- ✅ Liaison série décodée : **COM5, 250000 bauds, 8N1**.
- ✅ Trame identifiée : **4 octets, délimiteur `FF` en fin**. Heartbeat au repos = `42 CE 4E FF` (~10 Hz).
- 🔄 **En cours** : isoler la signature de chaque bouton (l'appui maintenu ne change pas la trame →
  hypothèse « événement à l'appui », pas un état permanent).

## Matériel

| Élément | Détail |
|---|---|
| Récepteur RF | Dongle USB-série à puce **FTDI** — `VID 0403:6001`, n° série `FTES44GZ` |
| Port (Windows) | **COM5** |
| Émetteur | Le tapis, **4 boutons** (haut/arrière = bouton 1, …) |

> ⚠️ Le récepteur est branché physiquement sur le **PC Windows**. Les Claude du serveur et du Mac
> travaillent sur la doc et le code ; la **lecture série en direct** se fait sur le PC Windows
> (ou là où le dongle est branché).

## Lire le tapis

PowerShell (Windows) :

```powershell
.\scripts\read_tapis.ps1            # écoute COM5 @250000, affiche les trames
```

Voir `docs/protocol.md` pour le format de trame et `scripts/` pour le lecteur.

## Organisation

```
docs/protocol.md   # format série + trame, ce qui est confirmé / à confirmer
docs/journal.md    # journal de suivi daté (multi-machines)
scripts/           # lecteurs / outils
```
