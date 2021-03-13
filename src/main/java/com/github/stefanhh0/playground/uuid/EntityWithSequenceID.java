package com.github.stefanhh0.playground.uuid;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;

@Entity
@Table(schema = "uuid", name = "entity_with_sequence_id")
public class EntityWithSequenceID {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "sequence_generator")
    @SequenceGenerator(name = "sequence_generator", sequenceName = "sequence", schema = "uuid")
    @Column(name = "id", nullable = false, updatable = false)
    private Long id;
}
