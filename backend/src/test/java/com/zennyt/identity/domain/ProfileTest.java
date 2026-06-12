package com.zennyt.identity.domain;

import com.zennyt.identity.domain.model.*;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProfileTest {
    @Test
    void validatesAvailabilityAndScores() {
        assertThatThrownBy(() -> Profile.create(1L, null, null, null, null, null,
            0, 101, null, false, null, null, null, null))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("soft skills");

        assertThatThrownBy(() -> Profile.create(1L, null, null, null, null, null,
            0, 80, null, false, AvailabilityType.SELECT_DATE, null, null, null))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("date");
    }

    @Test
    void ownsProfileCollections() {
        Profile profile = Profile.create(1L, "Developer", "Lead Developer",
            WorkplaceType.HYBRID, JobType.FULL_TIME, "Tunis", 3, 80, "About",
            true, AvailabilityType.IMMEDIATELY, null, null, null);

        profile.addSkill(Skill.create("Spring Boot", SkillType.TECHNICAL, 4));
        profile.addPosition(Position.create("Developer", "Example", "Tunis", null,
            LocalDate.of(2023, 1, 1), null, true));

        assertThat(profile.skills()).extracting(Skill::name).containsExactly("Spring Boot");
        assertThat(profile.positions()).extracting(Position::current).containsExactly(true);
    }

    @Test
    void rejectsInvalidPositionDates() {
        assertThatThrownBy(() -> Position.create("Developer", null, null, null,
            LocalDate.of(2025, 1, 1), LocalDate.of(2024, 1, 1), false))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
