import { Link } from "@tanstack/react-router";
import { Ban, Clock4, Gavel, Search, ShieldAlert, ShieldCheck } from "lucide-react";
import { useMemo, useState } from "react";

import {
  type Column,
  DataTable,
  DemoNotice,
  ErrorState,
  LoadingState,
  PageHeading,
  Pill,
  SelectFilter,
  Stat,
  UserCell,
} from "@/components/console-components";
import { loadModeration } from "@/fixtures/moderation-fixtures";
import { matchesSearch } from "@/lib/collections";
import { useConsoleData } from "@/lib/data-source";
import { formatDate, formatNumber, relativeTime } from "@/lib/format";
import { useTable } from "@/lib/use-table";
import {
  CONTENT_KIND_LABELS,
  CONTENT_KIND_OPTIONS,
  REPORT_PRIORITY_LABELS,
  REPORT_REASON_LABELS,
  REPORT_REASON_OPTIONS,
  REPORT_STATUS_LABELS,
  REPORT_STATUS_OPTIONS,
  type ContentKind,
  type ReportReason,
  type ReportRow,
  type ReportStatus,
} from "./moderation-view";

export const STATUS_TONE: Record<ReportStatus, "danger" | "warn" | "success" | "neutral"> = {
  NEW: "danger",
  IN_REVIEW: "warn",
  RESOLVED: "success",
  REJECTED: "neutral",
};

const PRIORITY_ORDER = { HIGH: 0, MEDIUM: 1, LOW: 2 } as const;

export function ModerationPage() {
  const { data, loading, error, reload } = useConsoleData("moderation", loadModeration);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<ReportStatus | "all">("all");
  const [kind, setKind] = useState<ContentKind | "all">("all");
  const [reason, setReason] = useState<ReportReason | "all">("all");

  const rows = data?.rows;
  const filtered = useMemo(() => {
    if (!rows) return [];
    return rows.filter(
      (row) =>
        (status === "all" || row.status === status) &&
        (kind === "all" || row.contentKind === kind) &&
        (reason === "all" || row.reason === reason) &&
        matchesSearch([row.excerpt, row.author.name, row.author.email], search),
    );
  }, [rows, status, kind, reason, search]);

  const table = useTable(filtered, {
    sortValue,
    initialSort: { key: "priority", direction: "asc" },
  });

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  return (
    <>
      <PageHeading
        eyebrow="Confiance et sécurité"
        title="Modération"
        description="La file des contenus signalés, par priorité, et les sanctions en cours."
      />

      <DemoNotice>
        File de démonstration. Les types de contenu correspondent à ce que le module engagement
        manipule réellement&nbsp;; les motifs de signalement et les sanctions sont des hypothèses
        d'écran, à confronter au contrat.
      </DemoNotice>

      <div className="stats">
        <Stat
          label="Signalements ouverts"
          value={formatNumber(data.stats.open)}
          detail="jamais examinés"
          icon={ShieldAlert}
        />
        <Stat
          label="En cours d'examen"
          value={formatNumber(data.stats.inReview)}
          detail="pris en charge"
          icon={Gavel}
        />
        <Stat
          label="Résolus (7 j)"
          value={formatNumber(data.stats.resolved7d)}
          detail="décision rendue"
          icon={ShieldCheck}
        />
        <Stat
          label="Sanctions actives"
          value={formatNumber(data.stats.activeSanctions)}
          detail="suspensions en cours"
          icon={Ban}
        />
        <Stat
          label="Délai médian"
          value={`${data.stats.medianResolutionHours} h`}
          detail="signalement → décision"
          icon={Clock4}
        />
      </div>

      <div className="toolbar">
        <div className="toolbar-fields">
          <label style={{ position: "relative", display: "inline-flex" }}>
            <Search
              size={16}
              style={{
                position: "absolute",
                left: 14,
                top: "50%",
                transform: "translateY(-50%)",
                color: "var(--muted)",
              }}
            />
            <input
              className="search"
              style={{ paddingLeft: 38 }}
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Contenu, auteur…"
              aria-label="Rechercher un signalement"
            />
          </label>
        </div>
        <div className="toolbar-fields">
          <SelectFilter
            label="Statut"
            value={status}
            options={REPORT_STATUS_OPTIONS}
            onChange={setStatus}
          />
          <SelectFilter
            label="Type"
            value={kind}
            options={CONTENT_KIND_OPTIONS}
            onChange={setKind}
          />
          <SelectFilter
            label="Motif"
            value={reason}
            options={REPORT_REASON_OPTIONS}
            onChange={setReason}
          />
        </div>
      </div>

      <DataTable
        columns={COLUMNS}
        page={table.page}
        sort={table.sort}
        onSort={table.onSort}
        goToPage={table.goToPage}
        rowKey={(row) => row.id}
        emptyTitle="File vide"
        emptyDescription="Aucun signalement ne correspond à ces filtres."
      />

      <section className="panel" style={{ marginTop: 18 }}>
        <div className="panel-pad section-head">
          <div>
            <h2>Sanctions actives</h2>
            <p>Avertissements et suspensions en cours.</p>
          </div>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Utilisateur</th>
                <th>Sanction</th>
                <th>Motif</th>
                <th>Prononcée</th>
                <th>Jusqu'au</th>
              </tr>
            </thead>
            <tbody>
              {data.sanctions.map((sanction) => (
                <tr key={sanction.id}>
                  <td>
                    <UserCell
                      name={sanction.user.name}
                      secondary={sanction.user.email}
                      userId={sanction.user.id}
                    />
                  </td>
                  <td>
                    <Pill tone={sanction.kind === "SUSPENSION" ? "danger" : "warn"}>
                      {sanction.kind === "SUSPENSION" ? "Suspension" : "Avertissement"}
                    </Pill>
                  </td>
                  <td>{sanction.reason}</td>
                  <td>{formatDate(sanction.issuedAt)}</td>
                  <td>{sanction.until ? formatDate(sanction.until) : "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}

function sortValue(row: ReportRow, key: string): unknown {
  switch (key) {
    case "content":
      return row.excerpt;
    case "author":
      return row.author.name;
    case "reason":
      return REPORT_REASON_LABELS[row.reason];
    case "reportCount":
      return row.reportCount;
    case "status":
      return REPORT_STATUS_LABELS[row.status];
    case "priority":
      return PRIORITY_ORDER[row.priority];
    case "reportedAt":
      return row.reportedAt;
    default:
      return null;
  }
}

const COLUMNS: Array<Column<ReportRow>> = [
  {
    key: "content",
    label: "Contenu",
    sortable: true,
    render: (row) => (
      <div>
        <Pill tone="neutral">{CONTENT_KIND_LABELS[row.contentKind]}</Pill>
        <Link
          to="/moderation/$reportId"
          params={{ reportId: row.id }}
          className="row-link"
          style={{ display: "block", marginTop: 6 }}
        >
          <span className="cell-excerpt">{row.excerpt}</span>
        </Link>
      </div>
    ),
  },
  {
    key: "author",
    label: "Auteur signalé",
    sortable: true,
    render: (row) => (
      <UserCell name={row.author.name} secondary={row.author.email} userId={row.author.id} />
    ),
  },
  {
    key: "reason",
    label: "Motif",
    sortable: true,
    render: (row) => REPORT_REASON_LABELS[row.reason],
  },
  {
    key: "reportCount",
    label: "Signalements",
    sortable: true,
    align: "right",
    render: (row) => <span className="numeric">{formatNumber(row.reportCount)}</span>,
  },
  {
    key: "priority",
    label: "Priorité",
    sortable: true,
    render: (row) => (
      <span>
        <i className={`priority-dot ${row.priority.toLowerCase()}`} />
        {REPORT_PRIORITY_LABELS[row.priority]}
      </span>
    ),
  },
  {
    key: "status",
    label: "Statut",
    sortable: true,
    render: (row) => <Pill tone={STATUS_TONE[row.status]}>{REPORT_STATUS_LABELS[row.status]}</Pill>,
  },
  {
    key: "reportedAt",
    label: "Signalé",
    sortable: true,
    render: (row) => relativeTime(row.reportedAt),
  },
  {
    key: "actions",
    label: "",
    align: "right",
    render: (row) => (
      <div className="row-actions">
        <Link to="/moderation/$reportId" params={{ reportId: row.id }} className="text-button">
          Examiner
        </Link>
      </div>
    ),
  },
];
