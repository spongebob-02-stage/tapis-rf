# Protocole du tapis RF

## Liaison série (CONFIRMÉ)

| Paramètre | Valeur |
|---|---|
| Port (Windows) | `COM5` |
| Débit | **250000 bauds** |
| Format | **8N1** (8 bits, pas de parité, 1 stop) |
| Contrôle de flux | aucun |

> ⚠️ Piège : à **115200 bauds** le flux *semble* propre (`A5 F1 81 F1 …`) mais c'est un
> **artefact d'aliasing**. Le débit réel est **250000**. Ne pas utiliser 115200.

## Format de trame (CONFIRMÉ)

- Trame de **4 octets**, terminée par le **délimiteur `0xFF`**.
- Cadence ~**10 trames/seconde**.
- Au repos (rien d'appuyé), heartbeat constant :

```
42 CE 4E FF
└─ payload (3 o) ─┘ └ délim
```

Parsing : lire le flux, découper sur `0xFF`, chaque trame = les 3 octets qui précèdent.

## Boutons (À CONFIRMER)

- Le tapis a **4 boutons**, nommés par **position** : **haut, bas, gauche, droite**.
- **haut** = le bouton « haut / arrière » (celui testé en premier). Les 3 autres restent à capter.

| Bouton | Position physique | Signature (payload 3 o) |
|---|---|---|
| **haut** | haut / arrière | à confirmer |
| **bas** | bas / avant | à confirmer |
| **gauche** | gauche | à confirmer |
| **droite** | droite | à confirmer |

- Observation : **maintenir un bouton ne modifie PAS** la trame heartbeat `42 CE 4E FF`
  (testé à 115200 ET à 250000 → identique au repos).
- **Hypothèse de travail** : les boutons sont des **événements envoyés à l'instant de l'appui**
  (front montant), pas un état permanent dans la trame. À capter en écoutant pendant l'appui.
- Glitches isolés observés (probablement bruit, à recouper) : `42 CE 0C FF`, `42 9C 4E FF`.

### Prochaines étapes
1. Capture live : logguer toute trame ≠ heartbeat avec horodatage pendant qu'on appuie sur les 4 boutons.
2. Établir la correspondance bouton → code.
3. Vérifier le comportement appui court vs maintenu, et les éventuels codes « relâché ».
