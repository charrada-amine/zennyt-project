import {
  Archive,
  ArrowLeft,
  Boxes,
  ChevronRight,
  Clock3,
  Copy,
  Edit3,
  FileQuestion,
  FolderKanban,
  Image,
  ListChecks,
  Plus,
  Rocket,
  Settings2,
  SlidersHorizontal,
  Trash2,
  Upload,
} from "lucide-react";
import { type ReactNode, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import { adminApi, authenticatedAssetUrl } from "./admin-api";
import {
  EmptyState,
  GameOrbs,
  InlineAction,
  PageHeading,
  ProtectedNotice,
  Stat,
  StatusPill,
  gameAsset,
} from "./admin-components";
import type {
  AdminData,
  AuditEntry,
  Bank,
  Configuration,
  ConfigurationKind,
  EditorState,
  GameAdminDefinition,
  GameId,
  ManagedAsset,
  Page,
  Question,
} from "./admin-types";
import { formatDate, GAME_CATEGORIES, gamePresentation } from "./admin-types";

interface PageProps {
  data: AdminData;
  navigate: (page: Page) => void;
  openEditor: (editor: EditorState) => void;
  refresh: () => Promise<void>;
  game: GameAdminDefinition | null;
  openGame: (gameId: GameId) => void;
  openGameControl: (gameId: GameId, page: Page) => void;
}

async function action(
  request: () => Promise<unknown>,
  message: string,
  refresh: () => Promise<void>,
) {
  try {
    await request();
    await refresh();
    toast.success(message);
    return true;
  } catch (error) {
    toast.error(error instanceof Error ? error.message : "Action impossible");
    return false;
  }
}

export function DashboardPage({ data, navigate, openGame }: PageProps) {
  const today = new Intl.DateTimeFormat("fr-FR", { dateStyle: "full" }).format(new Date());
  const recentBanks = data.banks.slice(0, 5);
  const publishedQuestions = data.questions.filter(
    (question) => question.status === "PUBLISHED",
  ).length;
  return (
    <>
      <PageHeading
        eyebrow={today}
        title="Bonjour, équipe Zennyt"
        description="État réel du contenu disponible et des changements en préparation."
        action={
          <button className="primary-button" onClick={() => navigate("questions")} type="button">
            <Plus />
            Créer une question
          </button>
        }
      />
      <GamesCatalog data={data} openGame={openGame} />
      <section className="hero">
        <div className="hero-copy">
          <p className="eyebrow">Publication versionnée</p>
          <h2>Contrôlez le contenu sans interrompre les parties en cours.</h2>
          <p>Chaque banque et configuration suit un cycle brouillon, publication et archivage.</p>
          <button className="secondary-button" onClick={() => navigate("banks")} type="button">
            Gérer les rotations
          </button>
        </div>
        <div className="hero-art">
          <GameOrbs />
        </div>
      </section>
      <div className="stats">
        <Stat
          label="Questions publiées"
          value={publishedQuestions}
          detail={`${data.overview.questionCount} versions visibles`}
          icon={FileQuestion}
        />
        <Stat
          label="Banques actives"
          value={data.overview.publishedBankCount}
          detail={`${data.banks.length} versions conservées`}
          icon={FolderKanban}
        />
        <Stat
          label="Brouillons"
          value={data.overview.draftCount}
          detail="À vérifier avant publication"
          icon={Boxes}
        />
        <Stat
          label="Assets administrés"
          value={data.overview.assetCount}
          detail="PNG et SVG persistés"
          icon={Image}
        />
      </div>
      <div className="grid-2">
        <section className="panel">
          <div className="panel-pad section-head">
            <div>
              <h2>Banques récentes</h2>
              <p>Versions, composition et poids de rotation.</p>
            </div>
            <button className="text-button" onClick={() => navigate("banks")} type="button">
              Tout gérer
            </button>
          </div>
          <BankTable banks={recentBanks} />
        </section>
        <RecentActivity entries={data.audit.slice(0, 6)} navigate={navigate} />
      </div>
    </>
  );
}

function GamesCatalog({ data, openGame }: { data: AdminData; openGame: (gameId: GameId) => void }) {
  return (
    <section className="games-catalog" aria-labelledby="games-catalog-title">
      <div className="section-head games-catalog-head">
        <div>
          <p className="eyebrow">Catalogue mobile</p>
          <h2 id="games-catalog-title">Choisissez un jeu à administrer</h2>
          <p>Chaque fiche ouvre directement ses contenus, réglages, modificateurs et médias.</p>
        </div>
        <span className="catalog-count">
          {GAME_CATEGORIES.flatMap((item) => item.games).length} jeux
        </span>
      </div>
      <div className="game-category-list">
        {GAME_CATEGORIES.map((category) => (
          <article className="game-category-panel" key={category.id}>
            <header className="game-category-heading">
              <div>
                <p>{category.duration}</p>
                <h3>{category.label}</h3>
                <span>
                  {category.games.length} {category.games.length > 1 ? "jeux" : "jeu"}
                </span>
              </div>
              <img src={gameAsset(category.asset)} alt={`Illustration ${category.label}`} />
            </header>
            <div className="admin-game-grid">
              {category.games.map((game) => {
                const questionCount = game.contentType
                  ? data.questions.filter((item) => item.contentType === game.contentType).length
                  : 0;
                const configurationCount = game.gameType
                  ? data.configurations.filter((item) => item.gameType === game.gameType).length
                  : 0;
                return (
                  <button
                    className="admin-game-card"
                    key={game.id}
                    onClick={() => openGame(game.id)}
                    type="button"
                  >
                    <span className="admin-game-visual">
                      <img src={gameAsset(game.asset)} alt="" />
                    </span>
                    <span className="admin-game-copy">
                      <span className="admin-game-title">
                        <strong>{game.label}</strong>
                        <ChevronRight />
                      </span>
                      <small>{game.subtitle}</small>
                      <span className="admin-game-meta">
                        {game.status === "PREVIEW" ? (
                          <span className="preview-label">Preview mobile</span>
                        ) : game.contentType ? (
                          <>{questionCount} versions de contenu</>
                        ) : (
                          <>{configurationCount} configurations</>
                        )}
                      </span>
                    </span>
                  </button>
                );
              })}
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

export function GamePage({
  data,
  game,
  navigate,
  openEditor,
  openGameControl,
}: PageProps & { game: GameAdminDefinition }) {
  const category = GAME_CATEGORIES.find((item) => item.games.some((entry) => entry.id === game.id));
  const questions = game.contentType
    ? data.questions.filter((item) => item.contentType === game.contentType)
    : [];
  const banks = game.contentType
    ? data.banks.filter((item) => item.contentType === game.contentType)
    : [];
  const settings = game.gameType
    ? data.configurations.filter(
        (item) => item.gameType === game.gameType && item.kind === "SETTINGS",
      )
    : [];
  const modifiers = game.gameType
    ? data.configurations.filter(
        (item) => item.gameType === game.gameType && item.kind === "MODIFIERS",
      )
    : [];
  const assets = game.gameType ? data.assets.filter((item) => item.gameType === game.gameType) : [];
  const published = (items: Array<{ status: string }>) =>
    items.filter((item) => item.status === "PUBLISHED").length;

  return (
    <>
      <PageHeading
        eyebrow={category?.label ?? "Catalogue des jeux"}
        title={game.label}
        description={game.description}
        action={
          <button className="secondary-button" onClick={() => navigate("dashboard")} type="button">
            <ArrowLeft />
            Tous les jeux
          </button>
        }
      />
      <section className="game-detail-hero">
        <div className="game-detail-art">
          <img src={gameAsset(game.asset)} alt={`Logo ${game.label}`} />
        </div>
        <div className="game-detail-copy">
          <div className="game-detail-flags">
            <span>{game.duration}</span>
            <span className={game.status === "PREVIEW" ? "preview" : "live"}>
              {game.status === "PREVIEW" ? "Preview mobile" : "Runtime actif"}
            </span>
          </div>
          <h2>{game.subtitle}</h2>
          <p>
            {game.gameType
              ? `Contexte Spring : ${humanize(game.gameType)}`
              : "Cette expérience ne possède pas encore de GameType ni de runtime Spring."}
          </p>
        </div>
        {category && (
          <img className="game-detail-category-art" src={gameAsset(category.asset)} alt="" />
        )}
      </section>
      <ProtectedNotice />
      <section className="game-controls" aria-label={`Contrôles de ${game.label}`}>
        <GameControlCard
          icon={<FileQuestion />}
          title="Questions"
          value={game.contentType ? `${questions.length} versions` : "Non applicable"}
          detail={
            game.contentType
              ? `${published(questions)} publiées pour les nouvelles sessions`
              : "Ce jeu n’utilise pas de catalogue de questions administré."
          }
          disabled={!game.contentType}
          onOpen={() => openGameControl(game.id, "questions")}
          onCreate={
            game.contentType
              ? () => openEditor({ kind: "question", contentType: game.contentType })
              : undefined
          }
        />
        <GameControlCard
          icon={<FolderKanban />}
          title="Banques et rotation"
          value={game.contentType ? `${banks.length} versions` : "Non applicable"}
          detail={
            game.contentType
              ? `${published(banks)} banques actives et composition ordonnée`
              : "Aucune banque éditoriale n’est attendue pour ce protocole."
          }
          disabled={!game.contentType}
          onOpen={() => openGameControl(game.id, "banks")}
          onCreate={
            game.contentType
              ? () => openEditor({ kind: "bank", contentType: game.contentType })
              : undefined
          }
        />
        <GameControlCard
          icon={<Settings2 />}
          title="Paramètres"
          value={game.gameType ? `${settings.length} versions` : "Indisponible"}
          detail={
            game.gameType
              ? `${published(settings)} version publiée, figée au démarrage de session`
              : "Le backend de cette preview n’est pas encore défini."
          }
          disabled={!game.gameType}
          onOpen={() => openGameControl(game.id, "settings")}
          onCreate={
            game.gameType
              ? () =>
                  openEditor({
                    kind: "configuration",
                    configurationKind: "SETTINGS",
                    gameType: game.gameType,
                  })
              : undefined
          }
        />
        <GameControlCard
          icon={<SlidersHorizontal />}
          title="Modificateurs"
          value={game.gameType ? `${modifiers.length} versions` : "Indisponible"}
          detail={
            game.gameType
              ? `${published(modifiers)} version publiée, toujours hors scoring`
              : "Aucun modificateur runtime ne peut encore être appliqué."
          }
          disabled={!game.gameType}
          onOpen={() => openGameControl(game.id, "modifiers")}
          onCreate={
            game.gameType
              ? () =>
                  openEditor({
                    kind: "configuration",
                    configurationKind: "MODIFIERS",
                    gameType: game.gameType,
                  })
              : undefined
          }
        />
        <GameControlCard
          icon={<Image />}
          title="Assets"
          value={game.gameType ? `${assets.length} administrés` : "Indisponible"}
          detail={
            game.gameType
              ? `${published(assets)} publiés, plus le logo Flutter officiel`
              : "Le logo de preview reste uniquement embarqué dans les clients."
          }
          disabled={!game.gameType}
          onOpen={() => openGameControl(game.id, "assets")}
          onCreate={
            game.gameType ? () => openEditor({ kind: "asset", gameType: game.gameType }) : undefined
          }
        />
      </section>
    </>
  );
}

function GameControlCard({
  icon,
  title,
  value,
  detail,
  disabled,
  onOpen,
  onCreate,
}: {
  icon: ReactNode;
  title: string;
  value: string;
  detail: string;
  disabled: boolean;
  onOpen: () => void;
  onCreate?: () => void;
}) {
  return (
    <article className={`game-control-card ${disabled ? "disabled" : ""}`}>
      <span className="game-control-icon">{icon}</span>
      <div>
        <p>{title}</p>
        <strong>{value}</strong>
        <small>{detail}</small>
      </div>
      <div className="game-control-actions">
        {onCreate && (
          <button className="text-button" onClick={onCreate} type="button">
            <Plus />
            Créer
          </button>
        )}
        <button className="secondary-button" disabled={disabled} onClick={onOpen} type="button">
          Ouvrir
          <ChevronRight />
        </button>
      </div>
    </article>
  );
}

function GameScopeBar({
  game,
  openGame,
}: {
  game: GameAdminDefinition;
  openGame: (gameId: GameId) => void;
}) {
  return (
    <div className="game-scope-bar">
      <button className="text-button" onClick={() => openGame(game.id)} type="button">
        <ArrowLeft />
        {game.label}
      </button>
      <span>Vue filtrée pour ce jeu</span>
      <img src={gameAsset(game.asset)} alt="" />
    </div>
  );
}

function RecentActivity({
  entries,
  navigate,
}: {
  entries: AuditEntry[];
  navigate: (page: Page) => void;
}) {
  return (
    <aside className="panel panel-pad">
      <div className="section-head">
        <div>
          <h2>Activité récente</h2>
          <p>Actions persistées dans le journal.</p>
        </div>
        <button className="text-button" onClick={() => navigate("releases")} type="button">
          Audit
        </button>
      </div>
      {entries.length === 0 ? (
        <EmptyState
          title="Aucune activité"
          description="Les prochaines actions apparaîtront ici."
        />
      ) : (
        <div className="activity">
          {entries.map((entry) => (
            <div className="activity-item" key={entry.id}>
              <span className="activity-icon">
                <Clock3 />
              </span>
              <div>
                <p>{actionLabel(entry.action)}</p>
                <small>{formatDate(entry.createdAt)}</small>
              </div>
            </div>
          ))}
        </div>
      )}
    </aside>
  );
}

export function QuestionsPage({ data, openEditor, refresh, game, openGame }: PageProps) {
  const [filter, setFilter] = useState(game?.contentType ?? "ALL");
  const [status, setStatus] = useState("ALL");
  const [query, setQuery] = useState("");
  const [pageIndex, setPageIndex] = useState(0);
  const visible = useMemo(
    () =>
      data.questions.filter(
        (question) =>
          (filter === "ALL" || question.contentType === filter) &&
          (status === "ALL" || question.status === status) &&
          `${question.externalCode} ${question.prompt}`.toLowerCase().includes(query.toLowerCase()),
      ),
    [data.questions, filter, query, status],
  );
  const pageSize = 25;
  const pageCount = Math.max(1, Math.ceil(visible.length / pageSize));
  const paginated = visible.slice(pageIndex * pageSize, (pageIndex + 1) * pageSize);
  useEffect(() => setPageIndex(0), [filter, query, status]);
  useEffect(() => setFilter(game?.contentType ?? "ALL"), [game]);

  const mutate = (question: Question, operation: "draft" | "publish" | "archive" | "delete") => {
    if (
      (operation === "delete" || operation === "archive") &&
      !window.confirm(
        operation === "delete"
          ? "Supprimer définitivement ce brouillon ?"
          : "Archiver cette question ?",
      )
    )
      return;
    const label =
      operation === "draft"
        ? "Brouillon créé"
        : operation === "publish"
          ? "Question publiée"
          : operation === "archive"
            ? "Question archivée"
            : "Brouillon supprimé";
    const request =
      operation === "delete"
        ? () => adminApi(`/questions/${question.id}`, { method: "DELETE" })
        : () => adminApi(`/questions/${question.id}/${operation}`, { method: "POST" });
    void action(request, label, refresh);
  };

  return (
    <>
      <PageHeading
        eyebrow="Contenu versionné"
        title={game ? `Questions · ${game.label}` : "Questions"}
        description={
          game
            ? `Créez et publiez uniquement les contenus de ${game.label}.`
            : "Créez, révisez, publiez et archivez les scénarios de jeu."
        }
        action={
          <button
            className="primary-button"
            onClick={() => openEditor({ kind: "question", contentType: game?.contentType })}
            type="button"
          >
            <Plus />
            Nouvelle question
          </button>
        }
      />
      {game && <GameScopeBar game={game} openGame={openGame} />}
      <ProtectedNotice />
      <section className="panel panel-pad">
        <div className="toolbar">
          <div className="filters">
            {[
              ["ALL", "Tous"],
              ["DECISION_SCENARIO", "Je Décide"],
              ["EMOTIONAL_RADAR_SCENE", "Emotional Radar"],
            ].map(([value, label]) => (
              <button
                key={value}
                className={`filter ${filter === value ? "active" : ""}`}
                onClick={() => setFilter(value)}
                type="button"
              >
                {label}
              </button>
            ))}
          </div>
          <div className="toolbar-fields">
            <select
              className="field compact"
              value={status}
              onChange={(event) => setStatus(event.target.value)}
              aria-label="Filtrer par statut"
            >
              <option value="ALL">Tous les statuts</option>
              <option value="DRAFT">Brouillons</option>
              <option value="PUBLISHED">Publiés</option>
              <option value="ARCHIVED">Archivés</option>
            </select>
            <input
              className="search"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Rechercher par code ou texte"
              aria-label="Rechercher une question"
            />
          </div>
        </div>
        {visible.length === 0 ? (
          <EmptyState
            title="Aucune question"
            description="Modifiez les filtres ou créez un nouveau brouillon."
          />
        ) : (
          <>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Question</th>
                    <th>Jeu</th>
                    <th>Banque</th>
                    <th>Origine</th>
                    <th>Statut</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.map((question) => {
                    const game = gamePresentation(question.contentType);
                    return (
                      <tr key={question.id}>
                        <td className="question-copy">
                          <strong>{question.externalCode}</strong>
                          <span>{question.prompt}</span>
                          <small>{formatDate(question.updatedAt)}</small>
                        </td>
                        <td>
                          <div className="game-cell">
                            <img src={gameAsset(game.image)} alt="" />
                            {game.label}
                          </div>
                        </td>
                        <td>{question.bankName ?? "Non affectée"}</td>
                        <td>{question.managed ? "Administrée" : "Catalogue système"}</td>
                        <td>
                          <StatusPill status={question.status} />
                        </td>
                        <td>
                          <div className="row-actions">
                            {question.managed && question.status === "DRAFT" && (
                              <>
                                <InlineAction
                                  onClick={() => openEditor({ kind: "question", value: question })}
                                >
                                  Modifier
                                </InlineAction>
                                <InlineAction onClick={() => mutate(question, "publish")}>
                                  Publier
                                </InlineAction>
                                <InlineAction danger onClick={() => mutate(question, "delete")}>
                                  Supprimer
                                </InlineAction>
                              </>
                            )}
                            {question.status !== "DRAFT" && (
                              <InlineAction onClick={() => mutate(question, "draft")}>
                                <Copy />
                                Créer une version
                              </InlineAction>
                            )}
                            {question.managed &&
                              question.status !== "ARCHIVED" &&
                              question.status !== "DRAFT" && (
                                <InlineAction danger onClick={() => mutate(question, "archive")}>
                                  <Archive />
                                  Archiver
                                </InlineAction>
                              )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <div className="pagination">
              <span>{visible.length} questions</span>
              <div>
                <button
                  className="secondary-button"
                  disabled={pageIndex === 0}
                  onClick={() => setPageIndex((current) => current - 1)}
                  type="button"
                >
                  Précédent
                </button>
                <strong>
                  {pageIndex + 1} / {pageCount}
                </strong>
                <button
                  className="secondary-button"
                  disabled={pageIndex + 1 >= pageCount}
                  onClick={() => setPageIndex((current) => current + 1)}
                  type="button"
                >
                  Suivant
                </button>
              </div>
            </div>
          </>
        )}
      </section>
    </>
  );
}

export function BanksPage({ data, openEditor, refresh, game, openGame }: PageProps) {
  const banks = game?.contentType
    ? data.banks.filter((bank) => bank.contentType === game.contentType)
    : data.banks;
  const mutate = (bank: Bank, operation: "publish" | "archive" | "delete") => {
    if (
      (operation === "delete" || operation === "archive") &&
      !window.confirm(
        operation === "delete"
          ? "Supprimer définitivement ce brouillon de banque ?"
          : "Archiver cette banque ?",
      )
    )
      return;
    const request =
      operation === "delete"
        ? () => adminApi(`/banks/${bank.id}`, { method: "DELETE" })
        : () => adminApi(`/banks/${bank.id}/${operation}`, { method: "POST" });
    void action(
      request,
      operation === "publish"
        ? "Banque publiée pour les nouvelles sessions"
        : operation === "archive"
          ? "Banque archivée"
          : "Brouillon supprimé",
      refresh,
    );
  };
  return (
    <>
      <PageHeading
        eyebrow="Rotation"
        title={game ? `Banques · ${game.label}` : "Banques de questions"}
        description={
          game
            ? `Composez et publiez les rotations de ${game.label}.`
            : "Composez l'ordre, réglez les poids et publiez chaque version atomiquement."
        }
        action={
          <button
            className="primary-button"
            onClick={() => openEditor({ kind: "bank", contentType: game?.contentType })}
            type="button"
          >
            <Plus />
            Nouvelle banque
          </button>
        }
      />
      {game && <GameScopeBar game={game} openGame={openGame} />}
      <div className="protected">
        <ListChecks />
        <div>
          <strong>Sessions épinglées</strong>
          <span>
            Une publication s'applique uniquement aux nouvelles sessions. Les parties en cours
            conservent leur version.
          </span>
        </div>
      </div>
      <section className="panel">
        <BankTable
          banks={banks}
          actions={(bank) => (
            <div className="row-actions">
              {bank.status === "DRAFT" && (
                <>
                  <InlineAction onClick={() => openEditor({ kind: "bank", value: bank })}>
                    <Edit3 />
                    Modifier
                  </InlineAction>
                  <InlineAction onClick={() => openEditor({ kind: "bank-items", value: bank })}>
                    <ListChecks />
                    Composer
                  </InlineAction>
                  <InlineAction
                    disabled={bank.itemCount === 0}
                    onClick={() => mutate(bank, "publish")}
                  >
                    <Rocket />
                    Publier
                  </InlineAction>
                  <InlineAction danger onClick={() => mutate(bank, "delete")}>
                    <Trash2 />
                    Supprimer
                  </InlineAction>
                </>
              )}
              {bank.status !== "ARCHIVED" && bank.status !== "DRAFT" && (
                <InlineAction danger onClick={() => mutate(bank, "archive")}>
                  <Archive />
                  Archiver
                </InlineAction>
              )}
            </div>
          )}
        />
      </section>
    </>
  );
}

function BankTable({ banks, actions }: { banks: Bank[]; actions?: (bank: Bank) => ReactNode }) {
  if (banks.length === 0)
    return (
      <EmptyState
        title="Aucune banque"
        description="Créez une banque et composez sa première version."
      />
    );
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Banque</th>
            <th>Version</th>
            <th>Questions</th>
            <th>Rotation</th>
            <th>Statut</th>
            <th>Modifiée</th>
            {actions && <th>Actions</th>}
          </tr>
        </thead>
        <tbody>
          {banks.map((bank) => {
            const game = gamePresentation(bank.contentType);
            return (
              <tr key={bank.id}>
                <td>
                  <div className="game-cell">
                    <img src={gameAsset(game.image)} alt="" />
                    <div>
                      <strong>{bank.name}</strong>
                      <small>{bank.code}</small>
                    </div>
                  </div>
                </td>
                <td>v{bank.version}</td>
                <td>{bank.itemCount}</td>
                <td>{bank.rotationWeight}%</td>
                <td>
                  <StatusPill status={bank.status} />
                </td>
                <td>{formatDate(bank.updatedAt)}</td>
                {actions && <td>{actions(bank)}</td>}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export function ConfigurationsPage({
  data,
  openEditor,
  refresh,
  kind,
  game,
  openGame,
}: PageProps & { kind: ConfigurationKind }) {
  const configurations = data.configurations.filter(
    (configuration) =>
      configuration.kind === kind && (!game?.gameType || configuration.gameType === game.gameType),
  );
  const settings = kind === "SETTINGS";
  const [publishReview, setPublishReview] = useState<Configuration | null>(null);
  const [publishing, setPublishing] = useState(false);
  const publishedForGame = (gameType: string) =>
    configurations
      .filter(
        (configuration) =>
          configuration.gameType === gameType && configuration.status === "PUBLISHED",
      )
      .sort((left, right) => right.version - left.version)[0];
  const schemaForGame = (gameType: string) =>
    data.configurationSchemas.find(
      (schema) => schema.gameType === gameType && schema.kind === kind,
    );
  const mutate = async (
    configuration: Configuration,
    operation: "publish" | "archive" | "delete",
  ) => {
    if (
      (operation === "delete" || operation === "archive") &&
      !window.confirm(
        operation === "delete"
          ? "Supprimer définitivement ce brouillon de configuration ?"
          : "Archiver cette configuration ?",
      )
    )
      return false;
    const request =
      operation === "delete"
        ? () => adminApi(`/configurations/${configuration.id}`, { method: "DELETE" })
        : () => adminApi(`/configurations/${configuration.id}/${operation}`, { method: "POST" });
    return action(
      request,
      operation === "publish"
        ? "Configuration publiée"
        : operation === "archive"
          ? "Configuration archivée"
          : "Brouillon supprimé",
      refresh,
    );
  };
  const gamePublishedConfiguration = game?.gameType ? publishedForGame(game.gameType) : undefined;
  return (
    <>
      <PageHeading
        eyebrow={settings ? "Déroulé et accessibilité" : "Variantes d'expérience"}
        title={
          game
            ? `${settings ? "Paramètres" : "Modificateurs"} · ${game.label}`
            : settings
              ? "Paramètres de jeu"
              : "Modificateurs"
        }
        description={
          settings
            ? "Versionnez les valeurs appliquées au déroulé de chaque jeu."
            : "Contrôlez les options de présentation indépendantes du score."
        }
        action={
          <button
            className="primary-button"
            onClick={() =>
              openEditor({
                kind: "configuration",
                configurationKind: kind,
                source: gamePublishedConfiguration,
                gameType: game?.gameType,
              })
            }
            type="button"
          >
            <Plus />
            Nouvelle configuration
          </button>
        }
      />
      {game && <GameScopeBar game={game} openGame={openGame} />}
      <ProtectedNotice />
      <div className="configuration-grid">
        {configurations.length === 0 ? (
          <EmptyState
            title="Aucune configuration"
            description="Créez une première version pour ce type de configuration."
          />
        ) : (
          configurations.map((configuration) => {
            const activePublished = publishedForGame(configuration.gameType);
            const schema = schemaForGame(configuration.gameType);
            const changes = configurationChanges(configuration, activePublished, schema);
            return (
              <article className="configuration-card" key={configuration.id}>
                <div className="configuration-title">
                  <span className="configuration-icon">
                    {settings ? <Settings2 /> : <SlidersHorizontal />}
                  </span>
                  <div>
                    <h2>{humanize(configuration.gameType)}</h2>
                    <p>
                      {settings ? "Paramètres" : "Modificateurs"} v{configuration.version}
                    </p>
                  </div>
                  <StatusPill status={configuration.status} />
                </div>
                <dl className="json-summary">
                  {Object.entries(configuration.values)
                    .slice(0, 8)
                    .map(([key, value]) => (
                      <div key={key}>
                        <dt>
                          {data.configurationSchemas
                            .find(
                              (schema) =>
                                schema.gameType === configuration.gameType && schema.kind === kind,
                            )
                            ?.fields.find((field) => field.key === key)?.label ?? humanize(key)}
                        </dt>
                        <dd>{formatValue(value)}</dd>
                      </div>
                    ))}
                </dl>
                {configuration.status === "DRAFT" && (
                  <section className="configuration-card-review">
                    <div>
                      <span>Écart de publication</span>
                      <strong>
                        {changes.length} {changes.length > 1 ? "changements" : "changement"}
                      </strong>
                    </div>
                    <p>
                      {activePublished
                        ? `Comparé à la version publiée v${activePublished.version}`
                        : "Première version publiée de ce jeu"}
                    </p>
                  </section>
                )}
                <div className="card-actions">
                  {configuration.status === "DRAFT" && (
                    <>
                      <button
                        className="secondary-button"
                        onClick={() =>
                          openEditor({
                            kind: "configuration",
                            configurationKind: kind,
                            value: configuration,
                          })
                        }
                        type="button"
                      >
                        <Edit3 />
                        Modifier
                      </button>
                      <button
                        className="primary-button"
                        onClick={() => setPublishReview(configuration)}
                        type="button"
                      >
                        <Rocket />
                        Publier
                      </button>
                      <button
                        className="icon-button danger"
                        aria-label="Supprimer le brouillon"
                        onClick={() => mutate(configuration, "delete")}
                        type="button"
                      >
                        <Trash2 />
                      </button>
                    </>
                  )}
                  {configuration.status !== "ARCHIVED" && configuration.status !== "DRAFT" && (
                    <>
                      <button
                        className="primary-button"
                        onClick={() =>
                          openEditor({
                            kind: "configuration",
                            configurationKind: kind,
                            source: configuration,
                          })
                        }
                        type="button"
                      >
                        <Copy />
                        Créer v{configuration.version + 1}
                      </button>
                      <button
                        className="secondary-button"
                        onClick={() => void mutate(configuration, "archive")}
                        type="button"
                      >
                        <Archive />
                        Archiver
                      </button>
                    </>
                  )}
                </div>
              </article>
            );
          })
        )}
      </div>
      {publishReview && (
        <ConfigurationPublishReview
          configuration={publishReview}
          published={publishedForGame(publishReview.gameType)}
          schema={schemaForGame(publishReview.gameType)}
          publishing={publishing}
          close={() => setPublishReview(null)}
          publish={async () => {
            setPublishing(true);
            const succeeded = await mutate(publishReview, "publish");
            setPublishing(false);
            if (succeeded) setPublishReview(null);
          }}
        />
      )}
    </>
  );
}

function ConfigurationPublishReview({
  configuration,
  published,
  schema,
  publishing,
  close,
  publish,
}: {
  configuration: Configuration;
  published?: Configuration;
  schema?: AdminData["configurationSchemas"][number];
  publishing: boolean;
  close: () => void;
  publish: () => Promise<void>;
}) {
  const changes = configurationChanges(configuration, published, schema);
  return (
    <div
      className="release-review-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !publishing) close();
      }}
    >
      <section
        aria-labelledby="configuration-publish-title"
        aria-modal="true"
        className="release-review-dialog"
        role="dialog"
      >
        <header className="release-review-head">
          <div>
            <p className="eyebrow">Contrôle de publication</p>
            <h2 id="configuration-publish-title">
              Publier {configuration.kind === "SETTINGS" ? "les paramètres" : "les modificateurs"} v
              {configuration.version}
            </h2>
            <span>{humanize(configuration.gameType)}</span>
          </div>
          <button
            aria-label="Fermer"
            className="icon-button"
            disabled={publishing}
            onClick={close}
            type="button"
          >
            ×
          </button>
        </header>
        <div className="release-review-impact">
          <ListChecks />
          <div>
            <strong>
              {changes.length === 0
                ? "Aucune valeur ne change"
                : `${changes.length} ${changes.length > 1 ? "valeurs vont changer" : "valeur va changer"}`}
            </strong>
            <p>
              {published
                ? `La version publiée v${published.version} sera archivée. Les sessions en cours conservent leur snapshot.`
                : "Cette version deviendra la première configuration active. Les sessions déjà lancées ne changent pas."}
            </p>
          </div>
        </div>
        <dl className="release-review-list">
          {changes.length > 0 ? (
            changes.map((change) => (
              <div key={change.key}>
                <dt>
                  <strong>{change.label}</strong>
                  <code>{change.key}</code>
                </dt>
                <dd>
                  <span>{formatReleaseValue(change.before)}</span>
                  <b aria-hidden="true">→</b>
                  <strong>{formatReleaseValue(change.after)}</strong>
                </dd>
              </div>
            ))
          ) : (
            <div className="release-review-unchanged">
              <dt>Version sans modification fonctionnelle</dt>
              <dd>Les valeurs correspondent exactement à la version actuellement publiée.</dd>
            </div>
          )}
        </dl>
        <footer className="release-review-actions">
          <button className="secondary-button" disabled={publishing} onClick={close} type="button">
            Retour au brouillon
          </button>
          <button
            className="primary-button"
            disabled={publishing}
            onClick={() => void publish()}
            type="button"
          >
            <Rocket />
            {publishing ? "Publication..." : "Confirmer la publication"}
          </button>
        </footer>
      </section>
    </div>
  );
}

function configurationChanges(
  configuration: Configuration,
  published?: Configuration,
  schema?: AdminData["configurationSchemas"][number],
) {
  const orderedKeys = [
    ...(schema?.fields.map((field) => field.key) ?? []),
    ...Object.keys(configuration.values).filter(
      (key) => !schema?.fields.some((field) => field.key === key),
    ),
  ];
  return orderedKeys
    .filter((key) => !published || published.values[key] !== configuration.values[key])
    .map((key) => ({
      key,
      label: schema?.fields.find((field) => field.key === key)?.label ?? humanize(key),
      before: published?.values[key],
      after: configuration.values[key],
    }));
}

function formatReleaseValue(value: unknown) {
  if (typeof value === "boolean") return value ? "Activé" : "Désactivé";
  if (value === undefined || value === null) return "Non défini";
  return String(value).replaceAll("_", " ");
}

const bundledAssets = [
  "category-cognitive-flexibility.png",
  "category-working-memory.png",
  "category-decision-making.png",
  "category-executive-planning.png",
  "category-emotional-regulation.png",
  "je-decide.png",
  "emotional-radar.png",
  "memory-quest.png",
  "move-fast.png",
  "je-coordonne.png",
  "je-place.png",
  "optimal-path.png",
  "predictive-puzzle.png",
  "reflective-pause.png",
  "task-scheduling.png",
  "strategic-choices.png",
];

export function AssetsPage({ data, openEditor, refresh, game, openGame }: PageProps) {
  const [tab, setTab] = useState<"managed" | "bundled">("managed");
  const managedAssets = game?.gameType
    ? data.assets.filter((item) => item.gameType === game.gameType)
    : data.assets;
  const visibleBundledAssets = game
    ? bundledAssets.filter((item) => item === game.asset)
    : bundledAssets;
  const copyRuntimeUrl = async (item: ManagedAsset) => {
    try {
      await navigator.clipboard.writeText(item.url);
      toast.success("URL runtime copiée");
    } catch {
      toast.error("Impossible de copier l’URL");
    }
  };
  const mutate = (item: ManagedAsset, operation: "publish" | "archive" | "delete") => {
    if (operation === "archive" && !window.confirm("Archiver cet asset ?")) return;
    if (
      operation === "delete" &&
      !window.confirm("Supprimer définitivement ce brouillon et son fichier distant ?")
    )
      return;
    const request =
      operation === "delete"
        ? () => adminApi(`/assets/${item.id}`, { method: "DELETE" })
        : () => adminApi(`/assets/${item.id}/${operation}`, { method: "POST" });
    void action(
      request,
      operation === "publish"
        ? "Asset publié"
        : operation === "archive"
          ? "Asset archivé"
          : "Brouillon et fichier supprimés",
      refresh,
    );
  };
  return (
    <>
      <PageHeading
        eyebrow="Médiathèque"
        title={game ? `Assets · ${game.label}` : "Assets de jeu"}
        description={
          game
            ? `Gérez le logo Flutter et les médias runtime de ${game.label}.`
            : "Importez, décrivez, publiez et archivez les médias utilisés par les jeux."
        }
        action={
          <button
            className="primary-button"
            onClick={() => openEditor({ kind: "asset", gameType: game?.gameType })}
            type="button"
          >
            <Upload />
            Importer un asset
          </button>
        }
      />
      {game && <GameScopeBar game={game} openGame={openGame} />}
      <div className="filters asset-tabs">
        <button
          className={`filter ${tab === "managed" ? "active" : ""}`}
          onClick={() => setTab("managed")}
          type="button"
        >
          Assets administrés ({managedAssets.length})
        </button>
        <button
          className={`filter ${tab === "bundled" ? "active" : ""}`}
          onClick={() => setTab("bundled")}
          type="button"
        >
          Bibliothèque Flutter ({visibleBundledAssets.length})
        </button>
      </div>
      {tab === "managed" ? (
        managedAssets.length === 0 ? (
          <EmptyState
            title="Aucun asset administré"
            description="Importez un PNG ou SVG pour démarrer la médiathèque versionnée."
            action={
              <button
                className="primary-button"
                onClick={() => openEditor({ kind: "asset", gameType: game?.gameType })}
                type="button"
              >
                <Upload />
                Importer
              </button>
            }
          />
        ) : (
          <div className="asset-grid">
            {managedAssets.map((item) => (
              <article className="asset-card" key={item.id}>
                <div className="asset-preview">
                  <ManagedAssetImage item={item} />
                </div>
                <div className="asset-meta">
                  <div>
                    <strong>{item.filename}</strong>
                    <small>
                      {item.mediaType} | {humanize(item.gameType)}
                    </small>
                  </div>
                  <StatusPill status={item.status} />
                  <p>{item.altText}</p>
                  <div className="card-actions">
                    {item.status === "PUBLISHED" && (
                      <button
                        className="secondary-button"
                        onClick={() => void copyRuntimeUrl(item)}
                        type="button"
                      >
                        <Copy />
                        Copier l’URL
                      </button>
                    )}
                    {item.status === "DRAFT" && (
                      <>
                        <button
                          className="secondary-button"
                          onClick={() => openEditor({ kind: "asset", value: item })}
                          type="button"
                        >
                          <Edit3 />
                          Métadonnées
                        </button>
                        <button
                          className="primary-button"
                          onClick={() => mutate(item, "publish")}
                          type="button"
                        >
                          <Rocket />
                          Publier
                        </button>
                        <button
                          className="icon-button danger"
                          aria-label="Supprimer le brouillon et son fichier"
                          onClick={() => mutate(item, "delete")}
                          type="button"
                        >
                          <Trash2 />
                        </button>
                      </>
                    )}
                    {item.status === "PUBLISHED" && (
                      <button
                        className="secondary-button"
                        onClick={() => mutate(item, "archive")}
                        type="button"
                      >
                        <Archive />
                        Archiver
                      </button>
                    )}
                  </div>
                </div>
              </article>
            ))}
          </div>
        )
      ) : (
        <div className="asset-grid">
          {visibleBundledAssets.map((item) => (
            <article className="asset-card bundled" key={item}>
              <div className="asset-preview">
                <img
                  src={gameAsset(item)}
                  alt={`Illustration du jeu ${item.replace(".png", "")}`}
                />
              </div>
              <div className="asset-meta">
                <strong>{item}</strong>
                <small>PNG original importé depuis Flutter</small>
              </div>
            </article>
          ))}
        </div>
      )}
    </>
  );
}

function ManagedAssetImage({ item }: { item: ManagedAsset }) {
  const [source, setSource] = useState(item.url.startsWith("/api/") ? "" : item.url);
  useEffect(() => {
    let objectUrl = "";
    let active = true;
    void authenticatedAssetUrl(item.url)
      .then((url) => {
        if (!active) {
          if (url.startsWith("blob:")) URL.revokeObjectURL(url);
          return;
        }
        objectUrl = url;
        setSource(url);
      })
      .catch(() => setSource(""));
    return () => {
      active = false;
      if (objectUrl.startsWith("blob:")) URL.revokeObjectURL(objectUrl);
    };
  }, [item.url]);
  return source ? (
    <img src={source} alt={item.altText} />
  ) : (
    <Image aria-label="Aperçu indisponible" />
  );
}

export function ReleasesPage({ data }: PageProps) {
  const [entity, setEntity] = useState("ALL");
  const entries = data.audit.filter((entry) => entity === "ALL" || entry.entityType === entity);
  return (
    <>
      <PageHeading
        eyebrow="Traçabilité"
        title="Versions et journal d'audit"
        description="Consultez chaque création, modification, publication, archivage et suppression."
      />
      <section className="panel panel-pad">
        <div className="toolbar">
          <div className="filters">
            {["ALL", "QUESTION", "BANK", "CONFIGURATION", "ASSET"].map((value) => (
              <button
                className={`filter ${entity === value ? "active" : ""}`}
                key={value}
                onClick={() => setEntity(value)}
                type="button"
              >
                {value === "ALL" ? "Toutes" : humanize(value)}
              </button>
            ))}
          </div>
        </div>
        {entries.length === 0 ? (
          <EmptyState
            title="Journal vide"
            description="Les actions d'administration apparaîtront ici."
          />
        ) : (
          <div className="audit-list">
            {entries.map((entry) => (
              <article className="audit-row" key={entry.id}>
                <span className="activity-icon">
                  <Clock3 />
                </span>
                <div>
                  <strong>{actionLabel(entry.action)}</strong>
                  <p>
                    {humanize(entry.entityType)} <code>{entry.entityId.slice(0, 8)}</code>
                  </p>
                </div>
                <div className="audit-meta">
                  <time>{formatDate(entry.createdAt)}</time>
                  <small>Acteur {entry.actorId.slice(0, 8)}</small>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </>
  );
}

function actionLabel(actionName: string) {
  const labels: Record<string, string> = {
    QUESTION_CREATED: "Question créée",
    QUESTION_UPDATED: "Question modifiée",
    QUESTION_PUBLISHED: "Question publiée",
    QUESTION_ARCHIVED: "Question archivée",
    QUESTION_DELETED: "Brouillon de question supprimé",
    BANK_CREATED: "Banque créée",
    BANK_UPDATED: "Banque modifiée",
    BANK_ITEMS_REPLACED: "Composition de banque enregistrée",
    BANK_PUBLISHED: "Banque publiée",
    BANK_ARCHIVED: "Banque archivée",
    BANK_DELETED: "Brouillon de banque supprimé",
    CONFIGURATION_CREATED: "Configuration créée",
    CONFIGURATION_UPDATED: "Configuration modifiée",
    CONFIGURATION_PUBLISHED: "Configuration publiée",
    CONFIGURATION_ARCHIVED: "Configuration archivée",
    CONFIGURATION_DELETED: "Brouillon de configuration supprimé",
    ASSET_UPLOADED: "Asset importé",
    ASSET_UPDATED: "Métadonnées d'asset modifiées",
    ASSET_PUBLISHED: "Asset publié",
    ASSET_ARCHIVED: "Asset archivé",
    ASSET_DELETED: "Brouillon d'asset supprimé",
  };
  return labels[actionName] ?? humanize(actionName);
}

function humanize(value: string) {
  return value
    .toLowerCase()
    .replaceAll("_", " ")
    .replace(/(^|\s)\p{L}/gu, (letter) => letter.toUpperCase());
}

function formatValue(value: unknown) {
  if (typeof value === "boolean") return value ? "Activé" : "Désactivé";
  if (Array.isArray(value)) return `${value.length} valeurs`;
  if (value && typeof value === "object") return "Objet configuré";
  return String(value ?? "Non défini");
}
