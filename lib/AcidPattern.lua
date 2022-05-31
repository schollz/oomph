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
  local prams={
    {name="volume",eng="amp",min=0,max=1,default=0.5,div=0.01},
    {name="sub volume",eng="sub",min=0,max=2,default=0.0,div=0.01},
    {name="cutoff",eng="cutoff",min=10,max=10000,default=200.0,div=10,exp=true,unit="Hz"},
    {name="cutoff env",eng="env_adjust",min=10,max=10000,default=500.0,div=10,exp=true,unit="Hz"},
    {name="env accent",eng="env_accent",min=0.0,max=10,default=0,div=0.01},
    {name="res",eng="res_adjust",min=0.01,max=0.99,default=0.303,div=0.01},
    {name="res accent",eng="res_accent",min=0.01,max=0.99,default=0.303,div=0.01},
    {name="portamento",eng="portamento",min=0,max=2,default=0.1,div=0.01,unit="s"},
    {name="sustain",eng="sustain",min=0,max=2,default=0.0,div=0.01,unit="s"},
    {name="decay",eng="decay",min=0.01,max=30,default=clock.get_beat_sec()*4,div=0.01,unit="s",exp=true},
    {name="saw/square",eng="wave",min=0.0,max=1,default=0.0,div=0.01},
    {name="detune",eng="detune",min=0.0,max=1,default=0.02,div=0.01,'notes'},
  }

  params:add_group("303",#prams)
  for _,p in ipairs(prams) do
    params:add_control(self.id..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action(self.id..p.eng,function(x)
      engine["threeohthree_"..p.eng]("dc",0,x,0.2)
    end)
  end


  -- https://acidpattern.bandcamp.com/album/july-acid-pattern-2014
  self.current=1
  self.note_scale={33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50}
  self.key_notes={"A","Bb","B","C","Db","D","Eb","E","F","Gb","G","Ab"}
  self.key_octave={"D","","U"}
  self.key_accent={"","A","S"}
  self.key_punctuation={"@","o","-"}
  -- do initialize here
  self.note={1,1,7,4,4,1,1,7,4,4,1,1,7,4,4,1}
  self.note={1,1,4,1,1,1,4,1,1,4,1,1,9,8,8,8}
  self.octave={2,1,2,2,2,2,1,2,2,2,2,1,2,2,1,2}
  self.accent={2,2,1,3,1,2,2,1,3,1,2,2,1,3,1,2}
  self.duration={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
  self.punct={1,1,1,1,2,1,1,1,1,2,1,1,1,1,2,1}
  self.punct={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
  self.step={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
end

function AP:set(ind,pos,d)
  local setters={"note","octave","accent","punct"}
  local maxes={12,3,3,3}
  self[setters[ind]][pos]=self[setters[ind]][pos]+d
  if self[setters[ind]][pos]<1 then
    self[setters[ind]][pos]=self[setters[ind]][pos]+maxes[ind]
  elseif self[setters[ind]][pos]>maxes[ind] then
    self[setters[ind]][pos]=self[setters[ind]][pos]-maxes[ind]
  end
end

function AP:process(beat)
  self.current=self.step[beat]
  local i=self.current
  if self.punct[i]==PUNCTUATION_REST then
    do return end
  end
  local note=self.note_scale[self.note[i]]+(self.octave[i]-2)*12+12
  -- do something with the note
  local accent=self.accent[i]==2 and 1 or 0
  local slide=self.accent[i]==3 and 1 or 0
  engine.threeohthree_trig(note,self.duration[i]*0.1,slide,accent)
end

return AP
