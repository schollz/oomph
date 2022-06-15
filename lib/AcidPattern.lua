local AP={}
local MusicUtil=require("musicutil")

local PUNCTUATION_REST=1
local PUNCTUATION_TIE=2
local PUNCUATION_NOTE=3

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
  -- https://acidpattern.bandcamp.com/album/july-oomph-2014
  self.current=1
  self.note_scale={0,2,4,5,7,9,11}
  self.key_step={"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
  self.key_notes={"C","D","E","F","G","A","B"}
  self.key_accid={"","b","#"}
  self.key_octave={"M","","P"}
  self.key_accent={"","H","O"}
  self.key_punctuation={"o","-","@"}
  -- do initialize here
  self.note={6,6,3,4,6,1,2,1,1,3,6,3,6,7,3,5}
  self.note={6,6,3,4,6,1,2,1,1,3,6,3,6,7,3,5}
  self.accid={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
  self.octave={2,2,1,3,2,2,2,2,1,3,2,2,2,1,3,2}
  self.accent={3,3,1,1,2,1,3,3,1,1,2,1,3,1,1,2}
  self.duration={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
  self.punct={3,3,3,3,3,1,3,3,3,3,3,2,3,3,3,3}
  self.step={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
end

function AP:set_note(i,midi_val)
  midi_val=midi_val%12+1
  local midi_transfer={
    {1,1}, --"C"
    {2,2}, --"Db"
    {2,1}, --"D"
    {3,2}, --"Eb"
    {3,1}, --"E"
    {4,1}, --"F"
    {5,2}, --"Gb"
    {5,1}, --"G"
    {6,2}, --"Ab"
    {6,1}, --"A"
    {7,2}, --"Bb"
    {7,1}, --"B"
  }
  self.note[i]=midi_transfer[midi_val][1]
  self.accid[i]=midi_transfer[midi_val][2]
end

function AP:dumps()
  local to_save={"note","accid","octave","accent","duration","punct","step"}
  local data={}
  for _,key in ipairs(to_save) do
    data[key]=self[key]
  end
  return json.encode(data)
end

function AP:loads(s)
  if s==nil then
    do return end
  end
  local data=json.decode(s)
  if data==nil then
    do return end
  end
  for k,v in pairs(data) do
    self[k]=v
  end
end

function AP:set(ind,pos,d)
  local setters={"note","accid","octave","accent","punct"}
  local maxes={7,3,3,3,3}
  self[setters[ind]][pos]=self[setters[ind]][pos]+d
  if self[setters[ind]][pos]<1 then
    self[setters[ind]][pos]=self[setters[ind]][pos]+maxes[ind]
  elseif self[setters[ind]][pos]>maxes[ind] then
    self[setters[ind]][pos]=self[setters[ind]][pos]-maxes[ind]
  end
  if setters[ind]=="punct" then
    -- figure out the durations of all the notes
    local punct={}
    local durations={}
    for i=1,2 do
      for _,p in ipairs(self.punct) do
        table.insert(durations,1)
        table.insert(punct,p)
      end
    end
    local duration=1
    for i=#punct,1,-1 do
      if punct[i]<=2 then
        durations[i]=duration
        duration=1
      else
        duration=duration+1
      end
    end
    for i=1,#self.duration do
      self.duration[i]=durations[i]
    end
  end
end

function AP:rotate_step(step,d)
  local pos=0
  for i,s in ipairs(self.step) do
    if s==step then
      pos=i
      break
    end
  end
  local pos_new=pos+d
  if pos_new>#self.steps then
    pos_new=pos_new-#self.steps
  end
  if pos_new<1 then
    pos_new=pos_new+#self.steps
  end
  local step_move=self.steps[pos_new]
  self.steps[pos_new]=step
  self.steps[step]=step_move
end

function AP:process(beat)
  self.current=self.step[beat%16+1]
  local i=self.current
  if self.punct[i]~=PUNCUATION_NOTE then
    do return end
  end
  local accid=self.accid[i]==3 and 1 or 0
  if accid==0 then
    accid=self.accid[i]==2 and-1 or 0
  end
  local note=params:get("root_note")+self.note_scale[self.note[i]]+accid+(self.octave[i]-2)*12+12
  -- do something with the note
  local accent=self.accent[i]==3 and 1 or 0
  local slide=self.accent[i]==2 and 1 or 0
  engine.threeohthree_trig(note,self.duration[i],slide,accent)
end

function AP:redraw(x,y,sh,sw)
  screen.level(15)
  screen.blend_mode(0)
  for i=1,16 do
    -- screen.move(x+sw*(i-1),y)
    -- screen.text_center(self.key_step[self.step[i]])
    screen.move(x+sw*(i-1),y+sh*1)
    screen.text_center(self.key_notes[self.note[i]])
    screen.move(x+sw*(i-1),y+sh*2)
    screen.text_center(self.key_accid[self.accid[i]])
    screen.move(x+sw*(i-1),y+sh*3)
    screen.text_center(self.key_octave[self.octave[i]])
    screen.move(x+sw*(i-1),y+sh*4)
    screen.text_center(self.key_accent[self.accent[i]])
    screen.move(x+sw*(i-1),y+sh*5)
    screen.text_center(self.key_punctuation[self.punct[i]])
  end
  screen.move(x+sw*(self.current-1),y+4)
  screen.text_center("^")
end

return AP
