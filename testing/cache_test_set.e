note
	description: "Test set for simple_cache"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	CACHE_TEST_SET

inherit
	TEST_SET_BASE

feature -- Basic Tests

	test_make_default
			-- Test default cache creation.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (100)
			check max_size: cache.max_size = 100 end
			check initially_empty: cache.is_empty end
			check no_ttl: cache.default_ttl = 0 end
		end

	test_make_with_ttl
			-- Test cache creation with TTL.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make_with_ttl (50, 3600)
			check max_size: cache.max_size = 50 end
			check ttl_set: cache.default_ttl = 3600 end
		end

feature -- Put/Get Tests

	test_put_and_get
			-- Test basic put and get.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (10)
			cache.put ("key1", "value1")
			check has_key: cache.has ("key1") end
			check value_correct: attached cache.get ("key1") as v and then v.same_string ("value1") end
		end

	test_get_missing_key
			-- Test get on missing key returns Void.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (10)
			check missing: cache.get ("nonexistent") = Void end
			check not_has: not cache.has ("nonexistent") end
		end

	test_put_overwrites
			-- Test that put overwrites existing value.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (10)
			cache.put ("key1", "value1")
			cache.put ("key1", "value2")
			check count_unchanged: cache.count = 1 end
			check value_updated: attached cache.get ("key1") as v and then v.same_string ("value2") end
		end

	test_put_integer_values
			-- Test cache with integer values.
		local
			cache: SIMPLE_CACHE [INTEGER]
		do
			create cache.make (10)
			cache.put ("count", 42)
			cache.put ("total", 100)
			check has_count: attached cache.get ("count") as v and then v = 42 end
			check has_total: attached cache.get ("total") as v and then v = 100 end
		end

feature -- LRU Eviction Tests

	test_lru_eviction
			-- Test LRU eviction when capacity reached.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (3)
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			-- Cache full, now add another
			cache.put ("d", "4")
			-- "a" should be evicted (least recently used)
			check a_evicted: not cache.has ("a") end
			check b_present: cache.has ("b") end
			check c_present: cache.has ("c") end
			check d_present: cache.has ("d") end
		end

	test_lru_access_updates_order
			-- Test that access updates LRU order.
		local
			cache: SIMPLE_CACHE [STRING]
			l_temp: detachable STRING
		do
			create cache.make (3)
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			-- Access "a" to make it recently used
			l_temp := cache.get ("a")
			-- Now add new entry, "b" should be evicted (now least recently used)
			cache.put ("d", "4")
			check a_present: cache.has ("a") end
			-- "b" or "c" may be evicted depending on implementation
			check some_evicted: not cache.has ("b") or not cache.has ("c") end
			check c_present: cache.has ("c") end
			check d_present: cache.has ("d") end
		end

feature -- Removal Tests

	test_remove
			-- Test removing an entry.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (10)
			cache.put ("key1", "value1")
			cache.put ("key2", "value2")
			cache.remove ("key1")
			check removed: not cache.has ("key1") end
			check other_remains: cache.has ("key2") end
			check count_updated: cache.count = 1 end
		end

	test_clear
			-- Test clearing all entries.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (10)
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			cache.clear
			check emptied: cache.is_empty end
			check count_zero: cache.count = 0 end
		end

feature -- Statistics Tests

	test_hit_miss_tracking
			-- Test hit/miss statistics.
		local
			cache: SIMPLE_CACHE [STRING]
			l_temp: detachable STRING
		do
			create cache.make (10)
			cache.put ("key1", "value1")
			l_temp := cache.get ("key1")  -- Hit
			l_temp := cache.get ("key1")  -- Hit
			l_temp := cache.get ("missing")  -- Miss
			check hits: cache.hits = 2 end
			check misses: cache.misses = 1 end
		end

	test_hit_rate
			-- Test hit rate calculation.
		local
			cache: SIMPLE_CACHE [STRING]
			l_temp: detachable STRING
		do
			create cache.make (10)
			cache.put ("key1", "value1")
			l_temp := cache.get ("key1")  -- Hit
			l_temp := cache.get ("key1")  -- Hit
			l_temp := cache.get ("key1")  -- Hit
			l_temp := cache.get ("missing")  -- Miss
			-- 3 hits, 1 miss = 75% hit rate
			check hit_rate: (cache.hit_rate - 0.75).abs < 0.01 end
		end

	test_eviction_count
			-- Test eviction tracking.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (2)
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")  -- Evicts "a"
			cache.put ("d", "4")  -- Evicts "b"
			check eviction_count: cache.evictions = 2 end
		end

	test_reset_statistics
			-- Test resetting statistics.
		local
			cache: SIMPLE_CACHE [STRING]
			l_temp: detachable STRING
		do
			create cache.make (10)
			cache.put ("key1", "value1")
			l_temp := cache.get ("key1")
			l_temp := cache.get ("missing")
			cache.reset_statistics
			check hits_reset: cache.hits = 0 end
			check misses_reset: cache.misses = 0 end
			check evictions_reset: cache.evictions = 0 end
		end

feature -- Configuration Tests

	test_set_max_size_smaller
			-- Test shrinking cache size.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (5)
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			cache.put ("d", "4")
			cache.put ("e", "5")
			-- Shrink to 2, should evict 3 entries
			cache.set_max_size (2)
			check new_size: cache.max_size = 2 end
			check count_reduced: cache.count = 2 end
		end

feature -- Edge Cases

	test_empty_cache_hit_rate
			-- Test hit rate when cache unused.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (10)
			check zero_rate: cache.hit_rate = 0.0 end
		end

	test_is_full
			-- Test is_full predicate.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			create cache.make (2)
			check not_full_initially: not cache.is_full end
			cache.put ("a", "1")
			check not_full_yet: not cache.is_full end
			cache.put ("b", "2")
			check now_full: cache.is_full end
		end

end
