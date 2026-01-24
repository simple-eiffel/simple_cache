# 7S-04: SIMPLE-STAR INTEGRATION

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Ecosystem Dependencies

### Required Libraries

1. **simple_date_time**
   - Purpose: TTL expiration calculations
   - Classes: SIMPLE_DATE_TIME
   - Used for: make_now, plus_seconds, comparison

### Optional Libraries

2. **simple_logger**
   - Purpose: Cache operation logging
   - Classes: SIMPLE_LOGGER
   - Used in: SIMPLE_CACHE_QUICK debug logging

### EiffelStudio Libraries

3. **EiffelNet**
   - Purpose: TCP socket for Redis
   - Classes: NETWORK_STREAM_SOCKET
   - Used in: SIMPLE_REDIS

4. **MML (Mathematical Model Library)**
   - Purpose: Model-based specifications
   - Classes: MML_SEQUENCE, MML_MAP
   - Used in: Postconditions, invariants

## Integration Patterns

### Web API Caching

```eiffel
-- Cache API responses
cache: SIMPLE_CACHE_QUICK
create cache.make
response := cache.remember ("api:/users/123", agent fetch_user (123))
```

### Database Query Caching

```eiffel
-- Cache with TTL
cache.set_for ("query:active_users", user_list_json, 300)  -- 5 min TTL
```

### Redis Distributed Cache

```eiffel
create redis.make ("localhost", 6379)
if redis.connect then
    redis.setex ("session:abc", 3600, session_data)  -- 1 hour
end
```

## Libraries Using simple_cache

1. **simple_http**: Response caching
2. **simple_oracle**: Query result caching
3. **simple_ai_client**: Embedding caching
4. **Web applications**: Session storage

## Namespace Conventions

- SIMPLE_CACHE [G]: Generic LRU cache
- SIMPLE_CACHE_QUICK: STRING-specialized facade
- SIMPLE_REDIS: Redis client
- No conflicts with other simple_* libraries
