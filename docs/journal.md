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

## 2026-06-17 — Téléphone (Claude téléphone) — Identité produit, internes tapis, capteurs, stratégie

Session de diagnostic « terrain » (au téléphone), **complémentaire** des mesures série PC-Win du même
jour. Apporte le **contexte produit** et l'**électronique de l'émetteur** qui manquaient au repo.

### Identité du matériel (NOUVEAU)
- Produit = **tapis de danse iDANCE2** (Positive Gaming, gamme *Impact Dance Platform*), variante
  **sans-fil** : batteries + récepteur RF + PC Windows dédié + logiciel **propriétaire**.
- La « borne clé en main » = ce **PC iDANCE2 + son logiciel** (contexte activation WeStage). **> 4 tapis**
  dispo, matériel **modifiable** (on peut ouvrir/bricoler).

### Capteurs de pas — CONFIRMÉ : contact sec, pas un FSR
- Chaque flèche = **interrupteur normalement ouvert** (2 fils). 2 plaques métalliques/panneau ;
  marcher dessus ferme le circuit.
- Panneaux → **PCB capteurs central** (JST 2 broches UP/DOWN/LEFT/RIGHT) → carte principale via **câble RJ**.
- **Test multimètre (continuité)** : repos = ouvert (pas de bip) ; appui = bip / ~0 Ω ; relâché =
  réouverture nette. → mécanique de détection **saine** sur le tapis testé.

### Électronique de l'émetteur (le tapis) (NOUVEAU)
- MCU + module RF doré **« TRU-246 »** + antenne PCB, quartz **FS8.000P (8 MHz)**, **DIP switches**
  (= très probablement **ID/canal** du tapis), connecteur batterie, LED de charge tricolore.
- Batterie = pack **NiMH AA 4.8 V 1500 mAh** (4 accus), ~70 h annoncées.
- Appairage officiel : on/off du tapis puis **marcher sur la flèche HAUT** pour connecter. Multi-systèmes
  via **fréquences différentes** → chaque tapis a un **ID radio**.
- ⚠️ Fréquence exacte du **TRU-246** = NON confirmée. À distinguer du module **récepteur** « TRH-?16 »
  ~916 MHz (voir `docs/materiel.md`).

### ✅ Test RF réussi
- Un tapis intact, allumé + appairé, s'est affiché à l'écran comme **tapis n°9** → toute la chaîne
  batterie → MCU → RF → antenne → récepteur → logiciel est **fonctionnelle**.

### Symptôme « seule la flèche HAUT répond » (en cours)
- **PIÈGE** : HAUT est la flèche **spéciale** (appairage + validation menu). Qu'elle réponde prouve
  juste que le tapis **se connecte**, pas qu'une chanson lit les 4 pas.
- Causes par ordre : (1) pas dans un round jouable (démo/attract) ; (2) **batterie faible** (s'annonce
  en RF mais ne transmet pas les pas) → recharger à fond ; (3) défaut propre au tapis.
- **Test différentiel** (on a > 4 tapis) : lancer une vraie chanson et comparer 2-3 tapis.

### Note opérationnelle — PC bloqué au BIOS (résolu)
- Écran AMI « CMOS Battery Low » → pile **CR2032** de la carte mère morte. **F2** continue le boot.
  Clavier **BT inopérant dans le BIOS** → clavier **USB filaire**. Correctif durable : remplacer la
  CR2032, régler l'heure, vérifier *USB Legacy Support*.

### Lien avec les mesures série PC-Win
- Le **Plan B** (sniff passif récepteur→PC) est **affiné** par la mesure PC-Win du jour : en COM5
  passif on n'obtient **que la balise** `42 CE 4E`, **jamais** les boutons → il **faut le handshake**
  de la borne. Donc Plan B passif insuffisant seul → **sniff matériel** borne↔récepteur (déjà la
  prochaine étape du repo) ou bascule **Plan C** (retrofit). Détail dans `docs/plan.md`.

### À faire
- [ ] Remplacer la pile **CR2032** de la carte mère.
- [ ] **Recharger à fond** les tapis avant tout verdict sur les flèches.
- [ ] **Test différentiel** : vraie chanson, comparer plusieurs tapis (4 flèches lues ou non).
- [ ] Brancher le récepteur sur le **laptop** → catégorie (COM / HID / générique) + VID:PID.
- [ ] Décider **Plan B (sniff)** vs **Plan C (retrofit)** selon lisibilité protocole + latence.

---

## 2026-06-19 — Borne inaccessible sous Windows → pivot vers transceiver RF (émuler un tapis)

Deux décisions du jour : (1) la capture **logicielle** sur la borne est infaisable ; (2) on **change
d'angle** — au lieu de courir après le handshake borne↔récepteur, on agit **côté radio**.

### Accès borne — constat
- PC **très ancien**, **BIOS AMI** (cohérent avec l'épisode CR2032/F2). Entrée BIOS par **F2** au POST.
- **Aucun accès au bureau Windows une fois le jeu lancé** : tous les raccourcis sont avalés (`Win`,
  `Alt+Tab`, `Ctrl+Shift+Échap`, `Ctrl+Alt+Suppr`… → rien). Kiosque plein écran qui mange le clavier.
- → **Capture logicielle USB (USBPcap/Wireshark) écartée** : driver noyau (admin + reboot) **et** il
  faut lancer Wireshark dans ce Windows-là, inatteignable. Boot Linux live inutile pour le sniff (jeu
  arrêté = pas de handshake). Ne pas risquer la seule machine de référence.

### Pivot : transceiver RF plutôt que sniff du handshake
Au lieu d'espionner / rejouer le dialogue borne↔récepteur, on **se met sur la radio** avec notre
propre transceiver **sub-GHz** (même bande que le récepteur d'origine **TRH-?16 ~916 MHz**) :
- **émettre** des trames forgées vers le **récepteur d'origine** (laissé branché) → il les relaie au
  jeu comme un vrai tapis. **Contourne le handshake** (c'est la borne qui réveille le récepteur).
- **recevoir** directement ce qu'émettent les vrais tapis → décoder ID + flèches pour notre moteur.
- **Récepteur + borne intacts → jeu de base jouable EN PARALLÈLE**, rien à débrancher ni souder.
- C'est le nouveau **Plan D** (voir `docs/plan.md`) ; montage détaillé dans `docs/transceiver-rf.md`.

### Matériel
- Cible : transceiver **sub-GHz** accordable (ex. **CC1101 868/915 MHz**, ~3-5 €, SPI depuis ESP32/Pico)
  **ou** un module **identique au TRU-246** récupéré sur un tapis de spare (émulation 1:1). RTL-SDR
  (~25 €) utile pour la recon de bande/modulation.
- ⚠️ **Bloquant avant achat ferme** : identifier l'**IC RF** + la **bande/modulation** réelles des
  modules **TRU-246** (tapis) et **TRH-?16** (récepteur). Pas de commande à l'aveugle.

### À faire (prochaine session)
- [ ] Relever réfs **TRU-246 / TRH-?16** → IC RF + **bande** + **modulation** (GFSK/ASK ?).
- [ ] Choisir/commander le transceiver (CC1101 ou module identique au tapis) + MCU hôte.
- [ ] **Recon RF** : capturer un vrai tapis (1 flèche / 1 tapis à la fois) → ID + bitmask + checksum.
- [ ] **Émettre** une trame forgée → validée si elle s'affiche dans le jeu (récepteur d'origine intact).
- [ ] **Reader** PC : sortie `{tapis, flèche, appui}` + pont WebSocket vers le moteur.
- [ ] Vérifier en fin de séance que vrais tapis + récepteur d'origine **rejouent au jeu de base**.

---

<!-- Nouvelles entrées au-dessus de cette ligne. Indiquer la machine. -->
