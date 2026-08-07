package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.SubmitTestAttemptUseCase;
import com.zennyt.recruitment.domain.event.TestResultCompletedEvent;
import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.model.TestAttempt;
import com.zennyt.recruitment.domain.model.TestResult;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.TestAttemptRepository;
import com.zennyt.recruitment.domain.repository.TestResultRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Verrouille la publication de {@code TestResultCompletedEvent}.
 *
 * <p>Ce cas d'usage n'avait aucun test, et c'est ce qui a laissé passer un défaut
 * silencieux : les événements étaient publiés depuis l'objet renvoyé par le dépôt, qui est
 * une <b>reconstruction</b> ne portant aucun événement. Rien n'était donc jamais publié —
 * ni le recalcul du Fit Score, ni la génération du résumé IA hard skills. Le symptôme
 * était invisible côté Fit Score, parce que le calcul à l'affichage rattrapait le score ;
 * seul le résumé, qui n'a pas de filet équivalent, restait vide indéfiniment.
 */
class SubmitTestAttemptUseCaseTest {

    private static final UUID CANDIDAT = UUID.randomUUID();
    private static final UUID OFFRE = UUID.randomUUID();

    private TestAttemptRepository testAttempts;
    private TestResultRepository testResults;
    private AssessmentRepository assessments;
    private ApplicationEventPublisher events;
    private SubmitTestAttemptUseCase useCase;

    private TestAttempt attempt;
    private List<AssessmentQuestion> questions;

    @BeforeEach
    void setUp() {
        testAttempts = mock(TestAttemptRepository.class);
        testResults = mock(TestResultRepository.class);
        assessments = mock(AssessmentRepository.class);
        events = mock(ApplicationEventPublisher.class);
        useCase = new SubmitTestAttemptUseCase(testAttempts, testResults, assessments, events);

        questions = List.of(
            new AssessmentQuestion("Q1", List.of("a", "b", "c", "d"), 0),
            new AssessmentQuestion("Q2", List.of("a", "b", "c", "d"), 1));
        Assessment assessment = Assessment.createManual(UUID.randomUUID(), "QCM", 900, questions);
        attempt = TestAttempt.start(OFFRE, assessment.id(), CANDIDAT, assessment.questions(), 900);

        when(testAttempts.findById(attempt.id())).thenReturn(Optional.of(attempt));
        when(assessments.findById(assessment.id())).thenReturn(Optional.of(assessment));
        // Le dépôt renvoie une RECONSTRUCTION, comme le vrai adaptateur : c'est exactement
        // ce détail qui rendait la publication silencieusement inopérante.
        when(testResults.save(any())).thenAnswer(invocation -> reconstruire(invocation.getArgument(0)));
    }

    private static TestResult reconstruire(TestResult source) {
        return TestResult.rehydrate(source.id(), source.jobOfferId(), source.hardSkillTestId(),
            source.candidateId(), source.score(), source.percentage(), source.passed(),
            source.answers(), source.startedAt(), source.completedAt(), source.duration(),
            source.status());
    }

    private List<SubmitTestAttemptUseCase.AnswerInput> reponses() {
        return attempt.presentedQuestions().stream()
            .map(presented -> new SubmitTestAttemptUseCase.AnswerInput(presented.questionId(), 0))
            .toList();
    }

    @Test
    void publieLEvenementDeResultatCompleteMemeSiLeDepotRenvoieUneReconstruction() {
        TestResult saved = useCase.execute(CANDIDAT, attempt.id(), reponses());

        var captor = org.mockito.ArgumentCaptor.forClass(TestResultCompletedEvent.class);
        verify(events).publishEvent(captor.capture());
        assertThat(captor.getValue().testResultId()).isEqualTo(saved.id());
        assertThat(captor.getValue().candidateId()).isEqualTo(CANDIDAT);
        assertThat(captor.getValue().jobOfferId()).isEqualTo(OFFRE);
        assertThat(captor.getValue().percentage()).isEqualTo(saved.percentage());
    }

    @Test
    void nePublieQuUneSeuleFois() {
        useCase.execute(CANDIDAT, attempt.id(), reponses());

        verify(events, times(1)).publishEvent(any(TestResultCompletedEvent.class));
    }
}
