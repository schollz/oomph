local AP={}

local PUNCUATION_NOTE=1
local PUNCTUATION_REST=2
local PUNCTUATION_TIE=3

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
  -- https://acidpattern.bandcamp.com/album/july-acid-pattern-2014
  self.current=1
  self.note_scale={33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50}
  self.key_notes={"A","Bb","B","C","Db","D","Eb","E","F","Gb","G","Ab"}
  self.key_octave={"D","","U"}
  self.key_accent={"","A","S"}
  self.key_punctuation={"@","o","-"}
  -- do initialize here
  self.note=    {1,1,7,4,4,1,1,7,4,4,1,1,7,4,4,1}
  self.octave=  {2,1,2,2,2,2,1,2,2,2,2,1,2,2,2,2}
  self.accent=  {2,2,1,3,1,2,2,1,3,1,2,2,1,3,1,2}
  self.duration={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
  self.punct   ={1,1,1,1,2,1,1,1,1,2,1,1,1,1,2,1}
  self.step={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
  -- create sequins
  self.step_s=s(self.step)
end

function AP:set(ind,pos,d)
  local setters={"note","octave","accent","punct"}
  local maxes={12,3,3,3}
  print(setters[ind],pos)
  self[setters[ind]][pos] = self[setters[ind]][pos] + d
  if self[setters[ind]][pos]<1 then 
    self[setters[ind]][pos] = self[setters[ind]][pos] + maxes[ind]
  elseif self[setters[ind]][pos]>maxes[ind] then 
    self[setters[ind]][pos] = self[setters[ind]][pos] - maxes[ind]
  end
end

function AP:process()
  local i=self.step_s()
  self.current=i
  if self.punct[i]==PUNCTUATION_REST then
    do return end
  end
  local note=self.note_scale[self.note[i]]+(self.octave[i]-2)*12 + 12
  -- do something with the note
  local accent=self.accent[i]==2 and 1 or 0
  local slide=self.accent[i]==3 and 1 or 0
  print(note,accent,slide)
  engine.trig(note,self.duration[i]*0.1,slide,accent)
end

return AP
