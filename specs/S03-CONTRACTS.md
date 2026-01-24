# S03: CONTRACTS

**Library**: simple_cache
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## SIMPLE_CACHE Contracts

### Feature: make
```eiffel
make (a_max_size: INTEGER)
    require
        positive_size: a_max_size > 0
    ensure
        max_size_set: max_size = a_max_size
        initially_empty: count = 0
        model_empty: model_keys.is_empty and model_entries.is_empty
```

### Feature: get
```eiffel
get (a_key: STRING): detachable G
    require
        key_not_empty: not a_key.is_empty
```

### Feature: has
```eiffel
has (a_key: STRING): BOOLEAN
    require
        key_not_empty: not a_key.is_empty
    ensure
        consistent_with_model: Result implies model_entries.domain [a_key]
```

### Feature: put
```eiffel
put (a_key: STRING; a_value: G)
    require
        key_not_empty: not a_key.is_empty
    ensure
        stored: entries.has (a_key)
        key_in_model: model_entries.domain [a_key]
        key_in_sequence: model_keys.has (a_key)
        key_is_most_recent: model_keys.last.same_string (a_key)
        capacity_maintained: model_keys.count <= max_size
```

### Feature: remove
```eiffel
remove (a_key: STRING)
    require
        key_not_empty: not a_key.is_empty
    ensure
        removed: not entries.has (a_key)
        key_not_in_model: not model_entries.domain [a_key]
        key_not_in_sequence: not model_keys.has (a_key)
```

### Feature: set_max_size
```eiffel
set_max_size (a_new_size: INTEGER)
    require
        positive_size: a_new_size > 0
    ensure
        max_size_updated: max_size = a_new_size
        within_capacity: count <= max_size
        model_bounded: model_keys.count <= max_size
```

### Invariants
```eiffel
invariant
    valid_max_size: max_size > 0
    count_within_limit: count <= max_size
    non_negative_hits: hits >= 0
    non_negative_misses: misses >= 0
    non_negative_evictions: evictions >= 0
    non_negative_ttl: default_ttl >= 0
    capacity_bounded: model_keys.count <= max_size
    keys_entries_same_count: access_order.count = entries.count
    hit_rate_valid: hit_rate >= 0.0 and hit_rate <= 1.0
```

## SIMPLE_REDIS Contracts

### Feature: make
```eiffel
make (a_host: STRING; a_port: INTEGER)
    require
        host_not_empty: not a_host.is_empty
        valid_port: a_port > 0 and a_port < 65536
    ensure
        host_set: host = a_host
        port_set: port = a_port
        not_connected: not is_connected
```

### Invariants
```eiffel
invariant
    host_not_empty: not host.is_empty
    valid_port: port > 0 and port < 65536
    valid_database: database >= 0
```
