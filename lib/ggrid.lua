-- local pattern_time = require("pattern")
local GGrid={}

local ROW_STEP=1
local ROW_NOTE=2
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
    if row==1 then
      row=7
    elseif row==ROW_NOTE then
      row=1
    end
    self.apm:set(row,col,1)
  end
end

function GGrid:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=self.visual[row][col]-4
      if self.visual[row][col]<0 then
        self.visual[row][col]=0
      end
    end
  end

  -- draw steps
  for i=1,16 do
    self.visual[ROW_STEP][i]=self.apm:get("step",i)-1
    self.visual[ROW_NOTE][i]=self.apm:get("note",i)*2
    self.visual[ROW_OCTAVE][i]=(self.apm:get("octave",i)-1)*4
    self.visual[ROW_ACCENT][i]=(self.apm:get("accent",i)-1)*4
    self.visual[ROW_PUNCT][i]=(self.apm:get("punct",i)-1)*4
  end
  self.visual[8][self.apm:current_step()]=10

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
