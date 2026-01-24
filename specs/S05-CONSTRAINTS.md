# S05: CONSTRAINTS

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Technical Constraints

### SIMPLE_CACHE Constraints

1. **Memory Bounds**
   - max_size limits entry count
   - Actual memory depends on value sizes
   - No value size limits

2. **Generic Type**
   - G must be `detachable separate ANY`
   - Values stored by reference
   - Caller responsible for thread safety

3. **LRU Implementation**
   - access_order is ARRAYED_LIST
   - Move to end on access is O(n)
   - Eviction is O(1) (remove first)

4. **TTL Precision**
   - Seconds granularity
   - Checked on access, not proactively
   - Call prune_expired for batch cleanup

### SIMPLE_CACHE_QUICK Constraints

1. **STRING Only**
   - Values must be STRING
   - Use core SIMPLE_CACHE for other types

2. **Remember Pattern**
   - Compute agent must return STRING
   - No exception handling in compute

### SIMPLE_REDIS Constraints

1. **Connection**
   - Single TCP connection
   - Not thread-safe
   - Blocking operations

2. **Protocol Limits**
   - Value size: Redis default (512MB)
   - Key count: Memory-limited
   - No pipelining

3. **Network**
   - Default timeout: 5 seconds connect
   - No read timeout
   - No automatic reconnection

## API Constraints

### Key Requirements
- Keys must be non-empty STRING
- Keys are case-sensitive
- No key size limits (Redis: ~500MB)

### Value Requirements
- SIMPLE_CACHE: Any detachable separate type
- SIMPLE_CACHE_QUICK: STRING only
- SIMPLE_REDIS: STRING (application serializes)

### Thread Safety
- SIMPLE_CACHE: Not thread-safe
- Create separate instances per thread
- Or use SCOOP for concurrent access

## Performance Constraints

| Operation | Complexity |
|-----------|-----------|
| get | O(n) update LRU |
| put | O(n) check/update LRU |
| remove | O(n) search LRU |
| evict_lru | O(1) |
| model_keys | O(n) copy |
| model_entries | O(n) copy |

Note: O(n) operations due to ARRAYED_LIST for LRU tracking. Consider LINKED_LIST for production with frequent access.
