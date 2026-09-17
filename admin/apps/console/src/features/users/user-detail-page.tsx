import { Link } from "@tanstack/react-router";
import {
  Gamepad2,
  KeyRound,
  LogIn,
  MessageSquare,
  Send,
  ShieldAlert,
  Smartphone,
  UserCheck,
  UserMinus,
} from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import {
  BackLink,
  DefinitionList,
  ErrorState,
  LoadingState,
  Pill,
} from "@/components/console-components";
import { loadUserDetail } from "@/fixtures/users-fixtures";
import { useConsoleData } from "@/lib/data-source";
import { formatDate, formatDateTime, formatPercent, initials, relativeTime } from "@/lib/format";
import {
  USER_ROLE_LABELS,
  USER_STATUS_LABELS,
  type UserActivityEntry,
  type UserStatus,
} from "./users-view";

const STATUS_TONE: Record<UserStatus, "success" | "warn" | "neutral"> = {
  ACTIVE: "success",
  DEACTIVATED: "warn",
  DELETED: "neutral",
};

const ACTIVITY_ICON = {
  GAME: Gamepad2,
  POST: MessageSquare,
  APPLICATION: Send,
  MESSAGE: MessageSquare,
  AUTH: LogIn,
} satisfies Record<UserActivityEntry["kind"], typeof Gamepad2>;

export function UserDetailPage({ userId }: { userId: string }) {
  const { data, loading, error, reload } = useConsoleData(`users/${userId}`, () =>
    loadUserDetail(userId),
  );
  // Les mutations ne sont qu'optimistes tant que l'API n'existe pas.
  const [statusOverride, setStatusOverride] = useState<UserStatus | null>(null);
  const [revoked, setRevoked] = useState<string[]>([]);

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  const status = statusOverride ?? data.status;
  const sessions = data.sessions.filter((session) => !revoked.includes(session.id));

  const toggleStatus = () => {
    const next: UserStatus = status === "ACTIVE" ? "DEACTIVATED" : "ACTIVE";
    setStatusOverride(next);
    toast.success(
      next === "ACTIVE"
        ? `${data.fullName} réactivé (démonstration, non persisté)`
        : `${data.fullName} désactivé (démonstration, non persisté)`,
    );
  };

  return (
    <>
      <BackLink to="/users">Retour aux utilisateurs</BackLink>

      <div className="detail-hero">
        <span className="avatar">{initials(data.fullName)}</span>
        <div>
          <h1>{data.fullName}</h1>
          <p>{data.email}</p>
          <div className="detail-hero-tags">
            <span>{USER_ROLE_LABELS[data.role]}</span>
            <span>{USER_STATUS_LABELS[status]}</span>
            <span>Inscrit le {formatDate(data.registeredAt)}</span>
            <span>{data.emailVerified ? "E-mail vérifié" : "E-mail non vérifié"}</span>
          </div>
        </div>
      </div>

      <div className="detail-grid">
        <div style={{ display: "grid", gap: 18 }}>
          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Identité</h2>
                <p>Informations déclarées par l'utilisateur.</p>
              </div>
              <Pill tone={STATUS_TONE[status]}>{USER_STATUS_LABELS[status]}</Pill>
            </div>
            <DefinitionList
              entries={[
                ["Téléphone", data.phoneNumber ?? "—"],
                ["Ville", data.city ?? "—"],
                ["Pays", data.country ?? "—"],
                ["Adresse", data.address ?? "—"],
                ["Onboarding", data.onboardingStage],
                [
                  "Complétude du profil",
                  <div key="completion" style={{ display: "grid", gap: 6 }}>
                    <span className="numeric">{formatPercent(data.profileCompletion, 0)}</span>
                    <div className="meter">
                      <span style={{ width: `${data.profileCompletion}%` }} />
                    </div>
                  </div>,
                ],
              ]}
            />
          </section>

          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Sessions actives</h2>
                <p>Appareils connectés au compte.</p>
              </div>
            </div>
            {sessions.length === 0 ? (
              <p style={{ color: "var(--muted)", fontSize: 13, margin: 0 }}>
                Aucune session active.
              </p>
            ) : (
              <div className="chain">
                {sessions.map((session) => (
                  <div key={session.id}>
                    <span className="activity-icon">
                      <Smartphone />
                    </span>
                    <div>
                      <p style={{ margin: 0, fontWeight: 700, color: "var(--navy)", fontSize: 13 }}>
                        {session.device}
                        {session.current && (
                          <span style={{ marginLeft: 8 }}>
                            <Pill tone="info">Session courante</Pill>
                          </span>
                        )}
                      </p>
                      <small style={{ color: "var(--muted)" }}>
                        {session.location} · vue {relativeTime(session.lastSeenAt)}
                      </small>
                    </div>
                    <button
                      className="text-button danger"
                      type="button"
                      onClick={() => {
                        setRevoked((previous) => [...previous, session.id]);
                        toast.success("Session révoquée (démonstration, non persisté)");
                      }}
                    >
                      Révoquer
                    </button>
                  </div>
                ))}
              </div>
            )}
          </section>

          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Activité récente</h2>
                <p>Jeux, candidatures, publications et connexions.</p>
              </div>
            </div>
            <div className="activity">
              {data.activity.map((entry) => {
                const Icon = ACTIVITY_ICON[entry.kind];
                return (
                  <div className="activity-item" key={entry.id}>
                    <span className="activity-icon">
                      <Icon />
                    </span>
                    <div>
                      <p>{entry.label}</p>
                      <small>{formatDateTime(entry.at)}</small>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        </div>

        <div style={{ display: "grid", gap: 18 }}>
          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Parrainage</h2>
              </div>
            </div>
            <DefinitionList
              entries={[
                [
                  "Invité par",
                  data.invitedBy ? (
                    <Link
                      to="/users/$userId"
                      params={{ userId: data.invitedBy.id }}
                      className="row-link"
                    >
                      {data.invitedBy.name}
                    </Link>
                  ) : (
                    "Inscription directe"
                  ),
                ],
                ["Filleuls inscrits", String(data.invitedCount)],
                ["Code de parrainage", <code key="code">{data.referralCode}</code>],
              ]}
            />
          </section>

          <section className="panel panel-pad">
            <div className="section-head">
              <div>
                <h2>Historique de modération</h2>
              </div>
            </div>
            {data.moderation.length === 0 ? (
              <p style={{ color: "var(--muted)", fontSize: 13, margin: 0 }}>
                Aucune sanction ni avertissement.
              </p>
            ) : (
              <div className="activity">
                {data.moderation.map((entry) => (
                  <div className="activity-item" key={entry.id}>
                    <span className="activity-icon">
                      <ShieldAlert />
                    </span>
                    <div>
                      <p>{entry.action}</p>
                      <small>
                        {entry.reason} · {formatDate(entry.at)}
                      </small>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>

          <section className="danger-zone">
            <h3>Zone dangereuse</h3>
            <p>
              La désactivation coupe l'accès au compte sans supprimer ses données. En mode
              démonstration, rien n'est envoyé au backend.
            </p>
            <div style={{ display: "grid", gap: 10 }}>
              <button
                className="secondary-button"
                type="button"
                onClick={toggleStatus}
                disabled={status === "DELETED"}
              >
                {status === "ACTIVE" ? <UserMinus /> : <UserCheck />}
                {status === "ACTIVE" ? "Désactiver le compte" : "Réactiver le compte"}
              </button>
              <button
                className="secondary-button"
                type="button"
                onClick={() =>
                  toast.success("E-mail de réinitialisation envoyé (démonstration, non persisté)")
                }
              >
                <KeyRound />
                Envoyer une réinitialisation
              </button>
            </div>
          </section>
        </div>
      </div>
    </>
  );
}
