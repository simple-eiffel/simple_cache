note
	description: "[
		Simple Redis client using RESP (REdis Serialization Protocol).

		Provides low-level access to Redis commands over TCP socket.

		Usage:
			create redis.make ("localhost", 6379)
			if redis.connect then
				redis.set ("key", "value")
				if attached redis.get ("key") as v then
					print (v)
				end
				redis.disconnect
			end

		With authentication:
			create redis.make_with_auth ("localhost", 6379, "password")

		Commands supported:
			String: GET, SET, SETEX, DEL, EXISTS, EXPIRE, TTL, INCR, DECR
			Keys: KEYS, SCAN, TYPE, RENAME
			Server: PING, INFO, FLUSHDB, DBSIZE
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_REDIS

create
	make,
	make_with_auth,
	make_with_database

feature {NONE} -- Initialization

	make (a_host: STRING; a_port: INTEGER)
			-- Create Redis client for `a_host' on `a_port'.
		require
			host_not_empty: not a_host.is_empty
			valid_port: a_port > 0 and a_port < 65536
		do
			host := a_host
			port := a_port
			database := 0
			create last_error.make_empty
			is_connected := False
		ensure
			host_set: host = a_host
			port_set: port = a_port
			not_connected: not is_connected
		end

	make_with_auth (a_host: STRING; a_port: INTEGER; a_password: STRING)
			-- Create Redis client with authentication.
		require
			host_not_empty: not a_host.is_empty
			valid_port: a_port > 0 and a_port < 65536
			password_not_empty: not a_password.is_empty
		do
			make (a_host, a_port)
			password := a_password
		ensure
			host_set: host = a_host
			port_set: port = a_port
			password_set: password = a_password
		end

	make_with_database (a_host: STRING; a_port: INTEGER; a_database: INTEGER)
			-- Create Redis client for specific database.
		require
			host_not_empty: not a_host.is_empty
			valid_port: a_port > 0 and a_port < 65536
			valid_database: a_database >= 0
		do
			make (a_host, a_port)
			database := a_database
		ensure
			host_set: host = a_host
			port_set: port = a_port
			database_set: database = a_database
		end

feature -- Access

	host: STRING
			-- Redis server hostname

	port: INTEGER
			-- Redis server port

	database: INTEGER
			-- Redis database number (0-15)

	password: detachable STRING
			-- Authentication password

	is_connected: BOOLEAN
			-- Is connected to Redis server?

	last_error: STRING
			-- Last error message

	has_error: BOOLEAN
			-- Did last operation produce an error?
		do
			Result := not last_error.is_empty
		end

feature -- Connection

	connect: BOOLEAN
			-- Connect to Redis server. Returns True on success.
		local
			l_socket: NETWORK_STREAM_SOCKET
		do
			last_error.wipe_out
			create l_socket.make_client_by_port (port, host)
			l_socket.set_connect_timeout (5000)  -- 5 second timeout
			l_socket.connect

			if l_socket.is_connected then
				socket := l_socket
				is_connected := True

				-- Authenticate if password set
				if attached password as pwd then
					if not auth (pwd) then
						disconnect
						Result := False
					else
						Result := select_database (database)
					end
				else
					Result := select_database (database)
				end
			else
				last_error := "Failed to connect to " + host + ":" + port.out
				Result := False
			end
		end

	disconnect
			-- Disconnect from Redis server.
		do
			if attached socket as s then
				if not s.is_closed then
					s.close
				end
			end
			socket := Void
			is_connected := False
		ensure
			disconnected: not is_connected
		end

	reconnect: BOOLEAN
			-- Reconnect to Redis server.
		do
			disconnect
			Result := connect
		end

feature -- String Commands

	get (a_key: STRING): detachable STRING
			-- Get value for `a_key'.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_string (<<"GET", a_key>>)
		end

	set (a_key: STRING; a_value: STRING): BOOLEAN
			-- Set `a_key' to `a_value'.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_ok (<<"SET", a_key, a_value>>)
		end

	setex (a_key: STRING; a_seconds: INTEGER; a_value: STRING): BOOLEAN
			-- Set `a_key' to `a_value' with expiration in seconds.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
			positive_seconds: a_seconds > 0
		do
			Result := send_command_ok (<<"SETEX", a_key, a_seconds.out, a_value>>)
		end

	setnx (a_key: STRING; a_value: STRING): BOOLEAN
			-- Set `a_key' to `a_value' only if key does not exist.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		local
			l_result: INTEGER
		do
			l_result := send_command_integer (<<"SETNX", a_key, a_value>>)
			Result := l_result = 1
		end

	incr (a_key: STRING): INTEGER
			-- Increment value at `a_key' by 1.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"INCR", a_key>>)
		end

	decr (a_key: STRING): INTEGER
			-- Decrement value at `a_key' by 1.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"DECR", a_key>>)
		end

	incrby (a_key: STRING; a_amount: INTEGER): INTEGER
			-- Increment value at `a_key' by `a_amount'.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"INCRBY", a_key, a_amount.out>>)
		end

feature -- Key Commands

	del (a_key: STRING): BOOLEAN
			-- Delete `a_key'.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		local
			l_result: INTEGER
		do
			l_result := send_command_integer (<<"DEL", a_key>>)
			Result := l_result > 0
		end

	exists (a_key: STRING): BOOLEAN
			-- Does `a_key' exist?
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		local
			l_result: INTEGER
		do
			l_result := send_command_integer (<<"EXISTS", a_key>>)
			Result := l_result > 0
		end

	expire (a_key: STRING; a_seconds: INTEGER): BOOLEAN
			-- Set expiration on `a_key' in seconds.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
			positive_seconds: a_seconds > 0
		local
			l_result: INTEGER
		do
			l_result := send_command_integer (<<"EXPIRE", a_key, a_seconds.out>>)
			Result := l_result = 1
		end

	ttl (a_key: STRING): INTEGER
			-- Get remaining TTL for `a_key' in seconds.
			-- Returns -1 if no expiration, -2 if key doesn't exist.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"TTL", a_key>>)
		end

	keys (a_pattern: STRING): ARRAYED_LIST [STRING]
			-- Get keys matching `a_pattern'.
		require
			connected: is_connected
			pattern_not_empty: not a_pattern.is_empty
		do
			Result := send_command_array (<<"KEYS", a_pattern>>)
		end

	rename_key (a_old_key, a_new_key: STRING): BOOLEAN
			-- Rename `a_old_key' to `a_new_key'.
		require
			connected: is_connected
			old_key_not_empty: not a_old_key.is_empty
			new_key_not_empty: not a_new_key.is_empty
		do
			Result := send_command_ok (<<"RENAME", a_old_key, a_new_key>>)
		end

	key_type (a_key: STRING): STRING
			-- Get type of value at `a_key'.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			if attached send_command_string (<<"TYPE", a_key>>) as t then
				Result := t
			else
				Result := "none"
			end
		end

feature -- List Commands

	lpush (a_key, a_value: STRING): INTEGER
			-- Prepend value to list. Returns list length.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"LPUSH", a_key, a_value>>)
		end

	rpush (a_key, a_value: STRING): INTEGER
			-- Append value to list. Returns list length.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"RPUSH", a_key, a_value>>)
		end

	lpop (a_key: STRING): detachable STRING
			-- Remove and return first element of list.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_string (<<"LPOP", a_key>>)
		end

	rpop (a_key: STRING): detachable STRING
			-- Remove and return last element of list.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_string (<<"RPOP", a_key>>)
		end

	blpop (a_key: STRING; a_timeout: INTEGER): detachable STRING
			-- Blocking left pop with timeout in seconds.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
			non_negative_timeout: a_timeout >= 0
		local
			l_response: detachable STRING
		do
			l_response := send_command_string (<<"BLPOP", a_key, a_timeout.out>>)
			-- BLPOP returns array [key, value], we want the value
			if attached l_response as r and then not r.is_empty then
				Result := r
			end
		end

	llen (a_key: STRING): INTEGER
			-- Get list length.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"LLEN", a_key>>)
		end

	lindex (a_key: STRING; a_index: INTEGER): detachable STRING
			-- Get element at index.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_string (<<"LINDEX", a_key, a_index.out>>)
		end

	ltrim (a_key: STRING; a_start, a_stop: INTEGER): BOOLEAN
			-- Trim list to specified range.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_ok (<<"LTRIM", a_key, a_start.out, a_stop.out>>)
		end

	lrem (a_key: STRING; a_count: INTEGER; a_value: STRING): INTEGER
			-- Remove elements from list. Returns number removed.
		require
			connected: is_connected
			key_not_empty: not a_key.is_empty
		do
			Result := send_command_integer (<<"LREM", a_key, a_count.out, a_value>>)
		end

	rpoplpush (a_source, a_destination: STRING): detachable STRING
			-- Pop from source and push to destination atomically.
		require
			connected: is_connected
			source_not_empty: not a_source.is_empty
			destination_not_empty: not a_destination.is_empty
		do
			Result := send_command_string (<<"RPOPLPUSH", a_source, a_destination>>)
		end

feature -- Server Commands

	ping: BOOLEAN
			-- Ping Redis server.
		require
			connected: is_connected
		local
			l_response: detachable STRING
		do
			l_response := send_command_string (<<"PING">>)
			Result := attached l_response as r and then r.is_equal ("PONG")
		end

	dbsize: INTEGER
			-- Get number of keys in current database.
		require
			connected: is_connected
		do
			Result := send_command_integer (<<"DBSIZE">>)
		end

	flushdb: BOOLEAN
			-- Delete all keys in current database.
		require
			connected: is_connected
		do
			Result := send_command_ok (<<"FLUSHDB">>)
		end

	info: detachable STRING
			-- Get server info.
		require
			connected: is_connected
		do
			Result := send_command_string (<<"INFO">>)
		end

feature {NONE} -- Authentication

	auth (a_password: STRING): BOOLEAN
			-- Authenticate with password.
		require
			connected: is_connected
		do
			Result := send_command_ok (<<"AUTH", a_password>>)
		end

	select_database (a_db: INTEGER): BOOLEAN
			-- Select database number.
		require
			connected: is_connected
			valid_db: a_db >= 0
		do
			if a_db = 0 then
				Result := True  -- Database 0 is default
			else
				Result := send_command_ok (<<"SELECT", a_db.out>>)
			end
		end

feature {NONE} -- RESP Protocol

	send_command_ok (a_args: ARRAY [STRING]): BOOLEAN
			-- Send command and expect OK response.
		local
			l_response: detachable STRING
		do
			l_response := send_command (a_args)
			Result := attached l_response as r and then (r.is_equal ("+OK") or r.starts_with ("+"))
		end

	send_command_string (a_args: ARRAY [STRING]): detachable STRING
			-- Send command and return string response.
		local
			l_response: detachable STRING
		do
			l_response := send_command (a_args)
			if attached l_response as r then
				if r.starts_with ("$-1") then
					-- Null bulk string
					Result := Void
				elseif r.starts_with ("$") then
					-- Bulk string: $<length>\r\n<data>\r\n
					Result := parse_bulk_string (r)
				elseif r.starts_with ("+") then
					-- Simple string
					Result := r.substring (2, r.count)
				elseif r.starts_with ("-") then
					-- Error
					last_error := r.substring (2, r.count)
					Result := Void
				else
					Result := r
				end
			end
		end

	send_command_integer (a_args: ARRAY [STRING]): INTEGER
			-- Send command and return integer response.
		local
			l_response: detachable STRING
		do
			l_response := send_command (a_args)
			if attached l_response as r then
				if r.starts_with (":") then
					Result := r.substring (2, r.count).to_integer
				elseif r.starts_with ("-") then
					last_error := r.substring (2, r.count)
					Result := 0
				end
			end
		end

	send_command_array (a_args: ARRAY [STRING]): ARRAYED_LIST [STRING]
			-- Send command and return array response.
		local
			l_response: detachable STRING
		do
			create Result.make (0)
			l_response := send_command (a_args)
			if attached l_response as r then
				if r.starts_with ("*") then
					Result := parse_array_response (r)
				elseif r.starts_with ("-") then
					last_error := r.substring (2, r.count)
				end
			end
		end

	send_command (a_args: ARRAY [STRING]): detachable STRING
			-- Send RESP command and read response.
		local
			l_cmd: STRING
			i: INTEGER
		do
			last_error.wipe_out

			if attached socket as s and then not s.is_closed then
				-- Build RESP array command
				create l_cmd.make (100)
				l_cmd.append ("*" + a_args.count.out + crlf)
				from i := a_args.lower until i > a_args.upper loop
					l_cmd.append ("$" + a_args[i].count.out + crlf)
					l_cmd.append (a_args[i] + crlf)
					i := i + 1
				end

				-- Send command
				s.put_string (l_cmd)

				-- Read response
				Result := read_response (s)
			else
				last_error := "Not connected"
			end
		end

	read_response (a_socket: NETWORK_STREAM_SOCKET): detachable STRING
			-- Read RESP response from socket.
		local
			l_line: STRING
			l_length: INTEGER
			l_data: STRING
			l_count: INTEGER
			l_full_response: STRING
			i: INTEGER
		do
			a_socket.read_line
			l_line := a_socket.last_string.twin

			if l_line.count > 0 then
				inspect l_line.item (1)
				when '+', '-', ':' then
					-- Simple string, error, or integer
					Result := l_line
				when '$' then
					-- Bulk string
					l_length := l_line.substring (2, l_line.count).to_integer
					if l_length >= 0 then
						create l_data.make (l_length)
						a_socket.read_stream (l_length)
						l_data := a_socket.last_string.twin
						a_socket.read_line  -- consume trailing CRLF
						Result := "$" + l_length.out + crlf + l_data
					else
						Result := "$-1"  -- Null
					end
				when '*' then
					-- Array
					l_count := l_line.substring (2, l_line.count).to_integer
					create l_full_response.make (100)
					l_full_response.append (l_line)
					l_full_response.append (crlf)
					from i := 1 until i > l_count loop
						if attached read_response (a_socket) as elem then
							l_full_response.append (elem)
							l_full_response.append (crlf)
						end
						i := i + 1
					end
					Result := l_full_response
				else
					Result := l_line
				end
			end
		end

	parse_bulk_string (a_response: STRING): detachable STRING
			-- Parse bulk string from RESP response.
		local
			l_newline_pos: INTEGER
		do
			-- Format: $<length>\r\n<data>\r\n
			l_newline_pos := a_response.index_of ('%N', 1)
			if l_newline_pos > 0 and l_newline_pos < a_response.count then
				Result := a_response.substring (l_newline_pos + 1, a_response.count)
				-- Remove trailing \r\n if present
				if Result.count >= 2 and then Result.item (Result.count) = '%N' then
					Result := Result.substring (1, Result.count - 1)
				end
				if Result.count >= 1 and then Result.item (Result.count) = '%R' then
					Result := Result.substring (1, Result.count - 1)
				end
			end
		end

	parse_array_response (a_response: STRING): ARRAYED_LIST [STRING]
			-- Parse array from RESP response.
		local
			l_lines: LIST [STRING]
			l_count: INTEGER
			i: INTEGER
			l_line: STRING
		do
			create Result.make (10)
			l_lines := a_response.split ('%N')
			if l_lines.count > 0 then
				l_line := l_lines.first
				if l_line.starts_with ("*") then
					if l_line.count > 1 then
						l_count := l_line.substring (2, l_line.count).to_integer
					end
				end
				-- Parse bulk strings from remaining lines
				from
					i := 2
				until
					i > l_lines.count or Result.count >= l_count
				loop
					l_line := l_lines.i_th (i)
					if l_line.starts_with ("$") then
						-- Next line is the value
						if i + 1 <= l_lines.count then
							Result.extend (l_lines.i_th (i + 1))
							i := i + 1
						end
					end
					i := i + 1
				end
			end
		end

	crlf: STRING = "%R%N"
			-- Carriage return + line feed

feature {NONE} -- Implementation

	socket: detachable NETWORK_STREAM_SOCKET
			-- TCP socket to Redis server

invariant
	host_not_empty: not host.is_empty
	valid_port: port > 0 and port < 65536
	valid_database: database >= 0

end
