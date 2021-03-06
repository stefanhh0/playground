package test;

import java.util.UUID;

import org.hibernate.engine.spi.SharedSessionContractImplementor;
import org.hibernate.id.UUIDGenerationStrategy;

import com.github.f4b6a3.uuid.UuidCreator;

public class TimeOrderedUUIDGeneratorStrategy implements UUIDGenerationStrategy {

    private static final long serialVersionUID = -510218196922637849L;

    @Override
    public int getGeneratedVersion() {
        return 6;
    }

    @Override
    public UUID generateUUID(SharedSessionContractImplementor session) {
        return UuidCreator.getTimeOrdered();
    }
}
