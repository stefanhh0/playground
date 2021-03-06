package test;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;

@Entity
@Table(schema = "test", name = "testseq")
public class TestSequenceIDEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "test_generator")
    @SequenceGenerator(name = "test_generator", sequenceName = "test_seq", allocationSize = 100)
    @Column(name = "id", nullable = false, updatable = false)
    private Long id;

}
