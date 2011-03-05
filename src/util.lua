module('util', package.seeall)

function descr_a(s)
   local c = s:sub(1,1)
   if c:match('%u') then
      return s
   elseif c:match('[aeiou]') then
      return 'an ' .. s
   else
      return 'a ' .. s
   end
end

function descr_the(s)
   c = s:sub(1,1)
   if c:match('%u') then
      return s
   else
      return 'the ' .. s
   end
end

function delete(tbl, e)
   for i, e2 in ipairs(tbl) do
      if e2 == e then
         table.remove(tbl, i)
         return
      end
   end
   assert(false, 'element not found')
end

function capitalize(s)
   return s:sub(1,1):upper() .. s:sub(2)
end
