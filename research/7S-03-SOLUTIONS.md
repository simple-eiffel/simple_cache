# 7S-03: SOLUTIONS

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Existing Solutions Comparison

### In-Memory Caches

| Solution | Pros | Cons |
|----------|------|------|
| Guava Cache | Feature-rich | Java only |
| lru-cache (Node) | Fast | JavaScript only |
| cachetools (Python) | Flexible | Python only |
| HASH_TABLE | Simple | No LRU, no TTL |

### Distributed Caches

| Solution | Pros | Cons |
|----------|------|------|
| Redis | Fast, feature-rich | External server |
| Memcached | Simple, fast | No persistence |
| Hazelcast | Clustering | Heavy |

### Eiffel Ecosystem

- HASH_TABLE: Basic storage, no caching features
- No LRU cache before simple_cache

## Why Build simple_cache?

1. **Fill Ecosystem Gap**: No Eiffel LRU cache
2. **Design by Contract**: Formal model-based specs
3. **TTL Support**: Automatic expiration
4. **Statistics**: Hit rate tracking
5. **"Remember" Pattern**: Killer feature for memoization
6. **Redis Option**: Distributed caching when needed

## Design Decisions

1. **Generic Cache**
   - SIMPLE_CACHE [G]: Any detachable separate type
   - Flexible storage for various use cases

2. **LRU Implementation**
   - access_order: ARRAYED_LIST for tracking
   - Move to end on access
   - Remove from front on eviction

3. **Model-Based Contracts**
   - MML_SEQUENCE/MML_MAP for specification
   - Enables AutoProof verification
   - Postconditions reference models

4. **Quick Facade**
   - SIMPLE_CACHE_QUICK: Zero-config STRING cache
   - "remember" feature for get-or-compute
   - Logging integration

5. **Redis Client**
   - SIMPLE_REDIS: Native RESP implementation
   - No external dependencies
   - String, Key, List, Server commands
