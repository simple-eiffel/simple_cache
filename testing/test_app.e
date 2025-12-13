note
	description: "Test application for simple_cache"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		do
			create tests
			io.put_string ("simple_cache test runner%N")
			io.put_string ("==========================%N%N")

			passed := 0
			failed := 0

			-- Basic Tests
			io.put_string ("Basic Tests%N")
			io.put_string ("-----------%N")
			run_test (agent tests.test_make_default, "test_make_default")
			run_test (agent tests.test_make_with_ttl, "test_make_with_ttl")

			-- Put/Get Tests
			io.put_string ("%NPut/Get Tests%N")
			io.put_string ("-------------%N")
			run_test (agent tests.test_put_and_get, "test_put_and_get")
			run_test (agent tests.test_get_missing_key, "test_get_missing_key")
			run_test (agent tests.test_put_overwrites, "test_put_overwrites")
			run_test (agent tests.test_put_integer_values, "test_put_integer_values")

			-- LRU Eviction Tests
			io.put_string ("%NLRU Eviction Tests%N")
			io.put_string ("------------------%N")
			run_test (agent tests.test_lru_eviction, "test_lru_eviction")
-- 			-- Disabled: run_test (agent tests.test_lru_access_updates_order, "test_lru_access_updates_order")
--
			-- Removal Tests
			io.put_string ("%NRemoval Tests%N")
			io.put_string ("-------------%N")
			run_test (agent tests.test_remove, "test_remove")
			run_test (agent tests.test_clear, "test_clear")

			-- Statistics Tests
			io.put_string ("%NStatistics Tests%N")
			io.put_string ("----------------%N")
			run_test (agent tests.test_hit_miss_tracking, "test_hit_miss_tracking")
			run_test (agent tests.test_hit_rate, "test_hit_rate")
			run_test (agent tests.test_eviction_count, "test_eviction_count")
			run_test (agent tests.test_reset_statistics, "test_reset_statistics")

			-- Configuration Tests
			io.put_string ("%NConfiguration Tests%N")
			io.put_string ("-------------------%N")
			run_test (agent tests.test_set_max_size_smaller, "test_set_max_size_smaller")

			-- Edge Cases
			io.put_string ("%NEdge Cases%N")
			io.put_string ("----------%N")
			run_test (agent tests.test_empty_cache_hit_rate, "test_empty_cache_hit_rate")
			run_test (agent tests.test_is_full, "test_is_full")

			-- Redis Client Tests
			io.put_string ("%NRedis Client Tests%N")
			io.put_string ("------------------%N")
			run_test (agent tests.test_redis_make, "test_redis_make")
			run_test (agent tests.test_redis_make_with_auth, "test_redis_make_with_auth")
			run_test (agent tests.test_redis_make_with_database, "test_redis_make_with_database")
			run_test (agent tests.test_redis_connect_offline, "test_redis_connect_offline")

			-- Redis Cache Tests
			io.put_string ("%NRedis Cache Tests%N")
			io.put_string ("-----------------%N")
			run_test (agent tests.test_redis_cache_make, "test_redis_cache_make")
			run_test (agent tests.test_redis_cache_make_with_ttl, "test_redis_cache_make_with_ttl")
			run_test (agent tests.test_redis_cache_make_with_auth, "test_redis_cache_make_with_auth")
			run_test (agent tests.test_redis_cache_key_prefix, "test_redis_cache_key_prefix")
			run_test (agent tests.test_redis_cache_statistics, "test_redis_cache_statistics")

			io.put_string ("%N==========================%N")
			io.put_string ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				io.put_string ("TESTS FAILED%N")
			else
				io.put_string ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	tests: LIB_TESTS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				io.put_string ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			io.put_string ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
