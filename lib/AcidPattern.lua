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
    {name="cutoff env",eng="envAdjust",min=10,max=10000,default=500.0,div=10,exp=true,unit="Hz"},
    {name="env accent",eng="envAccent",min=0.0,max=10,default=0,div=0.01},
    {name="res",eng="resAdjust",min=0.01,max=0.99,default=0.303,div=0.01},
    {name="res accent",eng="resAccent",min=0.01,max=0.99,default=0.303,div=0.01},
    {name="portamento",eng="portamento",min=0,max=2,default=0.1,div=0.01,unit="s"},
    {name="sustain",eng="sustain",min=0,max=2,default=0.0,div=0.01,unit="s"},
    {name="decay",eng="decay",min=0.01,max=30,default=clock.get_beat_sec()*4,div=0.01,unit="s",exp=true},
    {name="saw/square",eng="wave",min=0.0,max=1,default=0.0,div=0.01},
    {name="detune",eng="detune",min=0.0,max=1,default=0.02,div=0.01,'notes'},
  }

  for _, p in ipairs(prams) do
    params:add_control(self.id..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action(self.id..p.eng,function(x)
      engine[p.eng](x)
    end)
  end



  local tape_prams={
    {name="tape",eng="tape_wet",min=0,max=1,default=0.5,div=0.01,unit="wet/dry"},
    {name="bias",eng="tape_bias",min=0,max=1,default=0.8,div=0.01},
    {name="saturate",eng="saturation",min=0,max=1,default=0.8,div=0.01},
    {name="drive",eng="drive",min=0,max=1,default=0.8,div=0.01},
    {name="distortion",eng="dist_wet",min=0,max=1,default=0.1,div=0.01,unit="wet/dry"},
    {name="gain",eng="drivegain",min=0,max=1,default=0.1,div=0.01},
    {name="low gain",eng="lowgain",min=0,max=1,default=0.1,div=0.01},
    {name="high gain",eng="highgain",min=0,max=1,default=0.1,div=0.01},
    {name="shelf",eng="shelvingfreq",min=10,max=1000,default=600,div=10,exp=true},
  }
  params:add_group("tape fx",#tape_prams)
  for _, p in ipairs(tape_prams) do
    params:add_control(self.id..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action(self.id..p.eng,function(x)
      engine[p.eng](x)
    end)
  end

  params:bang()


  -- https://acidpattern.bandcamp.com/album/july-acid-pattern-2014
  self.current=1
  self.note_scale={33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50}
  self.key_notes={"A","Bb","B","C","Db","D","Eb","E","F","Gb","G","Ab"}
  self.key_octave={"D","","U"}
  self.key_accent={"","A","S"}
  self.key_punctuation={"@","o","-"}
  -- do initialize here
  self.note=    {1,1,7,4,4,1,1,7,4,4,1,1,7,4,4,1}
  self.note=    {1,1,4,1,1,1,4,1,1,4,1,1,9,8,8,8}
  self.octave=  {2,1,2,2,2,2,1,2,2,2,2,1,2,2,1,2}
  self.accent=  {2,2,1,3,1,2,2,1,3,1,2,2,1,3,1,2}
  self.duration={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
  self.punct   ={1,1,1,1,2,1,1,1,1,2,1,1,1,1,2,1}
  self.punct=    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
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
