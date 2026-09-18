/**
 * Graphiques SVG écrits à la main — aucune dépendance ajoutée au workspace.
 *
 * Le langage visuel de la console est déjà entièrement fait main (voir
 * index.css) : les tokens --indigo / --magenta / --panel s'appliquent
 * directement, et une librairie apporterait ses propres opinions graphiques
 * pour quatre formes de graphiques. Si un jour il faut du survol riche, du
 * zoom ou du brushing, seul ce fichier change.
 */

import { formatNumber, formatPercent } from "@/lib/format";

export const SERIES_COLORS = ["#4e46e8", "#d12e7d", "#14884a", "#d67e13"] as const;

export interface Series {
  label: string;
  color: string;
  points: number[];
}

const VIEW_WIDTH = 720;
const VIEW_HEIGHT = 240;
const PADDING = { top: 12, right: 12, bottom: 26, left: 44 };

function niceCeiling(value: number) {
  if (value <= 0) return 1;
  const magnitude = 10 ** Math.floor(Math.log10(value));
  return Math.ceil(value / magnitude) * magnitude;
}

export function LineChart({
  series,
  labels,
  ariaLabel,
}: {
  series: Series[];
  labels: string[];
  ariaLabel: string;
}) {
  const length = Math.max(...series.map((entry) => entry.points.length), 0);
  if (length < 2) return <div className="chart-empty">Pas assez de points à afficher</div>;

  const max = niceCeiling(Math.max(...series.flatMap((entry) => entry.points), 1));
  const plotWidth = VIEW_WIDTH - PADDING.left - PADDING.right;
  const plotHeight = VIEW_HEIGHT - PADDING.top - PADDING.bottom;
  const x = (index: number) => PADDING.left + (index / (length - 1)) * plotWidth;
  const y = (value: number) => PADDING.top + plotHeight - (value / max) * plotHeight;
  const gridValues = [0, 0.25, 0.5, 0.75, 1].map((ratio) => max * ratio);
  // Au plus six étiquettes d'abscisse, sinon elles se chevauchent.
  const labelStep = Math.max(1, Math.ceil(length / 6));

  return (
    <>
      <svg viewBox={`0 0 ${VIEW_WIDTH} ${VIEW_HEIGHT}`} role="img" aria-label={ariaLabel}>
        {gridValues.map((value) => (
          <g key={value}>
            <line
              x1={PADDING.left}
              x2={VIEW_WIDTH - PADDING.right}
              y1={y(value)}
              y2={y(value)}
              stroke="#edf0f7"
              strokeWidth={1}
            />
            <text
              x={PADDING.left - 9}
              y={y(value) + 4}
              textAnchor="end"
              fontSize={11}
              fill="#687493"
            >
              {formatNumber(Math.round(value))}
            </text>
          </g>
        ))}
        {labels.map((label, index) =>
          index % labelStep === 0 || index === length - 1 ? (
            <text
              key={label + String(index)}
              x={x(index)}
              y={VIEW_HEIGHT - 6}
              textAnchor="middle"
              fontSize={11}
              fill="#687493"
            >
              {label}
            </text>
          ) : null,
        )}
        {series.map((entry) => (
          <polyline
            key={entry.label}
            fill="none"
            stroke={entry.color}
            strokeWidth={2.5}
            strokeLinecap="round"
            strokeLinejoin="round"
            points={entry.points.map((value, index) => `${x(index)},${y(value)}`).join(" ")}
          />
        ))}
      </svg>
      <Legend series={series} />
    </>
  );
}

export function Legend({ series }: { series: Series[] }) {
  return (
    <div className="chart-legend">
      {series.map((entry) => (
        <span key={entry.label}>
          <i style={{ background: entry.color }} />
          {entry.label}
        </span>
      ))}
    </div>
  );
}

export interface FunnelStep {
  label: string;
  value: number;
}

export function Funnel({ steps }: { steps: FunnelStep[] }) {
  const first = steps[0]?.value ?? 0;
  if (first <= 0) return <div className="chart-empty">Aucune donnée d'entonnoir</div>;
  return (
    <div className="funnel">
      {steps.map((step) => {
        const ratio = (step.value / first) * 100;
        return (
          <div className="funnel-step" key={step.label}>
            <span>{step.label}</span>
            <div className="funnel-bar">
              <i style={{ width: `${Math.max(ratio, 1.5)}%` }} />
            </div>
            <span>{formatNumber(step.value)}</span>
          </div>
        );
      })}
      <p style={{ margin: "6px 0 0", color: "var(--muted)", fontSize: 12 }}>
        Conversion bout en bout&nbsp;:{" "}
        <strong style={{ color: "var(--navy)" }}>
          {formatPercent(((steps[steps.length - 1]?.value ?? 0) / first) * 100)}
        </strong>
      </p>
    </div>
  );
}

export interface BarDatum {
  label: string;
  value: number;
  hint?: string;
}

export function BarList({ data, color }: { data: BarDatum[]; color?: string }) {
  const max = Math.max(...data.map((item) => item.value), 1);
  if (data.length === 0) return <div className="chart-empty">Aucune donnée</div>;
  return (
    <div className="bar-list">
      {data.map((item) => (
        <div className="bar-row" key={item.label}>
          <span title={item.label}>{item.label}</span>
          <div className="bar-track">
            <i
              style={{
                width: `${Math.max((item.value / max) * 100, 2)}%`,
                background: color ?? "var(--magenta)",
              }}
            />
          </div>
          <span>{item.hint ?? formatNumber(item.value)}</span>
        </div>
      ))}
    </div>
  );
}

export interface DonutSlice {
  label: string;
  value: number;
  color: string;
}

export function Donut({ slices, caption }: { slices: DonutSlice[]; caption: string }) {
  const total = slices.reduce((sum, slice) => sum + slice.value, 0);
  if (total <= 0) return <div className="chart-empty">Aucune donnée</div>;

  const radius = 62;
  const circumference = 2 * Math.PI * radius;
  let consumed = 0;

  return (
    <>
      <svg viewBox="0 0 200 160" role="img" aria-label={caption} style={{ maxHeight: 190 }}>
        <g transform="translate(100 80) rotate(-90)">
          {slices.map((slice) => {
            const fraction = slice.value / total;
            const dash = `${fraction * circumference} ${circumference}`;
            const offset = -consumed * circumference;
            consumed += fraction;
            return (
              <circle
                key={slice.label}
                r={radius}
                fill="none"
                stroke={slice.color}
                strokeWidth={22}
                strokeDasharray={dash}
                strokeDashoffset={offset}
              />
            );
          })}
        </g>
        <text x={100} y={76} textAnchor="middle" fontSize={24} fontWeight={800} fill="#26224d">
          {formatNumber(total)}
        </text>
        <text x={100} y={95} textAnchor="middle" fontSize={11} fill="#687493">
          {caption}
        </text>
      </svg>
      <Legend series={slices.map((slice) => ({ ...slice, points: [] }))} />
    </>
  );
}
