# S02: CLASS CATALOG

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Core Classes

### SIMPLE_CACHE [G -> detachable separate ANY]
**Purpose**: Generic in-memory LRU cache with TTL
**Inherits**: None
**Key Features**:
- `make (max_size)`: Create with capacity
- `make_with_ttl (max_size, ttl)`: Create with default TTL
- `get (key)`: Get value (updates LRU order)
- `has (key)`: Check existence (checks expiration)
- `put (key, value)`: Store with default TTL
- `put_with_ttl (key, value, ttl)`: Store with specific TTL
- `remove (key)`: Delete entry
- `clear`: Remove all entries
- `prune_expired`: Remove expired entries
- `model_keys`: MML_SEQUENCE for specification
- `model_entries`: MML_MAP for specification
- Statistics: `hits`, `misses`, `evictions`, `hit_rate`

### SIMPLE_CACHE_QUICK
**Purpose**: Zero-configuration STRING cache facade
**Inherits**: None
**Uses**: SIMPLE_CACHE [STRING]
**Key Features**:
- `set (key, value)`: Store without TTL
- `set_for (key, value, ttl)`: Store with TTL
- `get (key)`: Retrieve value
- `remember (key, compute)`: Get-or-compute pattern
- `remember_for (key, ttl, compute)`: Get-or-compute with TTL
- `set_many`, `get_many`, `delete_many`: Bulk operations
- `increment`, `decrement`, `increment_by`: Counter operations
- `stats`: Formatted statistics string
- Uses SIMPLE_LOGGER for debug output

### SIMPLE_REDIS
**Purpose**: Redis client using RESP protocol
**Inherits**: None
**Key Features**:
- `make (host, port)`: Create client
- `make_with_auth (host, port, password)`: With authentication
- `make_with_database (host, port, database)`: Specific database
- `connect`, `disconnect`, `reconnect`: Connection management
- String: `get`, `set`, `setex`, `setnx`, `incr`, `decr`
- Keys: `del`, `exists`, `expire`, `ttl`, `keys`
- List: `lpush`, `rpush`, `lpop`, `rpop`, `blpop`, `llen`
- Server: `ping`, `dbsize`, `flushdb`, `info`
