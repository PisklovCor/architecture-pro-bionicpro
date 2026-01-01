package com.bionicpro.auth.service;

import com.bionicpro.auth.model.SessionData;
import com.bionicpro.auth.util.EncryptionUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
public class SessionService {
    
    private static final Logger logger = LoggerFactory.getLogger(SessionService.class);
    private final RedisTemplate<String, Object> redisTemplate;
    private final EncryptionUtil encryptionUtil;
    private final long sessionTtlSeconds;
    private final long accessTokenTtlSeconds;

    public SessionService(
            RedisTemplate<String, Object> redisTemplate,
            EncryptionUtil encryptionUtil,
            @Value("${token.session-ttl-seconds}") long sessionTtlSeconds,
            @Value("${token.access-ttl-seconds}") long accessTokenTtlSeconds) {
        this.redisTemplate = redisTemplate;
        this.encryptionUtil = encryptionUtil;
        this.sessionTtlSeconds = sessionTtlSeconds;
        this.accessTokenTtlSeconds = accessTokenTtlSeconds;
    }

    public String createSession(String accessToken, String refreshToken) {
        String sessionId = UUID.randomUUID().toString();
        String encryptedRefreshToken = encryptionUtil.encrypt(refreshToken);
        
        SessionData sessionData = new SessionData(accessToken, encryptedRefreshToken, System.currentTimeMillis());
        redisTemplate.opsForValue().set("session:" + sessionId, sessionData, sessionTtlSeconds, TimeUnit.SECONDS);
        
        logger.debug("Created session: {}", sessionId);
        return sessionId;
    }

    public SessionData getSession(String sessionId) {
        SessionData sessionData = (SessionData) redisTemplate.opsForValue().get("session:" + sessionId);
        if (sessionData != null) {
            sessionData.setRefreshToken(encryptionUtil.decrypt(sessionData.getRefreshToken()));
        }
        return sessionData;
    }

    public String rotateSession(String oldSessionId, String accessToken, String refreshToken) {
        deleteSession(oldSessionId);
        return createSession(accessToken, refreshToken);
    }

    public void updateSession(String sessionId, String accessToken, String refreshToken) {
        String encryptedRefreshToken = encryptionUtil.encrypt(refreshToken);
        SessionData sessionData = new SessionData(accessToken, encryptedRefreshToken, System.currentTimeMillis());
        
        Long ttl = redisTemplate.getExpire("session:" + sessionId, TimeUnit.SECONDS);
        if (ttl != null && ttl > 0) {
            redisTemplate.opsForValue().set("session:" + sessionId, sessionData, ttl, TimeUnit.SECONDS);
        } else {
            redisTemplate.opsForValue().set("session:" + sessionId, sessionData, sessionTtlSeconds, TimeUnit.SECONDS);
        }
        
        logger.debug("Updated session: {}", sessionId);
    }

    public void deleteSession(String sessionId) {
        redisTemplate.delete("session:" + sessionId);
        logger.debug("Deleted session: {}", sessionId);
    }

    public boolean isAccessTokenExpired(SessionData sessionData) {
        long elapsed = System.currentTimeMillis() - sessionData.getCreatedAt();
        return elapsed >= (accessTokenTtlSeconds * 1000);
    }

    public boolean shouldRotateSession(SessionData sessionData) {
        long elapsed = System.currentTimeMillis() - sessionData.getCreatedAt();
        return elapsed >= (accessTokenTtlSeconds * 1000 / 2);
    }
}

