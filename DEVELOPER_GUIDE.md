# Developer Guide for Booking Microservices

## Brief Introduction for Node.js/.NET Developers

### Project Overview
This is a **booking microservices** system built with **Java Spring Boot** using modern architectural patterns:
- **Vertical Slice Architecture** (similar to feature-based organization in Node.js or feature folders in .NET)
- **CQRS** (Command Query Responsibility Segregation) - separates reads and writes
- **Domain-Driven Design (DDD)**
- **Event-Driven Architecture** using RabbitMQ
- **Mediator Pattern** (similar to MediatR in .NET)

### Key Concepts Comparison

#### For .NET Developers:
- **`@Service`** annotation = Similar to dependency injection with interfaces
- **`ICommandHandler`** = Similar to `IRequestHandler<TRequest, TResponse>` in MediatR
- **`IMediator`** = Similar to MediatR's `IMediator`
- **`@RestController`** = Similar to ASP.NET Core Controllers
- **`pom.xml`** = Similar to `.csproj` files (Maven dependency management)
- **Spring Boot Application** = Similar to ASP.NET Core WebApplication

#### For Node.js Developers:
- **`@Service`** = Similar to a service class exported from a module
- **`ICommandHandler`** = Similar to a handler function that processes a specific command
- **`IMediator`** = Similar to an event bus or message router (like EventEmitter or a custom dispatcher)
- **`@RestController`** = Similar to Express.js route handlers
- **`pom.xml`** = Similar to `package.json` (but uses XML)
- **Spring Boot Application** = Similar to Express app initialization

### Architecture Pattern: Vertical Slice Architecture

Instead of traditional layered architecture (Controller → Service → Repository), this project uses **Vertical Slices** where each feature is self-contained:

```
feature/
  ├── CreateBookingCommand.java          (Request DTO)
  ├── CreateBookingCommandHandler.java   (Business Logic)
  ├── CreateBookingCommandValidator.java (Validation)
  ├── CreateBookingController.java       (REST Endpoint)
  ├── CreateBookingRequestDto.java       (API Request)
  └── Mappings.java                      (Domain ↔ Entity/DTO conversions)
```

Each feature slice contains everything it needs from controller to database operations.

---

## Where to Update Business Logic: Use Case Handlers vs Service Classes

### ✅ **Update Business Logic in Command/Query Handlers (NOT Service Classes)**

In this project, **business logic lives in Command/Query Handlers**, not in separate "Service" classes. This follows the **CQRS + Mediator Pattern**.

#### The Pattern:
1. **Command** = Represents an action (create, update, delete)
2. **Query** = Represents a read operation
3. **Handler** = Contains the business logic for that command/query
4. **Controller** = Thin layer that receives HTTP requests and delegates to Mediator

### Example Flow:

```
HTTP Request 
  → Controller (thin layer)
  → IMediator.send(command)
  → CommandHandler.handle(command) ← **YOUR BUSINESS LOGIC GOES HERE**
  → Repository (data access)
  → Response
```

### Example: ReserveSeatCommandHandler

```java
@Service
public class ReserveSeatCommandHandler implements ICommandHandler<ReserveSeatCommand, SeatDto> {
  private final SeatRepository seatRepository;

  @Override
  public SeatDto handle(ReserveSeatCommand command) {
    // 1. Validate/Fetch existing data
    SeatEntity existSeat = seatRepository.findSeatByFlightIdAndSeatNumber(...);
    if (existSeat == null) {
      throw new SeatNumberAlreadyReservedException();
    }

    // 2. Convert to domain model (DDD)
    Seat seat = Mappings.toSeatAggregate(existSeat);

    // 3. Apply business logic (domain method)
    seat.reserveSeat();  // ← Business rule applied here

    // 4. Save changes
    SeatEntity seatEntity = Mappings.toSeatEntity(seat);
    SeatEntity seatUpdated = seatRepository.save(seatEntity);

    // 5. Return DTO
    return Mappings.toSeatDto(seatUpdated);
  }
}
```

### When to Create a Handler:
- ✅ **New feature**: Create a new command/query handler
- ✅ **Update existing feature**: Modify the existing handler's `handle()` method
- ❌ **Don't create separate "Service" classes** - the handler IS the service

### Handler Types:

| Type | Interface | Use Case | Example |
|------|-----------|----------|---------|
| **Command Handler** | `ICommandHandler<TCommand, TResponse>` | Write operations (Create, Update, Delete) | `CreateBookingCommandHandler` |
| **Query Handler** | `IQueryHandler<TQuery, TResponse>` | Read operations (Get, List) | `GetAvailableFlightsQueryHandler` |

---

## How to Create a New Service

Follow these steps to create a new microservice that follows the current architecture:

### Step 1: Create Service Directory Structure

```
src/services/your-service-name/
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── io/bookingmicroservices/
│   │   │       └── yourservice/
│   │   │           ├── YourServiceApplication.java
│   │   │           ├── YourServiceConfigurations.java
│   │   │           ├── yourdomain/
│   │   │           │   ├── dtos/
│   │   │           │   ├── models/
│   │   │           │   ├── valueobjects/
│   │   │           │   ├── exceptions/
│   │   │           │   └── features/
│   │   │           │       └── yourfeature/
│   │   │           │           ├── YourFeatureCommand.java
│   │   │           │           ├── YourFeatureCommandHandler.java
│   │   │           │           ├── YourFeatureCommandValidator.java
│   │   │           │           ├── YourFeatureController.java
│   │   │           │           └── YourFeatureRequestDto.java
│   │   │           └── data/
│   │   │               ├── jpa/
│   │   │               │   ├── entities/
│   │   │               │   └── repositories/
│   │   │               └── mongo/
│   │   │                   ├── documents/
│   │   │                   └── repositories/
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       └── db/
│   │           └── migration/
│   │               └── V1__Init_Your_Service_Tables.sql
```

### Step 2: Copy and Modify pom.xml

Use `flight/pom.xml` as a template. Key points:
- Change `<artifactId>flight</artifactId>` to your service name
- Change `<name>flight</name>` to your service name
- Keep the `buildingblocks` dependency (provides all shared infrastructure)
- Add gRPC dependencies if your service needs gRPC

### Step 3: Create Application Main Class

```java
package io.bookingmicroservices.yourservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class YourServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(YourServiceApplication.class, args);
    }
}
```

### Step 4: Create Configuration Class

Copy from `FlightConfigurations.java` - this imports all necessary building blocks:

```java
package io.bookingmicroservices.yourservice;

import buildingblocks.core.event.EventDispatcherConfiguration;
import buildingblocks.jpa.JpaConfiguration;
import buildingblocks.keycloak.KeycloakConfiguration;
import buildingblocks.logger.LoggerConfiguration;
import buildingblocks.mediator.MediatorConfiguration;
import buildingblocks.mongo.MongoConfiguration;
import buildingblocks.otel.collector.OtelCollectorConfiguration;
import buildingblocks.outboxprocessor.PersistMessageProcessorConfiguration;
import buildingblocks.problemdetails.CustomProblemDetailsHandler;
import buildingblocks.rabbitmq.RabbitmqConfiguration;
import buildingblocks.swagger.SwaggerConfiguration;
import buildingblocks.threadpool.ThreadPoolConfiguration;
import buildingblocks.web.WebClientConfiguration;
import org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

@Configuration
@Import({
    CustomProblemDetailsHandler.class,
    JpaConfiguration.class,
    MongoConfiguration.class,
    LoggerConfiguration.class,
    FlywayAutoConfiguration.FlywayConfiguration.class,
    RabbitmqConfiguration.class,
    OtelCollectorConfiguration.class,
    SwaggerConfiguration.class,
    KeycloakConfiguration.class,
    WebClientConfiguration.class,
    ThreadPoolConfiguration.class,
    PersistMessageProcessorConfiguration.class,
    EventDispatcherConfiguration.class,
    MediatorConfiguration.class
})
public class YourServiceConfigurations {
}
```

### Step 5: Create Application Configuration Files

Copy `application.yml`, `application-dev.yml` from an existing service and update:
- Server port
- Database names
- Service-specific configurations

### Step 6: Create Your First Feature (Example: CreateResource)

#### 6.1 Create Command (Request Object)

```java
package io.bookingmicroservices.yourservice.resources.features.createresource;

import buildingblocks.mediator.abstractions.commands.ICommand;
import io.bookingmicroservices.yourservice.resources.dtos.ResourceDto;
import java.util.UUID;

public record CreateResourceCommand(
    UUID id,
    String name,
    String description
) implements ICommand<ResourceDto> {
}
```

#### 6.2 Create Command Handler (Business Logic)

```java
package io.bookingmicroservices.yourservice.resources.features.createresource;

import buildingblocks.mediator.abstractions.commands.ICommandHandler;
import io.bookingmicroservices.yourservice.data.jpa.repositories.ResourceRepository;
import io.bookingmicroservices.yourservice.resources.dtos.ResourceDto;
import io.bookingmicroservices.yourservice.resources.models.Resource;
import org.springframework.stereotype.Service;

@Service
public class CreateResourceCommandHandler 
    implements ICommandHandler<CreateResourceCommand, ResourceDto> {
    
    private final ResourceRepository resourceRepository;

    public CreateResourceCommandHandler(ResourceRepository resourceRepository) {
        this.resourceRepository = resourceRepository;
    }

    @Override
    public ResourceDto handle(CreateResourceCommand command) {
        // 1. Business validation
        // 2. Create domain model
        // 3. Save to database
        // 4. Return DTO
    }
}
```

#### 6.3 Create Controller

```java
package io.bookingmicroservices.yourservice.resources.features.createresource;

import buildingblocks.mediator.abstractions.IMediator;
import io.bookingmicroservices.yourservice.resources.dtos.ResourceDto;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "api/v1/your-service/resource")
@Tag(name = "your-service")
public class CreateResourceController {
    
    private final IMediator mediator;

    public CreateResourceController(IMediator mediator) {
        this.mediator = mediator;
    }

    @PostMapping()
    @PreAuthorize("hasAuthority('ADMIN')")  // Optional: add security
    public ResponseEntity<ResourceDto> createResource(
            @RequestBody CreateResourceRequestDto requestDto) {
        CreateResourceCommand command = Mappings.toCreateResourceCommand(requestDto);
        var result = this.mediator.send(command);
        return ResponseEntity.ok().body(result);
    }
}
```

### Step 7: Database Setup

1. **Create Entity** (JPA - Write Side - PostgreSQL):
```java
@Entity
@Table(name = "resources")
public class ResourceEntity {
    @Id
    private UUID id;
    // ... fields
}
```

2. **Create Repository**:
```java
public interface ResourceRepository extends JpaRepository<ResourceEntity, UUID> {
    // Custom queries
}
```

3. **Create Flyway Migration** (`db/migration/V1__Init_Resource_Tables.sql`):
```sql
CREATE TABLE resources (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    -- ... columns
);
```

4. **Create Document** (MongoDB - Read Side - Optional):
```java
@Document(collection = "resources")
public class ResourceDocument {
    // ... fields for read model
}
```

### Step 8: Build and Run

```bash
# Build buildingblocks first (if not already built)
cd src/buildingblocks
mvn clean install

# Build your service
cd src/services/your-service-name
mvn clean install

# Run your service
mvn spring-boot:run
```

### Step 9: Verify

- Check Swagger UI: `http://localhost:YOUR_PORT/swagger-ui/index.html`
- Test your endpoint
- Verify database tables are created (Flyway)

---

## Key Rules to Follow

1. ✅ **One Handler per Feature**: Each command/query has its own handler
2. ✅ **Feature Folder Structure**: All related files in one feature folder
3. ✅ **Use Mediator**: Never call repositories directly from controllers
4. ✅ **DDD Domain Models**: Use domain models (e.g., `Seat`, `Flight`) with business methods
5. ✅ **DTOs for API**: Use DTOs (`SeatDto`, `FlightDto`) for API responses
6. ✅ **Value Objects**: Use value objects (e.g., `SeatNumber`, `FlightId`) for type safety
7. ✅ **CQRS**: Commands write to PostgreSQL (JPA), Queries read from MongoDB (optional)
8. ✅ **Validation**: Create validators implementing validation logic
9. ✅ **Exceptions**: Create domain-specific exceptions in `exceptions/` folder
10. ✅ **Mappings**: Centralize conversions in `Mappings.java` per domain

---

## Common Patterns

### Pattern 1: Create Entity
```java
// Command Handler
Aircraft aircraft = Aircraft.create(...);  // Domain factory method
AircraftEntity entity = Mappings.toAircraftEntity(aircraft);
repository.save(entity);
```

### Pattern 2: Update Entity
```java
// Command Handler
AircraftEntity existing = repository.findById(id);
Aircraft aircraft = Mappings.toAircraftAggregate(existing);
aircraft.updateSomething(...);  // Domain method
AircraftEntity updated = Mappings.toAircraftEntity(aircraft);
repository.save(updated);
```

### Pattern 3: Query Data
```java
// Query Handler
List<FlightDocument> documents = readRepository.findAll();
return documents.stream()
    .map(Mappings::toFlightDto)
    .toList();
```

---

## Resources

- Existing services for reference:
  - `src/services/flight` - Most complete example
  - `src/services/booking` - Shows inter-service communication (gRPC)
  - `src/services/passenger` - Simpler service

- Building blocks (shared infrastructure):
  - `src/buildingblocks` - Contains all reusable components

- Architecture diagrams: See `assets/` folder

---

## Quick Reference: File Locations

| Concern | Location | Example |
|---------|----------|---------|
| **Business Logic** | `features/{feature-name}/{Feature}CommandHandler.java` | `ReserveSeatCommandHandler` |
| **REST Endpoint** | `features/{feature-name}/{Feature}Controller.java` | `ReserveSeatController` |
| **Request DTO** | `features/{feature-name}/{Feature}RequestDto.java` | `ReserveSeatRequestDto` |
| **Command/Query** | `features/{feature-name}/{Feature}Command.java` | `ReserveSeatCommand` |
| **Domain Model** | `{domain}/models/{Entity}.java` | `Seat.java` |
| **Value Objects** | `{domain}/valueobjects/` | `SeatNumber.java` |
| **Entities (JPA)** | `data/jpa/entities/` | `SeatEntity.java` |
| **Documents (MongoDB)** | `data/mongo/documents/` | `SeatDocument.java` |
| **Repositories** | `data/jpa/repositories/` or `data/mongo/repositories/` | `SeatRepository.java` |
| **Exceptions** | `{domain}/exceptions/` | `SeatNumberAlreadyReservedException.java` |
| **DTOs** | `{domain}/dtos/` | `SeatDto.java` |


