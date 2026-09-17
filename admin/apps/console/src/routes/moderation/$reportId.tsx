import { createFileRoute } from "@tanstack/react-router";

import { ReportDetailPage } from "@/features/moderation/report-detail-page";

export const Route = createFileRoute("/moderation/$reportId")({
  component: ReportDetailRoute,
});

function ReportDetailRoute() {
  const { reportId } = Route.useParams();
  return <ReportDetailPage reportId={reportId} />;
}
