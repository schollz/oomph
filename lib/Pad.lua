local Pad={}
local MusicUtil=require("musicutil")

function Pad:new(o)
  -- https://www.lua.org/pil/16.1.html
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  o:init()
  return o
end

function Pad:init()
  local prams={
    {name="volume",min=0,max=1,default=0.5,div=0.01,unit="amp"},
    {name="reverb",min=0,max=1,default=0.0,div=0.01,unit="wet/dry"},
    {name="attack",min=0,max=200,default=10,div=1,unit="%"},
    {name="decay",min=0,max=200,default=60,div=1,unit="%"},
    {name="sustain",min=0,max=200,default=90,div=1,unit="%"},
    {name="release",min=0,max=200,default=30,div=1,unit="%"},
  }
  params:add_group("PAD",#prams+19)
  for _,p in ipairs(prams) do
    params:add_control("pad_"..p.name,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
  end

  params:add{type="number",id="number_of_chords",name="num chords",min=1,max=8,default=4}
  params:add{type="number",id="pad_root_note",name="root note",min=0,max=127,default=48,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}
  self.scales_available={"Major","Minor"}
  params:add_option("pad_scale","scale",self.scales_available,1)
  params:set_action("root_note",function(x)
    self.do_update_chords=true
  end)
  local basic_chords={"I","ii","iii","IV","V","vi","VII","i","II","III","iv","v","VI","vii"}
  self.available_chords={}
  for _,v in ipairs({"","7","6-9","+7"}) do
    for _,c in ipairs(basic_chords) do
      table.insert(self.available_chords,c..v)
    end
  end
  local available_chords_default={6,4,3,1}
  for chord_num=1,8 do
    params:add_option("chord"..chord_num,"chord "..chord_num,self.available_chords,available_chords_default[(chord_num-1)%4+1])
    params:add{type="number",id="beats"..chord_num,name="beats "..chord_num,min=0,max=16,default=8}
  end

  self:update_chords()
end

function Pad:update_chords()
  self.chords={}
  for i=1,params:get("number_of_chords") do
    table.insert(self.chords,{chord=self.available_chords[params:get("chord"..i)],beats=params:get("beats"..i)})
    for j=1,params:get("beats"..i)-1 do
      table.insert(self.chords,{})
    end
  end
end

function Pad:process(beat)
  if (beat-1)%4~=0 then
    do return end
  end
  local qn=(beat-1)/4+1
  local chord_note=(qn-1)%#self.chords+1
  if next(self.chords[chord_note])==nil then
    do return end
  end
  local chord=self.chords[chord_note]
  print(chord.chord,chord.beats)
  local notes=MusicUtil.generate_chord_roman(params:get("pad_root_note"),params:get("pad_scale"),chord.chord)
  local duration=chord.beats*clock.get_beat_sec()
  for _,note in ipairs(notes) do
    engine.pad(
      params:get("pad_volume")/10,
      params:get("pad_reverb"),
      note,
      duration*params:get("pad_attack")/100,
      duration*params:get("pad_decay")/100,
      params:get("pad_attack")/100,
      duration*params:get("pad_release")/100,
      80 -- TODO change this to the top note
    )
  end
end

return Pad
