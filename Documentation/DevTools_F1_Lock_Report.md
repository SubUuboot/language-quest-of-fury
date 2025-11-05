---

# 🧠 Codex Investigation Report — DevTools & TankController Lock Issue

## 1. Objectif

Identifier pourquoi :

1. La touche **F1** ne déclenche pas le basculement (`_toggle_menu()`) du menu **DevTools**.
2. Le **TankController2D** reste bloqué (aucune direction, vitesse ou embrayage fonctionnels).

L’objectif final est de rétablir la séquence complète :

* **F1** → ouverture du DevTools + affichage souris + blocage du tank,
* **F1 à nouveau** → fermeture du DevTools + recapture du clavier + retour du contrôle du tank.

---

## 2. Périmètre technique

### Fichiers à analyser

| Type   | Fichier                                  | Rôle                                                                                |
| ------ | ---------------------------------------- | ----------------------------------------------------------------------------------- |
| Script | `res://Scripts/systems/DevTools.gd`      | Gère la capture de F1, la visibilité du menu et le signal `devtools_toggled(bool)`  |
| Script | `res://Scripts/systems/InputBootstrap.gd`| Enregistre toutes les actions clavier/manette, y compris `ui_devtools_menu` (F1)    |
| Script | `res://Scripts/TankController2D.gd`      | Comportement du tank, gestion des entrées, et réaction au signal `devtools_toggled` |
| Scène  | `res://Scenes/DevTools.tscn`             | Interface graphique du menu DevTools (propre, nettoyée, visible = false)            |
| Scène  | `res://Scenes/main/main.tscn`            | Contient le `Tank`, le `HUDLayer`, et le nœud `DevTools` (attaché à `HUDLayer`)     |

---

## 3. Contexte attendu

* **`DevTools`** doit être un `Control` (ou `CanvasLayer`) avec :

  ```gdscript
  func _ready():
      hide()
      set_process_input(true)
  ```
* Le raccourci **F1** est défini par `InputBootstrap` :

  ```gdscript
  _ensure_action("ui_devtools_menu", [KEY_F1])
  ```
* Dans `DevTools.gd` :

  ```gdscript
  func _input(event):
      if event.is_action_pressed("ui_devtools_menu"):
          _toggle_menu()
          get_viewport().set_input_as_handled()
  ```
* `DevTools._toggle_menu()` :

  * inverse `is_open`,
  * bascule `visible`,
  * émet `devtools_toggled(is_open)`,
  * ajuste le mode souris,
  * et, côté `TankController2D`,

    ```gdscript
    func _on_devtools_toggled(is_open: bool):
        set_input_enabled(not is_open)
    ```

---

## 4. Symptômes observés

| Problème                | Symptôme                                           | Commentaire                                      |
| ----------------------- | -------------------------------------------------- | ------------------------------------------------ |
| F1 inopérant            | aucune réaction ni log “🧭 DevTools toggled”       | indique que `_input()` ne reçoit pas l’événement |
| Tank bloqué             | seule la touche “Espace” (accélération) fonctionne | probablement `input_enabled` toujours `false`    |
| Pas d’erreurs critiques | console propre à part `orders_source` warning      | confirme que la scène se charge bien             |

---

## 5. Hypothèses de défaillance

1. **Collision de noms d’action :**

   * `InputBootstrap` crée `"ui_devtools_menu"`,
   * mais `DevTools.gd` écoute `"devtools_toggle"` ou `"debug_menu_toggle"`.
   * → aucune correspondance → `_input()` jamais déclenché.

2. **DevTools non en “process input” global :**

   * Le nœud racine est un `Control` avec `Focus Mode = All`,
   * mais si `set_process_input(true)` est manquant, il ne reçoit pas les entrées.

3. **Signal non connecté côté tank :**

   * `TankController2D` se connecte au signal `devtools_toggled`,
   * mais si la référence `devtools_path` est erronée, la connexion échoue silencieusement.

4. **InputMap non initialisé au moment du premier tick :**

   * Si `InputBootstrap` (autoload) s’exécute **après** le chargement de `DevTools`,
     le mapping F1 peut ne pas encore exister → aucun `event.is_action_pressed()` détecté.

---

## 6. Étapes d’analyse proposées

1. **Vérifier le nom exact de l’action**

   * Dans `Project > Input Map`, confirmer que `ui_devtools_menu` existe bien.
   * Dans `DevTools.gd`, s’assurer que le `_input` écoute *ce même nom exact*.
     Exemple :

     ```gdscript
     if event.is_action_pressed("ui_devtools_menu"):
         _toggle_menu()
     ```

2. **Ajouter un log temporaire**

   ```gdscript
   func _input(event):
       if event is InputEventKey:
           print("Input key:", event.as_text())
       if event.is_action_pressed("ui_devtools_menu"):
           print("F1 detected!")
           _toggle_menu()
   ```

   Si rien n’apparaît → problème de Focus/Input capture.

3. **Vérifier l’ordre d’exécution**

   * Dans `Project Settings > Autoload`, s’assurer que :

     1. `InputBootstrap` est **au-dessus** de `DevTools` (donc chargé avant).
     2. `DevTools` est **au-dessus** du reste (avant `MainScene` ou `StageManager`).

4. **Confirmer la connexion au tank**

   * Ajouter un log dans `_on_devtools_toggled` :

     ```gdscript
     print("Signal reçu par Tank:", is_open)
     ```

     pour vérifier si le signal circule bien.

---

## 7. Attentes post-correction

| Action                                        | Résultat attendu                                          |
| --------------------------------------------- | --------------------------------------------------------- |
| Pression sur F1                               | `🧭 DevTools toggled: true` dans la console, menu visible |
| Tank immobile pendant que DevTools est ouvert | `input_enabled = false`                                   |
| Deuxième pression sur F1                      | Menu caché, tank jouable à nouveau                        |
| F1 répété                                     | Alternance fluide sans perte de contrôle                  |

---

## 8. Suggestion à Codex

> Codex, peux-tu :
>
> * analyser la cohérence entre `InputBootstrap`, `DevTools` et `TankController2D`,
> * identifier pourquoi l’action `ui_devtools_menu` n’est pas interceptée par `DevTools.gd`,
> * vérifier que le signal `devtools_toggled` se propage bien au tank,
> * et proposer un correctif pour que le raccourci F1 verrouille/déverrouille correctement les entrées du tank ?

---
