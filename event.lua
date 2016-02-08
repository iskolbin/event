local pairs = pairs

local _listeners, _n

local event = {} 

function event.bind( source, listener )
	if listener ~= nil then
		local listeners = _listeners[source]
		if not listeners then
			_listeners[source] = {[listener] = listener}
			_n[source] = 1
		else
			if listeners[listener] == nil then
				_n[source] = _n[source] + 1
			end
			listeners[listener] = listener
		end
	end
end
		
function event.unbind( source, listener )
	if listener ~= nil then
		local listeners = _listeners[source] 
		if listeners and listeners[listener] then
			local n = _n[source]
			if n > 1 then
				listeners[listener] = nil
				_n[source] = n - 1
			else
				_listeners[source] = nil
				_n[source] = nil
			end
		end
	end
end

local function async( source, message, ... )
	local listeners = _listeners[source]
	if listeners then
		for listener, _ in pairs( listeners ) do
			if listener[message] then
				listener[message]( listener, source, ... )
			end
		end
	end
end

event.async = async

local queue, m, locked = {}, 0, false
local unpack = table.unpack or unpack

function event.emit( source, message, ... )
	if locked == false then
		locked = true
		async( source, message, ... )
		local i = 0
		while i < m do
			i = i + 1
			async( unpack( queue[i] ))
		end

		if m > 0 then
			queue = {}
			m = 0
		end

		locked = false
	else
		m = m + 1
		queue[m] = {source, message, ...}
	end
end

function event.bindAll( source, listeners, n )
	for i = 1, n or #listeners do
		event.bind( source, listeners[i] )
	end
end

function event.unbindAll( source, listeners, n )
	if listeners then
		for i = 1, n or #listeners do
			event.unbind( source, listeners[i] )
		end
	else
		_listeners[source] = nil
	end
end

function event.reset()
	_listeners = setmetatable( {}, {__mode = 'k'} )
	_n = setmetatable( {}, {__mode = 'k'} )

	queue, m, locked = {}, 0, false
end

event.reset()

return event
