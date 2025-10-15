package com.company.demo.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtTokenUtil {
    // Token có hạn trong vòng 2 giờ kể từ thời điểm tạo, thời gian tính theo giây
    @Value("${jwt.duration}")
    public Integer duration;

    // Lấy giá trị key được cấu hình trong file application.properties
    // Key này sẽ được sử dụng để mã hóa và giải mã
    @Value("${jwt.secret}")
    private String secret;

    // Get signing key from secret
    private SecretKey getSigningKey() {
        // Convert secret to bytes and create HMAC key
        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    // Sinh token
    public String generateToken(UserDetails userDetails) {
        // Lưu thông tin Authorities của user vào claims
        Map<String, Object> claims = new HashMap<>();

        // 1. Định nghĩa các claims: issuer, expiration, subject, id
        // 2. Mã hóa token sử dụng thuật toán HS512 và key bí mật
        // 3. Convert thành chuỗi URL an toàn
        String token = Jwts.builder()
                .setClaims(claims)
                .setSubject(userDetails.getUsername())
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + duration * 1000L))
                .signWith(getSigningKey(), SignatureAlgorithm.HS512)
                .compact();

        return token;
    }

    // Lấy thông tin được lưu trong token
    public Claims getClaimsFromToken(String token) {
        // Kiểm tra token có bắt đầu bằng tiền tố
        if (token == null) return null;

        try {
            return Jwts.parserBuilder()
                    .setSigningKey(getSigningKey())
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
        } catch (ExpiredJwtException e) {
            return null;
        } catch (Exception e) {
            // Log the exception but don't expose details
            return null;
        }
    }
}
