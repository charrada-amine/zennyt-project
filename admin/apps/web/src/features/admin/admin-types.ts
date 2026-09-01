export type Page =
  | "dashboard"
  | "game"
  | "questions"
  | "banks"
  | "settings"
  | "modifiers"
  | "assets"
  | "releases";
export type Status = "PUBLISHED" | "DRAFT" | "ARCHIVED";
export type ContentType = "DECISION_SCENARIO" | "EMOTIONAL_RADAR_SCENE";
export type ConfigurationKind = "SETTINGS" | "MODIFIERS";
export type ConfigurationValueType = "BOOLEAN" | "INTEGER" | "ENUM";

export type GameId =
  | "move-fast"
  | "je-continue"
  | "je-coordonne"
  | "memory-quest-digits"
  | "memory-quest-images"
  | "je-place"
  | "je-decide"
  | "optimal-path"
  | "task-scheduling"
  | "predictive-puzzle"
  | "emotional-radar"
  | "reflective-pause"
  | "strategic-choices";

export interface GameAdminDefinition {
  id: GameId;
  label: string;
  subtitle: string;
  description: string;
  asset: string;
  gameType?: (typeof GAME_TYPES)[number];
  contentType?: ContentType;
  duration: string;
  status: "LIVE" | "PREVIEW";
}

export interface GameCategoryDefinition {
  id: string;
  label: string;
  asset: string;
  duration: string;
  games: readonly GameAdminDefinition[];
}

export interface Overview {
  questionCount: number;
  publishedBankCount: number;
  draftCount: number;
  assetCount: number;
}

export interface Question {
  id: string;
  externalCode: string;
  contentType: ContentType;
  prompt: string;
  payload: Record<string, unknown>;
  bankName: string | null;
  sourceId: string | null;
  managed: boolean;
  status: Status;
  updatedAt: string;
}

export interface Bank {
  id: string;
  code: string;
  name: string;
  contentType: ContentType;
  itemCount: number;
  rotationWeight: number;
  version: number;
  status: Status;
  updatedAt: string;
}

export interface Configuration {
  id: string;
  gameType: string;
  kind: ConfigurationKind;
  version: number;
  values: Record<string, unknown>;
  protectedScoring: boolean;
  status: Status;
  updatedAt: string;
}

export interface ConfigurationField {
  key: string;
  label: string;
  description: string;
  valueType: ConfigurationValueType;
  required: boolean;
  defaultValue: boolean | number | string;
  minimum: number | null;
  maximum: number | null;
  options: string[];
}

export interface ConfigurationSchema {
  gameType: (typeof GAME_TYPES)[number];
  kind: ConfigurationKind;
  fields: ConfigurationField[];
}

export interface ManagedAsset {
  id: string;
  gameType: string;
  filename: string;
  mediaType: "PNG" | "SVG";
  url: string;
  altText: string;
  status: Status;
  createdAt: string;
}

export interface AuditEntry {
  id: string;
  action: string;
  entityType: string;
  entityId: string;
  actorId: string;
  details: Record<string, unknown>;
  createdAt: string;
}

export interface AdminData {
  overview: Overview;
  questions: Question[];
  banks: Bank[];
  configurations: Configuration[];
  configurationSchemas: ConfigurationSchema[];
  assets: ManagedAsset[];
  audit: AuditEntry[];
}

export type EditorState =
  | { kind: "question"; value?: Question; contentType?: ContentType }
  | { kind: "bank"; value?: Bank; contentType?: ContentType }
  | { kind: "bank-items"; value: Bank }
  | {
      kind: "configuration";
      configurationKind: ConfigurationKind;
      value?: Configuration;
      source?: Configuration;
      gameType?: string;
    }
  | { kind: "asset"; value?: ManagedAsset; gameType?: string };

export const GAME_TYPES = [
  "PLANIFIK",
  "MOVE_FAST",
  "MEMORY_QUEST",
  "DECISION",
  "EMOTIONAL_REGULATION",
  "CONTINUOUS_ATTENTION",
  "VISUOMOTOR_COORDINATION",
  "VISUOSPATIAL_MEMORY",
] as const;

export const GAME_CATEGORIES: readonly GameCategoryDefinition[] = [
  {
    id: "cognitive-flexibility",
    label: "Cognitive Flexibility",
    asset: "category-cognitive-flexibility.png",
    duration: "2–25 min",
    games: [
      {
        id: "move-fast",
        label: "Move Fast",
        subtitle: "Rule switching · Je bouge",
        description: "Flexibilité cognitive et alternance rapide entre deux règles.",
        asset: "move-fast.png",
        gameType: "MOVE_FAST",
        duration: "2 min",
        status: "LIVE",
      },
      {
        id: "je-continue",
        label: "Je continue",
        subtitle: "Sustained attention",
        description: "Attention soutenue X/AX sur le protocole Long Rosvold.",
        asset: "je-continue.png",
        gameType: "CONTINUOUS_ATTENTION",
        duration: "25 min",
        status: "LIVE",
      },
      {
        id: "je-coordonne",
        label: "Je coordonne",
        subtitle: "Eye–hand tracking",
        description: "Coordination visuo-motrice sur une trajectoire carrée continue.",
        asset: "je-coordonne.png",
        gameType: "VISUOMOTOR_COORDINATION",
        duration: "3 min",
        status: "LIVE",
      },
    ],
  },
  {
    id: "working-memory",
    label: "Working Memory",
    asset: "category-working-memory.png",
    duration: "5–13 min",
    games: [
      {
        id: "memory-quest-digits",
        label: "Memory Quest · Digits",
        subtitle: "Digit span · J’investigue",
        description: "Empan de chiffres, rappel direct puis inverse.",
        asset: "memory-quest.png",
        gameType: "MEMORY_QUEST",
        duration: "5–13 min",
        status: "LIVE",
      },
      {
        id: "memory-quest-images",
        label: "Memory Quest · Images",
        subtitle: "Object span · J’investigue",
        description: "Mémorisation et restauration d’objets après manipulation.",
        asset: "memory-quest.png",
        gameType: "MEMORY_QUEST",
        duration: "5–13 min",
        status: "LIVE",
      },
      {
        id: "je-place",
        label: "Je place",
        subtitle: "Object-location memory",
        description: "Mémoire visuo-spatiale et liaison objet–emplacement.",
        asset: "je-place.png",
        gameType: "VISUOSPATIAL_MEMORY",
        duration: "5 min",
        status: "LIVE",
      },
    ],
  },
  {
    id: "decision-making",
    label: "Decision-Making",
    asset: "category-decision-making.png",
    duration: "10–13 min",
    games: [
      {
        id: "je-decide",
        label: "Je Décide",
        subtitle: "Everyday choices · decision style",
        description: "Scénarios II, ER, DT, CS et RE administrés par banque.",
        asset: "je-decide.png",
        gameType: "DECISION",
        contentType: "DECISION_SCENARIO",
        duration: "10–13 min",
        status: "LIVE",
      },
    ],
  },
  {
    id: "executive-planning",
    label: "Executive Planning",
    asset: "category-executive-planning.png",
    duration: "10–13 min",
    games: [
      {
        id: "optimal-path",
        label: "Optimal Path",
        subtitle: "Path Mind · shortest route",
        description: "Planification spatiale d’un chemin optimal multi-niveaux.",
        asset: "optimal-path.png",
        gameType: "PLANIFIK",
        duration: "4 min",
        status: "LIVE",
      },
      {
        id: "task-scheduling",
        label: "Task Scheduling",
        subtitle: "Dependencies & deadlines",
        description: "Ordonnancement de tâches, contraintes et réajustements.",
        asset: "task-scheduling.png",
        gameType: "PLANIFIK",
        duration: "4 min",
        status: "LIVE",
      },
      {
        id: "predictive-puzzle",
        label: "Predictive Puzzle",
        subtitle: "Tower of Hanoi · foresight",
        description: "Planification prévisionnelle d’une séquence complète.",
        asset: "predictive-puzzle.png",
        gameType: "PLANIFIK",
        duration: "4 min",
        status: "LIVE",
      },
    ],
  },
  {
    id: "emotional-regulation",
    label: "Emotional Regulation",
    asset: "category-emotional-regulation.png",
    duration: "5–10 min",
    games: [
      {
        id: "emotional-radar",
        label: "Emotional Radar",
        subtitle: "Recognize emotions in real situations",
        description: "Scènes, nuances, intensité et médias administrés par banque.",
        asset: "emotional-radar.png",
        gameType: "EMOTIONAL_REGULATION",
        contentType: "EMOTIONAL_RADAR_SCENE",
        duration: "5 min",
        status: "LIVE",
      },
      {
        id: "reflective-pause",
        label: "Reflective Pause",
        subtitle: "Impulse control · pressure moments",
        description: "Pause contrôlée et prise de recul sous pression.",
        asset: "reflective-pause.png",
        gameType: "EMOTIONAL_REGULATION",
        duration: "5 min",
        status: "LIVE",
      },
      {
        id: "strategic-choices",
        label: "Strategic Choices",
        subtitle: "Reflect · choose · respond",
        description: "Preview mobile non scorée, sans runtime backend administrable.",
        asset: "strategic-choices.png",
        duration: "Preview",
        status: "PREVIEW",
      },
    ],
  },
] as const;

export const gameById = (id: GameId | null) =>
  id === null
    ? null
    : (GAME_CATEGORIES.flatMap((category) => category.games).find((game) => game.id === id) ??
      null);

export const gamePresentation = (type: ContentType) =>
  type === "DECISION_SCENARIO"
    ? { label: "Je Décide", image: "je-decide.png" }
    : { label: "Emotional Radar", image: "emotional-radar.png" };

export const formatDate = (value: string) =>
  new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeStyle: "short" }).format(
    new Date(value),
  );
