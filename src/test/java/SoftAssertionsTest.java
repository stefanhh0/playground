import java.util.HashSet;
import java.util.Set;
import java.util.function.Consumer;
import java.util.stream.Stream;

import org.assertj.core.api.SoftAssertions;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

class SoftAssertionsTest {

    @Test
    void test() {
        final Set<String> set = new HashSet<>();
        set.add(null);
        assertTrue(set.contains(null));

        SoftAssertions   softly = new SoftAssertions();
        Consumer<String> f      = s -> softly.assertThatExceptionOfType(Exception.class)
                                             .as(s)
                                             .isThrownBy(this::checkSomething);

        Stream.of("A", "B")
              .forEach(f);
        softly.assertAll();
    }

    private void checkSomething() {
    }
}
