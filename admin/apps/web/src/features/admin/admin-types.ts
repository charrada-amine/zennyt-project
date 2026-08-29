export type Page = "dashboard" | "questions" | "banks" | "settings" | "modifiers" | "assets" | "releases";
export type Status = "PUBLISHED" | "DRAFT" | "ARCHIVED";
export type ContentType = "DECISION_SCENARIO" | "EMOTIONAL_RADAR_SCENE";
export type ConfigurationKind = "SETTINGS" | "MODIFIERS";

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
  assets: ManagedAsset[];
  audit: AuditEntry[];
}

export type EditorState =
  | { kind: "question"; value?: Question }
  | { kind: "bank"; value?: Bank }
  | { kind: "bank-items"; value: Bank }
  | { kind: "configuration"; configurationKind: ConfigurationKind; value?: Configuration }
  | { kind: "asset"; value?: ManagedAsset };

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

export const gamePresentation = (type: ContentType) =>
  type === "DECISION_SCENARIO"
    ? { label: "Je Décide", image: "je-decide.png" }
    : { label: "Emotional Radar", image: "emotional-radar.png" };

export const formatDate = (value: string) =>
  new Intl.DateTimeFormat("fr-FR", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
