package test;

import static java.lang.System.out;

import java.time.Duration;
import java.time.Instant;
import java.time.Month;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.FormatStyle;
import java.util.Locale;
import java.util.UUID;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.EntityTransaction;
import javax.persistence.Persistence;

import com.github.f4b6a3.uuid.UuidCreator;
import com.github.f4b6a3.uuid.creator.rfc4122.TimeOrderedUuidCreator;
import com.github.f4b6a3.uuid.util.UuidUtil;

public class Main {

    private static final EntityManagerFactory emf = Persistence.createEntityManagerFactory("test");

    private static final EntityManager em = emf.createEntityManager();

    public static void main(final String[] args) {
        singleUUIDDemo();

        createSyntheticSequentialUUIDsStartingAtZero();

        persist1M_SequenceEntites();
        persist1M_UUIDEntities();

        em.close();
        emf.close();
    }

    private static void createSyntheticSequentialUUIDsStartingAtZero() {
        ZonedDateTime gregorianChange = ZonedDateTime.of(1582, Month.OCTOBER.getValue(), 15, 0, 0,
                0, 0, ZoneId.from(ZoneOffset.UTC));

        final long gregorianChangeInSeconds = gregorianChange.toEpochSecond();

        final TimeOrderedUuidCreator timeOrderedCreator = UuidCreator.getTimeOrderedCreator();
        for (long i = 0; i < 2000; i += 100) {
            final UUID oldId = timeOrderedCreator
                    .create(Instant.ofEpochSecond(gregorianChangeInSeconds, i), 0, 0L);
            out.println(oldId);
            out.println(toString(oldId));
        }
    }

    private static void singleUUIDDemo() {
        final EntityTransaction transaction = em.getTransaction();
        transaction.begin();
        final TestUUIDEntity test = new TestUUIDEntity();
        em.persist(test);
        transaction.commit();

        final UniqueID testId = test.getId();
        ZonedDateTime gregorianChange = ZonedDateTime.of(1582, Month.OCTOBER.getValue(), 15, 0, 0,
                0, 0, ZoneId.from(ZoneOffset.UTC));

        final long gregorianChangeInSeconds = gregorianChange.toEpochSecond();
        final long offsetToLinuxEpocheIn100Nanos = gregorianChangeInSeconds * 1000 * 1000 * 10;
        final long timestamp = testId.timestamp();
        final long instantIn100Nanos = timestamp + offsetToLinuxEpocheIn100Nanos;
        final long instantInSeconds = instantIn100Nanos / (1000 * 1000 * 10);
        final long instantRestIn100Nanos = instantIn100Nanos - instantInSeconds * 1000 * 1000 * 10;
        final long instantRestInNanos = instantRestIn100Nanos * 100;

        out.println("Gregorian change in seconds: " + gregorianChangeInSeconds);
        out.println("Offset to linux epoche in nanos: " + offsetToLinuxEpocheIn100Nanos);
        out.println("UUID: " + testId);
        out.println("Timestamp in 100 nanos: " + timestamp);
        out.println("Instant in 100 nanos: " + instantIn100Nanos);
        out.println("Instant in seconds: " + instantInSeconds);
        out.println("Instant rest in 100 nanos: " + instantRestIn100Nanos);
        out.println("Instant rest in nanos: " + instantRestInNanos);
        final Instant instant = Instant.ofEpochSecond(instantInSeconds, instantRestInNanos);
        out.println(DateTimeFormatter.ofLocalizedDateTime(FormatStyle.FULL)
                .withLocale(Locale.GERMANY)
                .withZone(ZoneId.from(ZoneOffset.UTC))
                .format(instant));

    }

    private static void persist1M_SequenceEntites() {
        // save 1.000.000 entities, commit every 10.000.
        final EntityTransaction transaction = em.getTransaction();
        final Instant start = Instant.now();
        transaction.begin();
        for (int i = 0; i < 1000000; i++) {
            em.persist(new TestSequenceIDEntity());
            if (i % 10000 == 0) {
                transaction.commit();
                transaction.begin();
            }
        }
        transaction.commit();
        final Duration duration = Duration.between(start, Instant.now());
        out.printf("Sequence-based: %02d:%02d:%02d.%03d%n", duration.toHoursPart(),
                duration.toMinutesPart(), duration.toSecondsPart(), duration.toMillisPart());

        // On disk usage for Sequence:
        // 431M
        // 488M -> 57M
    }

    private static void persist1M_UUIDEntities() {
        // save 1.000.000 entities, commit every 10.000.
        final EntityTransaction transaction = em.getTransaction();
        final Instant start = Instant.now();
        transaction.begin();
        for (int i = 0; i < 1000000; i++) {
            em.persist(new TestUUIDEntity());
            if (i % 10000 == 0) {
                transaction.commit();
                transaction.begin();
            }
        }
        transaction.commit();
        final Duration duration = Duration.between(start, Instant.now());
        out.printf("UUID-based: %02d:%02d:%02d.%03d%n", duration.toHoursPart(),
                duration.toMinutesPart(), duration.toSecondsPart(), duration.toMillisPart());
        // On disk usage for UUID:
        // 488M
        // 560M -> 72M
    }

    private static String toString(final UUID uuid) {
        ZonedDateTime gregorianChange = ZonedDateTime.of(1582, Month.OCTOBER.getValue(), 15, 0, 0,
                0, 0, ZoneId.from(ZoneOffset.UTC));
        final long gregorianChangeInSeconds = gregorianChange.toEpochSecond();
        final long offsetToLinuxEpocheIn100Nanos = gregorianChangeInSeconds * 1000 * 1000 * 10;
        final long instantIn100Nanos = UuidUtil.extractTimestamp(uuid)
                + offsetToLinuxEpocheIn100Nanos;
        final long instantInSeconds = instantIn100Nanos / (1000 * 1000 * 10);
        final long instantRestIn100Nanos = instantIn100Nanos - instantInSeconds * 1000 * 1000 * 10;
        final Instant timestamp = Instant.ofEpochSecond(instantInSeconds, instantRestIn100Nanos);
        return DateTimeFormatter.ofLocalizedDateTime(FormatStyle.FULL)
                .withLocale(Locale.GERMANY)
                .withZone(ZoneId.from(ZoneOffset.UTC))
                .format(timestamp);
    }
}
