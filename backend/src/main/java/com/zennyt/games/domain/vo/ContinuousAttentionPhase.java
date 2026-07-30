package com.zennyt.games.domain.vo;

import com.zennyt.games.domain.config.ContinuousAttentionConfig;

/** Phases du protocole Long Rosvold X/AX. */
public enum ContinuousAttentionPhase {
    X_PRACTICE(false, true),
    X_TEST(false, false),
    AX_PRACTICE(true, true),
    AX_TEST(true, false);

    private final boolean ax;
    private final boolean practice;

    ContinuousAttentionPhase(boolean ax, boolean practice) {
        this.ax = ax;
        this.practice = practice;
    }

    public boolean isAx() {
        return ax;
    }

    public boolean isPractice() {
        return practice;
    }

    public boolean isTest() {
        return !practice;
    }

    public int expectedBlockCount() {
        return practice
            ? ContinuousAttentionConfig.PRACTICE_BLOCK_COUNT
            : ContinuousAttentionConfig.TEST_BLOCK_COUNT;
    }
}
