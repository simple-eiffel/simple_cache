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

		Model Queries (for specification):
			model_keys: MML_SEQUENCE [STRING] -- LRU order (most recent last)
			model_entries: MML_MAP [STRING, G] -- key-value mappings
	]"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_CACHE [G -> detachable separate ANY]

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
			model_empty: model_keys.is_empty and model_entries.is_empty
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
			model_empty: model_keys.is_empty and model_entries.is_empty
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
		ensure
			consistent_with_model: Result implies model_entries.domain [a_key]
		end

	count: INTEGER
			-- Number of entries in cache.
		do
			Result := entries.count
		ensure
			consistent_with_model: Result = model_keys.count
		end

	is_empty: BOOLEAN
			-- Is cache empty?
		do
			Result := count = 0
		ensure
			definition: Result = model_keys.is_empty
		end

	is_full: BOOLEAN
			-- Is cache at max capacity?
		do
			Result := count >= max_size
		ensure
			definition: Result = (model_keys.count >= max_size)
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
			stored: entries.has (a_key)
			key_in_model: model_entries.domain [a_key]
			key_in_sequence: model_keys.has (a_key)
			key_is_most_recent: model_keys.last.same_string (a_key)
			capacity_maintained: model_keys.count <= max_size
		end

	put_with_ttl (a_key: STRING; a_value: G; a_ttl_seconds: INTEGER)
			-- Store `a_value' under `a_key' with specified TTL.
		require
			key_not_empty: not a_key.is_empty
			positive_ttl: a_ttl_seconds > 0
		do
			put_internal (a_key, a_value, a_ttl_seconds)
		ensure
			stored: entries.has (a_key)
			key_in_model: model_entries.domain [a_key]
			key_in_sequence: model_keys.has (a_key)
			key_is_most_recent: model_keys.last.same_string (a_key)
			capacity_maintained: model_keys.count <= max_size
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
				prune_key_from_access_order (a_key)
			end
		ensure
			removed: not entries.has (a_key)
			key_not_in_model: not model_entries.domain [a_key]
			key_not_in_sequence: not model_keys.has (a_key)
		end

	clear
			-- Remove all entries.
		do
			entries.wipe_out
			expiration_times.wipe_out
			access_order.wipe_out
		ensure
			emptied: is_empty
			model_empty: model_keys.is_empty and model_entries.is_empty
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

feature -- Model queries (for specification)

	model_keys: MML_SEQUENCE [STRING]
			-- Keys in LRU access order (most recent at end).
			-- This is the model view of access_order.
		local
			i: INTEGER
		do
			create Result
			from
				i := 1
			until
				i > access_order.count
			loop
				Result := Result & access_order.i_th (i)
				i := i + 1
			end
		end

	model_entries: MML_MAP [STRING, G]
			-- Key-value mappings as a mathematical map.
			-- This is the model view of entries.
		local
			l_keys: ARRAY [STRING]
			i: INTEGER
		do
			create Result
			l_keys := entries.current_keys
			from
				i := l_keys.lower
			until
				i > l_keys.upper
			loop
				Result := Result.updated (l_keys [i], entries.definite_item (l_keys [i]))
				i := i + 1
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
			model_bounded: model_keys.count <= max_size
		end

feature {NONE} -- Implementation

	entries: HASH_TABLE [G, STRING]
			-- Key-value storage.

	expiration_times: HASH_TABLE [SIMPLE_DATE_TIME, STRING]
			-- Expiration time per key (only for entries with TTL).

	access_order: ARRAYED_LIST [STRING]
			-- Keys ordered by access time (most recent at end).

	put_internal (a_key: STRING; a_value: G; a_ttl_seconds: INTEGER)
			-- Internal put with optional TTL.
		local
			l_expiration: SIMPLE_DATE_TIME
		do
			-- If key exists, remove from access order
			if entries.has (a_key) then
				prune_key_from_access_order (a_key)
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
				l_expiration := l_expiration.plus_seconds (a_ttl_seconds.to_integer_64)
				expiration_times.force (l_expiration, a_key)
			else
				expiration_times.remove (a_key)
			end
		ensure
			key_stored: entries.has (a_key)
			key_in_access_order: access_order.has (a_key)
			key_is_last: access_order.last.same_string (a_key)
			within_capacity: entries.count <= max_size
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
		ensure
			count_decreased: count = old count - 1
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
			prune_key_from_access_order (a_key)
			access_order.extend (a_key)
		ensure
			key_is_last: access_order.last.same_string (a_key)
		end

	prune_key_from_access_order (a_key: STRING)
			-- Remove `a_key' from access_order using string comparison.
		local
			i: INTEGER
			l_found: BOOLEAN
		do
			from
				i := 1
				l_found := False
			until
				i > access_order.count or l_found
			loop
				if access_order.i_th (i).same_string (a_key) then
					access_order.go_i_th (i)
					access_order.remove
					l_found := True
				else
					i := i + 1
				end
			end
		end

	is_expired (a_key: STRING): BOOLEAN
			-- Has entry for `a_key' expired?
		local
			l_now: SIMPLE_DATE_TIME
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
	-- Model-based invariants
	capacity_bounded: model_keys.count <= max_size
	keys_entries_same_count: access_order.count = entries.count
	hit_rate_valid: hit_rate >= 0.0 and hit_rate <= 1.0

end
