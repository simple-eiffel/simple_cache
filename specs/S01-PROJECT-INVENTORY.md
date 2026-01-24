# S01: PROJECT INVENTORY

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Project Structure

```
simple_cache/
├── simple_cache.ecf            # Library configuration
├── src/
│   ├── simple_cache.e          # Generic LRU cache with TTL
│   ├── simple_cache_quick.e    # Zero-config STRING facade
│   └── redis/
│       └── simple_redis.e      # Redis RESP protocol client
├── testing/
│   ├── test_app.e              # Test application root
│   └── lib_tests.e             # Test suite
├── research/                   # This directory
└── specs/                      # Specification directory
```

## File Count Summary

| Category | Files |
|----------|-------|
| Core source | 3 |
| Test files | 2 |
| Configuration | 1 |
| **Total** | **6** |

## External Dependencies

### Eiffel Libraries
- EiffelBase (standard library)
- EiffelNet (TCP sockets for Redis)
- MML (Mathematical Model Library)
- simple_date_time (TTL calculations)
- simple_logger (optional logging)

### System Requirements
- Network access (for Redis)
- Redis server (for SIMPLE_REDIS)
