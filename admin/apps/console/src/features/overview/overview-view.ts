/** Types de vue de la Vue d'ensemble. Voir l'avertissement de users-view.ts. */

import type { ReportRow } from "@/features/moderation/moderation-view";
import type { UserRow } from "@/features/users/users-view";

export interface OverviewKpis {
  activeUsers: number;
  activeUsersTrend: number;
  signups7d: number;
  signups7dTrend: number;
  pendingInvites: number;
  openReports: number;
  referralConversion: number;
}

export interface OverviewData {
  kpis: OverviewKpis;
  trendLabels: string[];
  trendPoints: number[];
  recentReports: ReportRow[];
  recentUsers: UserRow[];
}
