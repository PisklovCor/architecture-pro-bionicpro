package com.bionicpro.auth.model;

import java.io.Serializable;

public class SessionData implements Serializable {
    private String accessToken;
    private String refreshToken;
    private long createdAt;

    public SessionData() {
    }

    public SessionData(String accessToken, String refreshToken, long createdAt) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.createdAt = createdAt;
    }

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }
}

