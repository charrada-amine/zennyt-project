import { CheckCircle2, Clock, MailPlus, Percent, Search, Send, Slash } from "lucide-react";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import { BarList } from "@/components/console-charts";
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
import { loadInvites } from "@/fixtures/invites-fixtures";
import { matchesSearch } from "@/lib/collections";
import { useConsoleData } from "@/lib/data-source";
import { formatNumber, formatPercent, relativeTime } from "@/lib/format";
import { useTable } from "@/lib/use-table";
import {
  INVITE_CHANNEL_LABELS,
  INVITE_CHANNEL_OPTIONS,
  INVITE_STATUS_LABELS,
  INVITE_STATUS_OPTIONS,
  type InviteChannel,
  type InviteRow,
  type InviteStatus,
} from "./invites-view";

const STATUS_TONE: Record<InviteStatus, "success" | "warn" | "neutral" | "danger"> = {
  ACCEPTED: "success",
  PENDING: "warn",
  EXPIRED: "neutral",
  REVOKED: "danger",
};

export function InvitesPage() {
  const { data, loading, error, reload } = useConsoleData("invites", loadInvites);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<InviteStatus | "all">("all");
  const [channel, setChannel] = useState<InviteChannel | "all">("all");
  const [revoked, setRevoked] = useState<string[]>([]);

  const rows = data?.rows;
  const filtered = useMemo(() => {
    if (!rows) return [];
    return rows
      .map((row) => (revoked.includes(row.id) ? ({ ...row, status: "REVOKED" } as InviteRow) : row))
      .filter(
        (row) =>
          (status === "all" || row.status === status) &&
          (channel === "all" || row.channel === channel) &&
          matchesSearch([row.recipient, row.code, row.invitedBy.name], search),
      );
  }, [rows, status, channel, search, revoked]);

  const table = useTable(filtered, {
    sortValue,
    initialSort: { key: "createdAt", direction: "desc" },
  });

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  const byChannel = (Object.keys(INVITE_CHANNEL_LABELS) as InviteChannel[]).map((key) => ({
    label: INVITE_CHANNEL_LABELS[key],
    value: data.rows.filter((row) => row.channel === key).length,
  }));

  const columns = buildColumns((id) => {
    setRevoked((previous) => [...previous, id]);
    toast.success("Invitation révoquée (démonstration, non persisté)");
  });

  return (
    <>
      <PageHeading
        eyebrow="Croissance"
        title="Invitations"
        description="Suivre les invitations envoyées, relancer celles en attente, révoquer celles qui posent problème."
      />

      <DemoNotice>
        Révoquer ou renvoyer met à jour l'écran localement et affiche une notification&nbsp;: aucun
        e-mail n'est envoyé, rien n'est persisté.
      </DemoNotice>

      <div className="stats">
        <Stat
          label="Envoyées"
          value={formatNumber(data.stats.sent)}
          detail="total"
          icon={MailPlus}
        />
        <Stat
          label="Acceptées"
          value={formatNumber(data.stats.accepted)}
          detail="comptes créés"
          icon={CheckCircle2}
        />
        <Stat
          label="En attente"
          value={formatNumber(data.stats.pending)}
          detail="relance possible"
          icon={Clock}
        />
        <Stat
          label="Expirées"
          value={formatNumber(data.stats.expired)}
          detail="au-delà du délai"
          icon={Slash}
        />
        <Stat
          label="Taux d'acceptation"
          value={formatPercent(data.stats.acceptanceRate)}
          detail="envoyées → acceptées"
          icon={Percent}
        />
      </div>

      <div className="grid-2" style={{ marginBottom: 18 }}>
        <div>
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
                  placeholder="Destinataire, code, invitant…"
                  aria-label="Rechercher une invitation"
                />
              </label>
            </div>
            <div className="toolbar-fields">
              <SelectFilter
                label="Statut"
                value={status}
                options={INVITE_STATUS_OPTIONS}
                onChange={setStatus}
              />
              <SelectFilter
                label="Canal"
                value={channel}
                options={INVITE_CHANNEL_OPTIONS}
                onChange={setChannel}
              />
            </div>
          </div>
          <DataTable
            columns={columns}
            page={table.page}
            sort={table.sort}
            onSort={table.onSort}
            goToPage={table.goToPage}
            rowKey={(row) => row.id}
            emptyTitle="Aucune invitation"
            emptyDescription="Aucune invitation ne correspond à ces filtres."
          />
        </div>
        <section className="panel panel-pad" style={{ alignSelf: "start" }}>
          <div className="section-head">
            <div>
              <h2>Par canal</h2>
              <p>Répartition des envois.</p>
            </div>
          </div>
          <BarList data={byChannel} />
        </section>
      </div>
    </>
  );
}

function sortValue(row: InviteRow, key: string): unknown {
  switch (key) {
    case "recipient":
      return row.recipient;
    case "invitedBy":
      return row.invitedBy.name;
    case "channel":
      return INVITE_CHANNEL_LABELS[row.channel];
    case "status":
      return INVITE_STATUS_LABELS[row.status];
    case "createdAt":
      return row.createdAt;
    case "expiresAt":
      return row.expiresAt;
    default:
      return null;
  }
}

function buildColumns(onRevoke: (id: string) => void): Array<Column<InviteRow>> {
  return [
    {
      key: "recipient",
      label: "Destinataire",
      sortable: true,
      render: (row) => (
        <div>
          <strong style={{ display: "block", color: "var(--navy)", fontSize: 13 }}>
            {row.recipient}
          </strong>
          <small style={{ color: "var(--muted)" }}>
            <code>{row.code}</code>
          </small>
        </div>
      ),
    },
    {
      key: "invitedBy",
      label: "Invité par",
      sortable: true,
      render: (row) => (
        <UserCell
          name={row.invitedBy.name}
          secondary={row.invitedBy.email}
          userId={row.invitedBy.id}
        />
      ),
    },
    {
      key: "channel",
      label: "Canal",
      sortable: true,
      render: (row) => <Pill tone="info">{INVITE_CHANNEL_LABELS[row.channel]}</Pill>,
    },
    {
      key: "status",
      label: "Statut",
      sortable: true,
      render: (row) => (
        <Pill tone={STATUS_TONE[row.status]}>{INVITE_STATUS_LABELS[row.status]}</Pill>
      ),
    },
    {
      key: "createdAt",
      label: "Créée",
      sortable: true,
      render: (row) => relativeTime(row.createdAt),
    },
    {
      key: "expiresAt",
      label: "Expire",
      sortable: true,
      render: (row) => relativeTime(row.expiresAt),
    },
    {
      key: "actions",
      label: "",
      align: "right",
      render: (row) => (
        <div className="row-actions">
          {row.status === "PENDING" && (
            <>
              <button
                className="text-button"
                type="button"
                onClick={() => toast.success("Invitation renvoyée (démonstration, non persisté)")}
              >
                <Send size={14} />
                Renvoyer
              </button>
              <button className="text-button danger" type="button" onClick={() => onRevoke(row.id)}>
                Révoquer
              </button>
            </>
          )}
        </div>
      ),
    },
  ];
}
