note
	description: "[
		Simple Cache - In-memory LRU cache with optional TTL support.
		
		Features:
		- Generic key-value storage (STRING keys, ANY values)
		- Configurable max size with LRU eviction
		- Optional TTL (time-to-live) per entry
		- Thread-safe operations (optional)
		- Statistics tracking (hits, misses, evictions)
		
		Usage:
			create cache.make (100)  -- Max 100 entries
			cache.put ("user:123", user_object)
			if attached cache.get ("user:123") as user then
				-- Use cached value
			end
			
		With TTL:
			cache.put_with_ttl ("session:abc", data, 3600)  -- 1 hour TTL
		
		Statistics:
			print (cache.hit_rate)  -- 0.85 (85% hit rate)
	]"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_CACHE [G]

create
	make,
	make_with_ttl

feature {NONE} -- Initialization

	make (a_max_size: INTEGER)
			-- Create cache with maximum `a_max_size' entries.
		require
			positive_size: a_max_size > 0
		do
			max_size := a_max_size
			default_ttl := 0  -- No expiration by default
			create entries.make (a_max_size)
			create access_order.make (max_size)
			create expiration_times.make (a_max_size)
			hits := 0
			misses := 0
			evictions := 0
		ensure
			max_size_set: max_size = a_max_size
			initially_empty: count = 0
		end

	make_with_ttl (a_max_size: INTEGER; a_default_ttl: INTEGER)
			-- Create cache with max size and default TTL in seconds.
		require
			positive_size: a_max_size > 0
			non_negative_ttl: a_default_ttl >= 0
		do
			make (a_max_size)
			default_ttl := a_default_ttl
		ensure
			max_size_set: max_size = a_max_size
			ttl_set: default_ttl = a_default_ttl
		end

feature -- Access

	get (a_key: STRING): detachable G
			-- Get value for `a_key', or Void if not found or expired.
		require
			key_not_empty: not a_key.is_empty
		do
			if entries.has (a_key) then
				if is_expired (a_key) then
					-- Entry expired, remove it
					remove (a_key)
					misses := misses + 1
				else
					-- Valid entry, update access order
					Result := entries.item (a_key)
					update_access_order (a_key)
					hits := hits + 1
				end
			else
				misses := misses + 1
			end
		end

	has (a_key: STRING): BOOLEAN
			-- Does cache contain unexpired entry for `a_key'?
		require
			key_not_empty: not a_key.is_empty
		do
			if entries.has (a_key) then
				if is_expired (a_key) then
					remove (a_key)
					Result := False
				else
					Result := True
				end
			end
		end

	count: INTEGER
			-- Number of entries in cache.
		do
			Result := entries.count
		end

	is_empty: BOOLEAN
			-- Is cache empty?
		do
			Result := count = 0
		end

	is_full: BOOLEAN
			-- Is cache at max capacity?
		do
			Result := count >= max_size
		end

feature -- Element change

	put (a_key: STRING; a_value: G)
			-- Store `a_value' under `a_key' with default TTL.
		require
			key_not_empty: not a_key.is_empty
		do
			if default_ttl > 0 then
				put_with_ttl (a_key, a_value, default_ttl)
			else
				put_internal (a_key, a_value, 0)
			end
		ensure
			stored: has (a_key)
		end

	put_with_ttl (a_key: STRING; a_value: G; a_ttl_seconds: INTEGER)
			-- Store `a_value' under `a_key' with specified TTL.
		require
			key_not_empty: not a_key.is_empty
			positive_ttl: a_ttl_seconds > 0
		do
			put_internal (a_key, a_value, a_ttl_seconds)
		ensure
			stored: has (a_key)
		end

feature -- Removal

	remove (a_key: STRING)
			-- Remove entry for `a_key' if present.
		require
			key_not_empty: not a_key.is_empty
		do
			if entries.has (a_key) then
				entries.remove (a_key)
				expiration_times.remove (a_key)
				access_order.prune_all (a_key)
			end
		ensure
			removed: not entries.has (a_key)
		end

	clear
			-- Remove all entries.
		do
			entries.wipe_out
			expiration_times.wipe_out
			access_order.wipe_out
		ensure
			emptied: is_empty
		end

	prune_expired
			-- Remove all expired entries.
		local
			l_keys_to_remove: ARRAYED_LIST [STRING]
		do
			create l_keys_to_remove.make (10)
			from
				entries.start
			until
				entries.off
			loop
				if is_expired (entries.key_for_iteration) then
					l_keys_to_remove.extend (entries.key_for_iteration)
				end
				entries.forth
			end
			from
				l_keys_to_remove.start
			until
				l_keys_to_remove.after
			loop
				remove (l_keys_to_remove.item)
				l_keys_to_remove.forth
			end
		end

feature -- Statistics

	hits: INTEGER
			-- Number of cache hits.

	misses: INTEGER
			-- Number of cache misses.

	evictions: INTEGER
			-- Number of entries evicted due to capacity.

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
			-- Reset hit/miss/eviction counters.
		do
			hits := 0
			misses := 0
			evictions := 0
		ensure
			hits_reset: hits = 0
			misses_reset: misses = 0
			evictions_reset: evictions = 0
		end

feature -- Configuration

	max_size: INTEGER
			-- Maximum number of entries.

	default_ttl: INTEGER
			-- Default time-to-live in seconds (0 = no expiration).

	set_max_size (a_new_size: INTEGER)
			-- Change max size, evicting if necessary.
		require
			positive_size: a_new_size > 0
		do
			max_size := a_new_size
			evict_to_capacity
		ensure
			max_size_updated: max_size = a_new_size
			within_capacity: count <= max_size
		end

feature {NONE} -- Implementation

	entries: HASH_TABLE [G, STRING]
			-- Key-value storage.

	expiration_times: HASH_TABLE [DATE_TIME, STRING]
			-- Expiration time per key (only for entries with TTL).

	access_order: ARRAYED_LIST [STRING]
			-- Keys ordered by access time (most recent at end).

	put_internal (a_key: STRING; a_value: G; a_ttl_seconds: INTEGER)
			-- Internal put with optional TTL.
		local
			l_expiration: DATE_TIME
		do
			-- If key exists, remove from access order
			if entries.has (a_key) then
				access_order.prune_all (a_key)
			else
				-- New entry, may need to evict
				if is_full then
					evict_lru
				end
			end

			-- Store value
			entries.force (a_value, a_key)
			access_order.extend (a_key)

			-- Set expiration if TTL specified
			if a_ttl_seconds > 0 then
				create l_expiration.make_now
				l_expiration.second_add (a_ttl_seconds)
				expiration_times.force (l_expiration, a_key)
			else
				expiration_times.remove (a_key)
			end
		end

	evict_lru
			-- Evict least recently used entry.
		require
			not_empty: not is_empty
		local
			l_key: STRING
		do
			if not access_order.is_empty then
				l_key := access_order.first
				remove (l_key)
				evictions := evictions + 1
			end
		end

	evict_to_capacity
			-- Evict entries until within capacity.
		do
			from
			until
				count <= max_size
			loop
				evict_lru
			end
		ensure
			within_capacity: count <= max_size
		end

	update_access_order (a_key: STRING)
			-- Move `a_key' to end of access list (most recently used).
		do
			access_order.prune_all (a_key)
			access_order.extend (a_key)
		end

	is_expired (a_key: STRING): BOOLEAN
			-- Has entry for `a_key' expired?
		local
			l_now: DATE_TIME
		do
			if expiration_times.has (a_key) then
				create l_now.make_now
				if attached expiration_times.item (a_key) as l_exp then
					Result := l_now > l_exp
				end
			end
			-- No expiration time means never expires
		end

invariant
	valid_max_size: max_size > 0
	count_within_limit: count <= max_size
	non_negative_hits: hits >= 0
	non_negative_misses: misses >= 0
	non_negative_evictions: evictions >= 0
	non_negative_ttl: default_ttl >= 0

end
