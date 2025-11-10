# 🧭 Brief de Transmission – Super Language Quest of Fury (v2 Coordination)

## 🎮 Contexte général
**Projet :** Super Language Quest of Fury  
**Moteur :** Godot 4.5 (GDScript)  
**Type :** jeu narratif et éducatif, multilingue — premier arc : *Version Russian*  
**Objectif :** enseigner les langues par l’immersion narrative et la manipulation.  
Le joueur apprend en pratiquant, au fil de situations scénarisées et d’expérimentations physiques (tank, apprentissage progressif des commandes, dialogues contextualisés).

---

## 🧱 Architecture actuelle

### ⚙️ Scène principale
`GameBootstrap.tscn` — assure un chargement séquentiel propre et affiche un écran de démarrage avant de basculer sur la scène de jeu.

### ⚙️ Autoloads principaux
- **InputBootstrap** – gère les actions et leur auto-réparation (bindings clavier/manette).
- **DialogueSystem** – charge les dialogues localisés depuis JSON.
- **MotherAI** – structure narrative et logique de scénario.

### ⚙️ Systèmes intégrés
- **DevTools** – toggle F1 fonctionnel, interface visible mais non interactive (doit être étendue).
- **TankController2D** – moteur, embrayage, vitesses, commandes directionnelles (touches alphanumériques actives).
- **StageManager** – gère le chargement/déchargement des stages et les signaux de progression.
- **GameBootstrap** – garantit l’ordre d’initialisation : Input → DevTools → Stage → Tank.

---

## 🧩 Stages et mécaniques de gameplay

### **Stage 0 – Hangar (assignation des touches)**
- Séquence d’assignation manuelle des touches : l’instructeur demande au joueur d’appuyer sur les touches pour accélérer, tourner, embrayer, etc.
- Les contrôles sont temporairement désactivés (`set_input_enabled(false)`) pendant la séquence, puis réactivés.
- Le `BenchTrigger` permet de relancer la séquence d’assignation.
- Dialogue interactif via `Commander` et `FirstInstructionsScene`.

### **Stage 1 – Terrain d’entraînement (procédural)**
- Prototype de génération procédurale du terrain : obstacles, rampes, segments dynamiques.
- Objectif : tester les mécaniques apprises au Stage 0 dans un environnement évolutif.
- Connecté au `StageManager` pour une transition fluide *Hangar → TrainingGround → Mission*.

---

## 🧠 État fonctionnel actuel
✅ Chargement séquentiel stable via `GameBootstrap`  
✅ F1 toggle opérationnel entre DevTools et TankController2D  
✅ Stage0 et Stage1 se chargent sans crash  
✅ InputBootstrap répare les actions manquantes automatiquement  

⚠️ Pavé numérique et touches spéciales (`KEY_CTRL`, `KEY_ENTER`, etc.) encore inactives  
⚠️ DevTools limité : interface visible mais non cliquable, onglets et sliders inactifs  

---

## 🧰 Conventions et environnement

- Indentation : **tabulations uniquement** (strict sous Godot 4.5)  
- Typage : explicite sur toutes les variables locales  
- Interdiction des ternaires (`a if cond else b` uniquement)  
- **Branche active :** `refacto` (la branche `main` est obsolète)  
- **Dépôt :** [github.com/SubUuboot/language-quest-of-fury](https://github.com/SubUuboot/language-quest-of-fury)  
- **Codex :** configuré avec accès au repo et dossier `Documentation/` (`init.txt`, `GameBootstrap_Plan.md`, etc.)

---

## 🧭 Priorités pour la reprise

1. Rendre **DevTools interactif** (onglets, sliders, tab switching, métriques en temps réel).  
2. Restaurer la **compatibilité des touches spéciales** (`Ctrl`, `Enter`, pavé numérique).  
3. Finaliser **Stage 0** — assignation stable, rejouable et reliée au dialogue d’instruction.  
4. Étendre **Stage 1** — améliorer la génération procédurale et les tests d’apprentissage.  
5. Documenter la logique d’initialisation et les signaux inter-systèmes (pour Codex et la maintenance future).

---

## 🧾 Note méthodologique

Les anciens logs de debug, erreurs de chargement et tests d’input ont été archivés.  
Ce document sert de base propre et stable pour la **reprise de coordination**.  
Les futures branches et tâches Codex devront s’appuyer exclusivement sur cette structure consolidée.

---

> 💡 **En bref :**  
> SLQOF dispose maintenant d’une fondation fonctionnelle (bootstrap, input, tank, stages).  
> Le travail à venir doit rendre le DevTools utile, fiabiliser les inputs complexes,  
> et approfondir le lien entre pédagogie et gameplay procédural.
