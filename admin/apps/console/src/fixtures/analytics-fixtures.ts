/** ⚠️ PROVISOIRE — voir l'avertissement de demo-people.ts. */

import { SERIES_COLORS } from "@/components/console-charts";
import {
  type AnalyticsData,
  type AnalyticsPeriod,
  PERIOD_DAYS,
} from "@/features/analytics/analytics-view";
import { dayLabels, series } from "@/fixtures/demo-people";
import { demo } from "@/lib/data-source";

const CITIES = [
  { label: "Paris", value: 1840 },
  { label: "Lyon", value: 1120 },
  { label: "Marseille", value: 870 },
  { label: "Casablanca", value: 640 },
  { label: "Bruxelles", value: 515 },
  { label: "Dakar", value: 402 },
  { label: "Tunis", value: 361 },
];

const GAMES = [
  { label: "Emotional Radar", value: 4210 },
  { label: "Memory Quest", value: 3675 },
  { label: "Je décide", value: 2980 },
  { label: "Move Fast", value: 2314 },
  { label: "Optimal Path", value: 1702 },
];

export function loadAnalytics(period: AnalyticsPeriod): Promise<AnalyticsData> {
  const days = PERIOD_DAYS[period];
  // Moins de points sur 90 jours : une valeur par pas de 3 jours reste lisible.
  const step = days > 30 ? 3 : 1;
  const count = Math.round(days / step);
  const labels = dayLabels(days).filter((_, index) => index % step === 0);

  const candidates = series(count, 42 * step, 18 * step, 7);
  const students = series(count, 21 * step, 11 * step, 13);
  const recruiters = series(count, 9 * step, 6 * step, 29);
  const signups = candidates.map(
    (value, index) => value + (students[index] ?? 0) + (recruiters[index] ?? 0),
  );
  const total = signups.reduce((sum, value) => sum + value, 0);

  const funnelStart = Math.round(total * 1.18);

  return demo({
    kpis: {
      signups: total,
      signupsTrend: 12.4,
      activeUsers: Math.round(total * 2.6),
      activeUsersTrend: -3.1,
      onboardingCompletion: 61.8,
      gameSessions: GAMES.reduce((sum, game) => sum + game.value, 0),
    },
    labels,
    signupsByRole: [
      { label: "Candidats", color: SERIES_COLORS[0], points: candidates },
      { label: "Étudiants", color: SERIES_COLORS[1], points: students },
      { label: "Recruteurs", color: SERIES_COLORS[2], points: recruiters },
    ],
    activity: [
      {
        label: "Actifs / jour",
        color: SERIES_COLORS[0],
        points: series(count, 320 * step, 90 * step, 3),
      },
      {
        label: "Actifs / semaine",
        color: SERIES_COLORS[3],
        points: series(count, 910 * step, 140 * step, 17),
      },
    ],
    onboardingFunnel: [
      { label: "Compte créé", value: funnelStart },
      { label: "E-mail vérifié", value: Math.round(funnelStart * 0.83) },
      { label: "Onboarding terminé", value: Math.round(funnelStart * 0.62) },
      { label: "Profil complet", value: Math.round(funnelStart * 0.44) },
      { label: "Première action", value: Math.round(funnelStart * 0.31) },
    ],
    topCities: CITIES,
    gameEngagement: GAMES,
  });
}
