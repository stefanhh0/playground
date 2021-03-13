package com.github.stefanhh0.playground.uuid;

import java.util.UUID;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.Table;

import org.hibernate.annotations.GenericGenerator;
import org.hibernate.annotations.Parameter;

@Entity
@Table(schema = "uuid", name = "entity_with_uuid")
public class EntityWithUUID {

    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID",
                      strategy = "org.hibernate.id.UUIDGenerator",
                      parameters = { @Parameter(name = "uuid_gen_strategy_class",
                                                value = "com.github.stefanhh0.playground.uuid.TimeOrderedUUIDGeneratorStrategy") })
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // @Id
    // @GeneratedValue(generator = "UUID")
    // @GenericGenerator(name = "UUID", strategy =
    // "org.hibernate.id.UUIDGenerator")
    // @Column(name = "id", nullable = false, updatable = false)
    // private UUID id;

    // @Id
    // @GeneratedValue(generator = "UUID")
    // @GenericGenerator(name = "UUID",
    // strategy = "org.hibernate.id.UUIDGenerator",
    // parameters = { @Parameter(name = "uuid_gen_strategy_class",
    // value = "org.hibernate.id.uuid.CustomVersionOneStrategy") })
    // @Column(name = "id", nullable = false, updatable = false)
    // private UUID id;

    protected EntityWithUUID() {
    }

    public UniqueID getId() {
        return new UniqueID(id);
    }
}
