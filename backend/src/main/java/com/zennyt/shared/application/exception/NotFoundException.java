package com.zennyt.shared.application.exception;

public class NotFoundException extends RuntimeException {
    private final String code;

    public NotFoundException(String message) {
        this(null, message);
    }

    public NotFoundException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String code() { return code; }
}
