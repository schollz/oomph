local AP={}

local DURATION_NOTE=1
local DURATION_REST=2
local DURATION_HOLD=3

function AP:new(o)
  -- https://www.lua.org/pil/16.1.html
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  -- define defaults if they are not defined
  o.id=o.id or 1
  o:init()
  return o
end

function AP:init()
  self.note_scale={33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50}
  self.key_notes={"C","D","E"}
  self.key_octave={"D","","U"}
  self.key_accent={"","S","A"}
  self.key_duration={"*","o","-"}
  -- do initialize here
  self.note={}
  self.octave={}
  self.accent={}
  self.duration={}
  self.step={}
  for i=1,16 do
    table.insert(self.steps,i)
    table.insert(self.note,1)
    table.insert(self.octave,2)
    table.insert(self.accent,1)
    table.insert(self.duration,1)
  end
  -- create sequins
  self.step_s=s(self.step)
end

function AP:process()
  local i=self.step_s()
  if self.duration[i]~=DURATION_NOTE then
    do return end
  end
  local accent=self.key_accent[self.accent[i]]
  local note=self.key_notes[self.note[i]]+self.key_octave[self.octave[i]]
  -- do something with the note
  -- engine.play(id,note,accent,portament)
end

return AP
