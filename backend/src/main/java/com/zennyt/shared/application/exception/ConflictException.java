package com.zennyt.shared.application.exception;

import java.util.Map;

public class ConflictException extends RuntimeException {
    private final String code;
    private final Map<String, Object> extra;

    public ConflictException(String message) {
        this(null, message, null);
    }

    public ConflictException(String code, String message) {
        this(code, message, null);
    }

    public ConflictException(String code, String message, Map<String, Object> extra) {
        super(message);
        this.code = code;
        this.extra = extra;
    }

    public String code() { return code; }
    public Map<String, Object> extra() { return extra; }
}
