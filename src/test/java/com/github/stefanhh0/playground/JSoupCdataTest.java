package com.github.stefanhh0.playground;

import java.util.stream.Stream;

import org.jsoup.Jsoup;
import org.jsoup.safety.Whitelist;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

public class JSoupCdataTest {

    @Test
    void testDangerousInput() {
        final String dangerousInput = "<script>test</script>";
        final String result         = Jsoup.clean(dangerousInput, Whitelist.none());
        Assertions.assertEquals("", result);
    }

    static Stream<String> bogusCdataInput() {
        return Stream.of("<![cdata[<script>test</script>]]>",
                         "<![cdata[<SCRIPT>test</SCRIPT>]]>",
                         "<![Cdata[<script>test</script>]]>",
                         "<![cDatA[<script>test</script>]]>");
    }

    @ParameterizedTest
    @MethodSource("bogusCdataInput")
    void testBogusInput(final String input) {
        final String result = Jsoup.clean(input, Whitelist.none());
        Assertions.assertEquals("test]]&gt;", result);
    }

    static Stream<String> charactersOnly() {
        return Stream.of("&lt;script&gt;test&lt;/script&gt;", "<![CDATA[<script>test</script>]]>");
    }

    @ParameterizedTest
    @MethodSource("charactersOnly")
    void testCharactersOnly(final String input) {
        final String result = Jsoup.clean(input, Whitelist.none());
        Assertions.assertEquals("&lt;script&gt;test&lt;/script&gt;", result);
    }

    @Test
    @Disabled("Test fails because jsoup is not working as expected")
    void testScriptRemovedCompletely() {
        final String scriptInput     = "<script>test</script>";
        final String bogusCdataInput = "<![cdata[<script>test</script>]]>";

        final String scriptResult     = Jsoup.clean(scriptInput, Whitelist.none());
        final String bogusCdataResult = Jsoup.clean(bogusCdataInput, Whitelist.none());

        Assertions.assertEquals("", scriptResult);
        Assertions.assertEquals("]]&gt;", bogusCdataResult);
    }
}
