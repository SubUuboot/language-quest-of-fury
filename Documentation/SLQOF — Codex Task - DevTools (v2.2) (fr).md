# 🧭 Super Language Quest of Fury — Prompt Codex : DevTools (v2.2)

## 🎯 Objet
Ce document définit le **cadre de travail destiné à Codex** pour la création et l’évolution du système **DevTools** du projet *Super Language Quest of Fury* (SLQOF).
Il sert de référence interne pour les développeurs francophones souhaitant comprendre la logique, les conventions et les objectifs du module DevTools.

---

## 🧩 Contexte technique
| Élément | Détail |
|----------|---------|
| 🎮 Moteur | **Godot Engine 4.5 (GDScript)** |
| 🧱 Branche active | `refacto` |
| 🌐 Dépôt GitHub | [github.com/SubUuboot/language-quest-of-fury](https://github.com/SubUuboot/language-quest-of-fury) |
| ⚙️ Conventions | - Indentation par **tabulations uniquement** (aucun espace)<br>- **Typage explicite** pour toutes les variables locales<br>- **Pas d’opérateur ternaire** `?` (utiliser `a if condition else b`)<br>- Respect strict du style et du nommage déjà en place dans SLQOF |

---

## 🧠 Rôle de Codex
Codex est l’outil principal de **génération de code GDScript** pour le module DevTools.
Il doit produire du code :
- complet, fonctionnel et cohérent avec le dépôt GitHub ;
- conforme à la structure du projet (Bootstrap → Input → DevTools → Stage → Tank) ;
- prêt à être intégré sans rupture avec les autoloads (`InputBootstrap`, `StageManager`, etc.).

Le travail se déroule en deux temps :
1. **Codex génère** le code et les fichiers de scène (`.gd`, `.tscn`) ;
2. **Le Chat DevTools** (humain + IA) **relit, annote et ajuste** pour documenter et stabiliser.

---

## 🎛️ Modules DevTools à implémenter
| Module | Description | Objectif |
|---------|--------------|-----------|
| **1. Interface mécanique du Tank** | Panneau interactif de sliders (couple, friction, puissance, embrayage, RPM, etc.). | Permettre le réglage en temps réel des paramètres moteur. |
| **2. Remappeur d’Inputs** | Système de réassignation des touches (clavier/manette) directement en jeu. | Modifier la configuration sans recharger la scène, en lien avec `InputBootstrap`. |
| **3. Panneaux de Debug** | Interface à onglets : Physique, Dialogue, Signaux, MotherAI, etc. | Afficher en direct les valeurs des systèmes internes. |
| **4. Couche Sandbox** | Système de sécurité isolant le mode debug du gameplay normal. | Empêcher toute interférence en dehors du mode test. |

---

## 🧰 Fichiers et dépendances de référence
- `GameBootstrap.gd` et `GameBootstrap_Plan.md`
- `StageManager.gd`
- `TankController2D.gd`
- `InputBootstrap.gd`
- `DialogueSystem.gd`
- `Documentation/StageFlow.md` et `.puml`
- `Brief_de_Transmission_v2.2.md`

---

## 🧪 Règles de développement
- Suivre l’ordre d’initialisation :
  `Bootstrap → Input → DevTools → Stage → Tank`
- Le code doit être **réversible et sans persistance** hors mode debug.
- DevTools doit pouvoir être **désactivé proprement** dans les versions de production.
- Pas de chemins absolus : utiliser `preload()` et `get_node()` avec précaution.
- Les éléments UI doivent être **instanciés dynamiquement** ou intégrés via `DevTools.tscn`.

---

## 📘 Objectif final
Créer un **sous-système DevTools modulaire, robuste et extensible**, capable de :
- régler en temps réel les paramètres physiques du tank 🛞
- remapper les contrôles à la volée ⌨️
- afficher les données internes du jeu en direct 🔍
- rester totalement désactivable dans les versions de production 🚫

---

> 🧭 *SLQOF – DevTools v2.2* :
> Codex génère, le Chat affine.
> Chaque script produit doit respecter la structure et la philosophie du projet Super Language Quest of Fury.
