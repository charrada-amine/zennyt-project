package com.zennyt.recruitment.domain.vo;

public enum SalaryCurrency {
    EUR, USD, GBP, MAD, TND;

    public static SalaryCurrency fromNullable(String value) {
        return value == null ? EUR : valueOf(value);
    }
}