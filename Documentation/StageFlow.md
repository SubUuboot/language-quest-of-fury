# 🧭 StageFlow – Super Language Quest of Fury  
**Version :** 1.0  
**Auteur :** Kot  
**Dernière mise à jour :** 2025-11-09  
**Projet :** Super Language Quest of Fury  
**Moteur :** Godot 4.5 (GDScript)  
**Branche active :** `refacto`  
**Fichier associé :** `StageFlow.puml`

---

## 🎮 Description générale

Ce document présente le **flux narratif et technique global** du jeu *Super Language Quest of Fury*.  
Il illustre les transitions entre les différents stages (scènes principales), la coordination via les autoloads,  
et la logique de signaux inter-systèmes (DialogueSystem, MotherAI, InputBootstrap, StageManager).  

Ce schéma constitue la **référence canonique** pour toute modification de la structure de progression du jeu.

---

## 🧩 Diagramme de flux global

> Le diagramme ci-dessous est généré à partir du fichier `StageFlow.puml`.  
> Il est compatible avec PlantUML v1.2024.7 et supérieur.

```plantuml
@startuml
' =======================
' Super Language Quest of Fury – Flux global (version 100% compatible)
' =======================

skinparam componentStyle rectangle
skinparam rectangle {
	BackgroundColor #2e3a52
	FontColor white
	RoundCorner 8
}
skinparam arrowThickness 1.2
skinparam arrowColor #aaaaaa

' --- Stages principaux ---
rectangle "SplashScreen\n(Point d'entrée / boot minimal)" as SplashScreen
rectangle "StartMenu\n(Sélection langue / mode)" as StartMenu
rectangle "Level0 – Hangar\n(Assignation / Commander / Technicians)" as Level0
rectangle "Level1 – TrainingGround\n(Procédural / Instructor / Progression)" as Level1
rectangle "Level2 – Mission\n(Objectifs narratifs / Clôture d'arc)" as Level2

' --- Systèmes globaux ---
rectangle "InputBootstrap\nVérifie / répare les actions\nÉmet signaux d'input" as InputBootstrap #3d3d3d
rectangle "DialogueSystem\nCharge dialogues JSON\nSynchronise scènes & triggers" as DialogueSystem #3d3d3d
rectangle "MotherAI\nSupervise logique narrative\nSuit progression du joueur" as MotherAI #3d3d3d
rectangle "StageManager\nCoordonne transitions\nÉmet signaux d’étape" as StageManager #3d3d3d

' --- Flux principal du jeu ---
SplashScreen --> StartMenu : on_boot_complete
StartMenu --> Level0 : on_game_start
Level0 --> Level1 : on_assignment_complete
Level1 --> Level2 : on_training_complete
Level1 --> Level0 : on_reset
Level2 --> SplashScreen : end_of_arc (boucle)

' --- Connexions transversales ---
SplashScreen ..> StageManager : initialise()
StageManager ..> Level0 : load(stage)
StageManager ..> Level1 : load(stage)
StageManager ..> Level2 : load(stage)

Level0 ..> InputBootstrap : binding / assignation
Level1 ..> InputBootstrap : test inputs
Level0 ..> DialogueSystem : dialogues d’instruction
Level1 ..> MotherAI : progression / feedback
Level2 ..> MotherAI : arc closure

MotherAI ..> DialogueSystem : activeDialogue()
DialogueSystem ..> MotherAI : onDialogueComplete()
InputBootstrap ..> StageManager : on_assignment_complete()

@enduml

🗺️ Légende du flux global
🎮 Stages principaux

Les rectangles bleu foncé représentent les phases de jeu jouables.
Chaque stage correspond à une scène Godot indépendante, chargée par le StageManager.
Stage	Rôle principal	Script associé	Signal clé
SplashScreen	Point d’entrée – initialise les autoloads et la config minimale.	GameBootstrap.gd	on_boot_complete
StartMenu	Sélection de langue et du mode de jeu.	StartMenu.gd	on_game_start
Level0 – Hangar	Assignation manuelle des contrôles.	Stage0_Manager.gd	on_assignment_complete
Level1 – TrainingGround	Mise en pratique et suivi de progression.	Stage1_Manager.gd	on_training_complete, on_reset
Level2 – Mission	Objectifs narratifs, clôture de l’arc.	Stage2_Manager.gd	end_of_arc
⚙️ Systèmes globaux (autoloads)

Les rectangles gris représentent les systèmes persistants (autoloads).
Ils existent indépendamment des scènes chargées et assurent la cohérence du jeu.
Système	Rôle	Événements émis ou reçus
InputBootstrap	Répare ou crée les actions d’entrée manquantes ; diffuse les signaux d’input.	on_assignment_complete, on_input_detected
DialogueSystem	Charge les dialogues localisés (JSON) ; gère les événements et transitions de texte.	onDialogueComplete, onDialogueStart
MotherAI	Supervise la narration, adapte les dialogues et la difficulté.	activeDialogue(), onProgressUpdate()
StageManager	Orchestre le chargement/déchargement des stages ; centralise les transitions.	load(stage), onStageComplete
🔗 Types de liens dans le diagramme
Style de flèche	Signification	Exemple
→ (solide)	Transition directe d’un stage à un autre.	Level0 → Level1 : on_assignment_complete
..> (pointillée)	Interaction transversale entre scène et autoload (écoute, signal, ou dépendance).	Level0 ..> InputBootstrap
Boucle vers SplashScreen	Fin d’un arc narratif (retour menu / reboot).	Level2 → SplashScreen : end_of_arc
📘 Logique générale

    Le joueur commence toujours par SplashScreen, qui initialise les autoloads.

    Les transitions entre stages sont pilotées par signaux (jamais par appels directs).

    MotherAI reste active en permanence et ajuste la narration à la progression du joueur.

    DialogueSystem est invoqué par MotherAI ou par des triggers de scène.

    InputBootstrap agit comme une “couche nerveuse” globale : si une touche disparaît, il la recrée avant que le joueur ne s’en rende compte.

🧾 Conventions d’édition

    Toute modification des stages ou des signaux doit être répercutée ici.

    Les fichiers .puml associés doivent rester textuels et versionnés.

    Les exports (.svg, .png) peuvent être stockés dans Documentation/Diagrams/ mais ne sont pas obligatoires.

    Ce document fait autorité sur la structure de progression du jeu : toute refactorisation doit s’y référer.

    Document validé pour intégration dans la branche refacto — à ne pas modifier sans mise à jour du diagramme associé.


---
