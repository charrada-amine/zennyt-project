package com.zennyt.engagement.api.security;

import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.annotation.*;

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@PreAuthorize("isAuthenticated() and @engagementActorPolicy.allowed(authentication.name)")
public @interface EngagementAuthenticated {}
