package com.zennyt.games.domain.vo;

/** Marker interface for raw game metrics submitted by clients. */
public sealed interface GameMetrics permits PlanifikMetrics, MoveFastMetrics, PrevisionPuzzleMetrics {
}
