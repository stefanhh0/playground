package com.github.stefanhh0.playground;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Collections;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import org.junit.jupiter.api.Test;

public class JNDITest {

    @Test
    public void test() throws NamingException {
        Context context = new InitialContext();
        assertEquals("valueA", context.lookup("java:comp/env/setting.a"));
        assertEquals("valueB", context.lookup("java:comp/env/setting.b"));
        Collections.list(context.listBindings("java:comp/env"))
                   .stream()
                   .map(binding -> String.format("%s=%s", binding.getName(), binding.getObject()))
                   .forEach(System.out::println);
    }
}
