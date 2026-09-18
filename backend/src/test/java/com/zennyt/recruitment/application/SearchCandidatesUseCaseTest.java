package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.usecase.SearchCandidatesUseCase;
import com.zennyt.recruitment.domain.repository.RecruitmentActorRepository;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class SearchCandidatesUseCaseTest {
    @ParameterizedTest
    @CsvSource({"-1,0,0,1", "0,101,0,100", "2,20,2,20",
        "-2147483648,-2147483648,0,1", "2147483647,2147483647,2147483647,100"})
    void boundsPagination(int page, int size, int expectedPage, int expectedSize) {
        var actors = mock(RecruitmentActorRepository.class);
        new SearchCandidatesUseCase(actors).execute("Ada", "Paris", page, size);
        verify(actors).searchCandidates("Ada", "Paris", expectedPage, expectedSize);
    }
}
