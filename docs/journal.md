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
- Test boutons : appui **maintenu** sur bouton 1 (haut/arrière) → trame **identique** au repos.
  → hypothèse : boutons = **événements à l'appui**, pas un état permanent. **À CONFIRMER**.
- Mise en place du repo de suivi `tapis-rf` (Git + GitHub CLI installés sur PC-Win).

### À faire
- [ ] Capture live pendant appuis sur les 4 boutons → trouver le code de chaque bouton.
- [ ] Nommer/positionner les boutons 2, 3, 4.
- [ ] Script de lecture exploitable par les apps (sortie : bouton pressé).

---

<!-- Nouvelles entrées au-dessus de cette ligne. Indiquer la machine. -->
