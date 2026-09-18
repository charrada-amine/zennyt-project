package com.zennyt.games.domain.vo;

/**
 * Une case ouverte : laquelle, et quand. La couleur révélée n'est PAS transmise —
 * le serveur la connaît et ne croit pas le client sur ce point.
 */
public record IstBoxOpening(int boxIndex, long timestampMs) {
}
