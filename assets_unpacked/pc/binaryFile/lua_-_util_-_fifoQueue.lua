local FIFO = {}
package.loaded["FIFO"] = FIFO

function FIFO:new()
    self = {}
    self.first = 0
    self.last = -1
    return self
end

function FIFO:isEmpty ()
	return self.first>self.last
end

function FIFO:pushleft (value)
  local first = self.first - 1
  self.first = first
  self[first] = value
end

function FIFO:pushright (value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

function FIFO:popleft ()
  local first = self.first
  if first > self.last then error("fifo is empty") end
  local value = self[first]
  self[first] = nil        -- to allow garbage collection
  self.first = first + 1
  return value
end

function FIFO:popright ()
  local last = self.last
  if self.first > last then error("fifo is empty") end
  local value = self[last]
  self[last] = nil         -- to allow garbage collection
  self.last = last - 1
  return value
end

return FIFO