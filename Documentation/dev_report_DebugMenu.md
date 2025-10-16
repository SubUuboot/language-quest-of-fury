# 🧠 CONTEXTE
<!-- Résume le but du système concerné et sa place dans le jeu -->
Le jeu démarre sur le Stage0 (hangar). Le joueur contrôle le tank à travers les inputs configurés.
Un menu de debug (DebugMenu) est prévu pour s’ouvrir/fermer avec la touche F1 et permettre des réglages dynamiques (moteur, caméra, etc.).
Le projet est organisé avec `MainScene`, `Main`, `StageManager`, `Stage0`, etc.

---

# ⚙️ SCRIPTS CONCERNÉS
- `Debug_Menu.gd`
- `TankController2D.gd`
<!-- Ajouter d’autres si besoin -->
- éventuellement `InputBootstrap.gd` (pour les entrées clavier)
- `MainScene.tscn` (liée à l’affichage du menu debug)

---

# 🚨 SYMPTÔMES ACTUELS

### ⚠️ Warnings (Godot console)

W 0:00:03:317 The signal "moved" is declared but never explicitly used.
W 0:00:03:317 The signal "action_performed" is declared but never explicitly used.
W 0:00:03:317 The local variable "drive_force" is declared but never used.
W 0:00:03:500 The local variable "tank" is shadowing an already-declared variable.
W 0:00:03:500 The parameter "tab_name" is never used in the function "register_data_source()".
W 0:00:03:500 The parameter "callback" is never used in the function "register_data_source()".


### 🧱 Problèmes fonctionnels
1. Le **DebugMenu** est visible dès le lancement du jeu, au lieu d’être caché.
2. Appuyer sur **F1** ne fait rien : le menu ne s’affiche ni ne se ferme.
3. Quand le DebugMenu est visible, il **bloque le contrôle du tank**.
4. Le **tank ne passe plus les vitesses**, et l’**embrayage ne fonctionne plus**, mais l’**accélérateur fonctionne**.

---

# 🎯 COMPORTEMENT ATTENDU

1. Le jeu se lance avec le **DebugMenu masqué**.
2. Une pression sur **F1** :
   - affiche le DebugMenu,
   - bloque les contrôles du tank,
   - montre la souris.
3. Une deuxième pression sur **F1** :
   - cache le DebugMenu,
   - rend les contrôles au tank.
4. Le tank doit :
   - pouvoir **embrayer / débrayer**,
   - **changer de vitesse**,
   - **accélérer** normalement,
   - et **répondre aux commandes de direction** (`ui_left`, `ui_right`, etc.).

---

# 🔍 COMPORTEMENT ACTUEL

- Le menu s’affiche **automatiquement au démarrage**.
- La touche **F1 n’a plus d’effet visible**.
- Quand le menu est visible, le tank est bloqué.
- Le **moteur répond** (accélération visible), mais **la transmission n’est plus fonctionnelle** (pas de vitesse).
- Aucun crash, mais le gameplay est bloqué.

---

# 🧩 AUTRES SYSTÈMES POSSIBLEMENT IMPACTÉS
<!-- Si tu ne sais pas encore, laisse cette section pour Codex -->
- `InputBootstrap.gd` (gestion du mapping clavier)
- `StateMachine` de `InputAssigner`
- signaux `input_event`, `ui_accept`, ou `gear_up / gear_down`

---

# 📁 STRUCTURE DU PROJET

<!-- Tu peux mettre soit un extrait résumé ici, soit indiquer où la trouver -->
Structure complète disponible dans le repo GitHub :
`documentation/project_structure.txt`



---

# 🧰 OBJECTIF DEMANDÉ À CODEX

> Analyser les scripts `Debug_Menu.gd` et `TankController2D.gd`,  
> identifier la cause de :
> - l’affichage intempestif du DebugMenu au lancement,
> - l’absence de réaction à F1,
> - la perte de contrôle du tank (embrayage + vitesses).  
>
> Proposer des correctifs cohérents **sans casser le système existant**  
> (TankController2D, InputBootstrap, ou DebugMenu).

---

# 🧾 NOTES SUPPLÉMENTAIRES
- Aucune erreur fatale, uniquement des warnings.
- Le jeu tourne, mais les interactions de gameplay sont partiellement bloquées.
- Fichiers exportés disponibles :
  - `scene_structure.txt`
  - `project_structure.txt`
