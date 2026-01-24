# 7S-01: SCOPE

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Problem Domain

In-memory and distributed caching for Eiffel applications. The library provides LRU (Least Recently Used) caching with optional TTL (Time-To-Live) expiration, statistics tracking, and Redis integration for distributed caching scenarios.

## Target Users

1. **Web application developers** caching API responses
2. **Database users** caching query results
3. **Computation-heavy apps** memoizing results
4. **Distributed systems** sharing state via Redis
5. **Session management** storing temporary data

## Primary Use Cases

1. Cache frequently accessed data
2. Implement the "remember" pattern (get-or-compute)
3. Reduce database/API load
4. Store session data with expiration
5. Distributed caching via Redis
6. Monitor cache effectiveness (hit rate)

## Boundaries

### In Scope
- In-memory LRU cache
- TTL-based expiration
- Cache statistics (hits, misses, evictions)
- Generic key-value storage
- Redis client (RESP protocol)
- Quick-start facade
- Model-based specifications (MML)

### Out of Scope
- Disk-based caching
- Clustering (beyond single Redis)
- Cache replication
- Pub/sub messaging
- Cache invalidation callbacks
- Serialization (application responsibility)

## Dependencies

- EiffelBase: Standard library
- simple_date_time: TTL calculations
- simple_logger: Optional logging
- Network (for Redis): EiffelNet socket
