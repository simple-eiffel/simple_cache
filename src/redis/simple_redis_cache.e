note
	description: "[
		Redis-backed cache with API compatible with SIMPLE_CACHE.

		Provides distributed caching via Redis with the same interface
		as the in-memory SIMPLE_CACHE, enabling easy migration between
		local and distributed caching.

		Usage:
			create cache.make ("localhost", 6379, 1000)
			cache.connect
			cache.put ("user:123", user_json)
			if attached cache.get ("user:123") as data then
				-- Use cached data
			end

		With TTL:
			create cache.make_with_ttl ("localhost", 6379, 1000, 3600)
			cache.connect
			cache.put ("session:abc", token)  -- Expires in 1 hour

		Key prefix for namespacing:
			cache.set_key_prefix ("myapp:")
			cache.put ("user:1", data)  -- Stored as "myapp:user:1"
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_REDIS_CACHE

create
	make,
	make_with_ttl,
	make_with_auth

feature {NONE} -- Initialization

	make (a_host: STRING; a_port: INTEGER; a_max_size: INTEGER)
			-- Create Redis cache client.
		require
			host_not_empty: not a_host.is_empty
			valid_port: a_port > 0 and a_port < 65536
			positive_size: a_max_size > 0
		do
			create redis.make (a_host, a_port)
			max_size := a_max_size
			default_ttl := 0
			create key_prefix.make_empty
			hits := 0
			misses := 0
		ensure
			max_size_set: max_size = a_max_size
			no_ttl: default_ttl = 0
		end

	make_with_ttl (a_host: STRING; a_port: INTEGER; a_max_size: INTEGER; a_default_ttl: INTEGER)
			-- Create Redis cache with default TTL in seconds.
		require
			host_not_empty: not a_host.is_empty
			valid_port: a_port > 0 and a_port < 65536
			positive_size: a_max_size > 0
			positive_ttl: a_default_ttl > 0
		do
			make (a_host, a_port, a_max_size)
			default_ttl := a_default_ttl
		ensure
			max_size_set: max_size = a_max_size
			ttl_set: default_ttl = a_default_ttl
		end

	make_with_auth (a_host: STRING; a_port: INTEGER; a_max_size: INTEGER; a_password: STRING)
			-- Create Redis cache with authentication.
		require
			host_not_empty: not a_host.is_empty
			valid_port: a_port > 0 and a_port < 65536
			positive_size: a_max_size > 0
			password_not_empty: not a_password.is_empty
		do
			create redis.make_with_auth (a_host, a_port, a_password)
			max_size := a_max_size
			default_ttl := 0
			create key_prefix.make_empty
			hits := 0
			misses := 0
		ensure
			max_size_set: max_size = a_max_size
		end

feature -- Connection

	connect: BOOLEAN
			-- Connect to Redis server.
		do
			Result := redis.connect
			if not Result then
				last_error := redis.last_error
			end
		end

	disconnect
			-- Disconnect from Redis server.
		do
			redis.disconnect
		end

	is_connected: BOOLEAN
			-- Is connected to Redis?
		do
			Result := redis.is_connected
		end

	reconnect: BOOLEAN
			-- Reconnect to Redis.
		do
			Result := redis.reconnect
		end

feature -- Access

	get (a_key: STRING): detachable STRING
			-- Get value for `a_key', or Void if not found.
		require
			key_not_empty: not a_key.is_empty
			connected: is_connected
		do
			Result := redis.get (prefixed_key (a_key))
			if attached Result then
				hits := hits + 1
			else
				misses := misses + 1
			end
		end

	has (a_key: STRING): BOOLEAN
			-- Does cache contain entry for `a_key'?
		require
			key_not_empty: not a_key.is_empty
			connected: is_connected
		do
			Result := redis.exists (prefixed_key (a_key))
		end

	count: INTEGER
			-- Number of entries in cache (approximate - uses DBSIZE).
		require
			connected: is_connected
		do
			Result := redis.dbsize
		end

	is_empty: BOOLEAN
			-- Is cache empty?
		require
			connected: is_connected
		do
			Result := count = 0
		end

feature -- Element change

	put (a_key: STRING; a_value: STRING)
			-- Store `a_value' under `a_key' with default TTL.
		require
			key_not_empty: not a_key.is_empty
			connected: is_connected
		local
			l_ok: BOOLEAN
		do
			if default_ttl > 0 then
				l_ok := redis.setex (prefixed_key (a_key), default_ttl, a_value)
			else
				l_ok := redis.set (prefixed_key (a_key), a_value)
			end
			if not l_ok then
				last_error := redis.last_error
			end
		ensure
			stored: has (a_key)
		end

	put_with_ttl (a_key: STRING; a_value: STRING; a_ttl_seconds: INTEGER)
			-- Store `a_value' under `a_key' with specified TTL.
		require
			key_not_empty: not a_key.is_empty
			positive_ttl: a_ttl_seconds > 0
			connected: is_connected
		local
			l_ok: BOOLEAN
		do
			l_ok := redis.setex (prefixed_key (a_key), a_ttl_seconds, a_value)
			if not l_ok then
				last_error := redis.last_error
			end
		ensure
			stored: has (a_key)
		end

feature -- Removal

	remove (a_key: STRING)
			-- Remove entry for `a_key' if present.
		require
			key_not_empty: not a_key.is_empty
			connected: is_connected
		local
			l_ok: BOOLEAN
		do
			l_ok := redis.del (prefixed_key (a_key))
		ensure
			removed: not has (a_key)
		end

	clear
			-- Remove all entries (FLUSHDB).
		require
			connected: is_connected
		local
			l_ok: BOOLEAN
		do
			l_ok := redis.flushdb
		ensure
			emptied: is_empty
		end

feature -- TTL Operations

	set_ttl (a_key: STRING; a_seconds: INTEGER): BOOLEAN
			-- Set TTL on existing key.
		require
			key_not_empty: not a_key.is_empty
			positive_seconds: a_seconds > 0
			connected: is_connected
		do
			Result := redis.expire (prefixed_key (a_key), a_seconds)
		end

	get_ttl (a_key: STRING): INTEGER
			-- Get remaining TTL for key in seconds.
			-- Returns -1 if no expiration, -2 if key doesn't exist.
		require
			key_not_empty: not a_key.is_empty
			connected: is_connected
		do
			Result := redis.ttl (prefixed_key (a_key))
		end

feature -- Statistics

	hits: INTEGER
			-- Number of cache hits.

	misses: INTEGER
			-- Number of cache misses.

	hit_rate: REAL_64
			-- Cache hit rate (0.0 to 1.0).
		local
			l_total: INTEGER
		do
			l_total := hits + misses
			if l_total > 0 then
				Result := hits / l_total
			else
				Result := 0.0
			end
		ensure
			in_range: Result >= 0.0 and Result <= 1.0
		end

	reset_statistics
			-- Reset hit/miss counters.
		do
			hits := 0
			misses := 0
		ensure
			hits_reset: hits = 0
			misses_reset: misses = 0
		end

feature -- Configuration

	max_size: INTEGER
			-- Maximum number of entries (advisory - not enforced by Redis).

	default_ttl: INTEGER
			-- Default time-to-live in seconds (0 = no expiration).

	key_prefix: STRING
			-- Prefix added to all keys for namespacing.

	set_key_prefix (a_prefix: STRING)
			-- Set key prefix for namespacing.
		do
			key_prefix := a_prefix
		ensure
			prefix_set: key_prefix = a_prefix
		end

	last_error: detachable STRING
			-- Last error message.

	has_error: BOOLEAN
			-- Did last operation produce an error?
		do
			Result := attached last_error as e and then not e.is_empty
		end

feature -- Server Info

	ping: BOOLEAN
			-- Ping Redis server.
		require
			connected: is_connected
		do
			Result := redis.ping
		end

	server_info: detachable STRING
			-- Get Redis server info.
		require
			connected: is_connected
		do
			Result := redis.info
		end

feature {NONE} -- Implementation

	redis: SIMPLE_REDIS
			-- Underlying Redis client.

	prefixed_key (a_key: STRING): STRING
			-- Key with prefix applied.
		do
			if key_prefix.is_empty then
				Result := a_key
			else
				Result := key_prefix + a_key
			end
		end

invariant
	valid_max_size: max_size > 0
	non_negative_hits: hits >= 0
	non_negative_misses: misses >= 0
	non_negative_ttl: default_ttl >= 0

end
