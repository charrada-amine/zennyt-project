import { Award, Coins, Gift, Hourglass, Percent, Search } from "lucide-react";
import { useMemo, useState } from "react";

import {
  type Column,
  DataTable,
  DemoNotice,
  Drawer,
  ErrorState,
  LoadingState,
  PageHeading,
  Pill,
  SelectFilter,
  Stat,
  UserCell,
} from "@/components/console-components";
import { loadReferrals } from "@/fixtures/referrals-fixtures";
import { matchesSearch } from "@/lib/collections";
import { useConsoleData } from "@/lib/data-source";
import { formatCurrency, formatDate, formatNumber, formatPercent } from "@/lib/format";
import { useTable } from "@/lib/use-table";
import {
  FILLEUL_STATUS_LABELS,
  SPONSOR_STATUS_LABELS,
  SPONSOR_STATUS_OPTIONS,
  type FilleulStatus,
  type SponsorRow,
  type SponsorStatus,
} from "./referrals-view";

const FILLEUL_TONE: Record<FilleulStatus, "success" | "info" | "neutral"> = {
  QUALIFIED: "success",
  REGISTERED: "info",
  INVITED: "neutral",
};

export function ReferralsPage() {
  const { data, loading, error, reload } = useConsoleData("referrals", loadReferrals);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<SponsorStatus | "all">("all");
  const [openSponsor, setOpenSponsor] = useState<SponsorRow | null>(null);

  const rows = data?.rows;
  const filtered = useMemo(() => {
    if (!rows) return [];
    return rows.filter(
      (row) =>
        (status === "all" || row.status === status) &&
        matchesSearch([row.name, row.email, row.code], search),
    );
  }, [rows, status, search]);

  const table = useTable(filtered, {
    sortValue,
    initialSort: { key: "qualified", direction: "desc" },
  });

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "Aucune donnée"} retry={reload} />;

  // Le rang est calculé depuis la page courante plutôt que pendant le rendu
  // des cellules : l'ordre d'appel des `render` ne doit rien décider.
  const rankById = new Map(table.page.rows.map((row, index) => [row.id, table.page.from + index]));
  const columns = buildColumns(setOpenSponsor, rankById);

  return (
    <>
      <PageHeading
        eyebrow="Croissance"
        title="Parrainage"
        description="Qui fait grandir la plateforme, combien de filleuls se qualifient, et où en sont les bonus."
      />

      <DemoNotice>
        Classement de démonstration. Le barème du programme est une règle serveur&nbsp;: la console
        l'affiche, elle ne le modifie pas.
      </DemoNotice>

      <div className="stats">
        <Stat
          label="Parrains actifs"
          value={formatNumber(data.stats.activeSponsors)}
          detail="au moins un filleul"
          icon={Gift}
        />
        <Stat
          label="Filleuls qualifiés"
          value={formatNumber(data.stats.qualifiedFilleuls)}
          detail="conditions remplies"
          icon={Award}
        />
        <Stat
          label="Bonus versés"
          value={formatCurrency(data.stats.bonusPaid)}
          detail="cumul programme"
          icon={Coins}
        />
        <Stat
          label="Bonus en attente"
          value={formatCurrency(data.stats.bonusPending)}
          detail="qualification incomplète"
          icon={Hourglass}
        />
        <Stat
          label="Conversion"
          value={formatPercent(data.stats.conversionRate)}
          detail="invités → qualifiés"
          icon={Percent}
        />
      </div>

      <div className="grid-2">
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
                  placeholder="Parrain, e-mail, code…"
                  aria-label="Rechercher un parrain"
                />
              </label>
            </div>
            <SelectFilter
              label="Statut"
              value={status}
              options={SPONSOR_STATUS_OPTIONS}
              onChange={setStatus}
            />
          </div>
          <DataTable
            columns={columns}
            page={table.page}
            sort={table.sort}
            onSort={table.onSort}
            goToPage={table.goToPage}
            rowKey={(row) => row.id}
            emptyTitle="Aucun parrain"
            emptyDescription="Aucun parrain ne correspond à ces filtres."
          />
        </div>

        <section className="panel panel-pad" style={{ alignSelf: "start" }}>
          <div className="section-head">
            <div>
              <h2>Règles du programme</h2>
              <p>Lecture seule — barème serveur.</p>
            </div>
          </div>
          <div className="rules-list">
            {data.rules.map((rule) => (
              <div key={rule.label}>
                <span>
                  {rule.label}
                  <br />
                  <small style={{ fontSize: 11 }}>{rule.detail}</small>
                </span>
                <strong>{rule.value}</strong>
              </div>
            ))}
          </div>
        </section>
      </div>

      {openSponsor && (
        <Drawer
          title={openSponsor.name}
          subtitle={`Chaîne de parrainage · code ${openSponsor.code}`}
          onClose={() => setOpenSponsor(null)}
        >
          <div className="chain">
            {openSponsor.filleuls.map((filleul) => (
              <div key={filleul.id}>
                <span className="activity-icon">
                  <Gift />
                </span>
                <div>
                  <p style={{ margin: 0, fontWeight: 700, color: "var(--navy)", fontSize: 13 }}>
                    {filleul.name}
                  </p>
                  <small style={{ color: "var(--muted)" }}>
                    {filleul.email}
                    {filleul.joinedAt ? ` · inscrit le ${formatDate(filleul.joinedAt)}` : ""}
                  </small>
                </div>
                <Pill tone={FILLEUL_TONE[filleul.status]}>
                  {FILLEUL_STATUS_LABELS[filleul.status]}
                </Pill>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 22 }}>
            <div className="rules-list">
              <div>
                <span>Bonus versés</span>
                <strong>{formatCurrency(openSponsor.bonusEarned)}</strong>
              </div>
              <div>
                <span>Bonus en attente</span>
                <strong>{formatCurrency(openSponsor.bonusPending)}</strong>
              </div>
            </div>
          </div>
        </Drawer>
      )}
    </>
  );
}

function sortValue(row: SponsorRow, key: string): unknown {
  switch (key) {
    case "sponsor":
      return row.name;
    case "invited":
      return row.invited;
    case "registered":
      return row.registered;
    case "qualified":
      return row.qualified;
    case "bonus":
      return row.bonusEarned;
    case "status":
      return SPONSOR_STATUS_LABELS[row.status];
    default:
      return null;
  }
}

function buildColumns(
  onOpen: (row: SponsorRow) => void,
  rankById: Map<string, number>,
): Array<Column<SponsorRow>> {
  return [
    {
      key: "rank",
      label: "#",
      render: (row) => {
        const rank = rankById.get(row.id) ?? 0;
        return <span className={`rank ${rank <= 3 ? "top" : ""}`}>{rank}</span>;
      },
    },
    {
      key: "sponsor",
      label: "Parrain",
      sortable: true,
      render: (row) => <UserCell name={row.name} secondary={row.email} userId={row.userId} />,
    },
    {
      key: "invited",
      label: "Invités",
      sortable: true,
      align: "right",
      render: (row) => <span className="numeric">{formatNumber(row.invited)}</span>,
    },
    {
      key: "registered",
      label: "Inscrits",
      sortable: true,
      align: "right",
      render: (row) => <span className="numeric">{formatNumber(row.registered)}</span>,
    },
    {
      key: "qualified",
      label: "Qualifiés",
      sortable: true,
      align: "right",
      render: (row) => <span className="numeric">{formatNumber(row.qualified)}</span>,
    },
    {
      key: "bonus",
      label: "Bonus",
      sortable: true,
      align: "right",
      render: (row) => (
        <div>
          <span className="numeric" style={{ color: "var(--navy)", fontWeight: 750 }}>
            {formatCurrency(row.bonusEarned)}
          </span>
          {row.bonusPending > 0 && (
            <small style={{ display: "block", color: "var(--muted)" }}>
              +{formatCurrency(row.bonusPending)} en attente
            </small>
          )}
        </div>
      ),
    },
    {
      key: "status",
      label: "Statut",
      sortable: true,
      render: (row) => (
        <Pill tone={row.status === "ACTIVE" ? "success" : "warn"}>
          {SPONSOR_STATUS_LABELS[row.status]}
        </Pill>
      ),
    },
    {
      key: "actions",
      label: "",
      align: "right",
      render: (row) => (
        <div className="row-actions">
          <button className="text-button" type="button" onClick={() => onOpen(row)}>
            Chaîne
          </button>
        </div>
      ),
    },
  ];
}
