package com.zennyt.recruitment.application.exception;

/** Échec temporaire du fournisseur IA utilisé par Recruitment. */
public class UpstreamServiceException extends RuntimeException {
    public UpstreamServiceException(String message) { super(message); }
    public UpstreamServiceException(String message, Throwable cause) { super(message, cause); }
}
