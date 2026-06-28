package com.zennyt.identity.infrastructure.persistence;

import com.zennyt.identity.domain.model.User;
import com.zennyt.identity.domain.repository.UserRepository;
import com.zennyt.shared.domain.vo.Email;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class UserRepositoryAdapter implements UserRepository {
    private final JpaUserRepository jpa;

    @Override
    public User save(User user) {
        return toDomain(jpa.save(toEntity(user)));
    }

    @Override
    public Optional<User> findById(Long id) {
        return jpa.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return jpa.findByEmailIgnoreCaseAndDeletedAtIsNull(email).map(this::toDomain);
    }

    @Override
    public Optional<User> findByPublicId(UUID publicId) {
        return jpa.findByPublicIdAndDeletedAtIsNull(publicId).map(this::toDomain);
    }

    @Override
    public boolean existsByEmail(String email) {
        return jpa.existsByEmailIgnoreCaseAndDeletedAtIsNull(email);
    }

    private UserEntity toEntity(User user) {
        return new UserEntity(user.id(), user.publicId(), user.firstName(), user.lastName(),
            user.email().value(), user.phoneNumber(), user.passwordHash(), user.role(), user.city(),
            user.country(), user.address(), user.profileImageUrl(), user.profileImagePublicId(),
            user.termsAccepted(), user.emailVerified(), user.active(), user.deletedAt(),
            user.createdAt(), user.updatedAt());
    }

    private User toDomain(UserEntity entity) {
        return User.rehydrate(entity.getId(), entity.getPublicId(), entity.getFirstName(),
            entity.getLastName(), new Email(entity.getEmail()), entity.getPhoneNumber(),
            entity.getPasswordHash(), entity.getRole(), entity.getCity(), entity.getCountry(),
            entity.getAddress(), entity.getProfileImageUrl(), entity.getProfileImagePublicId(),
            entity.isTermsAccepted(), entity.isEmailVerified(), entity.isActive(),
            entity.getDeletedAt(), entity.getCreatedAt(), entity.getUpdatedAt());
    }
}
