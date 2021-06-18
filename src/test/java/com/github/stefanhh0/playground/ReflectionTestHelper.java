package com.github.stefanhh0.playground;

import static com.google.common.base.Preconditions.checkNotNull;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;

import org.checkerframework.checker.nullness.qual.NonNull;
import org.checkerframework.checker.nullness.qual.Nullable;
import org.springframework.util.ReflectionUtils;

/**
 * Method collection for reflection related purposes used in tests only.
 */
public class ReflectionTestHelper {

    /**
     * Sets the value of a field. In case the target is a regular object
     * (instance of a class), then the member of that instance is being set. If
     * the target is a class object, then the static field of that class is set.
     * This method is capable of setting final static fields.
     *
     * @param target the target, either a class object or an instance
     * @param name   the name of the field to set
     * @param value  the value to set
     * @return the original value that has been replaced
     * @throws IllegalArgumentException If no field with the specified name is
     *                                  found.
     */
    @Nullable
    public static Object setField(@NonNull final Object target,
                                  @NonNull final String name,
                                  @Nullable final Object value) {
        checkNotNull(target, "target must not be null");
        checkNotNull(name, "name must not be null");

        final boolean    targetIsAClass = target instanceof Class;
        final Class<?>   targetClass    = targetIsAClass ? (Class<?>) target : target.getClass();
        Field            modifiersField = null;
        int              modifiers      = 0;
        RuntimeException exception      = null;

        final Field field = ReflectionUtils.findField(targetClass, name, null);
        if (field == null) {
            throw new IllegalArgumentException(String.format("Could not find field [%s] on target [%s]", name, target));
        }
        ReflectionUtils.makeAccessible(field);

        try {
            if (targetIsAClass) {
                // Allow setting static final field
                modifiersField = Field.class.getDeclaredField("modifiers");
                modifiersField.setAccessible(true);
                modifiers = field.getModifiers();
                modifiersField.setInt(field, field.getModifiers() & ~Modifier.FINAL);
            }
            final Object oldValue = targetIsAClass ? field.get(null) : field.get(target);
            ReflectionUtils.setField(field, targetIsAClass ? null : target, value);
            return oldValue;
        } catch (final NoSuchFieldException | IllegalAccessException e) {
            exception = new RuntimeException(e);
            throw exception;
        } finally {
            try {
                if (modifiersField != null) {
                    // Reset modifiers to original state
                    modifiersField.setInt(field, modifiers);
                }
            } catch (IllegalAccessException e) {
                // Don't throw when an exception has been thrown already, since
                // that would swallow the original exception
                if (exception == null) {
                    throw new RuntimeException(e);
                }
            }
        }
    }
}
