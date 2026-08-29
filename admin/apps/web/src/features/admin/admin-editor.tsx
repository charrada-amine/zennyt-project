import { ArrowDown, ArrowUp, Plus, Save, Trash2, X } from "lucide-react";
import { type FormEvent, type ReactNode, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import { adminApi } from "./admin-api";
import { StatusPill } from "./admin-components";
import type { AdminData, Bank, EditorState, Question } from "./admin-types";
import { GAME_TYPES, gamePresentation } from "./admin-types";

export function AdminEditor({ editor, data, close, refresh }: { editor: EditorState; data: AdminData; close: () => void; refresh: () => Promise<void> }) {
  const title = editor.kind === "question" ? editor.value ? "Modifier la question" : "Nouvelle question" : editor.kind === "bank" ? editor.value ? "Modifier la banque" : "Nouvelle banque" : editor.kind === "bank-items" ? `Composer ${editor.value.name}` : editor.kind === "configuration" ? editor.value ? "Modifier la configuration" : "Nouvelle configuration" : editor.value ? "Modifier l'asset" : "Importer un asset";
  return (
    <div className="drawer-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) close(); }}>
      <aside className={`drawer ${editor.kind === "bank-items" ? "drawer-wide" : ""}`} aria-modal="true" aria-label={title}>
        <div className="drawer-head"><div><p className="eyebrow">Gestion versionnée</p><h2>{title}</h2></div><button className="icon-button" aria-label="Fermer" onClick={close} type="button"><X /></button></div>
        {editor.kind === "question" && <QuestionForm value={editor.value} close={close} refresh={refresh} />}
        {editor.kind === "bank" && <BankForm value={editor.value} banks={data.banks} close={close} refresh={refresh} />}
        {editor.kind === "bank-items" && <BankComposer bank={editor.value} questions={data.questions} close={close} refresh={refresh} />}
        {editor.kind === "configuration" && <ConfigurationForm kind={editor.configurationKind} value={editor.value} close={close} refresh={refresh} />}
        {editor.kind === "asset" && <AssetForm value={editor.value} close={close} refresh={refresh} />}
      </aside>
    </div>
  );
}

function useSubmit(close: () => void, refresh: () => Promise<void>) {
  const [saving, setSaving] = useState(false);
  const submit = async (request: () => Promise<unknown>, message: string) => {
    setSaving(true);
    try {
      await request();
      await refresh();
      toast.success(message);
      close();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Enregistrement impossible");
    } finally {
      setSaving(false);
    }
  };
  return { saving, submit };
}

function DrawerActions({ saving, close, label = "Enregistrer" }: { saving: boolean; close: () => void; label?: string }) {
  return <div className="drawer-actions"><button className="primary-button" disabled={saving} type="submit"><Save />{saving ? "Enregistrement..." : label}</button><button className="secondary-button" onClick={close} type="button">Annuler</button></div>;
}

function QuestionForm({ value, close, refresh }: { value?: Question; close: () => void; refresh: () => Promise<void> }) {
  const { saving, submit } = useSubmit(close, refresh);
  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    let payload: Record<string, unknown>;
    try { payload = JSON.parse(String(form.get("payload"))) as Record<string, unknown>; }
    catch { toast.error("Le payload doit être un objet JSON valide"); return; }
    const body = JSON.stringify({ externalCode: form.get("externalCode"), contentType: form.get("contentType"), prompt: form.get("prompt"), payload });
    void submit(() => adminApi(value ? `/questions/${value.id}` : "/questions", { method: value ? "PUT" : "POST", body }), value ? "Question modifiée" : "Brouillon créé");
  };
  return <form onSubmit={onSubmit}><Field label="Jeu"><select className="field" name="contentType" defaultValue={value?.contentType ?? "DECISION_SCENARIO"}><option value="DECISION_SCENARIO">Je Décide</option><option value="EMOTIONAL_RADAR_SCENE">Emotional Radar</option></select></Field><Field label="Code interne" helper="Identifiant stable utilisé pour retrouver les versions."><input className="field" name="externalCode" defaultValue={value?.externalCode} placeholder="DEC-B-025" maxLength={64} required /></Field><Field label="Scénario"><textarea className="field" name="prompt" defaultValue={value?.prompt} placeholder="Décrivez la situation présentée au joueur" required /></Field><Field label="Données éditoriales JSON" helper="Les clés de score, points, bonus et multiplicateurs sont refusées par le serveur."><textarea className="field code-field" name="payload" defaultValue={JSON.stringify(value?.payload ?? {}, null, 2)} spellCheck={false} required /></Field><DrawerActions saving={saving} close={close} /></form>;
}

function BankForm({ value, banks, close, refresh }: { value?: Bank; banks: Bank[]; close: () => void; refresh: () => Promise<void> }) {
  const { saving, submit } = useSubmit(close, refresh);
  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const body = value ? JSON.stringify({ name: form.get("name"), rotationWeight: Number(form.get("rotationWeight")) }) : JSON.stringify({ code: form.get("code"), name: form.get("name"), contentType: form.get("contentType"), rotationWeight: Number(form.get("rotationWeight")), sourceBankId: form.get("sourceBankId") || null });
    void submit(() => adminApi(value ? `/banks/${value.id}` : "/banks", { method: value ? "PUT" : "POST", body }), value ? "Banque modifiée" : "Banque créée");
  };
  return <form onSubmit={onSubmit}>{!value && <><Field label="Jeu"><select className="field" name="contentType"><option value="DECISION_SCENARIO">Je Décide</option><option value="EMOTIONAL_RADAR_SCENE">Emotional Radar</option></select></Field><Field label="Code de banque" helper="Majuscules, chiffres, tirets et underscores uniquement."><input className="field" name="code" pattern="[A-Z0-9_-]+" placeholder="DECISION_FORM_B" required /></Field></>}<Field label="Nom"><input className="field" name="name" defaultValue={value?.name} placeholder="Je Décide - Forme B" maxLength={120} required /></Field>{!value && <Field label="Cloner une version existante"><select className="field" name="sourceBankId"><option value="">Commencer avec une banque vide</option>{banks.map((bank) => <option value={bank.id} key={bank.id}>{bank.name} v{bank.version} ({bank.itemCount})</option>)}</select></Field>}<Field label="Poids de rotation (%)" helper="Répartition appliquée aux nouvelles sessions."><input className="field" type="number" name="rotationWeight" min="0" max="100" defaultValue={value?.rotationWeight ?? 0} required /></Field><DrawerActions saving={saving} close={close} /></form>;
}

function BankComposer({ bank, questions, close, refresh }: { bank: Bank; questions: Question[]; close: () => void; refresh: () => Promise<void> }) {
  const [selected, setSelected] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState("");
  const { saving, submit } = useSubmit(close, refresh);
  useEffect(() => {
    adminApi<{ questionIds: string[] }>(`/banks/${bank.id}/items`).then((response) => setSelected(response.questionIds)).catch((error: unknown) => toast.error(error instanceof Error ? error.message : "Composition indisponible")).finally(() => setLoading(false));
  }, [bank.id]);
  const questionById = useMemo(() => new Map(questions.map((question) => [question.id, question])), [questions]);
  const selectedIds = useMemo(() => new Set(selected), [selected]);
  const available = useMemo(() => questions.filter((question) => question.contentType === bank.contentType && question.status !== "ARCHIVED" && !selectedIds.has(question.id) && `${question.externalCode} ${question.prompt}`.toLowerCase().includes(query.toLowerCase())), [bank.contentType, query, questions, selectedIds]);
  const selectedQuestions = selected.map((id) => questionById.get(id)).filter((question): question is Question => Boolean(question));
  const move = (index: number, direction: -1 | 1) => setSelected((ids) => { const next = [...ids]; const destination = index + direction; if (destination < 0 || destination >= next.length) return ids; [next[index], next[destination]] = [next[destination]!, next[index]!]; return next; });
  if (loading) return <div className="composer-loading">Chargement de la composition...</div>;
  return <form onSubmit={(event) => { event.preventDefault(); void submit(() => adminApi(`/banks/${bank.id}/items`, { method: "PUT", body: JSON.stringify({ questionIds: selected }) }), "Composition enregistrée"); }}><div className="composer-summary"><div><span>Jeu</span><strong>{gamePresentation(bank.contentType).label}</strong></div><div><span>Questions</span><strong>{selected.length}</strong></div><div><span>Rotation</span><strong>{bank.rotationWeight}%</strong></div><StatusPill status={bank.status} /></div><div className="composer-grid"><section><h3>Ordre de jeu</h3>{selectedQuestions.length === 0 ? <p className="composer-empty">Ajoutez des questions depuis le catalogue.</p> : <ol className="composer-list">{selectedQuestions.map((question, index) => <li key={question.id}><span className="position">{index + 1}</span><div><strong>{question.externalCode}</strong><small>{question.prompt}</small></div><div className="composer-actions"><button type="button" aria-label="Monter" onClick={() => move(index, -1)} disabled={index === 0}><ArrowUp /></button><button type="button" aria-label="Descendre" onClick={() => move(index, 1)} disabled={index === selected.length - 1}><ArrowDown /></button><button type="button" aria-label="Retirer" onClick={() => setSelected((ids) => ids.filter((id) => id !== question.id))}><Trash2 /></button></div></li>)}</ol>}</section><section><h3>Catalogue disponible</h3><input className="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Rechercher une question" aria-label="Rechercher dans le catalogue" /><div className="catalog-list">{available.slice(0, 80).map((question) => <button key={question.id} onClick={() => setSelected((ids) => [...ids, question.id])} type="button"><Plus /><div><strong>{question.externalCode}</strong><span>{question.prompt}</span></div></button>)}</div></section></div><DrawerActions saving={saving} close={close} label="Enregistrer la composition" /></form>;
}

function ConfigurationForm({ kind, value, close, refresh }: { kind: "SETTINGS" | "MODIFIERS"; value?: import("./admin-types").Configuration; close: () => void; refresh: () => Promise<void> }) {
  const { saving, submit } = useSubmit(close, refresh);
  const defaultValues = kind === "SETTINGS" ? { sceneCount: 12, orderMode: "SHUFFLED", helpEnabled: true, reducedMotionDefault: false } : { compactMode: false, answerFeedback: true, transitionDurationMs: 450 };
  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault(); const form = new FormData(event.currentTarget); let values: Record<string, unknown>;
    try { values = JSON.parse(String(form.get("values"))) as Record<string, unknown>; } catch { toast.error("Les valeurs doivent former un objet JSON valide"); return; }
    const body = JSON.stringify({ gameType: form.get("gameType"), kind, values });
    void submit(() => adminApi(value ? `/configurations/${value.id}` : "/configurations", { method: value ? "PUT" : "POST", body }), value ? "Configuration modifiée" : "Configuration créée");
  };
  return <form onSubmit={onSubmit}><Field label="Jeu"><select className="field" name="gameType" defaultValue={value?.gameType ?? (kind === "SETTINGS" ? "EMOTIONAL_REGULATION" : "DECISION")}>{GAME_TYPES.map((game) => <option value={game} key={game}>{game.replaceAll("_", " ")}</option>)}</select></Field><Field label="Valeurs JSON" helper="Vous pouvez gérer tout paramètre non lié au score. Le serveur bloque les clés protégées."><textarea className="field code-field configuration-json" name="values" defaultValue={JSON.stringify(value?.values ?? defaultValues, null, 2)} spellCheck={false} required /></Field><DrawerActions saving={saving} close={close} /></form>;
}

function AssetForm({ value, close, refresh }: { value?: import("./admin-types").ManagedAsset; close: () => void; refresh: () => Promise<void> }) {
  const { saving, submit } = useSubmit(close, refresh);
  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault(); const form = new FormData(event.currentTarget);
    if (value) { void submit(() => adminApi(`/assets/${value.id}`, { method: "PUT", body: JSON.stringify({ gameType: form.get("gameType"), altText: form.get("altText") }) }), "Métadonnées modifiées"); return; }
    const file = form.get("file"); if (!(file instanceof File) || file.size === 0) { toast.error("Sélectionnez un fichier"); return; }
    const upload = new FormData(); upload.set("file", file); upload.set("gameType", String(form.get("gameType"))); upload.set("altText", String(form.get("altText")));
    void submit(() => adminApi("/assets", { method: "POST", body: upload }), "Asset importé en brouillon");
  };
  return <form onSubmit={onSubmit}>{!value && <Field label="Fichier PNG ou SVG" helper="Taille maximale: 5 Mo."><input className="field file-field" type="file" name="file" accept="image/png,image/svg+xml" required /></Field>}<Field label="Jeu"><select className="field" name="gameType" defaultValue={value?.gameType ?? "DECISION"}>{GAME_TYPES.map((game) => <option value={game} key={game}>{game.replaceAll("_", " ")}</option>)}<option value="SHARED_GAMES">Commun aux jeux</option></select></Field><Field label="Texte alternatif" helper="Décrivez le sens de l'image, pas seulement son apparence."><textarea className="field" name="altText" defaultValue={value?.altText} placeholder="Illustration de..." required /></Field><DrawerActions saving={saving} close={close} label={value ? "Enregistrer les métadonnées" : "Importer le brouillon"} /></form>;
}

function Field({ label, helper, children }: { label: string; helper?: string; children: ReactNode }) {
  return <label className="form-field"><span>{label}</span>{children}{helper && <small>{helper}</small>}</label>;
}
