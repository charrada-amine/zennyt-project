/** Formatage fr-FR partagé par toutes les pages de la console. */

const numberFormat = new Intl.NumberFormat("fr-FR");
const dateFormat = new Intl.DateTimeFormat("fr-FR", {
  day: "2-digit",
  month: "short",
  year: "numeric",
});
const dateTimeFormat = new Intl.DateTimeFormat("fr-FR", {
  day: "2-digit",
  month: "short",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});

export function formatNumber(value: number) {
  return numberFormat.format(value);
}

export function formatPercent(value: number, fractionDigits = 1) {
  return `${value.toFixed(fractionDigits).replace(".", ",")} %`;
}

export function formatCurrency(value: number) {
  return `${numberFormat.format(value)} €`;
}

export function formatDate(iso: string) {
  return dateFormat.format(new Date(iso));
}

export function formatDateTime(iso: string) {
  return dateTimeFormat.format(new Date(iso));
}

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/** « il y a 3 j », « dans 5 j » — volontairement court pour tenir dans un tableau. */
export function relativeTime(iso: string, now: number = Date.now()) {
  const delta = new Date(iso).getTime() - now;
  const ahead = delta > 0;
  const abs = Math.abs(delta);
  const render = (value: number, unit: string) =>
    ahead ? `dans ${value} ${unit}` : `il y a ${value} ${unit}`;

  if (abs < MINUTE) return "à l'instant";
  if (abs < HOUR) return render(Math.round(abs / MINUTE), "min");
  if (abs < DAY) return render(Math.round(abs / HOUR), "h");
  if (abs < 30 * DAY) return render(Math.round(abs / DAY), "j");
  if (abs < 365 * DAY) return render(Math.round(abs / (30 * DAY)), "mois");
  return render(Math.round(abs / (365 * DAY)), "ans");
}

/** Initiales pour les avatars sans photo. */
export function initials(fullName: string) {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  const first = parts[0]?.[0] ?? "";
  const last = parts.length > 1 ? (parts[parts.length - 1]?.[0] ?? "") : "";
  return `${first}${last}`.toUpperCase();
}
