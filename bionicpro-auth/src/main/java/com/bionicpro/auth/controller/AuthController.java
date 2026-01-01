package com.bionicpro.auth.controller;

import com.bionicpro.auth.model.SessionData;
import com.bionicpro.auth.service.AuthService;
import com.bionicpro.auth.service.SessionService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    
    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);
    private final AuthService authService;
    private final SessionService sessionService;
    private static final String SESSION_COOKIE_NAME = "BIONICPRO_SESSION";

    public AuthController(AuthService authService, SessionService sessionService) {
        this.authService = authService;
        this.sessionService = sessionService;
    }

    @PostMapping("/callback")
    public ResponseEntity<Map<String, String>> handleCallback(
            @RequestBody Map<String, String> request,
            HttpServletResponse response) {
        try {
            String code = request.get("code");
            String codeVerifier = request.get("code_verifier");
            String redirectUri = request.get("redirect_uri");

            String sessionId = authService.authenticate(code, codeVerifier, redirectUri);
            setSessionCookie(response, sessionId);

            return ResponseEntity.ok(Map.of("sessionId", sessionId, "status", "authenticated"));
        } catch (Exception e) {
            logger.error("Authentication failed", e);
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/session")
    public ResponseEntity<Map<String, Object>> getSession(HttpServletRequest request) {
        String sessionId = getSessionIdFromCookie(request);
        if (sessionId == null) {
            return ResponseEntity.status(401).body(Map.of("error", "No session found"));
        }

        SessionData sessionData = sessionService.getSession(sessionId);
        if (sessionData == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Session expired"));
        }

        return ResponseEntity.ok(Map.of(
                "sessionId", sessionId,
                "authenticated", true
        ));
    }

    @PostMapping("/refresh")
    public ResponseEntity<Map<String, String>> refreshSession(
            HttpServletRequest request,
            HttpServletResponse response) {
        try {
            String sessionId = getSessionIdFromCookie(request);
            if (sessionId == null) {
                return ResponseEntity.status(401).body(Map.of("error", "No session found"));
            }

            String newSessionId = authService.refreshSession(sessionId);
            setSessionCookie(response, newSessionId);

            return ResponseEntity.ok(Map.of("sessionId", newSessionId, "status", "refreshed"));
        } catch (Exception e) {
            logger.error("Session refresh failed", e);
            return ResponseEntity.status(401).body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(HttpServletRequest request, HttpServletResponse response) {
        String sessionId = getSessionIdFromCookie(request);
        if (sessionId != null) {
            sessionService.deleteSession(sessionId);
        }
        deleteSessionCookie(response);
        return ResponseEntity.ok(Map.of("status", "logged_out"));
    }

    @GetMapping("/token")
    public ResponseEntity<Map<String, String>> getAccessToken(HttpServletRequest request) {
        String sessionId = getSessionIdFromCookie(request);
        if (sessionId == null) {
            return ResponseEntity.status(401).body(Map.of("error", "No session found"));
        }

        try {
            String accessToken = authService.getValidAccessToken(sessionId);
            return ResponseEntity.ok(Map.of("access_token", accessToken));
        } catch (Exception e) {
            logger.error("Failed to get access token", e);
            return ResponseEntity.status(401).body(Map.of("error", e.getMessage()));
        }
    }

    private String getSessionIdFromCookie(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (SESSION_COOKIE_NAME.equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }

    private void setSessionCookie(HttpServletResponse response, String sessionId) {
        Cookie cookie = new Cookie(SESSION_COOKIE_NAME, sessionId);
        cookie.setHttpOnly(true);
        cookie.setSecure(false);
        cookie.setPath("/");
        cookie.setMaxAge(7200);
        response.addCookie(cookie);
    }

    private void deleteSessionCookie(HttpServletResponse response) {
        Cookie cookie = new Cookie(SESSION_COOKIE_NAME, "");
        cookie.setHttpOnly(true);
        cookie.setSecure(false);
        cookie.setPath("/");
        cookie.setMaxAge(0);
        response.addCookie(cookie);
    }
}

