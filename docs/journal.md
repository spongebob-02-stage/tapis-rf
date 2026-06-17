# Journal de suivi

Format : entrées datées, machine, ce qui a été fait / trouvé / à faire.
Machines : **PC-Win** (récepteur sur COM5), **serveur**, **mac**.

---

## 2026-06-16 — PC-Win — Détection & décodage liaison

- Récepteur RF branché en USB → détecté : dongle **FTDI** `0403:6001` (s/n `FTES44GZ`) sur **COM5**.
- Tapis allumé. Balayage des débits :
  - 115200 paraissait propre mais **faux** (aliasing) — à ignorer.
  - **250000 bauds, 8N1** = vrai débit. Trame **4 o** délimitée par `FF`.
- Heartbeat repos = `42 CE 4E FF` (~10 Hz).
- Test boutons : appui **maintenu** sur bouton « haut » (= haut/arrière) → trame **identique** au repos.
  → hypothèse : boutons = **événements à l'appui**, pas un état permanent. **À CONFIRMER**.
- Convention de nommage des 4 boutons fixée : **haut / bas / gauche / droite** (haut = le bouton haut/arrière).
- Mise en place du repo de suivi `tapis-rf` (Git + GitHub CLI installés sur PC-Win).

### À faire
- [ ] Capture live pendant appuis sur les 4 boutons → trouver le code de chaque bouton.
- [ ] Nommer/positionner les boutons 2, 3, 4.
- [ ] Script de lecture exploitable par les apps (sortie : bouton pressé).

---

## 2026-06-17 — PC-Win — Les boutons ne sont PAS dans le flux passif : il faut un handshake de la borne

**Conclusion majeure : écouter passivement COM5 ne donne JAMAIS les boutons.** Le récepteur n'émet
que sa balise `42 CE 4E` (+ bruit RF) tant que le logiciel de la borne ne lui envoie pas une
commande de « réveil ». Démontré, pas supposé.

### Outils créés (`scripts/`)
- `capture_buttons.ps1` — capture guidée d'un bouton (logge tout ≠ heartbeat + résumé).
- `raw_dump.ps1` — dump brut + analyse (longueurs de trame, trames distinctes).
- `live_sensor.ps1` — visualiseur console temps réel (baseline + détection « changement stable »).
- `tapis_app.ps1` — **app fenêtrée (WPF)** : trame courante (octets/barres) + historique + export CSV.
- `wake_probe.ps1` — sweep des 4 états **DTR/RTS**.
- `wake_probe2.ps1` — envoi de **commandes candidates** pour réveiller le récepteur.
- Correctif : le heartbeat (payload) est `42 CE 4E` sur **3 octets** (le `0xFF` est le délimiteur,
  pas dans la trame).

### Preuves (A/B propre, 3 exports de `tapis_app.ps1`)
| Test | écarts vs `42 CE 4E` | « stable » |
|---|---|---|
| 40 appuis (HAUT/BAS/DROITE/GAUCHE ×10) | 49 | **0** |
| **rien du tout** | **50** | **0** |
| HAUT ×10 | 17 | **0** |

- Le test « rien » a **autant/plus** d'écarts qu'en appuyant. Tous les écarts = **flips d'1 bit** du
  heartbeat (bruit du lien RF ; le bit `0x40` est le plus touché). **Aucune trame ne se répète** → pas de code de bouton.
- Le heartbeat `42 CE 4E` est présent **tapis éteint comme allumé** → c'est la **balise du récepteur**, pas du tapis.

### Faux départ instructif
- 1er tapis : plaques **encrassées** → « détecté » par la borne mais **aucun appui transmis**
  (mauvais contact). Après **nettoyage des plaques**, un autre tapis **fonctionne dans le jeu**…
  mais **toujours rien sur COM5 en écoute passive** chez nous.

### Diagnostic
- **Un seul récepteur**, déplacé entre le PC et la borne ; la borne signale « récepteur non branché »
  s'il manque → **c'est bien lui le chemin des appuis**.
- Donc le récepteur ne sort les boutons **qu'après un handshake/commande** envoyé par le logiciel de
  la borne (hypothèse B, confirmée par élimination).
- **DTR/RTS** : les 4 combinaisons → ne réveillent pas (DTR=1/RTS=1 supprime même le bruit, 0 bouton).
- **Commandes** testées en boucle (FF, 00, 55, AA, 42, 01, 10, 80, CR, LF, CRLF, `?`, S, R, V, I, echo
  du beacon) → aucune ne réveille. Brute-force aveugle = mauvaise piste.

### Matériel (photos `IMG_8026/8027`)
- Récepteur = **carte custom** : MCU (QFP) + **module radio sub-GHz ~916 MHz** (boîtier blindé,
  pastille « TRH-?16 », type RFM) + quartz + alim/batterie. Sérigraphie : BUTTON, TEMP, PWR-CHRG,
  STATUS, BAT, RF.
- Liaison hôte = câble **FTDI TTL232R** (USB↔TTL série) sur header 6 broches (TXD a priori câblé).
  `VID 0403:6001`, s/n `FTES44GZ` → **COM5**.
- Jeu = **borne clé en main** (auto-lancée au démarrage, pas copiable, pas open-source) → on ne peut
  ni la lancer ailleurs ni lire son code.

### À faire (prochaine session)
- [ ] **Capturer le dialogue borne↔récepteur en matériel** : câble FTDI sur la **borne** (jeu actif),
  espionner les fils UART de la carte avec un **analyseur logique** (ou 2ᵉ USB-TTL) relié au PC, à
  **250000 8N1** :
  - TX carte → ce que le récepteur renvoie = **trames de boutons** ;
  - RX carte → ce que la borne envoie = **handshake à rejouer**.
- [ ] Relever la sérigraphie **à côté du connecteur FTDI** (GND/VCC/TX/RX).
- [ ] Lire les réfs **MCU + module radio** (gros plan) → chercher datasheet/protocole.
- [ ] Handshake connu → le rejouer dans `scripts/` pour que NOTRE PC fasse streamer les boutons.

---

<!-- Nouvelles entrées au-dessus de cette ligne. Indiquer la machine. -->
