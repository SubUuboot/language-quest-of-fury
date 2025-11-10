# 🎮 Brief de Transmission – Super Language Quest of Fury (v2.2 Coordination)

## 🎮 Contexte général
**Projet :** *Super Language Quest of Fury*  
**Moteur :** Godot Engine 4.5 (GDScript)  
**Type :** jeu narratif et éducatif, multilingue  
**Premier arc :** *Version Russian*  
**Objectif :** enseigner une langue par immersion narrative et manipulation physique.  

Le joueur apprend en pratiquant : les mécaniques (pilotage, interaction, dialogues) sont des métaphores d’apprentissage linguistique.  
Chaque séquence scénarisée combine apprentissage moteur, contexte narratif et langage naturel.

---

## 🧪 Structure technique actuelle

### Points d’entrée
| Élément | Rôle | Statut |
|----------|------|--------|
| **GameBootstrap.tscn** | Point d’entrée du jeu. Charge les systèmes principaux et bascule vers `game.tscn`. | 🟢 Stable |
| **StageManager.gd** | Gère le chargement des stages, transitions et signaux de progression. | 🟢 Stable |
| **TankController2D.gd** | Système moteur : accélération, embrayage, vitesses, direction. | 🟡 Fonctionnel, à équilibrer |
| **DevTools.tscn** | Interface de debug (affiche F1). Visible mais non interactive. | 🔵 Partiel |

---

### Autoloads actifs
| Script | Fonction | Notes |
|---------|-----------|-------|
| **InputBootstrap.gd** | Vérifie et répare les actions d’entrée. Gestion du binding clavier/manette. | 🟢 Fonctionnel |
| **DialogueSystem.gd** | 💬 Charge les dialogues localisés (JSON). Émet signaux `onDialogueStart` / `onDialogueComplete`. | 🟡 Fonctionnel |
| **MotherAI.gd** | Fabrique les parcours, gère certains événements spéciaux, supervise la progression, ajuste la difficulté (deux balances : gameplay et apprentissage linguistique). | 🔵 En extension |

---

### Systèmes secondaires
- **GameBootstrap** précharge :  
  \`\`\`gdscript
  const GAME_SCENE: PackedScene = preload("res://game.tscn")
  const DEVTOOLS_SCENE: PackedScene = preload("res://Scenes/DevTools.tscn")
  const TANK_CONTROLLER_SCRIPT: Script = preload("res://Scripts/TankController2D.gd")
  \`\`\`
  puis initialise l’ordre : `Input → DevTools → Stage → Tank`.

- **StageManager** : gère les transitions Hangar → Terrain → Mission.  
- **DevTools** : à transformer en interface interactive avec onglets et sliders.  

---

## 🧪 État fonctionnel

| Catégorie | Fonctionnalité | Statut | Commentaire |
|------------|----------------|--------|--------------|
| Initialisation | Chargement séquentiel (bootstrap, autoloads, scène) | 🟢 Stable | Aucun crash connu |
| Input | Réparation automatique, assignation, signaux | 🟢 Fonctionnel | Pavé numérique et touches spéciales encore inactives |
| Stage 0 | Assignation, dialogues, triggers | 🟡 Partiellement stable | Triggers à rendre opérationnels |
| Stage 1 | Terrain procédural, apprentissage | 🟡 Prototype | Nécessite paramétrage dynamique |
| DevTools | HUD visible mais non interactif | 🔵 À compléter | Interface à développer |
| DialogueSystem | Synchronisation par signaux | 🟡 Prototype | À développer |

---

## 🧩 Stages et gameplay

### Stage 0 – Hangar
- Assignation manuelle des touches (accélérer, embrayer, tourner, etc.)  
- Tank bridé physiquement pendant la séquence (contrôles actifs, frein externe actif).  
- Dialogue avec *Commander* et *Technicians* via `DialogueSystem`.  
- `BenchTrigger` permet de relancer la séquence.  
- Transition : `on_assignment_complete → Stage1`.

### Stage 1 – Terrain d’entraînement (procédural)
- Génération dynamique du terrain (obstacles, rampes, segments aléatoires) par `MotherAI`.  
- Instructions données par *Instructor*.  
- Application des mécaniques apprises au Stage 0.  
- Supervision de la progression par `MotherAI`.  
- Transition : `on_training_complete → Stage2` ou `on_reset → Stage0`.

### Stage 2 à 8 (Final) (et intermédiaires à venir)
- Stages narratifs de l’arc Russian (non implémentés).  
- Objectifs contextualisés et dialogues immersifs.  
- Transition de clôture : `end_of_arc → SplashScreen`.

---

## 🧪 Priorités pour la reprise

| Priorité | Description | Type |
|-----------|--------------|------|
| **1. DevTools** | Rendre l’interface interactive : sliders, boutons, onglets. | Développement |
| **2. Input spéciaux** | Activer `Ctrl`, `Enter`, touches du pavé numérique. | Correctif |
| **3. Stage 0** | Finaliser la séquence d’assignation + liaison dialogues. | Finition |
| **4. Stage 1** | Améliorer génération procédurale et logique de test. | Développement |
| **5. Documentation** | Décrire les signaux inter-systèmes (`StageManager`, `MotherAI`). | Rédaction |

---

## 🧰 Conventions et environnement

| Élément | Règle |
|----------|-------|
| **Indentation** | Tabulations uniquement (strict sous Godot 4.5) |
| **Typage** | Explicite sur toutes les variables locales |
| **Ternaires** | Interdits (`a if cond else b` uniquement) |
| **Branche active** | `refacto` |
| **Dépôt GitHub** | 📂 [github.com/SubUuboot/language-quest-of-fury](https://github.com/SubUuboot/language-quest-of-fury) |

---

## 📘 Référence documentaire

| Fichier | Description | Statut |
|----------|--------------|--------|
| `Documentation/StageFlow.md` | Flux global du jeu (diagramme + légende). | 🟢 Terminé |
| `Documentation/StageFlow.puml` | Diagramme PlantUML correspondant. | 🟢 Terminé |
| `Documentation/init.txt` | Notes de démarrage et init des autoloads. | 🟡 À relire |
| `Documentation/GameBootstrap_Plan.md` | Ordre d’initialisation, plan d’exécution. | 🟡 À compléter |

---

## 🧾 Glossaire interne

| Terme | Rôle | Description |
|--------|------|--------------|
| **Commander** | Personnage guide | Supervise l’assignation au Stage 0. |
| **Technicians** | PNJ secondaires | Fournissent le cadre du hangar et des instructions. |
| **Instructor** | Personnage mentor | Intervient au Stage 1 pour l’apprentissage pratique. |
| **MotherAI** | Système narratif global | Supervise la progression et la logique adaptative. |

---

## 🧾 Note finale

Ce document remplace le *Brief v2* et constitue la **référence unique de coordination**.  
Toutes les futures itérations (Codex inclus) devront s’appuyer sur cette structure.  
Les modifications majeures du code ou des stages doivent entraîner la mise à jour du présent fichier.

---

> *SLQOF v2.2 – fondations consolidées, prêtes à reprendre le développement actif sans dépendance extérieure.*
