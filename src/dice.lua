module('dice', package.seeall)

require 'tcod'

local gen = tcod.Random()

function getInt(a, b)
   return gen:getInt(a, b)
end

-- roll AdB+C
function roll(d)
   local a, b, c = unpack(d)
   local n = c
   for i = 1, a do
      n = n + gen:getInt(1, b)
   end
   return n
end

function describe(d)
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

function choiceLevel(tbl, level)
   local n = 0
   for _, v in ipairs(tbl) do
      if not level or v.level <= level then
         n = n + 1
      end
   end
   n = getInt(1, n)
   for _, v in ipairs(tbl) do
      if not level or v.level <= level then
         n = n - 1
         if n == 0 then
            return v
         end
      end
   end
end

-- Fisher-Yates shuffle
function shuffle(tbl)
   for i = #tbl, 2, -1 do
      local j = gen:getInt(1, i)
      tbl[j], tbl[i] = tbl[i], tbl[j]
   end
end
