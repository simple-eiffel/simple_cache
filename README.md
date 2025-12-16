<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_cache

**[Documentation](https://simple-eiffel.github.io/simple_cache/)** | **[GitHub](https://github.com/simple-eiffel/simple_cache)**

In-memory LRU cache with optional TTL support for Eiffel applications. Now includes Redis support for distributed caching.

## Overview

`simple_cache` provides caching solutions for Eiffel:

- **SIMPLE_CACHE [G]** - In-memory LRU cache with TTL
- **SIMPLE_REDIS** - Low-level Redis client
- **SIMPLE_REDIS_CACHE** - Redis-backed cache with SIMPLE_CACHE-compatible API

### Features

- **Generic key-value storage** - STRING keys, any value type
- **LRU eviction** - Automatically removes least recently used entries
- **Optional TTL** - Time-to-live per entry or default
- **Statistics tracking** - Hits, misses, evictions, hit rate
- **Redis support** - Distributed caching via Redis

## Installation

1. Clone the repository
2. Set environment variable: `SIMPLE_CACHE=D:\path\to\simple_cache`
3. Add to your ECF:

```xml
<library name="simple_cache" location="$SIMPLE_CACHE\simple_cache.ecf"/>
```

## Dependencies

- EiffelBase (base, time)
- EiffelNet (for Redis support)

## Quick Start (Zero-Configuration)

Use `SIMPLE_CACHE_QUICK` for the simplest possible caching:

```eiffel
local
    cache: SIMPLE_CACHE_QUICK
    value: detachable STRING
do
    create cache.make  -- default 1000 entries

    -- Basic get/set
    cache.set ("user:123", user_json)
    value := cache.get ("user:123")

    -- With TTL (expires in 1 hour)
    cache.set_for ("session", token, 3600)

    -- The killer feature: get-or-compute
    value := cache.remember ("expensive_key", agent compute_value)
    -- Returns cached value if exists, otherwise computes and caches

    -- With TTL
    value := cache.remember_for ("data", 300, agent fetch_data)

    -- Counters
    cache.increment ("page_views")
    cache.increment_by ("score", 10)

    -- Statistics
    print (cache.stats)  -- "Hits: 42, Misses: 8, Rate: 84%"
end
```

## Standard API (Full Control)

```eiffel
local
    cache: SIMPLE_CACHE [STRING]
do
    -- Create cache with max 100 entries
    create cache.make (100)

    -- Store values
    cache.put ("user:123", "Alice")
    cache.put ("user:456", "Bob")

    -- Retrieve values
    if attached cache.get ("user:123") as name then
        print ("Found: " + name)
    end

    -- Check existence
    if cache.has ("user:456") then
        print ("User exists")
    end
end
```

## TTL (Time-to-Live) Support

```eiffel
local
    cache: SIMPLE_CACHE [ANY]
do
    -- Cache with default 1-hour TTL
    create cache.make_with_ttl (100, 3600)

    -- Store with default TTL
    cache.put ("session:abc", session_data)

    -- Store with custom TTL (5 minutes)
    cache.put_with_ttl ("temp:xyz", data, 300)

    -- Entries automatically expire
    -- get() returns Void for expired entries
end
```

## LRU Eviction

```eiffel
local
    cache: SIMPLE_CACHE [INTEGER]
do
    -- Small cache for demonstration
    create cache.make (3)

    cache.put ("a", 1)
    cache.put ("b", 2)
    cache.put ("c", 3)

    -- Access "a" to make it most recently used
    cache.get ("a")

    -- Adding "d" evicts "b" (least recently used)
    cache.put ("d", 4)

    -- "a", "c", "d" remain; "b" was evicted
end
```

## Statistics

```eiffel
local
    cache: SIMPLE_CACHE [STRING]
do
    create cache.make (100)

    -- Use the cache...
    cache.put ("key1", "value1")
    cache.get ("key1")  -- hit
    cache.get ("key2")  -- miss

    -- Check statistics
    print ("Hits: " + cache.hits.out)
    print ("Misses: " + cache.misses.out)
    print ("Evictions: " + cache.evictions.out)
    print ("Hit rate: " + (cache.hit_rate * 100).out + "%%")

    -- Reset statistics
    cache.reset_statistics
end
```

## Redis Cache

For distributed caching, use `SIMPLE_REDIS_CACHE` which provides a similar API to `SIMPLE_CACHE` but stores data in Redis:

```eiffel
local
    cache: SIMPLE_REDIS_CACHE
do
    -- Create Redis cache
    create cache.make ("localhost", 6379, 1000)

    -- Connect to Redis
    if cache.connect then
        -- Store values (same API as SIMPLE_CACHE)
        cache.put ("user:123", "{%"name%": %"Alice%"}")
        cache.put_with_ttl ("session:abc", token, 3600)

        -- Retrieve values
        if attached cache.get ("user:123") as data then
            print ("Found: " + data)
        end

        -- Check existence
        if cache.has ("session:abc") then
            print ("Session valid")
        end

        -- TTL operations
        cache.set_ttl ("user:123", 7200)  -- 2 hours
        print ("TTL: " + cache.get_ttl ("user:123").out)

        -- Statistics
        print ("Hit rate: " + (cache.hit_rate * 100).out + "%%")

        cache.disconnect
    end
end
```

### Redis with Authentication

```eiffel
local
    cache: SIMPLE_REDIS_CACHE
do
    create cache.make_with_auth ("redis.example.com", 6379, 1000, "password")
    if cache.connect then
        -- Use cache...
    end
end
```

### Key Prefixing (Namespacing)

```eiffel
local
    cache: SIMPLE_REDIS_CACHE
do
    create cache.make ("localhost", 6379, 1000)
    cache.set_key_prefix ("myapp:")

    if cache.connect then
        cache.put ("user:1", data)  -- Stored as "myapp:user:1" in Redis
    end
end
```

### Low-Level Redis Client

For direct Redis commands, use `SIMPLE_REDIS`:

```eiffel
local
    redis: SIMPLE_REDIS
do
    create redis.make ("localhost", 6379)
    if redis.connect then
        -- String commands
        redis.set ("key", "value")
        if attached redis.get ("key") as v then
            print (v)
        end

        -- With expiration
        redis.setex ("temp", 60, "expires in 1 minute")

        -- Key commands
        if redis.exists ("key") then
            redis.expire ("key", 3600)
            print ("TTL: " + redis.ttl ("key").out)
        end
        redis.del ("key")

        -- Atomic operations
        redis.incr ("counter")
        redis.incrby ("counter", 10)

        -- Server commands
        if redis.ping then
            print ("Connected!")
        end
        print ("Keys: " + redis.dbsize.out)

        redis.disconnect
    end
end
```

## API Reference

### Creation

| Feature | Description |
|---------|-------------|
| `make (max_size)` | Create cache with max entries, no expiration |
| `make_with_ttl (max_size, ttl_seconds)` | Create with default TTL |

### Storage

| Feature | Description |
|---------|-------------|
| `put (key, value)` | Store value (uses default TTL if set) |
| `put_with_ttl (key, value, ttl)` | Store with specific TTL in seconds |
| `remove (key)` | Remove entry |
| `clear` | Remove all entries |
| `prune_expired` | Remove all expired entries |

### Access

| Feature | Description |
|---------|-------------|
| `get (key): detachable G` | Get value (Void if not found/expired) |
| `has (key): BOOLEAN` | Check if key exists and not expired |
| `count: INTEGER` | Number of entries |
| `is_empty: BOOLEAN` | Is cache empty? |
| `is_full: BOOLEAN` | Is cache at capacity? |

### Configuration

| Feature | Description |
|---------|-------------|
| `max_size: INTEGER` | Maximum entries |
| `default_ttl: INTEGER` | Default TTL in seconds (0 = no expiration) |
| `set_max_size (size)` | Change max size (evicts if necessary) |

### Statistics

| Feature | Description |
|---------|-------------|
| `hits: INTEGER` | Cache hit count |
| `misses: INTEGER` | Cache miss count |
| `evictions: INTEGER` | LRU eviction count |
| `hit_rate: REAL_64` | Hit rate (0.0 to 1.0) |
| `reset_statistics` | Reset all counters |

### Redis Cache API

| Feature | Description |
|---------|-------------|
| `make (host, port, max_size)` | Create Redis cache |
| `make_with_ttl (host, port, max_size, ttl)` | Create with default TTL |
| `make_with_auth (host, port, max_size, password)` | Create with authentication |
| `connect: BOOLEAN` | Connect to Redis |
| `disconnect` | Disconnect from Redis |
| `is_connected: BOOLEAN` | Connection status |
| `set_key_prefix (prefix)` | Set key namespace prefix |
| `set_ttl (key, seconds): BOOLEAN` | Set TTL on existing key |
| `get_ttl (key): INTEGER` | Get remaining TTL |
| `ping: BOOLEAN` | Ping Redis server |
| `server_info: STRING` | Get Redis INFO |

### Redis Client API (SIMPLE_REDIS)

| Feature | Description |
|---------|-------------|
| `get (key): STRING` | Get value |
| `set (key, value): BOOLEAN` | Set value |
| `setex (key, seconds, value): BOOLEAN` | Set with expiration |
| `setnx (key, value): BOOLEAN` | Set if not exists |
| `del (key): BOOLEAN` | Delete key |
| `exists (key): BOOLEAN` | Check key exists |
| `expire (key, seconds): BOOLEAN` | Set expiration |
| `ttl (key): INTEGER` | Get TTL (-1 = no expire, -2 = not found) |
| `incr (key): INTEGER` | Increment by 1 |
| `incrby (key, amount): INTEGER` | Increment by amount |
| `decr (key): INTEGER` | Decrement by 1 |
| `keys (pattern): LIST [STRING]` | Find keys by pattern |
| `ping: BOOLEAN` | Ping server |
| `dbsize: INTEGER` | Key count |
| `flushdb: BOOLEAN` | Delete all keys |

## Use Cases

- **Session storage** - Cache user sessions with TTL
- **API response caching** - Reduce external API calls
- **Database query caching** - Cache frequent queries
- **Computed value caching** - Store expensive calculations
- **Rate limiting data** - Track request counts per user

## Design by Contract

```eiffel
invariant
    valid_max_size: max_size > 0
    count_within_limit: count <= max_size
    non_negative_hits: hits >= 0
    non_negative_misses: misses >= 0
    non_negative_evictions: evictions >= 0
    non_negative_ttl: default_ttl >= 0
```

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
