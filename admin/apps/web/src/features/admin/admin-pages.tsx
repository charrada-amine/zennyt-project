import {
  Archive,
  Boxes,
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
  ManagedAsset,
  Page,
  Question,
} from "./admin-types";
import { formatDate, gamePresentation } from "./admin-types";

interface PageProps {
  data: AdminData;
  navigate: (page: Page) => void;
  openEditor: (editor: EditorState) => void;
  refresh: () => Promise<void>;
}

async function action(request: () => Promise<unknown>, message: string, refresh: () => Promise<void>) {
  try {
    await request();
    await refresh();
    toast.success(message);
  } catch (error) {
    toast.error(error instanceof Error ? error.message : "Action impossible");
  }
}

export function DashboardPage({ data, navigate }: PageProps) {
  const today = new Intl.DateTimeFormat("fr-FR", { dateStyle: "full" }).format(new Date());
  const recentBanks = data.banks.slice(0, 5);
  const publishedQuestions = data.questions.filter((question) => question.status === "PUBLISHED").length;
  return (
    <>
      <PageHeading eyebrow={today} title="Bonjour, équipe Zennyt" description="État réel du contenu disponible et des changements en préparation." action={<button className="primary-button" onClick={() => navigate("questions")} type="button"><Plus />Créer une question</button>} />
      <section className="hero">
        <div className="hero-copy"><p className="eyebrow">Publication versionnée</p><h2>Contrôlez le contenu sans interrompre les parties en cours.</h2><p>Chaque banque et configuration suit un cycle brouillon, publication et archivage.</p><button className="secondary-button" onClick={() => navigate("banks")} type="button">Gérer les rotations</button></div>
        <div className="hero-art"><GameOrbs /></div>
      </section>
      <div className="stats">
        <Stat label="Questions publiées" value={publishedQuestions} detail={`${data.overview.questionCount} versions visibles`} icon={FileQuestion} />
        <Stat label="Banques actives" value={data.overview.publishedBankCount} detail={`${data.banks.length} versions conservées`} icon={FolderKanban} />
        <Stat label="Brouillons" value={data.overview.draftCount} detail="À vérifier avant publication" icon={Boxes} />
        <Stat label="Assets administrés" value={data.overview.assetCount} detail="PNG et SVG persistés" icon={Image} />
      </div>
      <div className="grid-2">
        <section className="panel"><div className="panel-pad section-head"><div><h2>Banques récentes</h2><p>Versions, composition et poids de rotation.</p></div><button className="text-button" onClick={() => navigate("banks")} type="button">Tout gérer</button></div><BankTable banks={recentBanks} /></section>
        <RecentActivity entries={data.audit.slice(0, 6)} navigate={navigate} />
      </div>
    </>
  );
}

function RecentActivity({ entries, navigate }: { entries: AuditEntry[]; navigate: (page: Page) => void }) {
  return <aside className="panel panel-pad"><div className="section-head"><div><h2>Activité récente</h2><p>Actions persistées dans le journal.</p></div><button className="text-button" onClick={() => navigate("releases")} type="button">Audit</button></div>{entries.length === 0 ? <EmptyState title="Aucune activité" description="Les prochaines actions apparaîtront ici." /> : <div className="activity">{entries.map((entry) => <div className="activity-item" key={entry.id}><span className="activity-icon"><Clock3 /></span><div><p>{actionLabel(entry.action)}</p><small>{formatDate(entry.createdAt)}</small></div></div>)}</div>}</aside>;
}

export function QuestionsPage({ data, openEditor, refresh }: PageProps) {
  const [filter, setFilter] = useState("ALL");
  const [status, setStatus] = useState("ALL");
  const [query, setQuery] = useState("");
  const [pageIndex, setPageIndex] = useState(0);
  const visible = useMemo(() => data.questions.filter((question) =>
    (filter === "ALL" || question.contentType === filter) &&
    (status === "ALL" || question.status === status) &&
    `${question.externalCode} ${question.prompt}`.toLowerCase().includes(query.toLowerCase())), [data.questions, filter, query, status]);
  const pageSize = 25;
  const pageCount = Math.max(1, Math.ceil(visible.length / pageSize));
  const paginated = visible.slice(pageIndex * pageSize, (pageIndex + 1) * pageSize);
  useEffect(() => setPageIndex(0), [filter, query, status]);

  const mutate = (question: Question, operation: "draft" | "publish" | "archive" | "delete") => {
    if ((operation === "delete" || operation === "archive") && !window.confirm(operation === "delete" ? "Supprimer définitivement ce brouillon ?" : "Archiver cette question ?")) return;
    const label = operation === "draft" ? "Brouillon créé" : operation === "publish" ? "Question publiée" : operation === "archive" ? "Question archivée" : "Brouillon supprimé";
    const request = operation === "delete"
      ? () => adminApi(`/questions/${question.id}`, { method: "DELETE" })
      : () => adminApi(`/questions/${question.id}/${operation}`, { method: "POST" });
    void action(request, label, refresh);
  };

  return <><PageHeading eyebrow="Contenu versionné" title="Questions" description="Créez, révisez, publiez et archivez les scénarios de jeu." action={<button className="primary-button" onClick={() => openEditor({ kind: "question" })} type="button"><Plus />Nouvelle question</button>} /><ProtectedNotice /><section className="panel panel-pad"><div className="toolbar"><div className="filters">{[["ALL", "Tous"], ["DECISION_SCENARIO", "Je Décide"], ["EMOTIONAL_RADAR_SCENE", "Emotional Radar"]].map(([value, label]) => <button key={value} className={`filter ${filter === value ? "active" : ""}`} onClick={() => setFilter(value)} type="button">{label}</button>)}</div><div className="toolbar-fields"><select className="field compact" value={status} onChange={(event) => setStatus(event.target.value)} aria-label="Filtrer par statut"><option value="ALL">Tous les statuts</option><option value="DRAFT">Brouillons</option><option value="PUBLISHED">Publiés</option><option value="ARCHIVED">Archivés</option></select><input className="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Rechercher par code ou texte" aria-label="Rechercher une question" /></div></div>{visible.length === 0 ? <EmptyState title="Aucune question" description="Modifiez les filtres ou créez un nouveau brouillon." /> : <><div className="table-wrap"><table><thead><tr><th>Question</th><th>Jeu</th><th>Banque</th><th>Origine</th><th>Statut</th><th>Actions</th></tr></thead><tbody>{paginated.map((question) => { const game = gamePresentation(question.contentType); return <tr key={question.id}><td className="question-copy"><strong>{question.externalCode}</strong><span>{question.prompt}</span><small>{formatDate(question.updatedAt)}</small></td><td><div className="game-cell"><img src={gameAsset(game.image)} alt="" />{game.label}</div></td><td>{question.bankName ?? "Non affectée"}</td><td>{question.managed ? "Administrée" : "Catalogue système"}</td><td><StatusPill status={question.status} /></td><td><div className="row-actions">{question.managed && question.status === "DRAFT" && <><InlineAction onClick={() => openEditor({ kind: "question", value: question })}>Modifier</InlineAction><InlineAction onClick={() => mutate(question, "publish")}>Publier</InlineAction><InlineAction danger onClick={() => mutate(question, "delete")}>Supprimer</InlineAction></>}{question.status !== "DRAFT" && <InlineAction onClick={() => mutate(question, "draft")}><Copy />Créer une version</InlineAction>}{question.managed && question.status !== "ARCHIVED" && question.status !== "DRAFT" && <InlineAction danger onClick={() => mutate(question, "archive")}><Archive />Archiver</InlineAction>}</div></td></tr>; })}</tbody></table></div><div className="pagination"><span>{visible.length} questions</span><div><button className="secondary-button" disabled={pageIndex === 0} onClick={() => setPageIndex((current) => current - 1)} type="button">Précédent</button><strong>{pageIndex + 1} / {pageCount}</strong><button className="secondary-button" disabled={pageIndex + 1 >= pageCount} onClick={() => setPageIndex((current) => current + 1)} type="button">Suivant</button></div></div></>}</section></>;
}

export function BanksPage({ data, openEditor, refresh }: PageProps) {
  const mutate = (bank: Bank, operation: "publish" | "archive" | "delete") => {
    if ((operation === "delete" || operation === "archive") && !window.confirm(operation === "delete" ? "Supprimer définitivement ce brouillon de banque ?" : "Archiver cette banque ?")) return;
    const request = operation === "delete" ? () => adminApi(`/banks/${bank.id}`, { method: "DELETE" }) : () => adminApi(`/banks/${bank.id}/${operation}`, { method: "POST" });
    void action(request, operation === "publish" ? "Banque publiée pour les nouvelles sessions" : operation === "archive" ? "Banque archivée" : "Brouillon supprimé", refresh);
  };
  return <><PageHeading eyebrow="Rotation" title="Banques de questions" description="Composez l'ordre, réglez les poids et publiez chaque version atomiquement." action={<button className="primary-button" onClick={() => openEditor({ kind: "bank" })} type="button"><Plus />Nouvelle banque</button>} /><div className="protected"><ListChecks /><div><strong>Sessions épinglées</strong><span>Une publication s'applique uniquement aux nouvelles sessions. Les parties en cours conservent leur version.</span></div></div><section className="panel"><BankTable banks={data.banks} actions={(bank) => <div className="row-actions">{bank.status === "DRAFT" && <><InlineAction onClick={() => openEditor({ kind: "bank", value: bank })}><Edit3 />Modifier</InlineAction><InlineAction onClick={() => openEditor({ kind: "bank-items", value: bank })}><ListChecks />Composer</InlineAction><InlineAction disabled={bank.itemCount === 0} onClick={() => mutate(bank, "publish")}><Rocket />Publier</InlineAction><InlineAction danger onClick={() => mutate(bank, "delete")}><Trash2 />Supprimer</InlineAction></>}{bank.status !== "ARCHIVED" && bank.status !== "DRAFT" && <InlineAction danger onClick={() => mutate(bank, "archive")}><Archive />Archiver</InlineAction>}</div>} /></section></>;
}

function BankTable({ banks, actions }: { banks: Bank[]; actions?: (bank: Bank) => ReactNode }) {
  if (banks.length === 0) return <EmptyState title="Aucune banque" description="Créez une banque et composez sa première version." />;
  return <div className="table-wrap"><table><thead><tr><th>Banque</th><th>Version</th><th>Questions</th><th>Rotation</th><th>Statut</th><th>Modifiée</th>{actions && <th>Actions</th>}</tr></thead><tbody>{banks.map((bank) => { const game = gamePresentation(bank.contentType); return <tr key={bank.id}><td><div className="game-cell"><img src={gameAsset(game.image)} alt="" /><div><strong>{bank.name}</strong><small>{bank.code}</small></div></div></td><td>v{bank.version}</td><td>{bank.itemCount}</td><td>{bank.rotationWeight}%</td><td><StatusPill status={bank.status} /></td><td>{formatDate(bank.updatedAt)}</td>{actions && <td>{actions(bank)}</td>}</tr>; })}</tbody></table></div>;
}

export function ConfigurationsPage({ data, openEditor, refresh, kind }: PageProps & { kind: ConfigurationKind }) {
  const configurations = data.configurations.filter((configuration) => configuration.kind === kind);
  const settings = kind === "SETTINGS";
  const mutate = (configuration: Configuration, operation: "publish" | "archive" | "delete") => {
    if ((operation === "delete" || operation === "archive") && !window.confirm(operation === "delete" ? "Supprimer définitivement ce brouillon de configuration ?" : "Archiver cette configuration ?")) return;
    const request = operation === "delete" ? () => adminApi(`/configurations/${configuration.id}`, { method: "DELETE" }) : () => adminApi(`/configurations/${configuration.id}/${operation}`, { method: "POST" });
    void action(request, operation === "publish" ? "Configuration publiée" : operation === "archive" ? "Configuration archivée" : "Brouillon supprimé", refresh);
  };
  return <><PageHeading eyebrow={settings ? "Déroulé et accessibilité" : "Variantes d'expérience"} title={settings ? "Paramètres de jeu" : "Modificateurs"} description={settings ? "Versionnez les valeurs appliquées au déroulé de chaque jeu." : "Contrôlez les options de présentation indépendantes du score."} action={<button className="primary-button" onClick={() => openEditor({ kind: "configuration", configurationKind: kind })} type="button"><Plus />Nouvelle configuration</button>} /><ProtectedNotice /><div className="configuration-grid">{configurations.length === 0 ? <EmptyState title="Aucune configuration" description="Créez une première version pour ce type de configuration." /> : configurations.map((configuration) => <article className="configuration-card" key={configuration.id}><div className="configuration-title"><span className="configuration-icon">{settings ? <Settings2 /> : <SlidersHorizontal />}</span><div><h2>{humanize(configuration.gameType)}</h2><p>{settings ? "Paramètres" : "Modificateurs"} v{configuration.version}</p></div><StatusPill status={configuration.status} /></div><dl className="json-summary">{Object.entries(configuration.values).slice(0, 8).map(([key, value]) => <div key={key}><dt>{humanize(key)}</dt><dd>{formatValue(value)}</dd></div>)}</dl><div className="card-actions">{configuration.status === "DRAFT" && <><button className="secondary-button" onClick={() => openEditor({ kind: "configuration", configurationKind: kind, value: configuration })} type="button"><Edit3 />Modifier</button><button className="primary-button" onClick={() => mutate(configuration, "publish")} type="button"><Rocket />Publier</button><button className="icon-button danger" aria-label="Supprimer le brouillon" onClick={() => mutate(configuration, "delete")} type="button"><Trash2 /></button></>}{configuration.status !== "ARCHIVED" && configuration.status !== "DRAFT" && <button className="secondary-button" onClick={() => mutate(configuration, "archive")} type="button"><Archive />Archiver</button>}</div></article>)}</div></>;
}

const bundledAssets = ["je-decide.png", "emotional-radar.png", "memory-quest.png", "move-fast.png", "je-coordonne.png", "optimal-path.png", "predictive-puzzle.png", "reflective-pause.png", "task-scheduling.png", "strategic-choices.png"];

export function AssetsPage({ data, openEditor, refresh }: PageProps) {
  const [tab, setTab] = useState<"managed" | "bundled">("managed");
  const mutate = (item: ManagedAsset, operation: "publish" | "archive" | "delete") => {
    if (operation === "archive" && !window.confirm("Archiver cet asset ?")) return;
    if (operation === "delete" && !window.confirm("Supprimer définitivement ce brouillon et son fichier distant ?")) return;
    const request = operation === "delete" ? () => adminApi(`/assets/${item.id}`, { method: "DELETE" }) : () => adminApi(`/assets/${item.id}/${operation}`, { method: "POST" });
    void action(request, operation === "publish" ? "Asset publié" : operation === "archive" ? "Asset archivé" : "Brouillon et fichier supprimés", refresh);
  };
  return <><PageHeading eyebrow="Médiathèque" title="Assets de jeu" description="Importez, décrivez, publiez et archivez les médias utilisés par les jeux." action={<button className="primary-button" onClick={() => openEditor({ kind: "asset" })} type="button"><Upload />Importer un asset</button>} /><div className="filters asset-tabs"><button className={`filter ${tab === "managed" ? "active" : ""}`} onClick={() => setTab("managed")} type="button">Assets administrés ({data.assets.length})</button><button className={`filter ${tab === "bundled" ? "active" : ""}`} onClick={() => setTab("bundled")} type="button">Bibliothèque Flutter ({bundledAssets.length})</button></div>{tab === "managed" ? data.assets.length === 0 ? <EmptyState title="Aucun asset administré" description="Importez un PNG ou SVG pour démarrer la médiathèque versionnée." action={<button className="primary-button" onClick={() => openEditor({ kind: "asset" })} type="button"><Upload />Importer</button>} /> : <div className="asset-grid">{data.assets.map((item) => <article className="asset-card" key={item.id}><div className="asset-preview"><ManagedAssetImage item={item} /></div><div className="asset-meta"><div><strong>{item.filename}</strong><small>{item.mediaType} | {humanize(item.gameType)}</small></div><StatusPill status={item.status} /><p>{item.altText}</p><div className="card-actions">{item.status === "DRAFT" && <><button className="secondary-button" onClick={() => openEditor({ kind: "asset", value: item })} type="button"><Edit3 />Métadonnées</button><button className="primary-button" onClick={() => mutate(item, "publish")} type="button"><Rocket />Publier</button><button className="icon-button danger" aria-label="Supprimer le brouillon et son fichier" onClick={() => mutate(item, "delete")} type="button"><Trash2 /></button></>}{item.status === "PUBLISHED" && <button className="secondary-button" onClick={() => mutate(item, "archive")} type="button"><Archive />Archiver</button>}</div></div></article>)}</div> : <div className="asset-grid">{bundledAssets.map((item) => <article className="asset-card bundled" key={item}><div className="asset-preview"><img src={gameAsset(item)} alt={`Illustration du jeu ${item.replace(".png", "")}`} /></div><div className="asset-meta"><strong>{item}</strong><small>PNG original importé depuis Flutter</small></div></article>)}</div>}</>;
}

function ManagedAssetImage({ item }: { item: ManagedAsset }) {
  const [source, setSource] = useState(item.url.startsWith("/api/") ? "" : item.url);
  useEffect(() => {
    let objectUrl = "";
    let active = true;
    void authenticatedAssetUrl(item.url).then((url) => {
      if (!active) { if (url.startsWith("blob:")) URL.revokeObjectURL(url); return; }
      objectUrl = url;
      setSource(url);
    }).catch(() => setSource(""));
    return () => { active = false; if (objectUrl.startsWith("blob:")) URL.revokeObjectURL(objectUrl); };
  }, [item.url]);
  return source ? <img src={source} alt={item.altText} /> : <Image aria-label="Aperçu indisponible" />;
}

export function ReleasesPage({ data }: PageProps) {
  const [entity, setEntity] = useState("ALL");
  const entries = data.audit.filter((entry) => entity === "ALL" || entry.entityType === entity);
  return <><PageHeading eyebrow="Traçabilité" title="Versions et journal d'audit" description="Consultez chaque création, modification, publication, archivage et suppression." /><section className="panel panel-pad"><div className="toolbar"><div className="filters">{["ALL", "QUESTION", "BANK", "CONFIGURATION", "ASSET"].map((value) => <button className={`filter ${entity === value ? "active" : ""}`} key={value} onClick={() => setEntity(value)} type="button">{value === "ALL" ? "Toutes" : humanize(value)}</button>)}</div></div>{entries.length === 0 ? <EmptyState title="Journal vide" description="Les actions d'administration apparaîtront ici." /> : <div className="audit-list">{entries.map((entry) => <article className="audit-row" key={entry.id}><span className="activity-icon"><Clock3 /></span><div><strong>{actionLabel(entry.action)}</strong><p>{humanize(entry.entityType)} <code>{entry.entityId.slice(0, 8)}</code></p></div><div className="audit-meta"><time>{formatDate(entry.createdAt)}</time><small>Acteur {entry.actorId.slice(0, 8)}</small></div></article>)}</div>}</section></>;
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
  return value.toLowerCase().replaceAll("_", " ").replace(/(^|\s)\p{L}/gu, (letter) => letter.toUpperCase());
}

function formatValue(value: unknown) {
  if (typeof value === "boolean") return value ? "Activé" : "Désactivé";
  if (Array.isArray(value)) return `${value.length} valeurs`;
  if (value && typeof value === "object") return "Objet configuré";
  return String(value ?? "Non défini");
}
