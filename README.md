<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_cache

**[Documentation](https://simple-eiffel.github.io/simple_cache/)** | **[GitHub](https://github.com/simple-eiffel/simple_cache)**

In-memory LRU cache with optional TTL support for Eiffel applications.

## Overview

`simple_cache` provides a generic `SIMPLE_CACHE [G]` class that offers:

- **Generic key-value storage** - STRING keys, any value type
- **LRU eviction** - Automatically removes least recently used entries
- **Optional TTL** - Time-to-live per entry or default
- **Statistics tracking** - Hits, misses, evictions, hit rate

## Installation

1. Clone the repository
2. Set environment variable: `SIMPLE_CACHE=D:\path\to\simple_cache`
3. Add to your ECF:

```xml
<library name="simple_cache" location="$SIMPLE_CACHE\simple_cache.ecf"/>
```

## Dependencies

- EiffelBase only (no external dependencies)

## Quick Start

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
