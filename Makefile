.PHONY: help build build-buildingblocks build-apigateway build-flight build-booking build-passenger \
        up down docker-compose docker-build \
        run-apigateway run-flight run-booking run-passenger \
        test test-apigateway test-flight test-booking test-passenger \
        clean clean-all

# Service directories
BUILDINGBLOCKS_DIR = src/buildingblocks
APIGATEWAY_DIR = src/apigateway
FLIGHT_DIR = src/services/flight
BOOKING_DIR = src/services/booking
PASSENGER_DIR = src/services/passenger

# Docker Compose file
DOCKER_COMPOSE_FILE = deployments/docker-compose/docker-compose.infrastructure.yaml

# Maven command (use mvnw if available, otherwise mvn)
MVN = mvn

# Help target
help:
	@echo "Booking Microservices - Makefile Commands"
	@echo ""
	@echo "Build commands:"
	@echo "  make build              - Build all services (buildingblocks + 4 services)"
	@echo "  make build-buildingblocks - Build buildingblocks only"
	@echo "  make build-apigateway   - Build API Gateway only"
	@echo "  make build-flight       - Build Flight Service only"
	@echo "  make build-booking      - Build Booking Service only"
	@echo "  make build-passenger    - Build Passenger Service only"
	@echo ""
	@echo "Docker commands:"
	@echo "  make docker-build       - Build Docker images for services (if Dockerfiles exist)"
	@echo "  make up                 - Start all infrastructure services (Postgres, MongoDB, RabbitMQ, etc.)"
	@echo "  make down               - Stop all infrastructure services"
	@echo "  make docker-compose     - Alias for up"
	@echo ""
	@echo "Run commands:"
	@echo "  make run-apigateway     - Run API Gateway only (recommended: use separate terminal)"
	@echo "  make run-flight         - Run Flight Service only (recommended: use separate terminal)"
	@echo "  make run-booking        - Run Booking Service only (recommended: use separate terminal)"
	@echo "  make run-passenger      - Run Passenger Service only (recommended: use separate terminal)"
	@echo ""
	@echo "Test commands:"
	@echo "  make test               - Test all services (buildingblocks + 4 services)"
	@echo "  make test-apigateway    - Test API Gateway only"
	@echo "  make test-flight        - Test Flight Service only"
	@echo "  make test-booking       - Test Booking Service only"
	@echo "  make test-passenger     - Test Passenger Service only"
	@echo ""
	@echo "Clean commands:"
	@echo "  make clean              - Clean all services"
	@echo "  make clean-all          - Clean all services and remove target directories"

# Build all services (buildingblocks must be built first)
build: build-buildingblocks build-apigateway build-flight build-booking build-passenger
	@echo "✅ All services built successfully!"

# Build buildingblocks (must be built first as it's a dependency for other services)
build-buildingblocks:
	@echo "🔨 Building buildingblocks..."
	cd $(BUILDINGBLOCKS_DIR) && $(MVN) clean install -DskipTests
	@echo "✅ buildingblocks built successfully!"

# Build API Gateway
build-apigateway: build-buildingblocks
	@echo "🔨 Building API Gateway..."
	cd $(APIGATEWAY_DIR) && $(MVN) clean install -DskipTests
	@echo "✅ API Gateway built successfully!"

# Build Flight Service
build-flight: build-buildingblocks
	@echo "🔨 Building Flight Service..."
	cd $(FLIGHT_DIR) && $(MVN) clean install -DskipTests
	@echo "✅ Flight Service built successfully!"

# Build Booking Service
build-booking: build-buildingblocks
	@echo "🔨 Building Booking Service..."
	cd $(BOOKING_DIR) && $(MVN) clean install -DskipTests
	@echo "✅ Booking Service built successfully!"

# Build Passenger Service
build-passenger: build-buildingblocks
	@echo "🔨 Building Passenger Service..."
	cd $(PASSENGER_DIR) && $(MVN) clean install -DskipTests
	@echo "✅ Passenger Service built successfully!"

# Docker Compose commands
docker-build:
	@echo "🐳 Building Docker images..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) build
	@echo "✅ Docker images built successfully!"

up: docker-compose

docker-compose:
	@echo "🐳 Starting infrastructure services (Postgres, MongoDB, RabbitMQ, etc.)..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) up -d
	@echo "✅ Infrastructure services started! Waiting 10 seconds for services to be ready..."
	@powershell -Command "Start-Sleep -Seconds 10"
	@echo "✅ Infrastructure is ready!"

down:
	@echo "🐳 Stopping infrastructure services..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) down
	@echo "✅ Infrastructure services stopped!"

# Run API Gateway
run-apigateway:
	@echo "🚀 Starting API Gateway..."
	cd $(APIGATEWAY_DIR) && $(MVN) spring-boot:run

# Run Flight Service
run-flight:
	@echo "🚀 Starting Flight Service..."
	cd $(FLIGHT_DIR) && $(MVN) spring-boot:run

# Run Booking Service
run-booking:
	@echo "🚀 Starting Booking Service..."
	cd $(BOOKING_DIR) && $(MVN) spring-boot:run

# Run Passenger Service
run-passenger:
	@echo "🚀 Starting Passenger Service..."
	cd $(PASSENGER_DIR) && $(MVN) spring-boot:run

# Test all services
test: test-buildingblocks test-apigateway test-flight test-booking test-passenger
	@echo "✅ All tests completed!"

# Test buildingblocks
test-buildingblocks:
	@echo "🧪 Testing buildingblocks..."
	cd $(BUILDINGBLOCKS_DIR) && $(MVN) test

# Test API Gateway
test-apigateway:
	@echo "🧪 Testing API Gateway..."
	cd $(APIGATEWAY_DIR) && $(MVN) test

# Test Flight Service
test-flight:
	@echo "🧪 Testing Flight Service..."
	cd $(FLIGHT_DIR) && $(MVN) test

# Test Booking Service
test-booking:
	@echo "🧪 Testing Booking Service..."
	cd $(BOOKING_DIR) && $(MVN) test

# Test Passenger Service
test-passenger:
	@echo "🧪 Testing Passenger Service..."
	cd $(PASSENGER_DIR) && $(MVN) test

# Clean all services
clean:
	@echo "🧹 Cleaning all services..."
	cd $(BUILDINGBLOCKS_DIR) && $(MVN) clean
	cd $(APIGATEWAY_DIR) && $(MVN) clean
	cd $(FLIGHT_DIR) && $(MVN) clean
	cd $(BOOKING_DIR) && $(MVN) clean
	cd $(PASSENGER_DIR) && $(MVN) clean
	@echo "✅ All services cleaned!"

# Clean all services and remove target directories
clean-all: clean
	@echo "🧹 Removing target directories..."
	rm -rf $(BUILDINGBLOCKS_DIR)/target
	rm -rf $(APIGATEWAY_DIR)/target
	rm -rf $(FLIGHT_DIR)/target
	rm -rf $(BOOKING_DIR)/target
	rm -rf $(PASSENGER_DIR)/target
	@echo "✅ All target directories removed!"

