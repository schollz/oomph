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
  if on and row<6 then
    self.apm:set(row,col,1)
  end
  if row==8 then
    if on then
      if self.row8~=nil then
        params:set("pattern"..self.row8,col)
        params:set("sequencer_on",1)
      else
        self.row8=col
        self.apm:set_current(col)
      end
    else
      self.row8=nil
    end
  end
end

function GGrid:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=0
    end
  end

  -- draw steps
  for i=1,16 do
    self.visual[ROW_NOTE][i]=self.apm:get("note",i)*2
    self.visual[ROW_ACCID][i]=(self.apm:get("accid",i)-1)*4
    self.visual[ROW_OCTAVE][i]=(self.apm:get("octave",i)-1)*4
    self.visual[ROW_ACCENT][i]=(self.apm:get("accent",i)-1)*4
    self.visual[ROW_PUNCT][i]=(self.apm:get("punct",i)-1)*4
    if self.apm.current==i then
      self.visual[8][i]=10
    elseif self.apm:next_pattern()==i then
      self.visual[8][i]=5
    end

  end
  self.visual[8][self.apm:current_step()]=self.visual[8][self.apm:current_step()]+5

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

return GGrid
