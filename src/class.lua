module('class', package.seeall)

Object = {}

function Object:makeMetatable()
   mt = {__index = self}
   return mt
end

function Object:subclass(c)
   c = c or {}
   c.super = self

   for k, v in pairs(self) do
      c[k] = c[k] or v
   end

   c.metatable = c:makeMetatable()
   return c
end

function Object:make(o)
   o = o or {}
   --o.class = self
   setmetatable(o, self.metatable)
   self:initialize(o)
   return o
end

function Object:initialize(o)
   if self.init then
      self.init(o)
   end
   if self.super then
      self.super:initialize(o)
   end
end
