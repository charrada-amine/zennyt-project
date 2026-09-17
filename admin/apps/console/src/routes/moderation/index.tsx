import { createFileRoute } from "@tanstack/react-router";

import { ModerationPage } from "@/features/moderation/moderation-page";

export const Route = createFileRoute("/moderation/")({ component: ModerationPage });
