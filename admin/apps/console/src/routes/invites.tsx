import { createFileRoute } from "@tanstack/react-router";

import { InvitesPage } from "@/features/invites/invites-page";

export const Route = createFileRoute("/invites")({ component: InvitesPage });
