import { AlertOctagon, Ban, EyeOff, MessageSquareWarning, ThumbsDown } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import {
  BackLink,
  DefinitionList,
  ErrorState,
  LoadingState,
  Pill,
  UserCell,
} from "@/components/console-components";
import { loadReportDetail } from "@/fixtures/moderation-fixtures";
import { useConsoleData } from "@/lib/data-source";
import { formatDate, formatDateTime, formatNumber, relativeTime } from "@/lib/format";
import { STATUS_TONE } from "./moderation-page";
import {
  CONTENT_KIND_LABELS,
  REPORT_PRIORITY_LABELS,
  REPORT_REASON_LABELS,
  REPORT_STATUS_LABELS,
  type ReportStatus,
} from "./moderation-view";

const ACTIONS = [
  { id: "hide", label: "Masquer le contenu", icon: EyeOff, danger: false },
  { id: "warn", label: "Avertir l'auteur", icon: MessageSquareWarning, danger: false },
  { id: "suspend", label: "Suspendre l'auteur", icon: Ban, danger: true },
  { id: "reject", label: "Rejeter le signalement", icon: ThumbsDown, danger: false },
] as const;

export function ReportDetailPage({ reportId }: { reportId: string }) {
  const { data, loading, error, reload } = useConsoleData(`moderation/${reportId}`, () =>
    loadReportDetail(reportId),
  );
  const [note, setNote] = useState("");
  const [decided, setDecided] = useState<ReportStatus | null>(null);

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  const status = decided ?? data.status;

  const apply = (label: string, next: ReportStatus) => {
    if (!note.trim()) {
      toast.error("Une note de décision est obligatoire.");
      return;
    }
    setDecided(next);
    toast.success(`${label} — décision enregistrée (démonstration, non persisté)`);
  };

  return (
    <>
      <BackLink to="/moderation">Retour à la file de modération</BackLink>

      <div className="page-heading">
        <div>
          <p className="eyebrow">{CONTENT_KIND_LABELS[data.contentKind]}</p>
          <h1>{REPORT_REASON_LABELS[data.reason]}</h1>
          <p>
            {formatNumber(data.reportCount)} signalement
            {data.reportCount > 1 ? "s" : ""} · {relativeTime(data.reportedAt)} ·{" "}
            <i className={`priority-dot ${data.priority.toLowerCase()}`} />
            priorité {REPORT_PRIORITY_LABELS[data.priority].toLowerCase()}
          </p>
        </div>
        <Pill tone={STATUS_TONE[status]}>{REPORT_STATUS_LABELS[status]}</Pill>
      </div>

      <div className="detail-grid">
        <div style={{ display: "grid", gap: 18 }}>
          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Contenu signalé</h2>
                <p>{data.context}</p>
              </div>
            </div>
            <div className="reported-content">
              <header>
                <span className="avatar" style={{ width: 28, height: 28, borderRadius: 9 }}>
                  {data.author.name.slice(0, 1)}
                </span>
                {data.author.name} · {formatDateTime(data.reportedAt)}
              </header>
              {data.content}
            </div>
          </section>

          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Décision</h2>
                <p>La note est obligatoire et sera jointe à l'historique de l'auteur.</p>
              </div>
            </div>
            <label style={{ display: "grid", gap: 8, fontSize: 12, fontWeight: 750 }}>
              Note de décision
              <textarea
                className="field"
                style={{ minHeight: 96, paddingBlock: 12 }}
                value={note}
                onChange={(event) => setNote(event.target.value)}
                placeholder="Ce qui a été constaté, et pourquoi cette décision."
              />
            </label>
            <div className="action-bar">
              {ACTIONS.map(({ id, label, icon: Icon, danger }) => (
                <button
                  key={id}
                  type="button"
                  className={danger ? "primary-button" : "secondary-button"}
                  onClick={() => apply(label, id === "reject" ? "REJECTED" : "RESOLVED")}
                  disabled={status === "RESOLVED" || status === "REJECTED"}
                >
                  <Icon />
                  {label}
                </button>
              ))}
            </div>
            {(status === "RESOLVED" || status === "REJECTED") && (
              <p style={{ marginTop: 14, color: "var(--muted)", fontSize: 12 }}>
                Ce signalement est clos pour cette session de démonstration.
              </p>
            )}
          </section>

          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Signalé par</h2>
                <p>{formatNumber(data.reporters.length)} témoignages joints.</p>
              </div>
            </div>
            <div className="reporter-list">
              {data.reporters.map((reporter) => (
                <div key={reporter.id}>
                  <span className="activity-icon">
                    <AlertOctagon />
                  </span>
                  <div>
                    <p style={{ margin: 0, fontWeight: 700, color: "var(--navy)", fontSize: 13 }}>
                      {reporter.name}
                    </p>
                    <small style={{ color: "var(--muted)" }}>
                      {REPORT_REASON_LABELS[reporter.reason]} · {relativeTime(reporter.at)}
                    </small>
                    <p style={{ margin: "6px 0 0", fontSize: 12, color: "#36415e" }}>
                      {reporter.note}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>

        <div style={{ display: "grid", gap: 18 }}>
          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Auteur</h2>
              </div>
            </div>
            <UserCell
              name={data.author.name}
              secondary={data.author.email}
              userId={data.author.id}
            />
            <div style={{ marginTop: 16 }}>
              <DefinitionList
                entries={[
                  ["Membre depuis", formatDate(data.authorHistory.memberSince)],
                  ["Signalements passés", String(data.authorHistory.previousReports)],
                  ["Sanctions passées", String(data.authorHistory.previousSanctions)],
                ]}
              />
            </div>
          </section>

          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Contexte</h2>
              </div>
            </div>
            <DefinitionList
              entries={[
                ["Type de contenu", CONTENT_KIND_LABELS[data.contentKind]],
                ["Emplacement", data.context],
                ["Motif principal", REPORT_REASON_LABELS[data.reason]],
                ["Priorité", REPORT_PRIORITY_LABELS[data.priority]],
              ]}
            />
          </section>
        </div>
      </div>
    </>
  );
}
