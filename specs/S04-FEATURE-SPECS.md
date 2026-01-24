# S04: FEATURE SPECIFICATIONS

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## SIMPLE_CACHE Features

### get (key): detachable G
**Purpose**: Retrieve cached value
**Behavior**:
1. If key exists and not expired: return value, update LRU, increment hits
2. If key exists but expired: remove entry, increment misses, return Void
3. If key doesn't exist: increment misses, return Void
**Side Effects**: Updates access_order, may remove expired entry

### put (key, value)
**Purpose**: Store value with default TTL
**Behavior**:
1. If key exists: remove from access_order (will re-add at end)
2. If key doesn't exist and cache full: evict LRU entry
3. Store value in entries
4. Add key to end of access_order
5. Set expiration if TTL > 0
**Eviction**: Removes first item in access_order (LRU)

### model_keys: MML_SEQUENCE [STRING]
**Purpose**: Provide formal model of LRU order
**Behavior**: Builds MML_SEQUENCE from access_order
**Use**: Postconditions referencing LRU order

### model_entries: MML_MAP [STRING, G]
**Purpose**: Provide formal model of key-value store
**Behavior**: Builds MML_MAP from entries hash table
**Use**: Postconditions referencing stored data

## SIMPLE_CACHE_QUICK Features

### remember (key, compute): STRING
**Purpose**: Get cached value or compute and cache if missing
**Behavior**:
1. Try to get from cache
2. If found: return cached value (HIT)
3. If not found: call compute agent, cache result, return
**Pattern**: Memoization / cache-aside
**Example**: `cache.remember ("user:123", agent fetch_user)`

### remember_for (key, ttl, compute): STRING
**Purpose**: Remember pattern with TTL
**Behavior**: Same as remember, but stores with specified TTL

### increment (key): INTEGER
**Purpose**: Increment numeric value
**Behavior**:
1. Get current value (parse as integer, default 0)
2. Add 1
3. Store new value as string
4. Return new value
**Use Case**: Counters, rate limiting

## SIMPLE_REDIS Features

### connect: BOOLEAN
**Purpose**: Establish connection to Redis
**Behavior**:
1. Create TCP socket
2. Connect to host:port
3. Authenticate if password set
4. Select database
**Returns**: True on success

### setex (key, seconds, value): BOOLEAN
**Purpose**: Set value with expiration
**Redis Command**: SETEX key seconds value
**Returns**: True on success (OK response)

### keys (pattern): ARRAYED_LIST [STRING]
**Purpose**: Get keys matching pattern
**Redis Command**: KEYS pattern
**Returns**: List of matching key names
**Note**: Avoid in production (blocks Redis)

### blpop (key, timeout): detachable STRING
**Purpose**: Blocking pop from list
**Redis Command**: BLPOP key timeout
**Behavior**: Blocks until element available or timeout
**Use Case**: Message queues
