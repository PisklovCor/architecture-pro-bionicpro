package com.bionicpro.auth.service;

import com.bionicpro.auth.config.KeycloakProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.io.entity.StringEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Service
public class KeycloakService {
    
    private static final Logger logger = LoggerFactory.getLogger(KeycloakService.class);
    private final KeycloakProperties keycloakProperties;
    private final ObjectMapper objectMapper;
    private final CloseableHttpClient httpClient;

    public KeycloakService(KeycloakProperties keycloakProperties) {
        this.keycloakProperties = keycloakProperties;
        this.objectMapper = new ObjectMapper();
        this.httpClient = HttpClients.createDefault();
    }

    public TokenResponse exchangeCodeForTokens(String code, String codeVerifier, String redirectUri) throws IOException {
        String tokenUrl = String.format("%s/realms/%s/protocol/openid-connect/token",
                keycloakProperties.getUrl(), keycloakProperties.getRealm());

        HttpPost request = new HttpPost(tokenUrl);
        request.setHeader("Content-Type", "application/x-www-form-urlencoded");

        String body = String.format(
                "grant_type=authorization_code&client_id=%s&code=%s&redirect_uri=%s&code_verifier=%s",
                keycloakProperties.getClientId(), code, redirectUri, codeVerifier);

        request.setEntity(new StringEntity(body, StandardCharsets.UTF_8));

        try (CloseableHttpResponse response = httpClient.execute(request)) {
            if (response.getCode() != 200) {
                logger.error("Failed to exchange code for tokens: {}", response.getCode());
                throw new RuntimeException("Failed to exchange code for tokens");
            }

            JsonNode jsonNode = objectMapper.readTree(response.getEntity().getContent());
            return new TokenResponse(
                    jsonNode.get("access_token").asText(),
                    jsonNode.get("refresh_token").asText(),
                    jsonNode.get("expires_in").asInt()
            );
        }
    }

    public TokenResponse refreshToken(String refreshToken) throws IOException {
        String tokenUrl = String.format("%s/realms/%s/protocol/openid-connect/token",
                keycloakProperties.getUrl(), keycloakProperties.getRealm());

        HttpPost request = new HttpPost(tokenUrl);
        request.setHeader("Content-Type", "application/x-www-form-urlencoded");

        String body = String.format(
                "grant_type=refresh_token&client_id=%s&refresh_token=%s",
                keycloakProperties.getClientId(), refreshToken);

        request.setEntity(new StringEntity(body, StandardCharsets.UTF_8));

        try (CloseableHttpResponse response = httpClient.execute(request)) {
            if (response.getCode() != 200) {
                logger.error("Failed to refresh token: {}", response.getCode());
                throw new RuntimeException("Failed to refresh token");
            }

            JsonNode jsonNode = objectMapper.readTree(response.getEntity().getContent());
            return new TokenResponse(
                    jsonNode.get("access_token").asText(),
                    jsonNode.get("refresh_token").asText(),
                    jsonNode.get("expires_in").asInt()
            );
        }
    }

    public static class TokenResponse {
        private final String accessToken;
        private final String refreshToken;
        private final int expiresIn;

        public TokenResponse(String accessToken, String refreshToken, int expiresIn) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
            this.expiresIn = expiresIn;
        }

        public String getAccessToken() {
            return accessToken;
        }

        public String getRefreshToken() {
            return refreshToken;
        }

        public int getExpiresIn() {
            return expiresIn;
        }
    }
}

