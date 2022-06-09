-- local pattern_time = require("pattern")
local GGrid={}

local ROW_NOTE=1
local ROW_ACCID=2
local ROW_OCTAVE=3
local ROW_ACCENT=4
local ROW_PUNCT=5

function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.apm=args.apm or {}
  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.03
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()
  m.last_press=clock.get_beats()*clock.get_beat_sec()
  m.last_key=m.apm.current

  local params_row7={"threeohthree_amp","amen_amp","pad_amp","plaits_amp","amen_timestretch_slow","amen_timestretch_beats","amen_timestretch","amen_rate"}
  local params_row8={"threeohthree_sub","threeohthree_cutoff","threeohthree_env_adjust","threeohthree_env_accent","threeohthree_res_adjust","threeohthree_res_accent","threeohthree_decay"}
  m.params={}
  table.insert(m.params,params_row7)
  table.insert(m.params,params_row8)
  return m
end

function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  if on then
    self.pressed_buttons[row..","..col]=true
  else
    self.pressed_buttons[row..","..col]=nil
  end
  if self.param_held~=nil and on then
    local val=16*((9-row)-1)+col
    params:set_raw(self.param_held,util.linlin(1,128,0,1,val))
    do return end
  end
  if on and row<6 then
    self.apm:set(row,col,1)
  end
  if row==6 then
    if on then
      local current_press=clock.get_beats()*clock.get_beat_sec()
      if self.row6~=nil then
        if self.is_playing==true then
          params:set("pattern"..self.row6,col)
          params:set("sequencer_on",1)
        else
          params:set("copy_from",self.row6)
          params:set("copy_to",col)
          params:set("do_copy",1)
        end
      else
        -- if self.is_playing==false and (current_press-self.last_press)>1
        --   and self.last_key==col then
        --   toggle_start()
        -- elseif (current_press-self.last_press)>0
        --   and (current_press-self.last_press)<1
        --   and self.last_key==col then
        --   toggle_start()
        -- end
        self.row6=col
        self.apm:set_current(col)
      end
      self.last_press=current_press
      self.last_key=col
    else
      self.row6=nil
    end
  end
  if row>6 then
    if self.param_held==nil and on then
      self.param_held=self.params[row-6][col]
      print(self.param_held)
    elseif self.param_held~=nil and not on
      and self.param_held==self.params[row-6][col] then
      self.param_held=nil
    end
  end
end

function GGrid:toggle_start(is_playing)
  self.is_playing=is_playing
end

function GGrid:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=0
    end
  end

  if self.param_held~=nil then
    local maxkey=util.linlin(0,1,1,128,params:get_raw(self.param_held))
    local i=0
    for row=8,1,-1 do
      for col=1,16 do
        i=i+1
        if i>maxkey then
          break
        end
        self.visual[row][col]=5
      end
      if i>maxkey then
        break
      end
    end
  else
    -- draw steps
    for i=1,16 do
      self.visual[ROW_NOTE][i]=self.apm:get("note",i)*2
      self.visual[ROW_ACCID][i]=(self.apm:get("accid",i)-1)*4
      self.visual[ROW_OCTAVE][i]=(self.apm:get("octave",i)-1)*4
      self.visual[ROW_ACCENT][i]=(self.apm:get("accent",i)-1)*4
      self.visual[ROW_PUNCT][i]=(self.apm:get("punct",i)-1)*4
      if self.apm.current==i then
        self.visual[6][i]=10
      elseif self.apm:next_pattern()==i then
        self.visual[6][i]=5
      end

    end
    self.visual[6][self.apm:current_step()]=self.visual[6][self.apm:current_step()]+5
  end
  -- -- illuminate currently pressed button
  -- for k,_ in pairs(self.pressed_buttons) do
  --   local row,col=k:match("(%d+),(%d+)")
  --   self.visual[tonumber(row)][tonumber(col)]=15
  -- end

  return self.visual
end

function GGrid:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function GGrid:redraw()
  if self.param_held~=nil then
    screen.blend_mode(0)
    local message=self.param_held..": "..params:string(self.param_held)
    screen.level(0)
    screen.aa(1)
    x=64
    y=28
    w=string.len(message)*6
    screen.rect(x-w/2,y-4,w,10+8)
    screen.fill()
    screen.level(15)
    screen.rect(x-w/2,y-4,w,10+8)
    screen.stroke()
    screen.move(x,y+7)
    screen.text_center(message)
    screen.aa(0)
  end
end

return GGrid
