package com.zennyt.identity.domain.model;

public enum Role {
    CANDIDATE,
    STUDENT,
    RECRUITER,
    ADMIN;

    public boolean hasProfessionalProfile() {
        return this == CANDIDATE || this == STUDENT;
    }
}
