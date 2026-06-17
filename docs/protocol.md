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

## Boutons — les appuis ne passent PAS en écoute passive (2026-06-17)

**Démontré : appuyer sur le tapis ne modifie pas du tout le flux COM5 en écoute passive.**
A/B propre (`tapis_app.ps1`) : « 40 appuis » = 49 écarts / « rien » = 50 écarts / « HAUT ×10 » = 17
écarts, **0 répétition** dans tous les cas. Les écarts sont uniquement des **flips d'1 bit** du
heartbeat (bruit du lien RF ; bit `0x40` le plus touché), pas des codes de boutons.

- Le heartbeat `42 CE 4E` est présent **tapis éteint comme allumé** → c'est la **balise du
  récepteur**, pas une trame du tapis.
- Les « glitches » notés le 2026-06-16 (`42 CE 0C`, `42 9C 4E`, etc.) étaient donc du **bruit**, pas
  des boutons.

### Le récepteur attend un « réveil » de l'hôte (handshake)
Un même tapis **fonctionne dans le jeu** (la borne) avec ce récepteur, mais reste **muet** quand on
écoute passivement. Un seul récepteur, déplacé entre PC et borne ; la borne le réclame s'il manque
→ **c'est bien le chemin des appuis**. Conclusion : le récepteur ne sort les boutons **qu'après une
commande envoyée par le logiciel de la borne**.

Pistes de réveil **écartées** (testées le 2026-06-17, voir `scripts/wake_probe*.ps1`) :
- **DTR/RTS** : aucune des 4 combinaisons ne déclenche les boutons.
- **Commandes simples** (FF, 00, 55, AA, 42, 01, 10, 80, CR, LF, CRLF, `?`, S, R, V, I, echo du
  beacon, envoyées en boucle) : aucune ne déclenche.

→ Le handshake est plus spécifique (séquence/timing) et **non devinable à l'aveugle**.

## Matériel

| Élément | Détail |
|---|---|
| Liaison hôte | câble **FTDI TTL232R** (USB↔TTL série) sur header 6 broches, TXD a priori câblé |
| FTDI | `VID 0403:6001`, s/n `FTES44GZ` → **COM5** |
| Carte réceptrice | **custom** : MCU (QFP) + **module radio sub-GHz ~916 MHz** (blindé, « TRH-?16 », type RFM) + quartz + alim/batterie |
| Sérigraphie | BUTTON, TEMP, PWR-CHRG, STATUS, BAT, RF |
| Jeu | **borne clé en main** (auto-lancée au boot, pas copiable, pas open-source) |

## Prochaine étape : sniffer matériel du dialogue borne↔récepteur

Comme on ne peut ni lancer le jeu ailleurs, ni installer sur la borne, on **espionne les fils UART**
de la carte pendant que la **borne** fait marcher le tapis (FTDI branché sur la borne) :

- **analyseur logique** (ou 2ᵉ USB-TTL) relié au PC, **250000 8N1** ;
- **TX carte** → trames de **boutons** ; **RX carte** → **handshake** à rejouer ensuite depuis nos scripts.
