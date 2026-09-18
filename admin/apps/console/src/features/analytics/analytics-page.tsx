import { Activity, Gamepad2, Route, TrendingUp } from "lucide-react";
import { useState } from "react";

import { BarList, Funnel, LineChart } from "@/components/console-charts";
import {
  DemoNotice,
  ErrorState,
  LoadingState,
  PageHeading,
  Segmented,
  Stat,
} from "@/components/console-components";
import { loadAnalytics } from "@/fixtures/analytics-fixtures";
import { useConsoleData } from "@/lib/data-source";
import { formatNumber, formatPercent } from "@/lib/format";
import { ANALYTICS_PERIOD_OPTIONS, type AnalyticsPeriod } from "./analytics-view";

export function AnalyticsPage() {
  const [period, setPeriod] = useState<AnalyticsPeriod>("30d");
  const { data, loading, error, reload } = useConsoleData(`analytics/${period}`, () =>
    loadAnalytics(period),
  );

  const periodPicker = (
    <Segmented
      label="Période d'analyse"
      options={ANALYTICS_PERIOD_OPTIONS}
      value={period}
      onChange={setPeriod}
    />
  );

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  return (
    <>
      <PageHeading
        eyebrow="Mesure"
        title="Analytics"
        description="Croissance, activité, onboarding et engagement sur la période choisie."
        action={periodPicker}
      />

      <DemoNotice>
        Séries générées localement de façon déterministe. Le module <code>analytics</code> du
        backend n'expose aujourd'hui aucun endpoint d'administration&nbsp;: ces graphiques seront
        alimentés dès que ce sera le cas.
      </DemoNotice>

      <div className="stats stats-4">
        <Stat
          label="Inscriptions"
          value={formatNumber(data.kpis.signups)}
          detail="sur la période"
          icon={TrendingUp}
          trend={{ direction: "up", label: `+${formatPercent(data.kpis.signupsTrend)}` }}
        />
        <Stat
          label="Utilisateurs actifs"
          value={formatNumber(data.kpis.activeUsers)}
          detail="au moins une action"
          icon={Activity}
          trend={{ direction: "down", label: formatPercent(data.kpis.activeUsersTrend) }}
        />
        <Stat
          label="Onboarding terminé"
          value={formatPercent(data.kpis.onboardingCompletion)}
          detail="des comptes créés"
          icon={Route}
        />
        <Stat
          label="Sessions de jeu"
          value={formatNumber(data.kpis.gameSessions)}
          detail="tous jeux confondus"
          icon={Gamepad2}
        />
      </div>

      <section className="panel chart-frame" style={{ marginBottom: 18 }}>
        <div className="section-head">
          <div>
            <h2>Inscriptions par rôle</h2>
            <p>Candidats, étudiants et recruteurs.</p>
          </div>
        </div>
        <LineChart
          ariaLabel="Inscriptions par rôle sur la période"
          labels={data.labels}
          series={data.signupsByRole}
        />
      </section>

      <div className="grid-even" style={{ marginBottom: 18 }}>
        <section className="panel chart-frame">
          <div className="section-head">
            <div>
              <h2>Activité</h2>
              <p>Utilisateurs actifs par jour et par semaine.</p>
            </div>
          </div>
          <LineChart
            ariaLabel="Utilisateurs actifs sur la période"
            labels={data.labels}
            series={data.activity}
          />
        </section>

        <section className="panel panel-pad">
          <div className="section-head">
            <div>
              <h2>Entonnoir d'onboarding</h2>
              <p>Du compte créé à la première action.</p>
            </div>
          </div>
          <Funnel steps={data.onboardingFunnel} />
        </section>
      </div>

      <div className="grid-even">
        <section className="panel panel-pad">
          <div className="section-head">
            <div>
              <h2>Répartition géographique</h2>
              <p>Villes les plus représentées.</p>
            </div>
          </div>
          <BarList data={data.topCities} />
        </section>

        <section className="panel panel-pad">
          <div className="section-head">
            <div>
              <h2>Engagement par jeu</h2>
              <p>Sessions terminées sur la période.</p>
            </div>
          </div>
          <BarList data={data.gameEngagement} color="var(--indigo)" />
        </section>
      </div>
    </>
  );
}
