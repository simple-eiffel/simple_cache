# S06: BOUNDARIES

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## System Boundaries

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Eiffel Application                          │
├─────────────────────────────────────────────────────────────────┤
│                        simple_cache                              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            SIMPLE_CACHE_QUICK (facade)                   │   │
│  │  - set, get, remember                                    │   │
│  │  - Statistics, logging                                   │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────┐   │
│  │              SIMPLE_CACHE [G] (core)                     │   │
│  │  - LRU eviction                                          │   │
│  │  - TTL expiration                                        │   │
│  │  - Model queries (MML)                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               SIMPLE_REDIS (distributed)                 │   │
│  │  - RESP protocol                                         │   │
│  │  - String/Key/List commands                              │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                           │                                      │
└───────────────────────────┼──────────────────────────────────────┘
                            │
                            ▼ TCP (RESP protocol)
┌─────────────────────────────────────────────────────────────────┐
│                       Redis Server                               │
│              (External, not part of library)                     │
└─────────────────────────────────────────────────────────────────┘
```

## Internal Dependencies

```
SIMPLE_CACHE_QUICK
       │
       └── SIMPLE_CACHE [STRING]
               │
               ├── HASH_TABLE (entries)
               ├── ARRAYED_LIST (access_order)
               ├── HASH_TABLE (expiration_times)
               ├── SIMPLE_DATE_TIME (TTL)
               └── MML_SEQUENCE, MML_MAP (models)

SIMPLE_REDIS
       │
       └── NETWORK_STREAM_SOCKET (TCP)
```

## Interface Boundaries

### Public API
- SIMPLE_CACHE [G]: Full-featured cache
- SIMPLE_CACHE_QUICK: Simplified STRING cache
- SIMPLE_REDIS: Redis client

### Internal Implementation
- entries: HASH_TABLE for storage
- access_order: ARRAYED_LIST for LRU tracking
- expiration_times: HASH_TABLE for TTL

## Data Flow

### In-Memory Cache
```
Application → SIMPLE_CACHE_QUICK → SIMPLE_CACHE → entries/access_order
```

### Distributed Cache
```
Application → SIMPLE_REDIS → TCP Socket → Redis Server → Response → Application
```

## Integration Points

### simple_date_time
- SIMPLE_DATE_TIME for expiration timestamps
- make_now, plus_seconds, comparison operators

### simple_logger
- Debug logging in SIMPLE_CACHE_QUICK
- Cache HIT/MISS/SET events
