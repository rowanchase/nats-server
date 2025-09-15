# Multi-stage build for NATS server
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the NATS server binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-w -s' -o nats-server .

# Final stage - minimal runtime image
FROM alpine:latest

# Add ca-certificates for TLS support
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/nats-server .

# Copy configuration file
COPY docker/nats-server.conf /root/nats-server.conf

# Expose NATS ports
# 4222: NATS client connections
# 8222: HTTP monitoring
# 6222: Routing port for clustering
# 5222: MQTT connections
EXPOSE 4222 8222 6222 5222

# Run nats-server
ENTRYPOINT ["./nats-server"]
CMD ["-c", "nats-server.conf"]