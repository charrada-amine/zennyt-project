import { createFileRoute } from "@tanstack/react-router";

import { ReferralsPage } from "@/features/referrals/referrals-page";

export const Route = createFileRoute("/referrals")({ component: ReferralsPage });
