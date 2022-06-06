-- acid pattern v0.0.1
-- ?
--
-- llllllll.co/t/?
--
--
--
--    ▼ instructions below ▼
--
-- ?

engine.name="AcidBreaks"
local lattice_=require("lattice")
local apm_=include("lib/AcidPatternManager")
local amen_=include("lib/Amen")
local ggrid_=include("lib/ggrid")
local pad_=include("lib/Pad")
if not string.find(package.cpath,"/home/we/dust/code/acid-pattern/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/acid-pattern/lib/?.so"
end
json=require("cjson")
local shift=false
local pos={1,3}
local playing=false
local beat_num=-1

function init()
  -- setup audio folders
  util.os_capture("mkdir -p /home/we/dust/audio/acid-pattern")

  apm=apm_:new()
  amen=amen_:new()
  pad=pad_:new()
  ggrid=ggrid_:new{apm=apm}

  -- setup tape fx

  local tape_prams={
    {name="aux",eng="auxin",min=0,max=1,default=0.5,div=0.01,unit="wet/dry"},
    {name="tape",eng="tape_wet",min=0,max=1,default=0.5,div=0.01,unit="wet/dry"},
    {name="bias",eng="tape_bias",min=0,max=1,default=0.8,div=0.01},
    {name="saturate",eng="tape_sat",min=0,max=1,default=0.8,div=0.01},
    {name="drive",eng="tape_drive",min=0,max=1,default=0.8,div=0.01},
    {name="distortion",eng="dist_wet",min=0,max=1,default=0.1,div=0.01,unit="wet/dry"},
    {name="gain",eng="dist_drive",min=0,max=1,default=0.1,div=0.01},
    {name="low gain",eng="dist_low",min=0,max=1,default=0.1,div=0.01},
    {name="high gain",eng="dist_high",min=0,max=1,default=0.1,div=0.01},
    {name="shelf",eng="dist_shelf",min=10,max=1000,default=600,div=10,exp=true},
  }
  params:add_group("TAPE FX",#tape_prams)
  for _,p in ipairs(tape_prams) do
    params:add_control("tape"..p.eng,p.name,controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.default,p.unit or "",p.div/(p.max-p.min)))
    params:set_action("tape"..p.eng,function(x)
      print(p.eng,x)
      engine["tape_"..p.eng]("lag",0,x,0)
      params:set("tape"..p.eng.."modtrig",0)
    end)
  end
  params:add_group("TAPE FX MOD",#tape_prams*5)
  local mod_ops_ids={"sine","drunk","xline","line"}
  local mod_ops_nom={"sine","drunk","exp ramp","linear ramp"}
  for _,p in ipairs(tape_prams) do
    params:add_option("tape"..p.eng.."modoption",p.name.." form",mod_ops_nom,1)
    params:add_control("tape"..p.eng.."modperiod",p.name.." period",controlspec.new(0.1,120,'exp',0.1,2,"s",0.1/119.9))
    params:add_control("tape"..p.eng.."modmin",p.name.." min",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.min,p.unit or "",p.div/(p.max-p.min)))
    params:add_control("tape"..p.eng.."modmax",p.name.." max",controlspec.new(p.min,p.max,p.exp and 'exp' or 'lin',p.div,p.max,p.unit or "",p.div/(p.max-p.min)))
    params:add_binary("tape"..p.eng.."modtrig",p.name.." trig","toggle")
    params:set_action("tape"..p.eng.."modtrig",function(x)
      print(p.eng,x)
      if x==1 then
        print(mod_ops_ids[params:get("tape"..p.eng.."modoption")],params:get("tape"..p.eng.."modmin"),
          params:get("tape"..p.eng.."modmax"),
        params:get("tape"..p.eng.."modperiod"))
        engine["tape_"..p.eng](mod_ops_ids[params:get("tape"..p.eng.."modoption")],params:get("tape"..p.eng.."modmin"),
          params:get("tape"..p.eng.."modmax"),
        params:get("tape"..p.eng.."modperiod"))
      end
    end)
  end

  -- setup global parameters
  params:add_control("drumlatency","drum latency",controlspec.new(-1,1,'lin',0.01,0,"beats",0.01/2))
  params:set_action("drumlatency",function(x)
    x=x*clock.get_beat_sec()
    if x>0.2 then
      x=0.2
    elseif x<-0.2 then
      x=-0.2
    end
    print(x)
    engine.amen_latency(x>0 and x or 0)
    engine.threeohthree_latency(x<0 and math.abs(x) or 0)
  end)

  -- initialize metro for updating screen
  timer=metro.init()
  timer.time=1/15
  timer.count=-1
  timer.event=update_screen
  timer:start()

  -- setup the lattice clock
  lattice=lattice_:new()
  beat_num=-1
  lattice:new_pattern{
    action=function(t)
      beat_num=beat_num+1 -- beat % 16 + 1 => [1,16]
      amen:process(beat_num)
      apm:process(beat_num)
      pad:process(beat_num)
    end,
    division=1/16,
  }

  -- dev stuff
  amen:load("/home/we/dust/code/acid-pattern/lib/beats16_bpm150_Ultimate_Jack_Loops_014__BPM_150_.wav")
  -- amen:stutter_build()

  params.action_write=function(filename,name)
    print("write",filename,name)
    apm:save(filename)
  end
  params.action_read=function(filename,silent)
    print("read",filename,silent)
    apm:open(filename)
  end

  -- setup midi transports
  local device={}
  local device_list={}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local name=string.lower(dev.name).." "..i
      table.insert(device_list,name)
      print("adding "..name.." to port "..dev.port)
      device[name]={
        name=name,
        port=dev.port,
        midi=midi.connect(dev.port),
      }
      device[name].midi.event=function(data)
        local msg=midi.to_msg(data)
        if msg.type=="clock" then do return end end
-- OP-1 fix for transport
        if msg.type=='start' or msg.type=='continue' then
          toggle_start(true)
        elseif msg.type=="stop" then
          toggle_start(false)
        end
      end
    end
  end
  ignore_transport=false

  -- load in the default parameters
  params:default()
  params:bang()

  toggle_start(true)
end

function clock.transport.start()
  if ignore_transport then
    do return end
  end
  toggle_start(true)
end

function clock.transport.stop()
  if ignore_transport then
    do return end
  end
  toggle_start(false)
end

function clock.transport.reset()
  if ignore_transport then
    do return end
  end
  toggle_start(true)
end

function update_screen()
  redraw()
end

function toggle_start(start)
  if start==nil then
    start=not playing
  end
  ignore_transport=true
  clock.run(function()
    clock.sleep(1)
    ignore_transport=false
  end)
  if start then
    print("starting")
    beat_num=-1
    lattice:hard_restart()
  else
    print("stopping")
    lattice:stop()
  end
  amen:toggle_start(start)
  playing=start
end

function key(k,z)
  if k==1 then
    shift=z==1
  end
  if shift then
    if k==1 then
    elseif k==2 then
    elseif k==3 and z==1 then
      toggle_start()
    end
  else
    if k==1 then
    elseif k>1 and z==1 then
      local d=k*2-5
      apm:set(pos[1],pos[2],d)
    end
  end
end

function enc(k,d)
  if shift then
    if k==1 then
    elseif k==2 then
    else
    end
  else
    if k==1 then
      apm:change_pattern(d)
    elseif k>1 then
      local k_=k==2 and 2 or 1
      pos[k_]=pos[k_]+(k==2 and d or-d)
      if pos[k_]>16 and k_==2 then
        pos[k_]=pos[k_]-16
      end
      if pos[k_]<1 and k_==2 then
        pos[k_]=pos[k_]+16
      end
      if pos[k_]>5 and k_==1 then
        pos[k_]=pos[k_]-5
      end
      if pos[k_]<1 and k_==1 then
        pos[k_]=pos[k_]+5
      end
    end
  end
end

function redraw()
  screen.clear()
  local x=2.5
  local y=10
  local sh=9
  local sw=8
  apm:redraw(x,y,sh,sw)
  screen.blend_mode(1)
  screen.rect(x+sw*(pos[2]-1)-4,y+sh*(pos[1]-1)+2,10,9)
  screen.fill()
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
