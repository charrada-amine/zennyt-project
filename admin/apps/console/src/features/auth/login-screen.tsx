import { LogIn } from "lucide-react";
import { type FormEvent, useState } from "react";

import { signIn } from "./console-auth";

export function LoginScreen({ onSuccess }: { onSuccess: () => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setPending(true);
    setError(null);
    try {
      await signIn(email, password);
      onSuccess();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Connexion impossible");
    } finally {
      setPending(false);
    }
  };

  return (
    <div className="login">
      <div className="login-visual">
        <img className="wordmark" src="/assets/brand/zennyt-logo.svg" alt="Zennyt" />
        <div className="login-message">
          <h1>Console plateforme</h1>
          <p>
            Utilisateurs, invitations, parrainage, modération et analytics — le pilotage quotidien
            de Zennyt, au même endroit.
          </p>
        </div>
        <div className="login-metrics">
          <div>
            <strong>5</strong>
            <span>ESPACES</span>
          </div>
          <div>
            <strong>ADMIN</strong>
            <span>RÔLE REQUIS</span>
          </div>
          <div>
            <strong>fr-FR</strong>
            <span>INTERFACE</span>
          </div>
        </div>
      </div>
      <div className="login-form-wrap">
        <form className="login-form" onSubmit={submit}>
          <img className="mobile-logo" src="/assets/brand/zennyt-logo.svg" alt="Zennyt" />
          <h2>Connexion</h2>
          <p>Accès réservé aux comptes administrateurs de la plateforme.</p>
          <label>
            E-mail
            <input
              className="field"
              type="email"
              autoComplete="username"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="prenom.nom@zennyt.com"
              required
            />
          </label>
          <label>
            Mot de passe
            <input
              className="field"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
            />
          </label>
          {error && (
            <p role="alert" style={{ color: "var(--danger)", fontSize: 13 }}>
              {error}
            </p>
          )}
          <button className="primary-button" type="submit" disabled={pending}>
            <LogIn />
            {pending ? "Connexion…" : "Se connecter"}
          </button>
          <p className="login-hint">
            <strong>Mode démonstration.</strong> Aucun appel au backend&nbsp;: n'importe quel e-mail
            et mot de passe ouvrent la session. La vérification du rôle ADMIN sera rebranchée en
            même temps que les endpoints <code>/admin/**</code>.
          </p>
        </form>
      </div>
    </div>
  );
}
