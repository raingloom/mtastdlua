--reimplements a subset of the standard io library
--[[io keys:
input
stdin
tmpfile
read
output
open
close
write
popen
flush
type
lines
stdout
stderr
]]
local IO = {}
local IOFile = {}


--TODO: check std error strings
function IO.open ( path, mode )
	local ret = {}
	local file
	mode = mode or 'r'
	local m, u, b = mode:match '^([rwa])(%+?)(b?)$'
	assert ( m, 'invalid mode string' )
	local mread = m == 'r' or m == 'a'
	local mwrite = m == 'w' or m == 'a'
	local mupdate = #u > 0
	local mappend = m == 'a'
	local exists = File.exists ( path )
	if mread then
		assert ( exists , 'File does not exist' )
	end
	if mread or mappend then
		if exists then
			file = File ( path )
		else
			file = File.new ( path )
		end
	end
	if mwrite then
		file = File.new ( path )
	end
	ret.mread = mread
	ret.mwrite = mwrite
	ret.mappend = mappend
	ret.file = file
	ret.type = 'file'
	return setmetatable ( ret, IOFile )
end


--[[notes
	vararg functions don't work the same way in standard Lua as in LuaJIT, probably due to 5.2 compatibility
	there is no other way to distinguish between passing `nil` as an argument and not passing any arguments than checking vararg or using table.pack
	since MTA currently uses vanilla Lua, there should be no problems
]]
function IO.type ( ... )
	if arg.n then
		local f = arg[1]
		if type ( f ) == 'table' then
			if getmetatable ( f ) == fileMt then
				return f.type
			end
		end
	else
		error "bad argument #1 to '?' (value expected)"
	end
end



--TODO: test argument defaults
--TODO: check how settings the position outside the file works
--success: currentPos
--fail: nil + errstr
function IO.seek ( file, whence, offset )
	--TODO: enforce append/update options
	local twhence, toffset = type ( whence ), type ( offset )
	local err = 'invalid arguments'
	if twhence == 'nil' then
		if toffset == 'number' then
			whence = offset
		else
			return nil, err
		end
	end
	offset = offset or 0
	whence = whence or 'cur'
	if whence == 'set' then
		file.file.pos = offset
	elseif whence == 'cur' then
		file.file.pos = file.file.pos + offset
	elseif whence == 'end' then
		file.file.pos = file.file.size + offset
	else
		return nil, err
	end
	return file.file.pos
end


return IO