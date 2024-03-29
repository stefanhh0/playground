package com.github.stefanhh0.playground.uuid;

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

import org.apache.commons.lang3.time.DurationFormatUtils;

import com.github.f4b6a3.uuid.UuidCreator;
import com.github.f4b6a3.uuid.util.UuidUtil;

public class Main {

    private static final EntityManagerFactory emf = Persistence.createEntityManagerFactory("playground");

    private static final EntityManager em = emf.createEntityManager();

    public static void main(final String[] args) {
        singleUUIDv6Demo();

        createSyntheticSequentialUUIDsStartingAtZero();

        persist1M_EntitiesWithSequenceID();
        persist1M_EntitiesWithUUIDv6();

        em.close();
        emf.close();
    }

    private static void singleUUIDv6Demo() {
        final EntityTransaction transaction = em.getTransaction();
        transaction.begin();
        final EntityWithUUID test = new EntityWithUUID();
        em.persist(test);
        transaction.commit();

        final UniqueID testId          = test.getId();
        final Instant  gregorianChange = Instant.parse("1582-10-15T00:00:00.000Z");

        final long gregorianChangeInMillis     = gregorianChange.toEpochMilli();
        final long offsetToUnixEpochIn100Nanos = gregorianChangeInMillis * 1000 * 10;
        final long timestamp                   = testId.getTimestamp();
        final long instantIn100Nanos           = timestamp + offsetToUnixEpochIn100Nanos;
        final long instantInSeconds            = instantIn100Nanos / (1000 * 1000 * 10);
        final long instantRestIn100Nanos       = instantIn100Nanos - instantInSeconds * 1000 * 1000 * 10;
        final long instantRestInNanos          = instantRestIn100Nanos * 100;

        out.println("Gregorian change in millis: " + gregorianChangeInMillis);
        out.println("Offset to linux epoche in nanos: " + offsetToUnixEpochIn100Nanos);
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

    private static void createSyntheticSequentialUUIDsStartingAtZero() {
        ZonedDateTime gregorianChange = ZonedDateTime.of(1582,
                                                         Month.OCTOBER.getValue(),
                                                         15,
                                                         0,
                                                         0,
                                                         0,
                                                         0,
                                                         ZoneId.from(ZoneOffset.UTC));

        final long gregorianChangeInSeconds = gregorianChange.toEpochSecond();

        for (long i = 0; i < 2000; i += 100) {
            final UUID oldId = UuidCreator.getTimeOrderedWithRandom(Instant.ofEpochSecond(gregorianChangeInSeconds, i),
                                                                    0);
            out.println(oldId);
            out.println(toString(oldId));
        }
    }

    private static void persist1M_EntitiesWithSequenceID() {
        // save 1.000.000 entities, commit every 10.000.
        final EntityTransaction transaction = em.getTransaction();

        final Instant start = Instant.now();
        transaction.begin();
        for (int i = 0; i < 1000000; i++) {
            em.persist(new EntityWithSequenceID());
            if (i % 10000 == 0) {
                transaction.commit();
                transaction.begin();
            }
        }
        transaction.commit();
        final Duration duration  = Duration.between(start, Instant.now());
        final String   durationS = DurationFormatUtils.formatDuration(duration.toMillis(), "HH:mm:ss.SSS");
        out.printf("Sequence-based: %s%n", durationS);

        // On disk usage for Sequence:
        // 431M
        // 488M -> 57M
    }

    private static void persist1M_EntitiesWithUUIDv6() {
        // save 1.000.000 entities, commit every 10.000.
        final EntityTransaction transaction = em.getTransaction();
        final Instant           start       = Instant.now();
        transaction.begin();
        for (int i = 0; i < 1000000; i++) {
            em.persist(new EntityWithUUID());
            if (i % 10000 == 0) {
                transaction.commit();
                transaction.begin();
            }
        }
        transaction.commit();
        final Duration duration  = Duration.between(start, Instant.now());
        final String   durationS = DurationFormatUtils.formatDuration(duration.toMillis(), "HH:mm:ss.SSS");
        out.printf("UUID-based: %s%n", durationS);

        // On disk usage for UUID:
        // 488M
        // 560M -> 72M
    }

    private static String toString(final UUID uuid) {
        final Instant gregorianChange             = Instant.parse("1582-10-15T00:00:00.000Z");
        final long    gregorianChangeInMillis     = gregorianChange.toEpochMilli();
        final long    offsetToUnixEpochIn100Nanos = gregorianChangeInMillis * 1000 * 10;
        final long    instantIn100Nanos           = UuidUtil.getTimestamp(uuid) + offsetToUnixEpochIn100Nanos;
        final long    instantInSeconds            = instantIn100Nanos / (1000 * 1000 * 10);
        final long    instantRestIn100Nanos       = instantIn100Nanos - instantInSeconds * 1000 * 1000 * 10;
        final Instant timestamp                   = Instant.ofEpochSecond(instantInSeconds, instantRestIn100Nanos);

        return DateTimeFormatter.ofLocalizedDateTime(FormatStyle.FULL)
                                .withLocale(Locale.GERMANY)
                                .withZone(ZoneId.from(ZoneOffset.UTC))
                                .format(timestamp);
    }
}
