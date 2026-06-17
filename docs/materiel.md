# Matériel — tapis de danse iDANCE2

Produit : **Positive Gaming**, gamme *Impact Dance Platform* (plateformes rigides polycarbonate
honeycomb, ~9 kg), système **iDANCE2** variante **sans-fil**. Chaîne d'origine :
tapis (émetteur RF sur batterie) → **récepteur USB** → **PC Windows** + logiciel propriétaire.

> Deux cartes radio **distinctes** : **émetteur** (dans chaque tapis, module *TRU-246*) et
> **récepteur** (dongle sur le PC, module *TRH-?16* ~916 MHz). Ne pas confondre les réfs.

## Émetteur — la carte dans le tapis

| Élément | Détail |
|---|---|
| MCU | microcontrôleur (boîtier QFP) |
| Module RF | doré **« TRU-246 »** + **antenne PCB** — fréquence exacte **non confirmée** |
| Horloge | quartz **FS8.000P** (8 MHz) |
| Config | **DIP switches** = très probablement **ID / canal** du tapis |
| Alim | pack **NiMH AA 4.8 V 1500 mAh** (4 accus), autonomie ~70 h |
| Indicateur | LED de charge tricolore (rouge / jaune / vert) |

### Appairage
- Interrupteur **on/off** sur le tapis, puis **marcher sur la flèche HAUT** pour connecter au système.
- Plusieurs systèmes cohabitent via des **fréquences différentes** → chaque tapis = un **ID radio**
  (cohérent avec les DIP switches).
- ⚠️ HAUT est la flèche **spéciale** (appairage + validation menu) : qu'elle réponde prouve seulement
  que le tapis **se connecte**, pas qu'une chanson lit les 4 pas.

## Capteurs de pas — contact sec (NO), confirmé

**Conclusion : simple fermeture de contact, PAS un capteur analogique (FSR).** Malgré le terme
marketing « pressure sensor » de Positive Gaming (aucun schéma/brochage public).

- Chaque flèche (UP / DOWN / LEFT / RIGHT) = un **interrupteur normalement ouvert** (2 fils).
- Mécanique : **deux plaques métalliques** par panneau ; marcher dessus les met en contact → circuit fermé.
- Câblage : panneaux → **PCB capteurs central** (connecteurs **JST blancs 2 broches**
  UP/DOWN/LEFT/RIGHT) → carte principale via un **câble type RJ**.

### Test de continuité (multimètre)
| Action | Mesure attendue |
|---|---|
| Repos | circuit **ouvert** (1 / pas de bip) |
| Appui | **bip** / ~0 Ω |
| Relâché | **réouverture** nette |

Accès aux broches JST : trombone / épingle / jumper Dupont enfoncé dans le connecteur, ou pointes sur
les broches mâles du header. → mécanique de détection **saine** sur le tapis testé.

## Récepteur — le dongle sur le PC

| Élément | Détail |
|---|---|
| Carte | **custom** : MCU (QFP) + module radio sub-GHz ~916 MHz **« TRH-?16 »** (blindé, type RFM) + quartz + alim/batterie |
| Sérigraphie | BUTTON, TEMP, PWR-CHRG, STATUS, BAT, RF |
| Liaison hôte | câble **FTDI TTL232R** (USB↔TTL série), header 6 broches |
| Identité USB | `VID 0403:6001`, s/n `FTES44GZ` → **COM5** (Windows) |

> Le détail du **lien série** (250000 8N1, trame 4 o, balise `42 CE 4E`) et l'état du décodage des
> boutons sont dans `docs/protocol.md`.

## Photos
- `IMG_8026`, `IMG_8027` — gros plans de la carte réceptrice (réfs MCU + module radio à relever).
