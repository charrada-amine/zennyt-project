package com.zennyt.identity.infrastructure.security;

import com.zennyt.identity.domain.model.User;
import com.zennyt.identity.domain.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DatabaseUserDetailsService implements UserDetailsService {
    private final UserRepository users;

    @Override
    public UserDetails loadUserByUsername(String username) {
        User user = users.findByEmail(username)
            .orElseThrow(() -> new UsernameNotFoundException("Utilisateur introuvable"));
        return org.springframework.security.core.userdetails.User.withUsername(user.email().value())
            .password(user.passwordHash())
            .roles(user.role().name())
            .disabled(!user.active())
            .build();
    }
}
