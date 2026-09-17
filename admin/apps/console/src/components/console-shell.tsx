import { Link, useRouterState } from "@tanstack/react-router";
import {
  BarChart3,
  CircleGauge,
  FlaskConical,
  Gift,
  LogOut,
  MailPlus,
  Menu,
  ShieldAlert,
  Users,
  X,
  type LucideIcon,
} from "lucide-react";
import { type ReactNode, useEffect, useState } from "react";

import { LoginScreen } from "@/features/auth/login-screen";
import { hasConsoleSession, signOut } from "@/features/auth/console-auth";
/** PROVISOIRE — le compteur de la pastille viendra de l'API de modération. */
import { OPEN_REPORTS } from "@/fixtures/moderation-fixtures";
import { DEMO_MODE } from "@/lib/data-source";

interface NavItem {
  to: string;
  label: string;
  icon: LucideIcon;
  count?: number;
}

const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "Vue d'ensemble", icon: CircleGauge },
  { to: "/users", label: "Utilisateurs", icon: Users },
  { to: "/invites", label: "Invitations", icon: MailPlus },
  { to: "/referrals", label: "Parrainage", icon: Gift },
  { to: "/moderation", label: "Modération", icon: ShieldAlert, count: OPEN_REPORTS },
  { to: "/analytics", label: "Analytics", icon: BarChart3 },
];

function titleFor(pathname: string) {
  if (pathname.startsWith("/users/")) return "Fiche utilisateur";
  if (pathname.startsWith("/moderation/")) return "Signalement";
  const match = NAV_ITEMS.find((item) => item.to === pathname);
  return match?.label ?? "Console plateforme";
}

export function ConsoleShell({ children }: { children: ReactNode }) {
  const [authenticated, setAuthenticated] = useState<boolean | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const pathname = useRouterState({ select: (state) => state.location.pathname });

  // sessionStorage n'existe pas au rendu serveur : on ne décide qu'au montage.
  useEffect(() => {
    setAuthenticated(hasConsoleSession());
  }, []);

  useEffect(() => {
    setMenuOpen(false);
  }, [pathname]);

  if (authenticated === null) return null;
  if (!authenticated) return <LoginScreen onSuccess={() => setAuthenticated(true)} />;

  const logout = () => {
    signOut();
    setAuthenticated(false);
  };

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
          <span>Platform Console</span>
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
          {NAV_ITEMS.map(({ to, label, icon: Icon, count }) => (
            <Link
              key={to}
              to={to}
              className="nav-button"
              activeProps={{ className: "nav-button active" }}
              activeOptions={{ exact: to === "/" }}
            >
              <Icon />
              {label}
              {count ? <span className="nav-count">{count}</span> : null}
            </Link>
          ))}
        </nav>
        <div className="sidebar-foot">
          <div className="connection-state">
            <span />
            {DEMO_MODE ? "Fixtures locales" : "API Spring connectée"}
          </div>
          <button className="nav-button" type="button" onClick={logout}>
            <LogOut />
            Déconnexion
          </button>
        </div>
      </aside>
      <div className="main">
        <header className="topbar">
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <button
              className="icon-button menu-button"
              aria-label="Ouvrir le menu"
              onClick={() => setMenuOpen(true)}
              type="button"
            >
              <Menu />
            </button>
            <span className="topbar-title">{titleFor(pathname)}</span>
          </div>
          <div className="top-actions">
            {DEMO_MODE && (
              <span className="demo-badge">
                <FlaskConical />
                Mode démonstration
              </span>
            )}
            <span className="avatar">ZN</span>
          </div>
        </header>
        <main className="content">{children}</main>
      </div>
    </div>
  );
}
