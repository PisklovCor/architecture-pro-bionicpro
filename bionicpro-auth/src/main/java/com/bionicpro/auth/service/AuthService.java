package com.bionicpro.auth.service;

import com.bionicpro.auth.model.SessionData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    
    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);
    private final KeycloakService keycloakService;
    private final SessionService sessionService;

    public AuthService(KeycloakService keycloakService, SessionService sessionService) {
        this.keycloakService = keycloakService;
        this.sessionService = sessionService;
    }

    public String authenticate(String code, String codeVerifier, String redirectUri) {
        try {
            KeycloakService.TokenResponse tokenResponse = keycloakService.exchangeCodeForTokens(
                    code, codeVerifier, redirectUri);
            
            return sessionService.createSession(
                    tokenResponse.getAccessToken(),
                    tokenResponse.getRefreshToken()
            );
        } catch (Exception e) {
            logger.error("Authentication failed", e);
            throw new RuntimeException("Authentication failed", e);
        }
    }

    public String getValidAccessToken(String sessionId) {
        SessionData sessionData = sessionService.getSession(sessionId);
        if (sessionData == null) {
            throw new RuntimeException("Session not found");
        }

        if (sessionService.isAccessTokenExpired(sessionData)) {
            return refreshAccessToken(sessionId, sessionData);
        }

        if (sessionService.shouldRotateSession(sessionData)) {
            return rotateSessionAndGetToken(sessionId, sessionData);
        }

        return sessionData.getAccessToken();
    }

    private String refreshAccessToken(String sessionId, SessionData sessionData) {
        try {
            KeycloakService.TokenResponse tokenResponse = keycloakService.refreshToken(
                    sessionData.getRefreshToken());
            
            sessionService.updateSession(sessionId,
                    tokenResponse.getAccessToken(),
                    tokenResponse.getRefreshToken());
            
            return tokenResponse.getAccessToken();
        } catch (Exception e) {
            logger.error("Failed to refresh access token", e);
            throw new RuntimeException("Failed to refresh token", e);
        }
    }

    private String rotateSessionAndGetToken(String sessionId, SessionData sessionData) {
        try {
            KeycloakService.TokenResponse tokenResponse = keycloakService.refreshToken(
                    sessionData.getRefreshToken());
            
            String newSessionId = sessionService.rotateSession(sessionId,
                    tokenResponse.getAccessToken(),
                    tokenResponse.getRefreshToken());
            
            logger.debug("Rotated session from {} to {}", sessionId, newSessionId);
            return tokenResponse.getAccessToken();
        } catch (Exception e) {
            logger.error("Failed to rotate session", e);
            return sessionData.getAccessToken();
        }
    }

    public String refreshSession(String sessionId) {
        SessionData sessionData = sessionService.getSession(sessionId);
        if (sessionData == null) {
            throw new RuntimeException("Session not found");
        }

        try {
            KeycloakService.TokenResponse tokenResponse = keycloakService.refreshToken(
                    sessionData.getRefreshToken());
            
            return sessionService.rotateSession(sessionId,
                    tokenResponse.getAccessToken(),
                    tokenResponse.getRefreshToken());
        } catch (Exception e) {
            logger.error("Failed to refresh session", e);
            throw new RuntimeException("Failed to refresh session", e);
        }
    }
}

