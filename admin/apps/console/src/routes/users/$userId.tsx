import { createFileRoute } from "@tanstack/react-router";

import { UserDetailPage } from "@/features/users/user-detail-page";

export const Route = createFileRoute("/users/$userId")({
  component: UserDetailRoute,
});

function UserDetailRoute() {
  const { userId } = Route.useParams();
  return <UserDetailPage userId={userId} />;
}
