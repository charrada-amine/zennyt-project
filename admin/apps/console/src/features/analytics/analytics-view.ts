/** Types de vue de l'espace Analytics. Voir l'avertissement de users-view.ts. */

import type { BarDatum, FunnelStep, Series } from "@/components/console-charts";

export type AnalyticsPeriod = "7d" | "30d" | "90d";

export interface AnalyticsKpis {
  signups: number;
  signupsTrend: number;
  activeUsers: number;
  activeUsersTrend: number;
  onboardingCompletion: number;
  gameSessions: number;
}

export interface AnalyticsData {
  kpis: AnalyticsKpis;
  labels: string[];
  signupsByRole: Series[];
  activity: Series[];
  onboardingFunnel: FunnelStep[];
  topCities: BarDatum[];
  gameEngagement: BarDatum[];
}

export const ANALYTICS_PERIOD_OPTIONS: ReadonlyArray<{ value: AnalyticsPeriod; label: string }> = [
  { value: "7d", label: "7 jours" },
  { value: "30d", label: "30 jours" },
  { value: "90d", label: "90 jours" },
];

export const PERIOD_DAYS: Record<AnalyticsPeriod, number> = { "7d": 7, "30d": 30, "90d": 90 };
