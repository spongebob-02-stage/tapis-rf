# Check-list de relevé RF — terrain (iDANCE2)

Objectif unique : pouvoir **identifier l'IC RF + la bande + la modulation** des deux modules radio, pour
choisir/accorder notre transceiver (voir `../docs/transceiver-rf.md`, **étape 0 bloquante**).

> Le **marquage de la puce RF** est le plus important ; le reste (quartz, SAW, antenne, brochage) sert
> à **recouper** la bande et le type de modulation.

Déposer les **photos** à côté de ce fichier (dans `captorisation/`) et reporter les marquages ci-dessous.

## 0. Avant de commencer
- [ ] Travailler sur un **tapis de spare** + le récepteur — **jamais** en cassant la chaîne de référence qui marche.
- [ ] **Éteint / débranché** avant d'ouvrir et de sonder.
- [ ] Bonne **lumière diffuse**, chiffon pour la poussière, noter le tapis testé (n° / DIP).

## 1. Module ÉMETTEUR — le tapis (« TRU-246 »)
- [ ] Photo macro du **marquage complet** du module doré (toute la sérigraphie, pas juste « TRU-246 »).
- [ ] **Puce RF principale** : photo macro du **top-marking** (réf + logo fabricant). ⬅️ *le plus important*
- [ ] **Quartz/résonateur près du module RF** : fréquence gravée (≠ le `FS8.000P` 8 MHz déjà connu, qui est sûrement l'horloge du MCU).
- [ ] **Filtre SAW** éventuel (petit boîtier près de l'antenne) → souvent gravé `433` / `868` / `915`.
- [ ] **Antenne** : type (piste PCB / fil / hélice) + **longueur mesurée** (¼λ ≈ 17 cm@433, ≈ 8,6 cm@868-915).
- [ ] **Brochage du module** : nombre de pins + labels (VCC, GND, ANT, DATA, SCK/SPI…) → SPI vs simple OOK.
- [ ] **Tension d'alim** du module si accessible (pack = 4,8 V NiMH).
- [ ] Réf du **MCU** du tapis (bonus).

## 2. Module RÉCEPTEUR — le dongle (« TRH-?16 ~916 MHz »)
- [ ] Photo du **blindage fermé** + sérigraphie autour (zone `RF`).
- [ ] **Soulever le capot blindé SI ça vient sans forcer** → photo macro de la **puce RF** + tout quartz/SAW dessous.
  - ⚠️ S'il est soudé/récalcitrant : **ne pas forcer** (récepteur = pièce critique). Photo capot fermé.
- [ ] Réf exacte « TRH-?16 » (le `?` à confirmer) + tout autre marquage.
- [ ] Réf du **MCU** du récepteur (bonus).

## 3. DIP switches du tapis (= ID / canal)
- [ ] **Nombre** de switches + **état actuel** (ON/OFF de chacun) du tapis testé.
- [ ] Si possible : **n° affiché dans le jeu** pour ce réglage (on avait vu « tapis n°9 ») → table **DIP → ID**.

## 4. Conseils photo (le marquage laser est traître)
- [ ] **Plusieurs angles** d'éclairage par puce (le texte gravé apparaît selon l'incidence de la lumière).
- [ ] **Macro nette**, stable, cadré serré ; refaire si flou.
- [ ] **Les deux faces** de chaque PCB.
- [ ] Une photo avec **règle/pièce** pour l'échelle (surtout l'antenne).

## 5. Réversibilité (rappel)
- [ ] **Aucune soudure / aucun dessoudage.** On observe, on photographie, on remonte à l'identique.
- [ ] À la fin : **vrais tapis + récepteur d'origine rebranchés**, jeu de base testé OK.

---

## Relevés (à remplir)

| Élément | Valeur relevée | Photo |
|---|---|---|
| TRU-246 — marquage complet | | |
| TRU-246 — puce RF (top-marking) | | |
| TRU-246 — quartz/SAW près RF | | |
| TRU-246 — antenne (type + longueur) | | |
| TRU-246 — brochage (pins/labels) | | |
| TRH-?16 — réf module | | |
| TRH-?16 — puce RF (sous blindage) | | |
| MCU tapis / MCU récepteur | | |
| DIP switches (nombre + état → n° jeu) | | |

---

**→ Ce qu'on en déduit :** réf puce RF → datasheet (bande, modulation, registres) ; quartz/SAW +
longueur d'antenne → recoupe la **bande** ; brochage → SPI vs OOK ; DIP → format de l'**ID tapis**.
