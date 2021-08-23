package com.github.stefanhh0.playground.uuid;

import com.google.errorprone.annotations.RestrictedApi;

public class ClassWithRestrictedMethod {

    @RestrictedApi(allowedOnPath = "./test/java", explanation = "", link = "")
    void methodForTestsOnly() {
    }
}
