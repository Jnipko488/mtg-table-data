JSON = (function()
-- -*- coding: utf-8 -*-
-- http://regex.info/blog/lua/json
-- 
-- Dan - Edited this quite a bit so we can .encode/.decode instead of :encode/:decode.
-- The tradeoff is we can't use the strict types.
--
-- Simple JSON encoding and decoding in pure Lua.
--
-- Copyright 2010-2014 Jeffrey Friedl
-- http://regex.info/blog/
--
-- Latest version: http://regex.info/blog/lua/json
--
-- This code is released under a Creative Commons CC-BY "Attribution" License:
-- http://creativecommons.org/licenses/by/3.0/deed.en_US
--
-- It can be used for any purpose so long as the copyright notice above,
-- the web-page links above, and the 'AUTHOR_NOTE' string below are
-- maintained.Enjoy.
--
local VERSION = 20141223.14-- version history at end of file
local AUTHOR_NOTE = "-[ JSON.lua package by Jeffrey Friedl (http://regex.info/blog/lua/json) version 20141223.14 ]-"

--
-- The 'AUTHOR_NOTE' variable exists so that information about the source
-- of the package is maintained even in compiled versions.It's also
-- included in OBJDEF below mostly to quiet warnings about unused variables.
--
local OBJDEF = {
        VERSION = VERSION,
   AUTHOR_NOTE = AUTHOR_NOTE,
}


--
-- Simple JSON encoding and decoding in pure Lua.
-- http://www.json.org/
--
--
--   JSON = assert(loadfile "JSON.lua")()-- one-time load of the routines
--
--   local lua_value = JSON:decode(raw_json_text)
--
--   local raw_json_text = JSON:encode(lua_table_or_value)
--   local pretty_json_text = JSON:encode_pretty(lua_table_or_value) -- "pretty printed" version for human readability
--
--
--
-- DECODING(from a JSON string to a Lua table)
--
--
--   JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines
--
--   local lua_value = JSON:decode(raw_json_text)
--
--   If the JSON text is for an object or an array, e.g.
--     { "what": "books", "count": 3 }
--   or
--     [ "Larry", "Curly", "Moe" ]
--
--   the result is a Lua table, e.g.
--     { what = "books", count = 3 }
--   or
--     { "Larry", "Curly", "Moe" }
--
--
--   The encode and decode routines accept an optional second argument,
--   "etc", which is not used during encoding or decoding, but upon error
--   is passed along to error handlers.It can be of any type(including nil).
--
--
--
-- ERROR HANDLING
--
--   With most errors during decoding, this code calls
--
--      JSON:onDecodeError(message, text, location, etc)
--
--   with a message about the error, and if known, the JSON text being
--   parsed and the byte count where the problem was discovered. You can
--   replace the default JSON:onDecodeError() with your own function.
--
--   The default onDecodeError() merely augments the message with data
--   about the text and the location if known (and if a second 'etc'
--   argument had been provided to decode(), its value is tacked onto the
--   message as well), and then calls JSON.assert(), which itself defaults
--   to Lua's built-in assert(), and can also be overridden.
--
--   For example, in an Adobe Lightroom plugin, you might use something like
--
--          function JSON:onDecodeError(message, text, location, etc)
--             LrErrors.throwUserError("Internal Error: invalid JSON data")
--          end
--
--   or even just
--
--          function JSON.assert(message)
--             LrErrors.throwUserError("Internal Error: " .. message)
--          end
--
--   If JSON:decode() is passed a nil, this is called instead:
--
--      JSON:onDecodeOfNilError(message, nil, nil, etc)
--
--   and if JSON:decode() is passed HTML instead of JSON, this is called:
--
--      JSON:onDecodeOfHTMLError(message, text, nil, etc)
--
--   The use of the fourth 'etc' argument allows stronger coordination
--   between decoding and error reporting, especially when you provide your
--   own error-handling routines. Continuing with the the Adobe Lightroom
--   plugin example:
--
--          function JSON:onDecodeError(message, text, location, etc)
--             local note = "Internal Error: invalid JSON data"
--             if type(etc) = 'table' and etc.photo then
--                note = note .. " while processing for " .. etc.photo:getFormattedMetadata('fileName')
--             end
--             LrErrors.throwUserError(note)
--          end
--
--            :
--            :
--
--          for i, photo in ipairs(photosToProcess) do
--               :             
--               :             
--               local data = JSON:decode(someJsonText, { photo = photo })
--               :             
--               :             
--          end
--
--
--
--
--
-- DECODING AND STRICT TYPES
--
--   Because both JSON objects and JSON arrays are converted to Lua tables,
--   it's not normally possible to tell which original JSON type a
--   particular Lua table was derived from, or guarantee decode-encode
--   round-trip equivalency.
--
--   However, if you enable strictTypes, e.g.
--
--      JSON = assert(loadfile "JSON.lua")() --load the routines
--      JSON.strictTypes = true
--
--   then the Lua table resulting from the decoding of a JSON object or
--   JSON array is marked via Lua metatable, so that when re-encoded with
--   JSON:encode() it ends up as the appropriate JSON type.
--
--   (This is not the default because other routines may not work well with
--   tables that have a metatable set, for example, Lightroom API calls.)
    --
    --
    --ENCODING(from a lua table to a JSON string)
    --
    --   JSON = assert(loadfile "JSON.lua")()-- one - time load of the routines
--
--local raw_json_text = JSON:encode(lua_table_or_value)
--   local pretty_json_text = JSON:encode_pretty(lua_table_or_value)-- "pretty printed" version for human readability
--local custom_pretty = JSON:encode(lua_table_or_value, etc, { pretty = true, indent = "|  ", align_keys = false })
--
--On error during encoding, this code calls:
--
--JSON:onEncodeError(message, etc)
--
--   which you can override in your local JSON object.
--
--   The 'etc' in the error call is the second argument to encode()
--   and encode_pretty(), or nil if it wasn't provided.
--
--
-- PRETTY - PRINTING
--
--   An optional third argument, a table of options, allows a bit of
--configuration about how the encoding takes place:
--
--pretty = JSON:encode(val, etc, {
    --pretty = true,      -- if false, no other options matter
--indent = "   ",     --this provides for a three-space indent per nesting level
--                                       align_keys = false, --see below
--                                     })
--
--encode() and encode_pretty() are identical except that encode_pretty()
--   provides a default options table if none given in the call:
--
--       { pretty = true, align_keys = false, indent = "  " }
--
--For example, if
--
--JSON:encode(data)
--
--   produces:
--
--      { "city":"Kyoto","climate":{ "avg_temp":16,"humidity":"high","snowfall":"minimal"},"country":"Japan","wards":11}
--
--then
--
--      JSON: encode_pretty(data)
 --
 --   produces:
--
--      {
    --"city": "Kyoto",
--"climate": {
        --"avg_temp": 16,
--"humidity": "high",
--"snowfall": "minimal"
--        },
--"country": "Japan",
--"wards": 11
--      }
--
--The following three lines return identical results:
--JSON:encode_pretty(data)
--       JSON: encode_pretty(data, nil, { pretty = true, align_keys = false, indent = "  " })
--JSON:encode(data, nil, { pretty = true, align_keys = false, indent = "  " })
--
--An example of setting your own indent string:
--
--JSON:encode_pretty(data, nil, { pretty = true, indent = "|    " })
--
--produces:
--
--      {
    --      | "city": "Kyoto",
--      | "climate": {
        --      |    | "avg_temp": 16,
--      |    | "humidity": "high",
--      |    | "snowfall": "minimal"
-- |    },
--      | "country": "Japan",
--      | "wards": 11
--      }
--
--An example of setting align_keys to true:
--
--JSON:encode_pretty(data, nil, { pretty = true, indent = "  ", align_keys = true })
--
--produces:
--
--      {
    --"city": "Kyoto",
--"climate": {
        --"avg_temp": 16,
--"humidity": "high",
--"snowfall": "minimal"
--                   },
--"country": "Japan",
--"wards": 11
--      }
--
--which I must admit is kinda ugly, sorry.This was the default for
--encode_pretty() prior to version 20141223.14.
--
--
--  AMBIGUOUS SITUATIONS DURING THE ENCODING
--
--   During the encode, if a Lua table being encoded contains both string
--and numeric keys, it fits neither JSON's idea of an object, nor its
--   idea of an array. To get around this, when any string key exists(or
--   when non - positive numeric keys exist), numeric keys are converted to
--   strings.
--
--   For example,
--JSON:encode({ "one", "two", "three", SOMESTRING = "some string" }))
--produces the JSON object
--     { "1":"one","2":"two","3":"three","SOMESTRING":"some string"}
--
--To prohibit this conversion and instead make it an error condition, set
--JSON.noKeyConversion = true
--




--
-- SUMMARY OF METHODS YOU CAN OVERRIDE IN YOUR LOCAL LUA JSON OBJECT
--
--assert
--    onDecodeError
--    onDecodeOfNilError
--    onDecodeOfHTMLError
--    onEncodeError
--
--  If you want to create a separate Lua JSON object with its own error handlers,
--you can reload JSON.lua or use the :new() method.
--
-------------------------------------------------------------------------- -

local default_pretty_indent = "  "
local default_pretty_options = { pretty = true, align_keys = false, indent = default_pretty_indent }

local isArray = { __tostring = function() return "JSON array"  end }
isArray.__index  = isArray
local isObject = { __tostring = function() return "JSON object" end }
isObject.__index = isObject


function OBJDEF:newArray(tbl)
   return setmetatable(tbl or { }, isArray)
end

function OBJDEF:newObject(tbl)
   return setmetatable(tbl or { }, isObject)
end

local function unicode_codepoint_as_utf8(codepoint)
   --
   -- codepoint is a number
   --
   if codepoint <= 127 then
      return string.char(codepoint)

   elseif codepoint <= 2047 then
      --
      -- 110yyyxx 10xxxxxx         <-- useful notation from http://en.wikipedia.org/wiki/Utf8
      --
      local highpart = math.floor(codepoint / 0x40)
      local lowpart  = codepoint - (0x40 * highpart)
      return string.char(0xC0 + highpart,
                         0x80 + lowpart)

   elseif codepoint <= 65535 then
      --
      -- 1110yyyy 10yyyyxx 10xxxxxx
      --
      local highpart  = math.floor(codepoint / 0x1000)
      local remainder = codepoint - 0x1000 * highpart
      local midpart   = math.floor(remainder / 0x40)
      local lowpart   = remainder - 0x40 * midpart

      highpart = 0xE0 + highpart
      midpart  = 0x80 + midpart
      lowpart  = 0x80 + lowpart

      --
      -- Check for an invalid character (thanks Andy R. at Adobe).
      -- See table 3.7, page 93, in http://www.unicode.org/versions/Unicode5.2.0/ch03.pdf#G28070
      --
      if ( highpart == 0xE0 and midpart < 0xA0 ) or
         ( highpart == 0xED and midpart > 0x9F ) or
         ( highpart == 0xF0 and midpart < 0x90 ) or
         ( highpart == 0xF4 and midpart > 0x8F )
      then
         return "?"
      else
         return string.char(highpart,
                            midpart,
                            lowpart)
      end

   else
      --
      -- 11110zzz 10zzyyyy 10yyyyxx 10xxxxxx
      --
      local highpart  = math.floor(codepoint / 0x40000)
      local remainder = codepoint - 0x40000 * highpart
      local midA      = math.floor(remainder / 0x1000)
      remainder       = remainder - 0x1000 * midA
      local midB      = math.floor(remainder / 0x40)
      local lowpart   = remainder - 0x40 * midB

      return string.char(0xF0 + highpart,
                         0x80 + midA,
                         0x80 + midB,
                         0x80 + lowpart)
   end
end

function OBJDEF.onDecodeError(message, text, location, etc)
   if text then
      if location then
         message = string.format("%s at char %d of: %s", message, location, text)
      else
         message = string.format("%s: %s", message, text)
      end
   end

   if etc ~= nil then
      message = message .. " (" .. OBJDEF.encode(etc) .. ")"
   end

   if self.assert then
      self.assert(false, message)
   else
      assert(false, message)
   end
end

OBJDEF.onDecodeOfNilError  = OBJDEF.onDecodeError
OBJDEF.onDecodeOfHTMLError = OBJDEF.onDecodeError

function OBJDEF:onEncodeError(message, etc)
   if etc ~= nil then
      message = message .. " (" .. OBJDEF:encode(etc) .. ")"
   end

   if self.assert then
      self.assert(false, message)
   else
      assert(false, message)
   end
end

local function grok_number(self, text, start, etc)
   --
   -- Grab the integer part
   --
   local integer_part = text:match('^-?[1-9]%d*', start)
                     or text:match("^-?0",        start)

   if not integer_part then
      --self:onDecodeError("expected number", text, start, etc)
      error('JSON.decode() expected number')
   end

   local i = start + integer_part:len()

   --
   -- Grab an optional decimal part
   --
   local decimal_part = text:match('^%.%d+', i) or ""

   i = i + decimal_part:len()

   --
   -- Grab an optional exponential part
   --
   local exponent_part = text:match('^[eE][-+]?%d+', i) or ""

   i = i + exponent_part:len()

   local full_number_text = integer_part .. decimal_part .. exponent_part
   local as_number = tonumber(full_number_text)

   if not as_number then
      --self:onDecodeError("bad number", text, start, etc)
      error('JSON.decode() found bad number')
   end

   return as_number, i
end


local function grok_string(self, text, start, etc)
   if text:sub(start,start) ~= '"' then
      --self:onDecodeError("expected string's opening quote", text, start, etc)
      error('JSON.decode() expected string\'s opening quote')
   end

   local i = start + 1 -- +1 to bypass the initial quote
   local text_len = text:len()
   local VALUE = ""
   while i <= text_len do
      local c = text:sub(i,i)
      if c == '"' then
         return VALUE, i + 1
      end
      if c ~= '\\' then
         VALUE = VALUE .. c
         i = i + 1
      elseif text:match('^\\b', i) then
         VALUE = VALUE .. "\b"
         i = i + 2
      elseif text:match('^\\f', i) then
         VALUE = VALUE .. "\f"
         i = i + 2
      elseif text:match('^\\n', i) then
         VALUE = VALUE .. "\n"
         i = i + 2
      elseif text:match('^\\r', i) then
         VALUE = VALUE .. "\r"
         i = i + 2
      elseif text:match('^\\t', i) then
         VALUE = VALUE .. "\t"
         i = i + 2
      else
         local hex = text:match('^\\u([0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])', i)
         if hex then
            i = i + 6 -- bypass what we just read

            -- We have a Unicode codepoint. It could be standalone, or if in the proper range and
            -- followed by another in a specific range, it'll be a two-code surrogate pair.
            local codepoint = tonumber(hex, 16)
            if codepoint >= 0xD800 and codepoint <= 0xDBFF then
               -- it's a hi surrogate... see whether we have a following low
               local lo_surrogate = text:match('^\\u([dD][cdefCDEF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])', i)
               if lo_surrogate then
                  i = i + 6 -- bypass the low surrogate we just read
                  codepoint = 0x2400 + (codepoint - 0xD800) * 0x400 + tonumber(lo_surrogate, 16)
               else
                  -- not a proper low, so we'll just leave the first codepoint as is and spit it out.
               end
            end
            VALUE = VALUE .. unicode_codepoint_as_utf8(codepoint)

         else

            -- just pass through what's escaped
            VALUE = VALUE .. text:match('^\\(.)', i)
            i = i + 2
         end
      end
   end

   --self:onDecodeError("unclosed string", text, start, etc)
   error('JSON.decode() found unclosed string')
end

local function skip_whitespace(text, start)

   local _, match_end = text:find("^[ \n\r\t]+", start) -- [http://www.ietf.org/rfc/rfc4627.txt] Section 2
   if match_end then
      return match_end + 1
   else
      return start
   end
end

local grok_one -- assigned later

local function grok_object(self, text, start, etc)
   if text:sub(start, start) ~= '{' then
      --self:onDecodeError("expected '{'", text, start, etc)
      error('JSON.decode() expected \'{\'')
   end

   local i = skip_whitespace(text, start + 1) -- +1 to skip the '{'

   --local VALUE = self.strictTypes and self:newObject { } or { }
   local VALUE = {}

   if text:sub(i, i) == '}' then
      return VALUE, i + 1
   end

   local text_len = text:len()
   while i <= text_len do
      local key, new_i = grok_string(self, text, i, etc)

      i = skip_whitespace(text, new_i)

      if text:sub(i, i) ~= ':' then
         --self:onDecodeError("expected colon", text, i, etc)
        error('JSON.decode() expected colon')
      end

      i = skip_whitespace(text, i + 1)

      local new_val, new_i = grok_one(self, text, i)

      VALUE[key] = new_val

      --
      -- Expect now either '}' to end things, or a ',' to allow us to continue.
      --
      i = skip_whitespace(text, new_i)

      local c = text:sub(i, i)

      if c == '}' then
         return VALUE, i + 1
      end

      if text:sub(i, i) ~= ',' then
         --self:onDecodeError("expected comma or '}'", text, i, etc)
         error('JSON.decode() expected comma or \'}\'')
      end

      i = skip_whitespace(text, i + 1)
   end

   --self:onDecodeError("unclosed '{'", text, start, etc)
    error('JSON.decode() found unclosed \'{\'')
end

local function grok_array(self, text, start, etc)
   if text:sub(start, start) ~= '[' then
       --self:onDecodeError("expected '['", text, start, etc)
       error('JSON.decode() expected \'[\'')
   end

   local i = skip_whitespace(text, start + 1) -- +1 to skip the '['
   --local VALUE = self.strictTypes and self:newArray { } or { }
   local VALUE = { }
   if text:sub(i, i) == ']' then
      return VALUE, i + 1
   end

   local VALUE_INDEX = 1

   local text_len = text:len()
   while i <= text_len do
      local val, new_i = grok_one(self, text, i)

      -- can't table.insert(VALUE, val) here because it's a no-op if val is nil
      VALUE[VALUE_INDEX] = val
      VALUE_INDEX = VALUE_INDEX + 1

      i = skip_whitespace(text, new_i)

      --
      -- Expect now either ']' to end things, or a ',' to allow us to continue.
      --
      local c = text:sub(i, i)
      if c == ']' then
         return VALUE, i + 1
      end
      if text:sub(i, i) ~= ',' then
         --self:onDecodeError("expected comma or '['", text, i, etc)
         error('JSON.decode() found unlcosed \'[\'')
      end
      i = skip_whitespace(text, i + 1)
   end
   --self:onDecodeError("unclosed '['", text, start, etc)
   error('JSON.decode() found unlcosed \'[\'')
end


grok_one = function(self, text, start, etc)
   -- Skip any whitespace
   start = skip_whitespace(text, start)

   if start > text:len() then
      error('JSON.decode() found unexpected end of string')
   end

   if text:find('^"', start) then
      return grok_string(self, text, start, etc)

   elseif text:find('^[-0123456789 ]', start) then
      return grok_number(self, text, start, etc)

   elseif text:find('^%{', start) then
      return grok_object(self, text, start, etc)

   elseif text:find('^%[', start) then
      return grok_array(self, text, start, etc)

   elseif text:find('^true', start) then
      return true, start + 4

   elseif text:find('^false', start) then
      return false, start + 5

   elseif text:find('^null', start) then
      return nil, start + 4

   else
      --self.onDecodeError("can\'t parse JSON", text, start, etc)
      error('JSON.decode() can\'t parse JSON')
   end
end

--[[
This is weird. OBJDEF:decode is needed if we want to use 'self' for the strict types in grok_object, etc.
--]]
function OBJDEF.decode(text, etc)
   if type(self) ~= 'table' or self.__index ~= OBJDEF then
      --OBJDEF:onDecodeError("JSON:decode must be called in method format", nil, nil, etc)
   end

   if text == nil then
      error('Expected string argument to JSON.decode(), got nil')
   elseif type(text) ~= 'string' then
      error('Expected string argument to JSON.decode(), got '.. type(text))
      return nil
   end

   if text:match('^%s*$') then
      return nil
   end

   if text:match('^%s*<') then
      -- Can't be JSON... we'll assume it's HTML
      error('Expected string argument to JSON.decode(), got HTML?')
   end

   --
   -- Ensure that it's not UTF-32 or UTF-16.
   -- Those are perfectly valid encodings for JSON(as per RFC 4627 section 3),
   -- but this package can't handle them.
   --
   if text:sub(1,1):byte() == 0 or (text:len() >= 2 and text:sub(2,2):byte() == 0) then
      error('JSON.decode() only works with UTF-8')
   end

   local success, value = pcall(grok_one, self, text, 1, etc)

   if success then
      return value
   else
      -- if JSON:onDecodeError() didn't abort out of the pcall, we'll have received the error message here as "value", so pass it along as an assert.
      if self.assert then
         self.assert(false, value)
      else
         assert(false, value)
      end
      -- and if we're still here, return a nil and throw the error message on as a second arg
      return nil, value
   end
end

local function backslash_replacement_function(c)
   if c == "\n" then
      return "\\n"
   elseif c == "\r" then
      return "\\r"
   elseif c == "\t" then
      return "\\t"
   elseif c == "\b" then
      return "\\b"
   elseif c == "\f" then
      return "\\f"
   elseif c == '"' then
      return '\\"'
   elseif c == '\\' then
      return '\\\\'
   elseif c < ' ' then
      return string.format("\\u%04x", c:byte())
   else
      return c
   end
end

local chars_to_be_escaped_in_JSON_string
   = '['
   ..    '"'   -- class sub-pattern to match a double quote
   ..    '%\\'  -- class sub-pattern to match a backslash
   ..    '%z'   -- class sub-pattern to match a null
   ..    '%c'   -- class sub-pattern to match control characters
   .. ']'

local function json_string_literal(value)
   local newval = value:gsub(chars_to_be_escaped_in_JSON_string, backslash_replacement_function)
   return '"' .. newval.. '"'
end

local function object_or_array(self, T, etc)
   --
   -- We need to inspect all the keys... if there are any strings, we'll convert to a JSON
   -- object. If there are only numbers, it's a JSON array.
   --
   -- If we'll be converting to a JSON object, we'll want to sort the keys so that the
   -- end result is deterministic.
   --
   local string_keys = { }
   local number_keys = { }
   local number_keys_must_be_strings = false
   local maximum_number_key

   for key in pairs(T) do
      if type(key) == 'string' then
         table.insert(string_keys, key)
      elseif type(key) == 'number' then
         table.insert(number_keys, key)
         if key <= 0 or key >= math.huge then
            number_keys_must_be_strings = true
         elseif not maximum_number_key or key > maximum_number_key then
            maximum_number_key = key
         end
      else
         --self:onEncodeError("can't encode table with a key of type " .. type(key), etc)
         error('JSON.encode() can\'t encode table with a key of type' .. type(key))
      end
   end

   if #string_keys == 0 and not number_keys_must_be_strings then
      --
      -- An empty table, or a numeric-only array
      --
      if #number_keys > 0 then
         return nil, maximum_number_key -- an array
      elseif tostring(T) == "JSON array" then
         return nil
      elseif tostring(T) == "JSON object" then
         return { }
      else
         -- have to guess, so we'll pick array, since empty arrays are likely more common than empty objects
         return nil
      end
   end

   table.sort(string_keys)

   local map
   if #number_keys > 0 then
      --
      -- If we're here then we have either mixed string/number keys, or numbers inappropriate for a JSON array
      -- It's not ideal, but we'll turn the numbers into strings so that we can at least create a JSON object.
      --

      if self.noKeyConversion then
         --self:onEncodeError("a table with both numeric and string keys could be an object or array; aborting", etc)
         error('JSON.encode() - a table with both numeric and string keys could be an object or array; aborting')
      end

      --
      -- Have to make a shallow copy of the source table so we can remap the numeric keys to be strings
      --
      map = { }
      for key, val in pairs(T) do
         map[key] = val
      end

      table.sort(number_keys)

      --
      -- Throw numeric keys in there as strings
      --
      for _, number_key in ipairs(number_keys) do
         local string_key = tostring(number_key)
         if map[string_key] == nil then
            table.insert(string_keys , string_key)
            map[string_key] = T[number_key]
         else
            --self:onEncodeError("conflict converting table with mixed-type keys into a JSON object: key " .. number_key.. " exists both as a string and a number.", etc)
            error('JSON.encode() - conflict converting table with mixed-type keys into a JSON object: key ' .. number_key.. ' exists both as a string and a number.')
         end
      end
   end

   return string_keys, nil, map
end

--
-- Encode
--
-- 'options' is nil, or a table with possible keys:
--    pretty            -- if true, return a pretty-printed version
--    indent            -- a string (usually of spaces) used to indent each nested level
--    align_keys        -- if true, align all the keys when formatting a table
--
local encode_value -- must predeclare because it calls itself
function encode_value(self, value, parents, etc, options, indent)

   if value == nil then
      return 'null'

   elseif type(value) == 'string' then
      return json_string_literal(value)

   elseif type(value) == 'number' then
      if value ~= value then
         --
         -- NaN(Not a Number).
         -- JSON has no NaN, so we have to fudge the best we can.This should really be a package option.
         --
         return "null"
      elseif value >= math.huge then
         --
         -- Positive infinity. JSON has no INF, so we have to fudge the best we can.This should
         -- really be a package option.Note: at least with some implementations, positive infinity
         -- is both ">= math.huge" and "<= -math.huge", which makes no sense but that's how it is.
         -- Negative infinity is properly "<= -math.huge". So, we must be sure to check the ">="
         -- case first.
         --
         return "1e+9999"
      elseif value <= -math.huge then
         --
         -- Negative infinity.
         -- JSON has no INF, so we have to fudge the best we can.This should really be a package option.
         --
         return "-1e+9999"
      else
         return tostring(value)
      end

   elseif type(value) == 'boolean' then
      return tostring(value)

   elseif type(value) ~= 'table' then
      --self:onEncodeError("can't convert " .. type(value) .. " to JSON", etc)
      error('JSON.encode() - can\'t convert ' .. type(value) .. ' to JSON')

   else
      --
      -- A table to be converted to either a JSON object or array.
      --
      local T = value

      if type(options) ~= 'table' then
         options = { }
      end
      if type(indent) ~= 'string' then
         indent = ""
      end

      if parents[T] then
         --self:onEncodeError("table " .. tostring(T) .. " is a child of itself", etc)
         error('JSON.encode() - table ' .. tostring(T) .. ' is a child of itself')
      else
         parents[T] = true
      end

      local result_value

      local object_keys, maximum_number_key, map = object_or_array(self, T, etc)
      if maximum_number_key then
         --
         -- An array...
         --
         local ITEMS = { }
         for i = 1, maximum_number_key do
            table.insert(ITEMS, encode_value(self, T[i], parents, etc, options, indent))
         end

         if options.pretty then
            result_value = "[ " .. table.concat(ITEMS, ", ") .. " ]"
         else
            result_value = "["  .. table.concat(ITEMS, ",")  .. "]"
         end

      elseif object_keys then
         --
         -- An object
         --
         local TT = map or T

         if options.pretty then

            local KEYS = { }
            local max_key_length = 0
            for _, key in ipairs(object_keys) do
               local encoded = encode_value(self, tostring(key), parents, etc, options, indent)
               if options.align_keys then
                  max_key_length = math.max(max_key_length, #encoded)
               end
               table.insert(KEYS, encoded)
            end
            local key_indent = indent..tostring(options.indent or "")
            local subtable_indent = key_indent.. string.rep(" ", max_key_length) .. (options.align_keys and "  " or "")
            local FORMAT = "%s%".. string.format("%d", max_key_length) .. "s: %s"

            local COMBINED_PARTS = { }
            for i, key in ipairs(object_keys) do
               local encoded_val = encode_value(self, TT[key], parents, etc, options, subtable_indent)
               table.insert(COMBINED_PARTS, string.format(FORMAT, key_indent, KEYS[i], encoded_val))
            end
            result_value = "{\n"..table.concat(COMBINED_PARTS, ",\n").. "\n" .. indent.. "}"

         else

            local PARTS = { }
            for _, key in ipairs(object_keys) do
               local encoded_val = encode_value(self, TT[key], parents, etc, options, indent)
               local encoded_key = encode_value(self, tostring(key), parents, etc, options, indent)
               table.insert(PARTS, string.format("%s:%s", encoded_key, encoded_val))
            end
            result_value = "{"..table.concat(PARTS, ",").. "}"

         end
      else
         --
         -- An empty array/object... we'll treat it as an array, though it should really be an option
         --
         result_value = "[]"
      end

      parents[T] = false
      return result_value
   end
end


function OBJDEF.encode(value, etc, options)
   if type(self) ~= 'table' or self.__index ~= OBJDEF then
      --OBJDEF:onEncodeError("JSON:encode must be called in method format", etc)
   end
   return encode_value(self, value, { }, etc, options or nil)
end

function OBJDEF.encode_pretty(value, etc, options)
   if type(self) ~= 'table' or self.__index ~= OBJDEF then
      --OBJDEF:onEncodeError("JSON:encode_pretty must be called in method format", etc)
   end
   return encode_value(self, value, { }, etc, options or default_pretty_options)
end

function OBJDEF.__tostring()
   return "JSON encode/decode package"
end

OBJDEF.__index = OBJDEF

function OBJDEF:new(args)
   local new = { }

   if args then
      for key, val in pairs(args) do
         new[key] = val
      end
   end

   return setmetatable(new, OBJDEF)
end

return OBJDEF:new()

--
-- Version history:
--
--   20141223.14   The encode_pretty() routine produced fine results for small datasets, but isn't really
--                 appropriate for anything large, so with help from Alex Aulbach I've made the encode routines
--                 more flexible, and changed the default encode_pretty() to be more generally useful.
--
--                 Added a third 'options' argument to the encode() and encode_pretty() routines, to control
--                 how the encoding takes place.
--
--                 Updated docs to add assert() call to the loadfile() line, just as good practice so that
--                 if there is a problem loading JSON.lua, the appropriate error message will percolate up.
--
--   20140920.13   Put back (in a way that doesn't cause warnings about unused variables) the author string,
--                 so that the source of the package, and its version number, are visible in compiled copies.
--
--   20140911.12   Minor lua cleanup.
--                 Fixed internal reference to 'JSON.noKeyConversion' to reference 'self' instead of 'JSON'.
--                 (Thanks to SmugMug's David Parry for these.)
--
--   20140418.11   JSON nulls embedded within an array were being ignored, such that
--                     ["1",null,null,null,null,null,"seven"],
--                 would return
--                     {1,"seven"}
--                 It's now fixed to properly return
--                     {1, nil, nil, nil, nil, nil, "seven"}
--                 Thanks to "haddock" for catching the error.
--
--   20140116.10   The user's JSON.assert() wasn't always being used.Thanks to "blue" for the heads up.
--
--   20131118.9    Update for Lua 5.3... it seems that tostring(2/1) produces "2.0" instead of "2",
--                 and this caused some problems.
--
--   20131031.8    Unified the code for encode() and encode_pretty(); they had been stupidly separate,
--                 and had of course diverged (encode_pretty didn't get the fixes that encode got, so
--                 sometimes produced incorrect results; thanks to Mattie for the heads up).
--
--                 Handle encoding tables with non-positive numeric keys (unlikely, but possible).
--
--                 If a table has both numeric and string keys, or its numeric keys are inappropriate
--                 (such as being non-positive or infinite), the numeric keys are turned into
--                 string keys appropriate for a JSON object. So, as before,
--                         JSON:encode({ "one", "two", "three" })
--                 produces the array
--                         ["one","two","three"]
--                 but now something with mixed key types like
--                         JSON:encode({ "one", "two", "three", SOMESTRING = "some string" }))
--                 instead of throwing an error produces an object:
--                         { "1":"one","2":"two","3":"three","SOMESTRING":"some string"}
--
--                 To maintain the prior throw-an-error semantics, set
--JSON.noKeyConversion = true
--
--   20131004.7    Release under a Creative Commons CC-BY license, which I should have done from day one, sorry.
--
--20130120.6    Comment update: added a link to the specific page on my blog where this code can
--be found, so that folks who come across the code outside of my blog can find updates
--                 more easily.
--
--20111207.5    Added support for the 'etc' arguments, for better error reporting.
--
--   20110731.4    More feedback from David Kolf on how to make the tests for Nan / Infinity system independent.
--
--   20110730.3    Incorporated feedback from David Kolf at http://lua-users.org/wiki/JsonModules:
--
--*When encoding lua for JSON, Sparse numeric arrays are now handled by
--                     spitting out full arrays, such that
--                        JSON:encode({ "one", "two", [10] = "ten"})
--                     returns
--                        ["one","two",null,null,null,null,null,null,null,"ten"]
--
--                     In 20100810.2 and earlier, only up to the first non-null value would have been retained.
--
--                   * When encoding lua for JSON, numeric value NaN gets spit out as null, and infinity as "1+e9999".
--                     Version 20100810.2 and earlier created invalid JSON in both cases.
--
--                   * Unicode surrogate pairs are now detected when decoding JSON.
--
--   20100810.2    added some checking to ensure that an invalid Unicode character couldn't leak in to the UTF-8 encoding
--
--   20100731.1    initial public release
--

end)()
Vector = (function()

local Vector = {}
Vector.__isVector = true
Vector.__version = '1.0.1'

function Vector.new(...)
    local vec = setmetatable({
        x = 0,
        y = 0,
        z = 0
    }, Vector)
    
    local argNum = select('#', ...)
    if argNum == 3 then
        -- Vector.new(x, y, z)
        vec.x, vec.y, vec.z = ...
    elseif argNum == 1 and type(...) == 'table' then
        -- Vector.new(table)
        local src = ...
        vec.x = src.x or src[1] or vec.x
        vec.y = src.y or src[2] or vec.y
        vec.z = src.z or src[3] or vec.z
    end
    
    return vec
end
setmetatable(Vector, {__call = function(_, ...) return Vector.new(...) end})

do
    local remap = {'x', 'y', 'z'}
    function Vector:__index(k)
        k = remap[k] or k
        return rawget(self, k) or Vector[k]
    end
    function Vector:__newindex(k, v)
        k = remap[k] or k
        return rawset(self, k, v)
    end
end

function Vector:setAt(k, v)
    self[k] = v
    return self
end

function Vector:set(x, y, z)
    self.x = x or self.x
    self.y = y or self.y
    self.z = z or self.z
    return self
end

function Vector:get()
    return self.x, self.y, self.z
end

function Vector:copy()
    return Vector(self)
end

function Vector:add(other)
    self.x = self.x + other.x
    self.y = self.y + other.y
    self.z = self.z + other.z
    return self
end

function Vector.__add(v1, v2)
    return v1:copy():add(v2)
end

function Vector:sub(other)
    self.x = self.x - other.x
    self.y = self.y - other.y
    self.z = self.z - other.z
    return self
end

function Vector.__sub(v1, v2)
    return v1:copy():sub(v2)
end

function Vector:dot(other)
    return self.x * other.x
        + self.y * other.y
        + self.z * other.z
end

function Vector:sqrMagnitude()
    return self:dot(self)
end

function Vector:magnitude()
    return math.sqrt(self:dot(self))
end

function Vector:scale(...)
    local sx, sy, sz
    
    local argNum = select('#', ...)
    if argNum == 1 then
        local arg = ...
        if type(arg) == 'number' then
            -- vec:scale(number)
            sx, sy, sz = arg, arg, arg
        else
            -- vec:scale(vector)
            sx, sy, sz = arg:get()
        end
    elseif argNum == 3 then
        -- vec:scale(x, y, z)
        sx, sy, sz = ...
        sx = sx or 1
        sy = sy or 1
        sz = sz or 1
    end
    
    self.x = self.x * sx
    self.y = self.y * sy
    self.z = self.z * sz
    return self
end

function Vector.__mul(val1, val2)
    if type(val1) == 'number' then
        val1, val2 = val2, val1
    end
    return val1:copy():scale(val2)
end

function Vector:sqrDistance(other)
    local dx = self.x - other.x
    local dy = self.y - other.y
    local dz = self.z - other.z
    return dx*dx + dy*dy + dz*dz
end

function Vector:distance(other)
    return math.sqrt(self:sqrDistance(other))
end

function Vector:equals(other, margin)
    margin = margin or 1e-3
    return self:sqrDistance(other) <= margin
end

Vector.__eq = Vector.equals

function Vector:string(prefix)
    prefix = prefix and (prefix .. ': ') or ''
    return (('%s{ %f, %f, %f }'):format(
        prefix,
        self.x,
        self.y,
        self.z
        -- cut trailing zeroes from numbers
    ):gsub('%.0+([ ,])', '%1'):gsub('%.(%d-)0+([ ,])', '.%1%2'))
end

function Vector:__tostring()
    return self:string('Vector')
end

function Vector:angle(other)
    local cosAng = self:dot(other) / (self:magnitude() * other:magnitude())
    return math.deg(math.acos(cosAng))
end

function Vector:clamp(maxLen)
    local len = self:magnitude()
    if len <= maxLen then
        return self
    end
    local factor = maxLen/len
    return self:scale(factor)
end

function Vector:cross(other)
    return Vector(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

function Vector.between(from, to)
    return to - from
end

function Vector:lerp(target, t)
    return self:between(target):scale(t):add(self)
end

function Vector:moveTowards(target, maxDist)
    local delta = self:between(target):clamp(maxDist)
    return self:add(delta)
end

function Vector:normalize()
    local sqrLen = self:sqrMagnitude()
    if sqrLen == 1 or sqrLen == 0 then
        return self
    end
        
    return self:scale(1/math.sqrt(sqrLen))
end

function Vector:normalized()
    return self:copy():normalize()
end

function Vector:project(other)
    if other:sqrMagnitude() ~= 1 then
        other = other:normalized()
    end
    local scalar = self:dot(other)
    return self:set(other:get()):scale(scalar)
end

do
    -- skew symmetric cross product
    local function sscp(v)
        return { Vector(   0,  -v.z,  v.y ),
                 Vector(  v.z,   0,  -v.x ),
                 Vector( -v.y,  v.x,   0  ) }
    end
    
    --[[
    local function mDump(m)
        return ('{ %s,\n  %s,\n  %s }'):format(
            m[1], m[2], m[3]
        )
    end
    --]]
    
    local function qMult(x, y, z, w, factor)
        return x*factor, y*factor, z*factor, w*factor
    end
    
    local function qNormalize(x, y, z, w)
        local norm = math.sqrt(x*x + y*y + z*z + w*w)
        return qMult(x, y, z, w, 1/norm)
    end
    
    -- interpolate quaternion
    local function qSlerp(x, y, z, w, t)
        local dot = w
        if dot > 0.0005 then
            return qNormalize(t*x, t*y, t*z, 1 + t*w - t)
        end
        
        local th0 = math.acos(dot)
        local th = th0*t
        local sth = math.sin(th)
        local sth0 = math.sin(th0)
        
        local s1 = sth/sth0
        local s0 = math.cos(th) - dot*s1

        return qMult(x, y, z, w + s0, s1)
    end
        
    local function matrixToQuat(m, scale)
        local w = math.sqrt(1.0 + m[1].x + m[2].y + m[3].z)/2;
        local x = (m[3].y - m[2].z) / (w * 4)
        local y = (m[1].z - m[3].x) / (w * 4)
        local z = (m[2].x - m[1].y) / (w * 4)
        if scale then
            x, y, z, w = qSlerp(x, y, z, w, scale)
        end
        return x, y, z, w
    end
    
    local function quatToMatrix(x, y, z, w)
        return {
            Vector(1-2*y*y-2*z*z, 2*x*y-2*z*w, 2*x*z+2*y*w),
            Vector(2*x*y+2*z*w, 1-2*x*x-2*z*z, 2*y*z-2*x*w),
            Vector(2*x*z-2*y*w, 2*y*z+2*x*w, 1-2*x*x-2*y*y)
        }
    end
    
    -- scale rotation matrix
    local function mInterp(m, factor)
        return quatToMatrix(matrixToQuat(m, factor))
    end
    
    local function mScale(m, factor)
        for _, row in ipairs(m) do
            row:scale(factor)
        end
        return m
    end
    
    -- apply a rotation matrix to vector
    local function mApply(m, v)
        v:set(m[1]:dot(v), m[2]:dot(v), m[3]:dot(v))
        return v
    end
    
    -- matrix multiplication
    local function mMult(m1, m2)
        local trans = {
            Vector(m2[1].x, m2[2].x, m2[3].x),
            Vector(m2[1].y, m2[2].y, m2[3].y),
            Vector(m2[1].z, m2[2].z, m2[3].z),
        }
        local result = { Vector(), Vector(), Vector() }
        for row = 1, 3 do
            result[row]:set( m1[row]:dot(trans[1]), m1[row]:dot(trans[2]), m1[row]:dot(trans[3]) )
        end
        return result
    end
    
    -- matrix addition
    local function mAdd(m1, m2)
        for row = 1, 3 do
            m1[row]:add(m2[row])
        end
        return m1
    end
    
    -- eye matrix
    local function mUnit()
        return { Vector(1, 0, 0),
                 Vector(0, 1, 0),
                 Vector(0, 0, 1) }
    end
    
    local function rotationMatrix(from, to)
        local sscross = sscp(from:cross(to))
        local dot = from:dot(to)
        -- maybe skew one of them instead to not bother the user
        -- or include a bool/etc result
        assert(math.abs(dot + 1) > 0.05, 'Vectors too close to opposite of each other')
        local factor = 1 / (1 + dot)
        local ss2scaled = mScale(mMult(sscross, sscross), factor)
        return mAdd(mAdd(mUnit(), sscross), ss2scaled)
    end
    
    local function mTrail(m)
        return m[1].x + m[2].y + m[3].z
    end
    
    -- Amount of rotation in degrees
    local function mDeg(m)
        return math.deg(math.acos((mTrail(m)-1)/2))
    end    
    
    function Vector:rotateTowardsUnit(unitTarget, maxDelta)
        local m = rotationMatrix(self, unitTarget)
        if maxDelta then
            local angle = mDeg(m)
            if angle > maxDelta then
                m = mInterp(m, maxDelta/angle)
            end
        end
        return mApply(m, self)
    end
    
    function Vector:rotateTowards(target, maxDelta)
        local len = self:magnitude()
        return self:normalize()
            :rotateTowardsUnit(target:normalized(), maxDelta)
            :scale(len)
    end
    
    function Vector:reflect(planeNormal)
        local x, y, z = planeNormal:normalized():get()
        local reflectMatrix = {
            Vector(1-2*x*x, -2*x*y, -2*x*z),
            Vector(-2*x*y, 1-2*y*y, -2*y*z),
            Vector(-2*x*z, -2*y*z, 1-2*z*z)
        }
        return mApply(reflectMatrix, self)
    end
    
    local function basicRotationMatrix(axis, angle)
        angle = math.rad(angle)
        local sin, cos = math.sin(angle), math.cos(angle)
        
        if axis == 'x' then
            return {
                Vector( 1,   0,    0  ),
                Vector( 0,  cos, -sin ),
                Vector( 0,  sin,  cos )
            }
        elseif axis == 'y' then
            return {
                Vector( cos,  0,  sin ),
                Vector(  0,   1,   0  ),
                Vector(-sin,  0,  cos )
            }
        elseif axis == 'z' then
            return {
                Vector( cos, -sin,  0 ),
                Vector( sin,  cos,  0 ),
                Vector(  0,    0,   1 )
            }
        end
    end    
    
    function Vector:rotateOver(axis, angle)
        return mApply(basicRotationMatrix(axis, angle), self)
    end
end

function Vector.max(v1, v2)
    return Vector(
        math.max(v1.x, v2.x),
        math.max(v1.y, v2.y),
        math.max(v1.z, v2.z)
    )
end

function Vector.min(v1, v2)
    return Vector(
        math.min(v1.x, v2.x),
        math.min(v1.y, v2.y),
        math.min(v1.z, v2.z)
    )
end

function Vector:inverse()
    return self:set(-1*self.x, -1*self.y, -1*self.z)
end

function Vector:projectOnPlane(planeNormal)
    local _, _, planeShadow = planeNormal:orthoNormalize(self)
    if self:angle(planeShadow) > 90 then
        planeShadow:inverse()
    end
    return self:project(planeShadow)
end

function Vector:orthoNormalize(binormalPlanar)
    
    -- if no vector was supplied, create an arbitrary one
    if not binormalPlanar then
        binormalPlanar = Vector(1, 0, 0)
        if self:angle(binormalPlanar) < 10 then
            binormalPlanar = Vector(0, 0, 1)
        end
    elseif binormalPlanar:sqrMagnitude() ~= 1 then
        binormalPlanar = binormalPlanar:normalized()
    end
    
    local base = self:normalized()
    local normal = base:cross(binormalPlanar:normalized())
    local binormal = base:cross(normal)
   
    return base, normal, binormal
end

function Vector:heading(axis)
    if not axis then
        return self:heading('x'), self:heading('y'), self:heading('z')
    end
    
    local c1, c2
    
    if axis == 'x' then
        c1, c2 = self.y, self.z
    elseif axis == 'y' then
        c1, c2 = self.x, self.z
    elseif axis == 'z' then
        c1, c2 = self.x, self.y
    end
    
    return math.deg(math.atan2(c1, c2))
end

return Vector
        
end)()
Color = (function()

local Color = {}
Color.__isColor = true
Color.__version = '1.0.1'

local colorMt = {}

local function clamp(val)
    return math.min(1, math.max(0, val or 0))
end
local function clampMultiple(a, b, c, d)
    return clamp(a), clamp(b), clamp(c), clamp(d)
end

function Color.new(...)
    local col = setmetatable({
        r = 0,
        g = 0,
        b = 0,
        a = 1
    }, Color)

    local argNum = select('#', ...)
    if argNum == 1 and type(...) == 'table' then
        -- Color.new(colorTable)
        local arg = ...
        col.r = clamp(arg.r or col.r)
        col.g = clamp(arg.g or col.g)
        col.b = clamp(arg.b or col.b)
        col.a = clamp(arg.a or col.a)
    elseif argNum == 3 then
        -- Color.new(r, g, b)
        col.r, col.g, col.b = clampMultiple(...)
    elseif argNum == 4 then
        col.r, col.g, col.b, col.a = clampMultiple(...)
    end
    
    return col
end
colorMt.__call = function(_, ...) return Color.new(...) end

local function normalizeName(str)
    return str:sub(1, 1):upper() .. str:sub(2, -1):lower()
end

local playerColors = {
    ['white']  = Color.new(1, 1, 1),
    ['brown']  = Color.new(0.443, 0.231, 0.09),
    ['red']    = Color.new(0.856, 0.1, 0.094),
    ['orange'] = Color.new(0.956, 0.392, 0.113),
    ['yellow'] = Color.new(0.905, 0.898, 0.172),
    ['green']  = Color.new(0.192, 0.701, 0.168),
    ['teal']   = Color.new(0.129, 0.694, 0.607),
    ['blue']   = Color.new(0.118, 0.53, 1),
    ['purple'] = Color.new(0.627, 0.125, 0.941),
    ['pink']   = Color.new(0.96, 0.439, 0.807),
    ['grey']   = Color.new(0.5, 0.5, 0.5),
    ['black']  = Color.new(0.25, 0.25, 0.25),
}
colorMt.__index = function(_, colorName)
    colorName = colorName:lower()
    if playerColors[colorName] then
        return playerColors[colorName]:copy()
    end
    return nil
end

Color.list = {}
for colorName in pairs(playerColors) do
    table.insert(Color.list, normalizeName(colorName))
end

function Color.Add(name, color)
    name = name:lower()
    assert(not playerColors[name], 'Color ' .. name .. ' already defined')
    assert(color.__isColor, tostring(color) .. ' is not a Color instance')
    playerColors[name] = color
    table.insert(Color.list, normalizeName(name))
end

function Color.fromString(strColor)
    local color = assert(playerColors[strColor:lower()], strColor .. ' is not a valid color string')
    return color:copy()
end

function Color.fromHex(hexColor)
    local rStr, gStr, bStr, aStr = hexColor:match('^#?(%x%x)(%x%x)(%x%x)(%x?%x?)$')

    assert(rStr and gStr and bStr and (aStr:len() == 0 or aStr:len() == 2), tostring(hexColor) .. ' is not a valid color hex string')

    if aStr == '' then
        return Color(
            tonumber(rStr, 16)/255,
            tonumber(gStr, 16)/255,
            tonumber(bStr, 16)/255,
            1
        )
    else
        return Color(
            tonumber(rStr, 16)/255,
            tonumber(gStr, 16)/255,
            tonumber(bStr, 16)/255,
            tonumber(aStr, 16)/255
        )
    end
end


function Color:get()
    return self.r, self.g, self.b, self.a
end

function Color:toHex(includeAlpha)
    if includeAlpha then
        return ('%02x%02x%02x%02x'):format(
            self.r*255,
            self.g*255,
            self.b*255,
            self.a*255
        )
    else
        return ('%02x%02x%02x'):format(
            self.r*255,
            self.g*255,
            self.b*255
        )
    end
end

function Color:toString(tolerance)
    for name, color in pairs(playerColors) do
        if self:equals(color, tolerance) then
            return normalizeName(name)
        end
    end
    return nil
end

do
    local remap = {'r', 'g', 'b', 'a'}
    function Color:__index(k)
        k = remap[k] or k
        return rawget(self, k) or Color[k]
    end
    function Color:__newindex(k, v)
        k = remap[k] or k
        return rawset(self, k, v)
    end
end

function Color:set(r, g, b, a)
    self.r = clamp(r or self.r)
    self.g = clamp(g or self.g)
    self.b = clamp(b or self.b)
    self.a = clamp(a or self.a)
end

function Color:setAt(key, value)
    self[key] = clamp(value)
    return self
end

function Color:equals(other, margin)
    margin = margin or 1e-2
    local diff = math.abs(self.r - other.r)
        + math.abs(self.g - other.g)
        + math.abs(self.b - other.b)
        + math.abs(self.a - other.a)
    return diff <= margin
end
Color.__eq = Color.equals

function Color:copy()
    return Color(self:get())
end

function Color:dump(prefix)
    local name = self:toString()
    local str = (self.a < 1) and '%s%s{ r = %f, g = %f, b = %f, a = %f }' or '%s%s{ r = %f, g = %f, b = %f }'
    return (str:format(
        prefix and (prefix .. ': ') or '',
        name and (name .. ' ') or '',
        self:get()
        -- cut trailing zeroes from numbers
    ):gsub('%.0+([ ,])', '%1'):gsub('%.(%d-)0+([ ,])', '.%1%2'))
end

function Color:__tostring()
    return self:dump('Color')
end

function Color:lerp(other, t)
    local mid = self:copy()
    mid.r = mid.r + (other.r - self.r)*t
    mid.g = mid.g + (other.g - self.g)*t
    mid.b = mid.b + (other.b - self.b)*t
    mid.a = mid.a + (other.a - self.a)*t
    return mid
end

setmetatable(Color, colorMt)

return Color

end)()
