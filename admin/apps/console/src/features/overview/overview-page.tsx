import { Link } from "@tanstack/react-router";
import { Gift, MailPlus, ShieldAlert, TrendingUp, Users } from "lucide-react";

import { LineChart, SERIES_COLORS } from "@/components/console-charts";
import {
  DemoNotice,
  ErrorState,
  LoadingState,
  PageHeading,
  Pill,
  Stat,
  UserCell,
} from "@/components/console-components";
import {
  REPORT_REASON_LABELS,
  REPORT_STATUS_LABELS,
  type ReportStatus,
} from "@/features/moderation/moderation-view";
import { USER_ROLE_LABELS } from "@/features/users/users-view";
import { loadOverview } from "@/fixtures/overview-fixtures";
import { formatNumber, formatPercent, relativeTime } from "@/lib/format";
import { useConsoleData } from "@/lib/data-source";

const REPORT_TONE: Record<ReportStatus, "danger" | "warn" | "success" | "neutral"> = {
  NEW: "danger",
  IN_REVIEW: "warn",
  RESOLVED: "success",
  REJECTED: "neutral",
};

export function OverviewPage() {
  const { data, loading, error, reload } = useConsoleData("overview", loadOverview);

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  const { kpis } = data;

  return (
    <>
      <PageHeading
        eyebrow="Console plateforme"
        title="Vue d'ensemble"
        description="L'état de la plateforme ce matin : croissance, invitations en cours et file de modération."
      />

      <DemoNotice>
        Les chiffres proviennent de fixtures locales, pas du backend. Les endpoints d'administration{" "}
        <code>/admin/**</code> seront branchés dès la publication de leur contrat OpenAPI.
      </DemoNotice>

      <div className="stats">
        <Stat
          label="Utilisateurs actifs"
          value={formatNumber(kpis.activeUsers)}
          detail="sur 30 jours"
          icon={Users}
          trend={{ direction: "up", label: `+${formatPercent(kpis.activeUsersTrend)}` }}
        />
        <Stat
          label="Inscriptions (7 j)"
          value={formatNumber(kpis.signups7d)}
          detail="vs semaine précédente"
          icon={TrendingUp}
          trend={{ direction: "up", label: `+${formatPercent(kpis.signups7dTrend)}` }}
        />
        <Stat
          label="Invitations en attente"
          value={formatNumber(kpis.pendingInvites)}
          detail="non encore acceptées"
          icon={MailPlus}
        />
        <Stat
          label="Signalements ouverts"
          value={formatNumber(kpis.openReports)}
          detail="à traiter"
          icon={ShieldAlert}
        />
        <Stat
          label="Conversion parrainage"
          value={formatPercent(kpis.referralConversion)}
          detail="invités → qualifiés"
          icon={Gift}
        />
      </div>

      <section className="panel chart-frame" style={{ marginBottom: 18 }}>
        <div className="section-head">
          <div>
            <h2>Inscriptions — 30 derniers jours</h2>
            <p>Toutes catégories de comptes confondues.</p>
          </div>
          <Link to="/analytics" className="secondary-button">
            Analytics détaillées
          </Link>
        </div>
        <LineChart
          ariaLabel="Inscriptions quotidiennes sur les 30 derniers jours"
          labels={data.trendLabels}
          series={[{ label: "Inscriptions", color: SERIES_COLORS[0], points: data.trendPoints }]}
        />
      </section>

      <div className="grid-even">
        <section className="panel panel-pad">
          <div className="section-head">
            <div>
              <h2>Signalements récents</h2>
              <p>Les cinq derniers contenus remontés.</p>
            </div>
            <Link to="/moderation" className="text-button">
              Tout voir
            </Link>
          </div>
          <div className="activity">
            {data.recentReports.map((report) => (
              <div className="activity-item" key={report.id}>
                <span className="activity-icon">
                  <ShieldAlert />
                </span>
                <div>
                  <p>
                    <Link
                      to="/moderation/$reportId"
                      params={{ reportId: report.id }}
                      className="row-link"
                    >
                      {report.excerpt}
                    </Link>
                  </p>
                  <small>
                    {REPORT_REASON_LABELS[report.reason]} · {report.author.name} ·{" "}
                    {relativeTime(report.reportedAt)}{" "}
                  </small>
                  <div style={{ marginTop: 6 }}>
                    <Pill tone={REPORT_TONE[report.status]}>
                      {REPORT_STATUS_LABELS[report.status]}
                    </Pill>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="panel">
          <div className="panel-pad section-head">
            <div>
              <h2>Derniers inscrits</h2>
              <p>Comptes créés le plus récemment.</p>
            </div>
            <Link to="/users" className="text-button">
              Tout voir
            </Link>
          </div>
          <div className="table-wrap">
            <table style={{ minWidth: 420 }}>
              <thead>
                <tr>
                  <th>Utilisateur</th>
                  <th>Rôle</th>
                  <th>Inscrit</th>
                </tr>
              </thead>
              <tbody>
                {data.recentUsers.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <UserCell name={user.fullName} secondary={user.email} userId={user.id} />
                    </td>
                    <td>
                      <Pill tone="info">{USER_ROLE_LABELS[user.role]}</Pill>
                    </td>
                    <td>{relativeTime(user.registeredAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </>
  );
}
