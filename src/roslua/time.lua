
----------------------------------------------------------------------------
--  time.lua - time related classes and functions
--
--  Created: Mon Aug 09 14:11:59 2010 (at Intel Research, Pittsburgh)
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--
----------------------------------------------------------------------------

-- Licensed under BSD license

--- Time utility class for roslua.
-- This module provides the Time class. Currently, it always uses the local
-- system time and not the central ROS time.
-- @copyright Tim Niemueller, Carnegie Mellon University, Intel Research Pittsburgh
-- @release Released under BSD license
module("roslua.time", package.seeall)

require("pimpedposix")

Time = { sec = 0, nsec = 0 }

--- Contructor.
-- @param sec seconds, 0 if not supplied
-- @param nsec nano seconds, 0 if not supploed
-- @return new Time instance
function Time:new(sec, nsec)
   local o = {}
   setmetatable(o, self)
   self.__index = self

   o.sec  = sec  or 0
   o.nsec = nsec or 0

   -- for deserialization compatibility
   o[1]   = o.sec
   o[2]   = o.nsec

   return o
end

--- Check if given table is an instance of Time.
-- @param t instance to check
-- @return true if given object t is an instance of Time
function Time.is_instance(t)
   return getmetatable(t) == Time
end

--- Clone an instance (copy constructor).
-- @param time Time instance to clone
-- @return new instances for the same time as the given one
function Time:clone()
   return Time:new(self.sec, self.nsec)
end

--- Get current time.
-- @return new Time instance set to the current time
function Time.now()
   local t = Time:new()
   t:stamp()
   return t
end


--- Set to current time.
function Time:stamp()
   self.sec, self.nsec = posix.clock_gettime(posix.CLOCK_REALTIME)
end

--- Create Time from seconds.
-- @param sec seconds since the epoch as a floating point number,
-- the fraction is converted internally to nanoseconds
-- @return new instance for the given time
function Time.from_sec(sec)
   local t = Time:new()
   t.sec  = math.floor(sec)
   t.nsec = (sec - t.sec) * 1000000000
   return t
end


--- Create Time from message array.
-- @param a array that contains two entries, index 1 must be seconds, index 2 must
-- be nano seconds.
-- @return new instance for the given time
function Time.from_message_array(a)
   local t = Time:new()
   t.sec  = a[1]
   t.nsec = math.floor(a[2] / 1000.)
   return t
end

--- Check if time is zero.
-- @return true if sec and nsec fields are zero, false otherwise
function Time:is_zero()
   return self.sec == 0 and self.nsec == 0
end


--- Set sec and nsec values.
-- @param sec new seconds value
-- @param nsec new nano seconds value
function Time:set(sec, nsec)
   self.sec  = sec or 0
   self.nsec = nsec or 0
end


--- Convert time to seconds.
-- @return floating point number in seconds.
function Time:to_sec()
   return self.sec + self.nsec / 1000000
end


--- Add the given times t1 and t2.
-- @param t1 first time to add
-- @param t2 second time to add
-- @return new time instance with the sum of t1 and t2
function Time.__add(t1, t2)
   local t = Time:new()
   t.sec  = t1.sec + t2.sec
   t.nsec = t1.nsec + t2.nsec
   if t.nsec > 1000000 then
      local n = math.floor(t.nsec / 1000000000)
      t.sec  = t.sec  + n
      t.nsec = t.nsec - n * 1000000000
   end
   return t
end


--- Subtract t2 from t1.
-- @param t1 time to subtract from
-- @param t2 time to subtract
-- @return new time instance for the result of t1 - t2
function Time.__sub(t1, t2)
   local t = Time:new()
   t.sec = t1.sec - t2.sec
   t.nsec = t1.nsec - t2.nsec
   if t.nsec < 0 then
      local n = math.floor(-t.nsec / 1000000000)
      t.sec  = t.sec  - n
      t.nsec = t.nsec + n * 1000000000
   end
   return t
end


--- Check if times equal.
-- @param t1 first time to compare
-- @param t2 second time to compare
-- @return true if t1 == t2, false otherwise
function Time.__eq(t1, t2)
   return t1.sec == t2.sec and t1.nsec == t2.nsec
end

--- Check if t1 is less than t2.
-- @param t1 first time to compare
-- @param t2 second time to compare
-- @return true if t1 < t2, false otherwise
function Time.__lt(t1, t2)
   return t1.sec < t2.sec or (t1.sec == t2.sec and t1.nsec < t2.nsec)
end

--- Check if t1 is greater than t2.
-- @param t1 first time to compare
-- @param t2 second time to compare
-- @return true if t1 > t2, false otherwise
function Time.__gt(t1, t2)
   return t1.sec > t2.sec or (t1.sec == t2.sec and t1.nsec > t2.nsec)
end


--- Convert time to string.
-- @param t time to convert
-- @return string representing this time
function Time.__tostring(t)
   if t.sec < 1000000000 then
      return tostring(t.sec) .. "." .. tostring(t.nsec)
   else
      local tm = posix.localtime(t.sec)
      return posix.strftime("%H:%M:%S", tm) .. "." ..tostring(t.nsec)
   end
end

--- Format time as string.
-- @param format format string, cf. documentation of your system's strftime
-- @return string representation of this time given the supplied format
function Time:format(format)
   local format = format or "%H:%M:%S"
   local tm = posix.localtime(t.sec)
   return posix.strftime(format, tm) .. "." ..tostring(t.nsec)
end