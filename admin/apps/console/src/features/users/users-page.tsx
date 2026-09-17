import { BadgeCheck, Search, UserCheck, UserMinus, Users } from "lucide-react";
import { useMemo, useState } from "react";

import {
  type Column,
  DataTable,
  DemoNotice,
  ErrorState,
  LoadingState,
  PageHeading,
  Pill,
  SelectFilter,
  Stat,
  UserCell,
} from "@/components/console-components";
import { loadUsers } from "@/fixtures/users-fixtures";
import { matchesSearch } from "@/lib/collections";
import { useConsoleData } from "@/lib/data-source";
import { formatNumber, formatPercent, relativeTime } from "@/lib/format";
import { useTable } from "@/lib/use-table";
import {
  USER_ROLE_LABELS,
  USER_ROLE_OPTIONS,
  USER_STATUS_LABELS,
  USER_STATUS_OPTIONS,
  type UserRole,
  type UserRow,
  type UserStatus,
} from "./users-view";

const STATUS_TONE: Record<UserStatus, "success" | "warn" | "neutral"> = {
  ACTIVE: "success",
  DEACTIVATED: "warn",
  DELETED: "neutral",
};

type VerifiedFilter = "verified" | "unverified";

export function UsersPage() {
  const { data, loading, error, reload } = useConsoleData("users", loadUsers);
  const [search, setSearch] = useState("");
  const [role, setRole] = useState<UserRole | "all">("all");
  const [status, setStatus] = useState<UserStatus | "all">("all");
  const [verified, setVerified] = useState<VerifiedFilter | "all">("all");

  const rows = data?.rows;
  const filtered = useMemo(() => {
    if (!rows) return [];
    return rows.filter(
      (row) =>
        (role === "all" || row.role === role) &&
        (status === "all" || row.status === status) &&
        (verified === "all" || row.emailVerified === (verified === "verified")) &&
        matchesSearch([row.fullName, row.email, row.city, row.country], search),
    );
  }, [rows, role, status, verified, search]);

  const table = useTable(filtered, {
    sortValue: sortValue,
    initialSort: { key: "registeredAt", direction: "desc" },
  });

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  const active = data.rows.filter((row) => row.status === "ACTIVE").length;
  const unverified = data.rows.filter((row) => !row.emailVerified).length;
  const deactivated = data.rows.filter((row) => row.status !== "ACTIVE").length;

  return (
    <>
      <PageHeading
        eyebrow="Supervision"
        title="Utilisateurs"
        description="Rechercher un compte, suivre son état et ouvrir sa fiche complète."
      />

      <DemoNotice>
        Population de démonstration. Les filtres, le tri et la pagination fonctionnent en local ;
        ils deviendront des paramètres de requête une fois l'API branchée.
      </DemoNotice>

      <div className="stats stats-4">
        <Stat
          label="Comptes"
          value={formatNumber(data.rows.length)}
          detail="toutes catégories"
          icon={Users}
        />
        <Stat
          label="Actifs"
          value={formatNumber(active)}
          detail={`${formatPercent((active / data.rows.length) * 100, 0)} du total`}
          icon={UserCheck}
        />
        <Stat
          label="E-mail non vérifié"
          value={formatNumber(unverified)}
          detail="relance possible"
          icon={BadgeCheck}
        />
        <Stat
          label="Désactivés ou supprimés"
          value={formatNumber(deactivated)}
          detail="hors population active"
          icon={UserMinus}
        />
      </div>

      <div className="toolbar">
        <div className="toolbar-fields">
          <label style={{ position: "relative", display: "inline-flex" }}>
            <Search
              size={16}
              style={{
                position: "absolute",
                left: 14,
                top: "50%",
                transform: "translateY(-50%)",
                color: "var(--muted)",
              }}
            />
            <input
              className="search"
              style={{ paddingLeft: 38 }}
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Nom, e-mail, ville…"
              aria-label="Rechercher un utilisateur"
            />
          </label>
        </div>
        <div className="toolbar-fields">
          <SelectFilter label="Rôle" value={role} options={USER_ROLE_OPTIONS} onChange={setRole} />
          <SelectFilter
            label="Statut"
            value={status}
            options={USER_STATUS_OPTIONS}
            onChange={setStatus}
          />
          <SelectFilter
            label="E-mail"
            value={verified}
            options={[
              { value: "verified", label: "Vérifié" },
              { value: "unverified", label: "Non vérifié" },
            ]}
            onChange={setVerified}
          />
        </div>
      </div>

      <DataTable
        columns={COLUMNS}
        page={table.page}
        sort={table.sort}
        onSort={table.onSort}
        goToPage={table.goToPage}
        rowKey={(row) => row.id}
        emptyTitle="Aucun utilisateur"
        emptyDescription="Aucun compte ne correspond à cette combinaison de filtres."
      />
    </>
  );
}

function sortValue(row: UserRow, key: string): unknown {
  switch (key) {
    case "user":
      return row.fullName;
    case "role":
      return USER_ROLE_LABELS[row.role];
    case "status":
      return USER_STATUS_LABELS[row.status];
    case "location":
      return row.city ?? row.country;
    case "registeredAt":
      return row.registeredAt;
    case "lastSeenAt":
      return row.lastSeenAt;
    case "profileCompletion":
      return row.profileCompletion;
    default:
      return null;
  }
}

const COLUMNS: Array<Column<UserRow>> = [
  {
    key: "user",
    label: "Utilisateur",
    sortable: true,
    render: (row) => <UserCell name={row.fullName} secondary={row.email} userId={row.id} />,
  },
  {
    key: "role",
    label: "Rôle",
    sortable: true,
    render: (row) => <Pill tone="info">{USER_ROLE_LABELS[row.role]}</Pill>,
  },
  {
    key: "status",
    label: "Statut",
    sortable: true,
    render: (row) => <Pill tone={STATUS_TONE[row.status]}>{USER_STATUS_LABELS[row.status]}</Pill>,
  },
  {
    key: "emailVerified",
    label: "E-mail",
    render: (row) =>
      row.emailVerified ? (
        <Pill tone="success">Vérifié</Pill>
      ) : (
        <Pill tone="warn">Non vérifié</Pill>
      ),
  },
  {
    key: "location",
    label: "Localisation",
    sortable: true,
    render: (row) => [row.city, row.country].filter(Boolean).join(", ") || "—",
  },
  {
    key: "profileCompletion",
    label: "Profil",
    sortable: true,
    align: "right",
    render: (row) => <span className="numeric">{formatPercent(row.profileCompletion, 0)}</span>,
  },
  {
    key: "registeredAt",
    label: "Inscrit",
    sortable: true,
    render: (row) => relativeTime(row.registeredAt),
  },
  {
    key: "lastSeenAt",
    label: "Dernière activité",
    sortable: true,
    render: (row) => (row.lastSeenAt ? relativeTime(row.lastSeenAt) : "—"),
  },
];
