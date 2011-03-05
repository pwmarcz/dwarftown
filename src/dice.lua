module('dice', package.seeall)

require 'tcod'

local gen = tcod.Random()

-- roll AdB+C
function roll(d)
   local a, b, c = unpack(d)
   local n = c
   for i = 1, a do
      n = n + gen:getInt(1, b)
   end
   return n
end

function format(d)
   local a, b, c = unpack(d)

   s = a .. 'd' .. b
   if c > 0 then
      s = s .. '+' .. c
   elseif c < 0 then
      s = s .. '-' .. -c
   end
   return s
end

function choice(tbl)
   return tbl[gen:getInt(1, #tbl)]
end
