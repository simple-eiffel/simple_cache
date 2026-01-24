# 7S-02: STANDARDS

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Applicable Standards

### Caching Patterns

1. **LRU (Least Recently Used)**
   - Most common eviction strategy
   - Recently accessed items kept
   - Oldest unused items evicted

2. **TTL (Time-To-Live)**
   - Expiration timestamp per entry
   - Automatic expiration on access
   - Manual pruning via prune_expired

### Redis Protocol (RESP)

1. **RESP (REdis Serialization Protocol)**
   - Simple text-based protocol
   - Types: Simple Strings, Errors, Integers, Bulk Strings, Arrays
   - CRLF-terminated lines

2. **RESP Format**
   ```
   *<count>\r\n        -- Array with count elements
   $<length>\r\n       -- Bulk string with length
   <data>\r\n          -- Actual data
   +<string>\r\n       -- Simple string (OK, PONG)
   :<integer>\r\n      -- Integer
   -<error>\r\n        -- Error
   ```

### Redis Commands (Implemented)

| Category | Commands |
|----------|----------|
| String | GET, SET, SETEX, SETNX, INCR, DECR, INCRBY |
| Keys | DEL, EXISTS, EXPIRE, TTL, KEYS, RENAME, TYPE |
| List | LPUSH, RPUSH, LPOP, RPOP, BLPOP, LLEN, LINDEX, LTRIM, LREM, RPOPLPUSH |
| Server | PING, INFO, DBSIZE, FLUSHDB |
| Auth | AUTH, SELECT |

### Model-Based Specification

1. **MML (Mathematical Model Library)**
   - MML_SEQUENCE for access order
   - MML_MAP for key-value mappings
   - Enables formal verification

2. **Model Queries**
   - model_keys: LRU order sequence
   - model_entries: Key-value map
   - Used in postconditions and invariants
