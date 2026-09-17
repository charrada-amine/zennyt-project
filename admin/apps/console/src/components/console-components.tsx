import { Link } from "@tanstack/react-router";
import {
  AlertTriangle,
  ArrowLeft,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronsUpDown,
  FlaskConical,
  type LucideIcon,
  PackageOpen,
  RefreshCw,
  X,
} from "lucide-react";
import type { ReactNode } from "react";

import type { Page, SortState } from "@/lib/collections";
import { formatNumber, initials } from "@/lib/format";

/** Variantes de pastille, mappées sur les classes de index.css. */
export type Tone = "success" | "warn" | "danger" | "neutral" | "info" | "accent";

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

export function Pill({ tone, children }: { tone: Tone; children: ReactNode }) {
  return <span className={`pill ${tone === "success" ? "" : tone}`}>{children}</span>;
}

export function Stat({
  label,
  value,
  detail,
  icon: Icon,
  trend,
}: {
  label: string;
  value: string;
  detail: string;
  icon: LucideIcon;
  trend?: { direction: "up" | "down"; label: string };
}) {
  return (
    <div className="stat">
      <div className="stat-top">
        <span>{label}</span>
        <span className="stat-icon">
          <Icon />
        </span>
      </div>
      <strong>{value}</strong>
      <small>
        {trend && <span className={`stat-trend ${trend.direction}`}>{trend.label} </span>}
        {detail}
      </small>
    </div>
  );
}

export function UserCell({
  name,
  secondary,
  userId,
}: {
  name: string;
  secondary: string;
  /** Rend la cellule cliquable vers la fiche utilisateur. */
  userId?: string;
}) {
  const body = (
    <div className="cell-user">
      <span className="avatar">{initials(name)}</span>
      <div>
        <strong>{name}</strong>
        <small>{secondary}</small>
      </div>
    </div>
  );
  return userId ? (
    <Link to="/users/$userId" params={{ userId }} className="row-link">
      {body}
    </Link>
  ) : (
    body
  );
}

/* ── Tableau de données ───────────────────────────────────────────────── */

export interface Column<T> {
  key: string;
  label: string;
  sortable?: boolean;
  align?: "right";
  render: (row: T) => ReactNode;
}

export function DataTable<T>({
  columns,
  page,
  sort,
  onSort,
  rowKey,
  goToPage,
  emptyTitle,
  emptyDescription,
}: {
  columns: Array<Column<T>>;
  page: Page<T>;
  sort: SortState | null;
  onSort: (key: string) => void;
  rowKey: (row: T) => string;
  goToPage: (page: number) => void;
  emptyTitle: string;
  emptyDescription: string;
}) {
  if (page.total === 0) {
    return (
      <div className="panel panel-pad">
        <EmptyState title={emptyTitle} description={emptyDescription} />
      </div>
    );
  }
  return (
    <div className="panel">
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column.key} style={column.align === "right" ? textRight : undefined}>
                  {column.sortable ? (
                    <button
                      type="button"
                      className={`sort-button ${sort?.key === column.key ? "sorted" : ""}`}
                      onClick={() => onSort(column.key)}
                      aria-label={`Trier par ${column.label}`}
                    >
                      {column.label}
                      {sort?.key !== column.key ? (
                        <ChevronsUpDown />
                      ) : sort.direction === "asc" ? (
                        <ChevronUp />
                      ) : (
                        <ChevronDown />
                      )}
                    </button>
                  ) : (
                    column.label
                  )}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {page.rows.map((row) => (
              <tr key={rowKey(row)}>
                {columns.map((column) => (
                  <td key={column.key} style={column.align === "right" ? textRight : undefined}>
                    {column.render(row)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination page={page} goToPage={goToPage} />
    </div>
  );
}

const textRight = { textAlign: "right" } as const;

export function Pagination({
  page,
  goToPage,
}: {
  page: Page<unknown>;
  goToPage: (page: number) => void;
}) {
  return (
    <div className="pagination">
      <span>
        {formatNumber(page.from)}–{formatNumber(page.to)} sur {formatNumber(page.total)}
      </span>
      <div className="pagination-controls">
        <button type="button" disabled={page.page <= 1} onClick={() => goToPage(page.page - 1)}>
          <ChevronLeft size={14} /> Précédent
        </button>
        <span>
          Page {page.page} / {page.pageCount}
        </span>
        <button
          type="button"
          disabled={page.page >= page.pageCount}
          onClick={() => goToPage(page.page + 1)}
        >
          Suivant <ChevronRight size={14} />
        </button>
      </div>
    </div>
  );
}

/* ── Filtres ──────────────────────────────────────────────────────────── */

export function SelectFilter<T extends string>({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: T | "all";
  options: ReadonlyArray<{ value: T; label: string }>;
  onChange: (value: T | "all") => void;
}) {
  return (
    <span className="filter-group">
      <label htmlFor={`filter-${label}`}>{label}</label>
      <select
        id={`filter-${label}`}
        className="field compact"
        value={value}
        onChange={(event) => onChange(event.target.value as T | "all")}
      >
        <option value="all">Tous</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </span>
  );
}

export function Segmented<T extends string>({
  options,
  value,
  onChange,
  label,
}: {
  options: ReadonlyArray<{ value: T; label: string }>;
  value: T;
  onChange: (value: T) => void;
  label: string;
}) {
  return (
    <div className="segmented" role="group" aria-label={label}>
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          aria-pressed={value === option.value}
          onClick={() => onChange(option.value)}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}

/* ── États ────────────────────────────────────────────────────────────── */

export function LoadingState() {
  return (
    <div className="loading-layout" aria-label="Chargement des données" aria-busy="true">
      <div className="skeleton skeleton-title" />
      <div className="skeleton-grid">
        {[0, 1, 2].map((index) => (
          <div className="skeleton-card" key={index}>
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

/**
 * Rappel permanent : les actions de cette console n'appellent aucun backend.
 * À supprimer en même temps que les fixtures.
 */
export function DemoNotice({ children }: { children: ReactNode }) {
  return (
    <div className="demo-notice">
      <FlaskConical />
      <div>
        <strong>Mode démonstration</strong>
        {children}
      </div>
    </div>
  );
}

export function BackLink({ to, children }: { to: "/users" | "/moderation"; children: ReactNode }) {
  return (
    <Link to={to} className="back-link">
      <ArrowLeft />
      {children}
    </Link>
  );
}

export function Drawer({
  title,
  subtitle,
  onClose,
  children,
  actions,
}: {
  title: string;
  subtitle?: string;
  onClose: () => void;
  children: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <div
      className="drawer-backdrop"
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
      role="presentation"
    >
      <aside className="drawer" role="dialog" aria-modal="true" aria-label={title}>
        <div className="drawer-head">
          <div>
            <h2>{title}</h2>
            {subtitle && <p style={{ color: "var(--muted)", fontSize: 13 }}>{subtitle}</p>}
          </div>
          <button className="icon-button" type="button" onClick={onClose} aria-label="Fermer">
            <X />
          </button>
        </div>
        {children}
        {actions && <div className="drawer-actions">{actions}</div>}
      </aside>
    </div>
  );
}

export function DefinitionList({ entries }: { entries: Array<[string, ReactNode]> }) {
  return (
    <dl className="definition-list">
      {entries.map(([term, value]) => (
        <div key={term}>
          <dt>{term}</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
  );
}
