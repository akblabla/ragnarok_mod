local GrooveVerb = require "wargroove/groove_verb"
local Wargroove = require "wargroove/wargroove"
local Resumable = require "wargroove/resumable"

local MiniGrooveVerb = GrooveVerb:new()


function MiniGrooveVerb:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MiniGrooveVerb:getGrooveId(unit)
    return unit.miniGrooveId;
end

return MiniGrooveVerb
