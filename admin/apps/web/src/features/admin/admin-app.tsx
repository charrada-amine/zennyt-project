import {
  CircleGauge,
  FileQuestion,
  FolderKanban,
  Image,
  LogOut,
  Menu,
  Rocket,
  Settings2,
  SlidersHorizontal,
  X,
  type LucideIcon,
} from "lucide-react";
import { type FormEvent, useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

import { AdminApiError, loadAdminData, login } from "./admin-api";
import { ErrorState, GameOrbs, LoadingState } from "./admin-components";
import { AdminEditor } from "./admin-editor";
import {
  AssetsPage,
  BanksPage,
  ConfigurationsPage,
  DashboardPage,
  GamePage,
  QuestionsPage,
  ReleasesPage,
} from "./admin-pages";
import { gameById } from "./admin-types";
import type { AdminData, EditorState, GameId, Page } from "./admin-types";

const navItems: Array<{ id: Page; label: string; icon: LucideIcon }> = [
  { id: "dashboard", label: "Vue d'ensemble", icon: CircleGauge },
  { id: "questions", label: "Questions", icon: FileQuestion },
  { id: "banks", label: "Banques et rotation", icon: FolderKanban },
  { id: "settings", label: "Paramètres", icon: Settings2 },
  { id: "modifiers", label: "Modificateurs", icon: SlidersHorizontal },
  { id: "assets", label: "Assets", icon: Image },
  { id: "releases", label: "Versions et audit", icon: Rocket },
];

export function AdminApp() {
  const [authenticated, setAuthenticated] = useState(false);
  const [page, setPage] = useState<Page>("dashboard");
  const [selectedGameId, setSelectedGameId] = useState<GameId | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const [editor, setEditor] = useState<EditorState | null>(null);
  const [data, setData] = useState<AdminData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const logout = useCallback(() => {
    sessionStorage.removeItem("zennyt.admin.auth");
    sessionStorage.removeItem("zennyt.admin.token");
    setAuthenticated(false);
    setData(null);
    setEditor(null);
  }, []);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setData(await loadAdminData());
    } catch (cause) {
      if (cause instanceof AdminApiError && cause.status === 401) logout();
      else setError(cause instanceof Error ? cause.message : "Chargement impossible");
    } finally {
      setLoading(false);
    }
  }, [logout]);

  useEffect(() => {
    if (authenticated) void refresh();
  }, [authenticated, refresh]);

  useEffect(() => {
    setAuthenticated(sessionStorage.getItem("zennyt.admin.auth") === "true");
  }, []);

  if (!authenticated) return <Login onSuccess={() => setAuthenticated(true)} />;

  const navigate = (next: Page) => {
    setPage(next);
    setSelectedGameId(null);
    setMenuOpen(false);
  };
  const openGame = (gameId: GameId) => {
    setSelectedGameId(gameId);
    setPage("game");
    setMenuOpen(false);
  };
  const openGameControl = (gameId: GameId, next: Page) => {
    setSelectedGameId(gameId);
    setPage(next);
    setMenuOpen(false);
  };
  const selectedGame = gameById(selectedGameId);
  const pageLabel = navItems.find((item) => item.id === page)?.label;
  const title = selectedGame
    ? `${selectedGame.label} · ${pageLabel ?? "Contrôles"}`
    : (pageLabel ?? "Game Studio");
  const pageProps = data
    ? {
        data,
        navigate,
        openEditor: setEditor,
        refresh,
        game: selectedGame,
        openGame,
        openGameControl,
      }
    : null;

  return (
    <div className="app">
      {menuOpen && (
        <button
          className="sidebar-scrim"
          aria-label="Fermer le menu"
          onClick={() => setMenuOpen(false)}
          type="button"
        />
      )}
      <aside className={`sidebar ${menuOpen ? "open" : ""}`} aria-label="Navigation principale">
        <div className="brand">
          <img src="/assets/brand/zennyt-logo.svg" alt="Zennyt" />
          <span>Game Studio</span>
          <button
            className="icon-button sidebar-close"
            aria-label="Fermer le menu"
            onClick={() => setMenuOpen(false)}
            type="button"
          >
            <X />
          </button>
        </div>
        <nav className="nav">
          {navItems.map(({ id, label, icon: Icon }) => (
            <button
              key={id}
              className={`nav-button ${page === id || (page === "game" && id === "dashboard") ? "active" : ""}`}
              onClick={() => navigate(id)}
              type="button"
            >
              <Icon />
              {label}
            </button>
          ))}
        </nav>
        <div className="sidebar-foot">
          <div className="connection-state">
            <span />
            API Spring connectée
          </div>
          <button className="nav-button" type="button" onClick={logout}>
            <LogOut />
            Se déconnecter
          </button>
          <small>Accès réservé au rôle ADMIN.</small>
        </div>
      </aside>
      <main className="main">
        <header className="topbar">
          <div className="top-actions">
            <button
              className="icon-button menu-button"
              aria-label="Ouvrir le menu"
              onClick={() => setMenuOpen(true)}
              type="button"
            >
              <Menu />
            </button>
            <div className="topbar-title">{title}</div>
          </div>
          <div className="top-actions">
            <button
              className="sync-button"
              disabled={loading}
              onClick={() => void refresh()}
              type="button"
            >
              {loading ? "Synchronisation..." : "Actualiser"}
            </button>
            <div className="avatar" aria-label="Compte Zennyt Admin">
              ZA
            </div>
          </div>
        </header>
        <div className="content">
          {loading && !data ? (
            <LoadingState />
          ) : error && !data ? (
            <ErrorState message={error} retry={() => void refresh()} />
          ) : pageProps ? (
            <>
              {error && (
                <div className="inline-error">
                  {error}
                  <button onClick={() => void refresh()} type="button">
                    Réessayer
                  </button>
                </div>
              )}
              {page === "dashboard" && <DashboardPage {...pageProps} />}
              {page === "game" && selectedGame && <GamePage {...pageProps} game={selectedGame} />}
              {page === "questions" && <QuestionsPage {...pageProps} />}
              {page === "banks" && <BanksPage {...pageProps} />}
              {page === "settings" && <ConfigurationsPage {...pageProps} kind="SETTINGS" />}
              {page === "modifiers" && <ConfigurationsPage {...pageProps} kind="MODIFIERS" />}
              {page === "assets" && <AssetsPage {...pageProps} />}
              {page === "releases" && <ReleasesPage {...pageProps} />}
            </>
          ) : null}
        </div>
      </main>
      {editor && data && (
        <AdminEditor editor={editor} data={data} close={() => setEditor(null)} refresh={refresh} />
      )}
    </div>
  );
}

function Login({ onSuccess }: { onSuccess: () => void }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoading(true);
    setError(null);
    const values = new FormData(event.currentTarget);
    try {
      await login(String(values.get("email")), String(values.get("password")));
      onSuccess();
    } catch (cause) {
      const message = cause instanceof Error ? cause.message : "Connexion impossible";
      setError(message);
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };
  return (
    <div className="login">
      <section className="login-visual" aria-label="Univers des jeux Zennyt">
        <img className="wordmark" src="/assets/brand/zennyt-logo.svg" alt="Zennyt" />
        <div className="login-message">
          <p className="eyebrow">Game Studio</p>
          <h1>Pilotez chaque expérience de jeu.</h1>
          <p>Contenu, rotations, paramètres et médias dans une console reliée au backend Spring.</p>
        </div>
        <div className="splash-art" aria-hidden="true">
          <GameOrbs />
        </div>
      </section>
      <section className="login-form-wrap">
        <form className="login-form" onSubmit={submit}>
          <img className="mobile-logo" src="/assets/brand/zennyt-logo.svg" alt="Zennyt" />
          <p className="eyebrow">Administration sécurisée</p>
          <h2>Bienvenue</h2>
          <p>Connectez-vous avec un compte disposant du rôle administrateur.</p>
          {error && (
            <div className="form-error" role="alert">
              {error}
            </div>
          )}
          <label>
            Adresse e-mail
            <input className="field" type="email" name="email" autoComplete="email" required />
          </label>
          <label>
            Mot de passe
            <input
              className="field"
              type="password"
              name="password"
              autoComplete="current-password"
              required
            />
          </label>
          <button className="primary-button" type="submit" disabled={loading}>
            {loading ? "Connexion..." : "Se connecter"}
          </button>
        </form>
      </section>
    </div>
  );
}
