# Architecture cible — arbre de décision

But : lire les tapis depuis **notre** moteur de jeu (Godot 4 / web / Python), sans rester prisonnier
du logiciel iDANCE2 propriétaire. On garde l'infra sans-fil d'origine (RF, appairage, batteries,
multi-tapis) **intacte et réversible** tant que possible.

## Plan A — Le récepteur expose du HID standard
- Brancher le récepteur sur un PC → Gestionnaire de périphériques + `joy.cpl` / gamepad tester.
- Si manette / clavier **HID** standard → lecture directe dans Godot/web/Python. **Cas idéal** mais
  **peu probable** sur du proprio.

## Plan B — Sniffer le lien récepteur → PC (recommandé au départ)
1. Identifier le récepteur (VID:PID). Trois familles :
   - **Port COM** (USB-série) → PySerial / moniteur série.
   - **Manette / HID** → hidapi / node-hid / gamepad tester.
   - **USB générique** → USBPcap + Wireshark (Windows) ou usbmon (Linux).
2. Capturer en marchant **une flèche à la fois, un tapis à la fois** → diff des octets : header,
   ID tapis, bitmask boutons, checksum, keep-alive.
3. Écrire un lecteur (Python pyserial/hidapi ou Node serialport/node-hid) qui émet `{tapis, flèche, appui}`.
4. Bridge vers le jeu : serveur **WebSocket** local → client Godot/web (ou lecture directe si jeu Python).

> ⚠️ **Affiné par les mesures PC-Win (2026-06-17)** : le récepteur est bien un **port COM** (FTDI,
> COM5), mais en **écoute passive** il ne sort **que sa balise** `42 CE 4E` — **jamais** les boutons.
> Le récepteur n'émet les appuis **qu'après un handshake** envoyé par le logiciel de la borne. Donc
> le sniff **passif** du lien récepteur→PC est **insuffisant seul**. Deux issues :
> - **Sniff matériel** du dialogue **borne↔récepteur** (FTDI / analyseur logique sur les fils UART
>   pendant que le jeu tourne, 250000 8N1) → récupérer le handshake + les trames de boutons, puis les
>   rejouer. *(= prochaine étape déjà actée, voir `docs/protocol.md` et `docs/journal.md`.)*
> - Sinon bascule **Plan C**.
>
> 🚫 **MAJ 2026-06-19** : la capture logicielle (USBPcap) sur la borne est **écartée** (bureau Windows
> inatteignable), et on **ne poursuit plus** le sniff/replay du handshake en priorité — le **Plan D
> (transceiver RF)** ci-dessous **contourne le handshake** (on émet en amont du récepteur). Détail
> `docs/transceiver-rf.md` et `docs/journal.md`.

## Plan C — Retrofit (fallback ; on est libres de bricoler)
- Repiquer les **4 contacts** de chaque tapis vers notre microcontrôleur :
  - **filaire** : Raspberry Pi **Pico** (~4 €) flashé en **HID gamepad** → chaque tapis = manette USB native.
  - **sans fil** : un **ESP32** par tapis (BLE gamepad ou ESP-NOW vers un hub).
- ➕ Contrôle total latence/mapping. ➖ Ouvrir les tapis, refaire alim/appairage pour > 4 unités.
- À garder si le protocole est **chiffré/illisible** ou la **latence RF** d'origine trop élevée pour
  du jeu de rythme.

## Plan D — Transceiver RF, émuler un tapis (retenu 2026-06-19)
- On se met **côté radio** avec notre propre transceiver **sub-GHz** (même bande que le récepteur
  d'origine **TRH-?16 ~916 MHz**) : **recevoir** les trames d'un vrai tapis (ID + 4 flèches) **et
  émettre** des trames forgées que le **récepteur d'origine accepte** comme venant d'un tapis.
- ➕ **Contourne le handshake** borne↔récepteur (on injecte en amont du récepteur ; c'est la borne qui
  le réveille normalement). ➕ Récepteur + borne **intacts** → **jeu de base jouable en parallèle**,
  rien à débrancher ni souder. ➕ La réception RF directe sert aussi le but final (lire les tapis dans
  notre moteur).
- ➖ Demande d'**identifier d'abord l'IC RF + la bande/modulation** (TRU-246 / TRH-?16) avant de
  pouvoir accorder le transceiver et forger une trame valide.
- Montage, matériel et procédure : **`docs/transceiver-rf.md`**.

## Reverse engineering du jeu — note
- Décompiler le jeu = **mauvais chemin** : son code montre comment **lui** affiche/score les flèches,
  rien sur les données **récepteur→PC** (le vrai besoin) → privilégier le **sniff** (Plan B / matériel).
- Si fouille quand même (sans décompiler d'abord) : dossier d'install → configs (INI/XML/JSON), logs,
  charts de chansons, DLL. Runtime **.NET** (gros .dll/.exe managés) → dnSpy / ILSpy ; **natif** C/C++
  → Ghidra (gros chantier, faible ROI ici).
- Garde-fous : travailler sur une **copie**, sur le laptop, **jamais** sur le PC iDANCE2 (seule
  référence qui marche). Logiciel sous licence agence → **interop interne OK**, pas de redistribution
  (en UE, l'interopérabilité bénéficie d'une exception légale spécifique).
