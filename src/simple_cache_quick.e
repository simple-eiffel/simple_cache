note
	description: "[
		Zero-configuration cache facade for beginners.

		One-liner caching with the killer 'remember' pattern.
		For full control, use SIMPLE_CACHE directly.

		Quick Start Examples:
			create cache.make

			-- Basic get/set
			cache.set ("user:123", user_json)
			user := cache.get ("user:123")

			-- With TTL (expires in 1 hour)
			cache.set_for ("session", token, 3600)

			-- The killer feature: get-or-compute
			result := cache.remember ("expensive", agent compute_value)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_CACHE_QUICK

create
	make,
	make_sized

feature {NONE} -- Initialization

	make
			-- Create quick cache with default 1000 entry limit.
		do
			make_sized (1000)
		end

	make_sized (a_max_size: INTEGER)
			-- Create quick cache with specified max entries.
		require
			positive_size: a_max_size > 0
		do
			create cache.make (a_max_size)
			create logger.make
		ensure
			cache_exists: cache /= Void
		end

feature -- Basic Operations

	set (a_key: STRING; a_value: STRING)
			-- Store value in cache (no expiration).
		require
			key_not_empty: not a_key.is_empty
		do
			logger.debug_log ("Cache SET: " + a_key)
			cache.put (a_key, a_value)
		end

	set_for (a_key: STRING; a_value: STRING; a_ttl_seconds: INTEGER)
			-- Store value with TTL in seconds.
		require
			key_not_empty: not a_key.is_empty
			positive_ttl: a_ttl_seconds > 0
		do
			logger.debug_log ("Cache SET: " + a_key + " (TTL: " + a_ttl_seconds.out + "s)")
			cache.put_with_ttl (a_key, a_value, a_ttl_seconds)
		end

	get (a_key: STRING): detachable STRING
			-- Get value from cache (Void if not found or expired).
		require
			key_not_empty: not a_key.is_empty
		do
			Result := cache.get (a_key)
			if Result /= Void then
				logger.debug_log ("Cache HIT: " + a_key)
			else
				logger.debug_log ("Cache MISS: " + a_key)
			end
		end

	has (a_key: STRING): BOOLEAN
			-- Is key in cache and not expired?
		require
			key_not_empty: not a_key.is_empty
		do
			Result := cache.has (a_key)
		end

	delete (a_key: STRING)
			-- Remove key from cache.
		require
			key_not_empty: not a_key.is_empty
		do
			logger.debug_log ("Cache DELETE: " + a_key)
			cache.remove (a_key)
		end

feature -- The Killer Feature

	remember (a_key: STRING; a_compute: FUNCTION [STRING]): STRING
			-- Get from cache, or compute and store if missing.
			-- This is the most useful caching pattern!
			--
			-- Example:
			--   result := cache.remember ("user:123", agent fetch_user (123))
		require
			key_not_empty: not a_key.is_empty
			compute_not_void: a_compute /= Void
		do
			if attached cache.get (a_key) as cached then
				logger.debug_log ("Cache REMEMBER HIT: " + a_key)
				Result := cached
			else
				logger.debug_log ("Cache REMEMBER MISS: " + a_key + " (computing...)")
				Result := a_compute.item (Void)
				cache.put (a_key, Result)
			end
		ensure
			result_not_void: Result /= Void
		end

	remember_for (a_key: STRING; a_ttl_seconds: INTEGER; a_compute: FUNCTION [STRING]): STRING
			-- Get from cache, or compute and store with TTL.
		require
			key_not_empty: not a_key.is_empty
			positive_ttl: a_ttl_seconds > 0
			compute_not_void: a_compute /= Void
		do
			if attached cache.get (a_key) as cached then
				Result := cached
			else
				Result := a_compute.item (Void)
				cache.put_with_ttl (a_key, Result, a_ttl_seconds)
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Bulk Operations

	set_many (a_pairs: ARRAY [TUPLE [key: STRING; value: STRING]])
			-- Store multiple key-value pairs.
		require
			pairs_not_empty: a_pairs.count > 0
		do
			across a_pairs as ic_p loop
				cache.put (ic_p.key, ic_p.value)
			end
		end

	get_many (a_keys: ARRAY [STRING]): ARRAYED_LIST [TUPLE [key: STRING; value: detachable STRING]]
			-- Get multiple values.
		require
			keys_not_empty: a_keys.count > 0
		do
			create Result.make (a_keys.count)
			across a_keys as ic_k loop
				Result.extend ([ic_k, cache.get (ic_k)])
			end
		ensure
			result_exists: Result /= Void
			same_count: Result.count = a_keys.count
		end

	delete_many (a_keys: ARRAY [STRING])
			-- Delete multiple keys.
		require
			keys_not_empty: a_keys.count > 0
		do
			across a_keys as ic_k loop
				cache.remove (ic_k)
			end
		end

feature -- Cache Management

	clear
			-- Remove all entries from cache.
		do
			logger.info ("Cache CLEAR")
			cache.clear
		ensure
			is_empty: cache.is_empty
		end

	prune
			-- Remove expired entries.
		do
			cache.prune_expired
		end

	count: INTEGER
			-- Number of entries in cache.
		do
			Result := cache.count
		ensure
			non_negative: Result >= 0
		end

	is_empty: BOOLEAN
			-- Is cache empty?
		do
			Result := cache.is_empty
		end

feature -- Statistics

	hits: INTEGER
			-- Cache hit count.
		do
			Result := cache.hits
		end

	misses: INTEGER
			-- Cache miss count.
		do
			Result := cache.misses
		end

	hit_rate: REAL_64
			-- Hit rate (0.0 to 1.0).
		do
			Result := cache.hit_rate
		end

	hit_rate_percent: INTEGER
			-- Hit rate as percentage.
		do
			Result := (cache.hit_rate * 100).truncated_to_integer
		end

	stats: STRING
			-- Formatted statistics string.
		do
			Result := "Hits: " + hits.out + ", Misses: " + misses.out + ", Rate: " + hit_rate_percent.out + "%%"
		end

	reset_stats
			-- Reset statistics counters.
		do
			cache.reset_statistics
		end

feature -- Increment/Decrement (for counters)

	increment (a_key: STRING): INTEGER
			-- Increment numeric value at key by 1.
			-- Returns new value, initializes to 1 if missing.
		require
			key_not_empty: not a_key.is_empty
		local
			l_val: INTEGER
		do
			if attached cache.get (a_key) as v and then v.is_integer then
				l_val := v.to_integer + 1
			else
				l_val := 1
			end
			cache.put (a_key, l_val.out)
			Result := l_val
		end

	decrement (a_key: STRING): INTEGER
			-- Decrement numeric value at key by 1.
			-- Returns new value, initializes to -1 if missing.
		require
			key_not_empty: not a_key.is_empty
		local
			l_val: INTEGER
		do
			if attached cache.get (a_key) as v and then v.is_integer then
				l_val := v.to_integer - 1
			else
				l_val := -1
			end
			cache.put (a_key, l_val.out)
			Result := l_val
		end

	increment_by (a_key: STRING; a_amount: INTEGER): INTEGER
			-- Increment numeric value by specified amount.
		require
			key_not_empty: not a_key.is_empty
		local
			l_val: INTEGER
		do
			if attached cache.get (a_key) as v and then v.is_integer then
				l_val := v.to_integer + a_amount
			else
				l_val := a_amount
			end
			cache.put (a_key, l_val.out)
			Result := l_val
		end

feature -- Advanced Access

	cache: SIMPLE_CACHE [STRING]
			-- Access underlying cache for advanced operations.

feature {NONE} -- Implementation

	logger: SIMPLE_LOGGER
			-- Logger for debugging.

invariant
	cache_exists: cache /= Void
	logger_exists: logger /= Void

end
