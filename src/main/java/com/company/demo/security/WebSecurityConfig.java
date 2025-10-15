package com.company.demo.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.builders.WebSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@EnableWebSecurity
@Configuration
public class WebSecurityConfig<CustomUserDetailService> extends WebSecurityConfigurerAdapter {
    @Autowired
    private AuthenticationEntryPoint jwtAuthenticationEntryPoint;

    @Autowired
    private JwtRequestFilter jwtRequestFilter;

    @Autowired
    private JwtUserDetailsService jwtUserDetailsService;

    @Autowired
    private RateLimitingFilter rateLimitingFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Autowired
    protected void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
        auth.userDetailsService(jwtUserDetailsService).passwordEncoder(passwordEncoder());
    }

    @Bean
    @Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                // CORS configuration
                .cors()
                .and()
                // CSRF enabled for better security - exempt API endpoints that use JWT
                .csrf()
                .ignoringAntMatchers("/api/login", "/api/register", "/api/**")
                .and()
                // Add security headers
                .headers()
                .contentSecurityPolicy("default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';")
                .and()
                .xssProtection()
                .and()
                .contentTypeOptions()
                .and()
                .frameOptions().deny()
                .and()
                // Authorization
                .authorizeRequests()
                .antMatchers("/actuator/health", "/actuator/info").permitAll()
                .antMatchers("/actuator/**").hasRole("ADMIN")
                .antMatchers("/api/order", "/tai-khoan", "/tai-khoan/**", "/api/change-password", "/api/update-profile").authenticated()
                .antMatchers("/admin/**", "/api/admin/**").hasRole("ADMIN")
                .anyRequest().permitAll()
                .and()
                // Logout configuration
                .logout()
                .logoutUrl("/api/logout")
                .logoutSuccessUrl("/")
                .deleteCookies("JWT_TOKEN")
                .invalidateHttpSession(true)
                .clearAuthentication(true)
                .and()
                // Exception handling
                .exceptionHandling()
                .authenticationEntryPoint(jwtAuthenticationEntryPoint)
                .and()
                // Session management - stateless for JWT
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                // Add security filters
                .addFilterBefore(rateLimitingFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);
    }

    @Override
    public void configure(WebSecurity web) throws Exception {
        web
                .ignoring()
                .antMatchers("/css/**", "/script/**", "/image/**", "/vendor/**", "/favicon.ico", "/adminlte/**", "/media/static/**");
    }
}
