/** ⚠️ PROVISOIRE — voir l'avertissement de demo-people.ts. */

import type { OverviewData } from "@/features/overview/overview-view";
import { dayLabels, series } from "@/fixtures/demo-people";
import { INVITE_ROWS } from "@/fixtures/invites-fixtures";
import { REPORT_ROWS } from "@/fixtures/moderation-fixtures";
import { SPONSOR_ROWS } from "@/fixtures/referrals-fixtures";
import { USER_ROWS } from "@/fixtures/users-fixtures";
import { demo } from "@/lib/data-source";

const TREND_DAYS = 30;

export function loadOverview(): Promise<OverviewData> {
  const totalInvited = SPONSOR_ROWS.reduce((sum, row) => sum + row.invited, 0);
  const totalQualified = SPONSOR_ROWS.reduce((sum, row) => sum + row.qualified, 0);

  return demo({
    kpis: {
      activeUsers: USER_ROWS.filter((row) => row.status === "ACTIVE").length * 137,
      activeUsersTrend: 8.2,
      signups7d: 412,
      signups7dTrend: 12.4,
      pendingInvites: INVITE_ROWS.filter((row) => row.status === "PENDING").length,
      openReports: REPORT_ROWS.filter((row) => row.status === "NEW").length,
      referralConversion: (totalQualified / Math.max(totalInvited, 1)) * 100,
    },
    trendLabels: dayLabels(TREND_DAYS),
    trendPoints: series(TREND_DAYS, 46, 22, 5),
    recentReports: [...REPORT_ROWS]
      .sort((left, right) => right.reportedAt.localeCompare(left.reportedAt))
      .slice(0, 5),
    recentUsers: [...USER_ROWS]
      .sort((left, right) => right.registeredAt.localeCompare(left.registeredAt))
      .slice(0, 5),
  });
}
