import {
  AlertTriangle,
  Check,
  ChevronRight,
  FileQuestion,
  FolderKanban,
  Image,
  type LucideIcon,
  PackageOpen,
  RefreshCw,
} from "lucide-react";
import type { ReactNode } from "react";

import type { Status } from "./admin-types";

export const gameAsset = (name: string) => `/assets/games/${name}`;

export function PageHeading({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="page-heading">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {action}
    </div>
  );
}

export function StatusPill({ status }: { status: Status }) {
  const label = status === "PUBLISHED" ? "Publié" : status === "DRAFT" ? "Brouillon" : "Archivé";
  return <span className={`pill ${status.toLowerCase()}`}>{label}</span>;
}

export function Stat({
  label,
  value,
  detail,
  icon: Icon,
}: {
  label: string;
  value: number;
  detail: string;
  icon: LucideIcon;
}) {
  return (
    <div className="stat">
      <div className="stat-top">
        <span>{label}</span>
        <span className="stat-icon">
          <Icon />
        </span>
      </div>
      <strong>{new Intl.NumberFormat("fr-FR").format(value)}</strong>
      <small>{detail}</small>
    </div>
  );
}

export function LoadingState() {
  return (
    <div className="loading-layout" aria-label="Chargement des données">
      <div className="skeleton skeleton-title" />
      <div className="skeleton-grid">
        {[FileQuestion, FolderKanban, Image].map((Icon, index) => (
          <div className="skeleton-card" key={index}>
            <Icon />
            <span />
          </div>
        ))}
      </div>
      <div className="skeleton skeleton-table" />
    </div>
  );
}

export function ErrorState({ message, retry }: { message: string; retry: () => void }) {
  return (
    <div className="state-panel error-state">
      <AlertTriangle />
      <h2>Chargement interrompu</h2>
      <p>{message}</p>
      <button className="primary-button" onClick={retry} type="button">
        <RefreshCw />
        Réessayer
      </button>
    </div>
  );
}

export function EmptyState({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="empty-state">
      <PackageOpen />
      <h3>{title}</h3>
      <p>{description}</p>
      {action}
    </div>
  );
}

export function ProtectedNotice() {
  return (
    <div className="protected">
      <Check />
      <div>
        <strong>Barèmes protégés</strong>
        <span>
          Les paramètres de score restent calculés et validés par le serveur. Cette console gère
          uniquement le contenu et l'expérience.
        </span>
      </div>
    </div>
  );
}

export function GameOrbs() {
  return (
    <>
      <span className="game-orb">
        <img src={gameAsset("je-decide.png")} alt="" />
      </span>
      <span className="game-orb">
        <img src={gameAsset("emotional-radar.png")} alt="" />
      </span>
      <span className="game-orb">
        <img src={gameAsset("memory-quest.png")} alt="" />
      </span>
    </>
  );
}

export function InlineAction({
  children,
  onClick,
  danger = false,
  disabled = false,
}: {
  children: ReactNode;
  onClick: () => void;
  danger?: boolean;
  disabled?: boolean;
}) {
  return (
    <button
      className={`text-button ${danger ? "danger" : ""}`}
      disabled={disabled}
      onClick={onClick}
      type="button"
    >
      {children}
      <ChevronRight />
    </button>
  );
}
