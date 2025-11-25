6. Stage0_Hangar

[Stage0_Hangar] (Node2D)
│
├── Environment (WorldEnvironment)
│   ├── Bench (StaticBody2D) → CollisionShape2D / Sprite2D
│   └── Hangar (Node2D)
│       ├── Concrete (Area2D)
│       ├── Hangar (Area2D) → BuildingB01, RigidBody2D
│       └── HangarDoor (Node2D) → Sprite2D, AnimationPlayer
│
├── Characters (Node)
│   ├── MotherAI_Physical (Node2D)
│   ├── Commander (Node2D) → DialoguesPlayer, AudioStreamPlayer, CommandTimer
│   └── Technicians (Node2D) → DialoguesPlayer, AudioStreamPlayer
│
├── Logic (Node2D)
│   ├── Stage0_Manager (Node)
│   ├── InputAssignmentScene (Node)
│   │   ├── UI (CanvasLayer)
│   │   │   ├── InstructionLabel(Label) /!\ Le nom d'accessibilité ne doit pas être vide ou contenir seulement des espaces. /!\
│   │   │   ├── KeyPromptLabel(Label) /!\ Le nom d'accessibilité ne doit pas être vide ou contenir seulement des espaces. /!\
│   │   │   ├── FeedbackLabel(Label) /!\ Le nom d'accessibilité ne doit pas être vide ou contenir seulement des espaces. /!\
│   │   │   └── ProgressBar(ProgressBar) /!\ Le nom d'accessibilité ne doit pas être vide ou contenir seulement des espaces. /!\
│   │   └── InputAssigner (Node) (InputAssigner.gd)
│   │       ├── ConfigFileHandler(Node)
│   │       ├── DialogueSync(Node)
│   │       └── StateMachine(Node)
│   └── FirstInstructionsScene (Node)
│
└── TransitionTriggers (Node)
    ├── DoorTrigger (Area2D)
    │   └── CollisionShape2D (CollisionShape2D)
    └── BenchTrigger (Area2D)
        └── CollisionShape2D (CollisionShape2D)
