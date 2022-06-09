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
  self.mx_samples="/home/we/dust/audio/mx.samples/ultra_synth/"
  if not util.file_exists(self.mx_samples) then
    print("ERROR ERROR ERROR - PLEASE SEE README TO INSTALL MX.SAMPLES DEFAULT")
  end
  local prams={
    {name="volume",eng="amp",min=-64,max=32,default=-64,div=0.5,unit="dB",db=true},
    {name="attack",eng="attack",min=0,max=64,default=0.25,div=0.01,unit="beats",beat=true},
    {name="decay",eng="decay",min=0,max=64,default=1,div=0.1,unit="beats",beat=true},
    {name="sustain",eng="sustain",min=0,max=2,default=1,div=0.1,unit="amp"},
    {name="release",eng="release",min=0,max=64,default=4,div=0.1,unit="beats",beat=true},
    {name="pan",eng="pan",min=-1,max=1,default=0,div=0.01},
    {name="lpf",eng="lpf",min=50,max=20000,default=20000,div=100,exp=true,unit='Hz'},
  }
  params:add_group("CHORDS",#prams+28)
  params:add_file("mx_samples","load mx.samples",_path.audio.."mx.samples/")
  params:set_action("mx_samples",function(x)
    if x==nil then
      do return end
    end
    pathname,filename,ext=string.match(x,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    if string.find(pathname,"mx.samples/") then
      local suffix="mx.samples/"
      if pathname:sub(-string.len(suffix))==suffix then
        do return end
      end
      print("loading "..pathname)
      self.mx_samples=pathname
    end
  end)
  for _,p in ipairs(prams) do
    params:add_control("pad_"..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action("pad_"..p.eng,function(x)
      -- TODO: make the ultra_synth a parameter
      if p.beat then
        x=x*clock.get_beat_sec()
      end
      if p.db then
        x=util.dbamp(x)
      end
      print("pad",p.eng,x)
      engine["pad_"..p.eng](self.mx_samples,x)
    end)
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
  local available_chords_default={6,1,4,4,6,1,4,5}
  for chord_num=1,8 do
    params:add_option("chord"..chord_num,"chord "..chord_num,self.available_chords,available_chords_default[chord_num])
    params:add{type="number",id="beats"..chord_num,name="beats "..chord_num,min=0,max=16,default=8}
    params:add{type="number",id="transpose"..chord_num,name="transpose "..chord_num,min=0,max=8,default=0}
    params:set_action("chord"..chord_num,function()
      self:update_chords()
    end)
    params:set_action("beats"..chord_num,function()
      self:update_chords()
    end)
  end

  self:update_chords()
end

function Pad:update_chords()
  self.chords={}
  for i=1,params:get("number_of_chords") do
    if params:get("beats"..i)>0 then
      table.insert(self.chords,{chord_num=i,chord=self.available_chords[params:get("chord"..i)],beats=params:get("beats"..i)})
      for j=1,params:get("beats"..i)-1 do
        table.insert(self.chords,{})
      end
    end
  end
end

function Pad:process(beat)
  if beat%4~=0 then
    do return end
  end
  local qn=beat/4+1
  local chord_note=(qn-1)%#self.chords+1
  if next(self.chords[chord_note])==nil then
    do return end
  end
  local chord=self.chords[chord_note]
  -- print(chord.chord,chord.beats)
  local notes=MusicUtil.generate_chord_roman(params:get("pad_root_note"),params:get("pad_scale"),chord.chord)
  if params:get("transpose"..chord.chord_num)>0 then
    for i=1,params:get("transpose"..chord.chord_num) do
      local notei=(i-1)%#notes+1
      notes[notei]=notes[notei]+12
    end
  end
  local duration=(chord.beats-2)*clock.get_beat_sec()
  local highestnote=0
  for _,note in ipairs(notes) do
    if note>highestnote then
      highestnote=note
    end
  end

  for _,note in ipairs(notes) do
    engine.pad_note(self.mx_samples,note,math.random(80,110),duration)
    -- engine.pad(
    --   params:get("pad_volume")/5,
    --   params:get("pad_reverb"),
    --   note,
    --   duration*params:get("pad_attack")/100,
    --   duration*params:get("pad_decay")/100,
    --   params:get("pad_attack")/100,
    --   duration*params:get("pad_release")/100,
    --   highestnote+12*params:get("pad_lpf mult")
    -- )
  end
end

return Pad
