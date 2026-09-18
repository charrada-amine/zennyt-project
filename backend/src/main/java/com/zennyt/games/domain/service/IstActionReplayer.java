package com.zennyt.games.domain.service;

import com.zennyt.games.domain.config.IstConfig;
import com.zennyt.games.domain.vo.IstBoxOpening;
import com.zennyt.games.domain.vo.IstColor;
import com.zennyt.games.domain.vo.IstMetrics;
import com.zennyt.games.domain.vo.IstTrialMetric;
import com.zennyt.games.domain.vo.IstTrialReport;

import java.util.ArrayList;
import java.util.List;

/**
 * Rejoue chaque essai contre la grille serveur : couleurs réellement révélées,
 * justesse, P(correct) et points. Le client ne transmet aucune couleur révélée.
 */
public final class IstActionReplayer {

    private final IstPosteriorModel posterior = new IstPosteriorModel();

    public List<IstTrialReport> replay(List<IstLayoutGenerator.Layout> layouts, IstMetrics metrics) {
        if (layouts.size() != IstConfig.TOTAL_TRIAL_COUNT) {
            throw new IllegalStateException("Grilles IST incomplètes");
        }
        List<IstTrialReport> reports = new ArrayList<>(metrics.trials().size());
        for (IstTrialMetric trial : metrics.trials()) {
            IstLayoutGenerator.Layout layout = layouts.get(trial.trialIndex());
            int blueSeen = 0;
            for (IstBoxOpening opening : trial.openings()) {
                if (layout.boxes().get(opening.boxIndex()) == IstColor.BLUE) blueSeen++;
            }
            int opened = trial.openings().size();
            int orangeSeen = opened - blueSeen;
            boolean correct = trial.chosenColor() == layout.majorityColor();
            reports.add(new IstTrialReport(trial.trialIndex(), trial.phase(), trial.condition(),
                layout.majorityColor(), trial.chosenColor(), correct, opened, blueSeen, orangeSeen,
                DecisionBehavioralStatistics.round4(
                    posterior.pCorrect(blueSeen, orangeSeen, trial.chosenColor())),
                IstConfig.trialPoints(trial.condition(), opened, correct),
                trial.decisionTimestampMs(), trial.confidence()));
        }
        return List.copyOf(reports);
    }
}
