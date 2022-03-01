package com.github.stefanhh0.playground;

import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;

import com.google.common.hash.Hashing;

public class HashTest {

    @Test
    public void test() {
        System.out.println(hash("slajlsajsg", "Alfred"));
        System.out.println(hash("ihsaihg833", "Alfred"));
        System.out.println(hash("hfaklsfhsh", "alfred"));
        System.out.println(hash("hfaklsfhsh", "Erwin"));
        System.out.println(hash("9highiegiw", "Thomas"));
    }

    private String hash(final String sessionId, final String username) {
        return Hashing.goodFastHash(1)
                      .hashString(sessionId, StandardCharsets.UTF_8)
                      .toString()
                      .substring(0, 4)
               + "."
               + Hashing.goodFastHash(1)
                        .hashString(username, StandardCharsets.UTF_8)
                        .toString()
                        .substring(0, 4);
    }
}
