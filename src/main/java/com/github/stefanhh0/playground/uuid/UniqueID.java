package com.github.stefanhh0.playground.uuid;

import java.io.Serializable;
import java.util.UUID;

import com.github.f4b6a3.uuid.util.UuidUtil;

public final class UniqueID implements Serializable, Comparable<UniqueID> {

    private static final long serialVersionUID = 4064446459404479446L;

    private final UUID uuid;

    protected UniqueID(final UUID uuid) {
        this.uuid = uuid;
    }

    public long timestamp() {
        return UuidUtil.extractTimestamp(uuid);
    }

    @Override
    public int compareTo(UniqueID o) {
        return uuid.compareTo(uuid);
    }

    @Override
    public String toString() {
        return uuid.toString();
    }

    @Override
    public int hashCode() {
        return uuid.hashCode();
    }

    @Override
    public boolean equals(Object obj) {
        if (obj instanceof UniqueID) {
            uuid.equals(((UniqueID) obj).uuid);
        }
        return false;
    }
}
