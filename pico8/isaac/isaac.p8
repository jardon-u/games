pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- game: isaac
-- author: log0
-- 
--todo:
-- more/better boss patterns
-- add more items
-- add spider enemies
-- dif emies based on level
-- -- bomb closed doors
-- -- prevent pushing drops in rocks
-- -- hold shoot always same dir ?
--bugs:
-- godhead overkill
-- more than 6 hearts ?
-- locked rooms up and left
-- diagonal move should be 1
-- tear speed depends on speed
-- fix boss missing sometimes
-- stuck inside it lives
-- resurect can block you
-- sometimes supersecret appears at start
-- enemies double when reentering

-- only issue with door seems to be
-- changing the status of the door
-- having door objects seems to
-- conflict with the solid block logic
-- better just look at isaac position
-- and hardset doors


function begin()end
p = {
 life=6, blife=0, maxlife=6,
 lives = 0,
 bombs = 1,
 keys  = 0,
 -- position
 x=64, y=72,
 -- cell width.height
 w=16, h=16,
 --sprite
 s = 64,
 -- sprite sequence
 --anim = {66,66,66,66,66,
 --        70,70,70,70,70,
 --        68,68,68,68,68,
 --        70,70,70,70,70},
 anim = {{66,5},{70,5},
         {68,5},{70,5}},
 -- anim index
 a = 1,
 -- flip sprite
 f = false,
 -- timers
 invincible = 0,
 cooldown   = 0,
 bcooldown  = 0,
 -- stats
 speed = 1,
 deal  = 0,
 tear_rate = 2,
 tsize     = 3,
 tcolor    = 7,
 -- items state
 double_shot=false,
 proptosis  =false,
 holy_mantle=false,
 mind       =true,//false,
 whore      =false,
 god        =false,
 ipecac     =false,
 mine       ={},
 -- curse
 curse_night=false,
}

function p:damage()
	local d=p.tsize/5
	if (p.whore and p.life<=1) d+=0.5
	return d
end

function p:hurt(v)
 p.tcolor=upd_tear_color()
 if p.invincible>0 then
  return
 end
 sfx(1)

 if not (p.holy_mantle and
         cr.no_hit) then
	 if v > self.blife then
	 	v -= self.blife
	 	self.blife=0
	 	self.life -= v
	 	self.deal/=2
	 else
	 	self.blife -= v
	 end
	end
 p.invincible=30
	cr.no_hit=false
end
 
-- move player
function p.move()
 p.s=64
 if p.vx!=0 or p.vy!=0 then
  p.s,p.a = rot(p.anim, p.a)
 end
 p.f=p.vx>0
 local nx=p.x+p.vx
 local ny=p.y+p.vy
//	if solida(nx-4,p.y,7,6) then
//  nx=p.x
// end
// if solida(p.x-4,ny,7,6) then
//  ny=p.y
// end
 local newpx={s=p.s,
  x=nx,y=p.y,
  w=7,h=7}
 local newpy={s=p.s,
  x=p.x,y=ny,
  w=7,h=7}
 local dohitx=false
 local dohity=false
 for ro in all(cr.rocks) do
  if ro.s==s_trap and
     room_timer > 60 and
     hit(p,ro,-2) then
   level_i += 1
   if (level_i > 1) p.deal=100
   reset(levels[level_i].size)
  end
  if hit(newpx,ro,-1,false) then
   dohitx=true
  end
  if hit(newpy,ro,-1,false) then
   dohity=true
  end
 end
 if not dohitx then
  p.x=nx
 end
 if not dohity then
  p.y=ny
 end

 -- push pickups
 --for e in all(cr.elts) do
 -- local d=dist(p,e)
 -- if d<5 and d!=0 then
 --  	e.x+=(e.x-p.x)/d*2
 --  	e.y+=(e.y-p.y)/d*2
 -- end
 --end
 
 -- update last player dir
 if p.vx!=0 or p.vy!=0 then
  --todo normalize
  lx,ly=p.vx,p.vy
 end
 
 --todo fix touching locked doors
 --if touch(nx-4,ny,10,10,216) or
 --   touch(nx-4,ny,10,10,217) or
 --  touch(nx-4,ny,10,10,230) or
 --   touch(nx-4,ny,10,10,246)
 --then
 -- if #level[rj][ri].emies==0 and
 --    p.keys > 0 then
 --  p.keys-=1
 --  --todo get room from current pos
 --  _,rooms=nbgh(ri,rj,level)
 --  for c in all(rooms) do
 --   local i,j=c[1],c[2]
 --   level[j][i].locked=false
 --  end
 --  gen_room(ri,rj)
 -- end
 --end
 --not ok because doors span on
 -- several cells
 checkdoors(nx,ny,10,10)
end

function p:draw()
 if self.holy_mantle and
    cr.no_hit then
  circ(p.x-1,p.y+4, 4, 12)
  circ(p.x-1,p.y+4, 6, 13)
 end
 if (p.whore and p.life<=1) pal(15,8)
 draw(p)
 pal()
end

-- draw the minimap
function draw_minimap(x,y)
 --rectfill(4+x-1,2+y,
 --        x+(gridw+1)*4+1,
 --        y+(gridh+1)*3+1,6)
 for i=1,gridh do
 for j=1,gridw do
  local r=level[j][i]
  if r.type!=0 and
     (r.seen or p.mind) then
   local c=7
   local t=r.type
   if not r.visited and
     t==r_classic then
    t = -1
   end
   c=roomcolor(t)
   rect(x+j*4,y+i*3,
        x+j*4+4,y+i*3+3,5)
   rectfill(x+j*4+1,y+i*3+1,
            x+j*4+3,y+i*3+2,c)
  end
 end
 end
 rect(x+rj*4-1,y+ri*3-1,
      x+rj*4+5,y+ri*3+4,7)
end

function gauge(x,y,min,max,v)
	local step=(max-min)/3
	for i=2,0,-1 do
	 c=7
		if (v<step*i or v==0) c=5
		line(x+i*2,y,x+i*2,y+2,c)
	end
end

function draw_stats(x,y)
 sspr(8,4,4,4,  x   ,y)
 gauge(x,y+5,0,4,p.tear_rate)
 x+=8
 sspr(12,0,4,4, x   ,y)
 gauge(x,y+5,0,2,p.speed)
 x+=8
 sspr(8,0,4,4,  x   ,y)
 gauge(x,y+5,0,5,p.damage())
 x+=8
 sspr(12,4,4,4,  x   ,y)
	gauge(x,y+5,0,100,p.deal)
end

function draw_life(x,y)
 print("  - life -  ", x, y-7,8)
 if p.lives>0 then
  print("x",    x-4,y+2,8)
  print(p.lives,x-4,y+8,8)
 end
 local fullhp=flr(p.life)
 for i=0,p.maxlife-1 do
  if i<fullhp then
   spr(35,x+i*8,y,1,1)
  elseif i==fullhp and
   p.life-fullhp!=0 then
   spr(50,x+i*8,y,1,1)
  else
   spr(51,x+i*8,y,1,1)
  end
 end
 -- blue hearts
 x+=p.maxlife*8
 pal(8,12)
 local fullbhp=flr(p.blife)
 for i=0,ceil(p.blife)-1 do
  if i<fullbhp then
   spr(35,x+i*8,y,1,1)
  elseif i==fullbhp and
   p.blife-fullbhp!=0 then
   spr(50,x+i*8,y,1,1)
  end
 end
 pal()
end

function draw_hud()
 minimapx,minimapy=0,3 //92,3
 draw_minimap(minimapx,minimapy)
 draw_life(80,14) // 4,4
 --draw bombs
 statsx=45
 spr(s_bomb, statsx-4, 4)
 print(":"..p.bombs,statsx+4,6,7)
 --draw keys
 spr(s_key, statsx+17, 4)
 print(":"..p.keys,statsx+25,6,7)
 -- draw stats 98,121
 draw_stats(statsx,14)
 --item tracker
 for i=1,#p.mine do
 	local p=p.mine[#p.mine+1-i]
  sspr(p.px,p.py,p.w,p.h,
  	   (i-1)*14,116)
 end
end

function reset(nb_rooms)
 gridw,gridh=8,5
 p.x,p.y=64,72

 tears={}
 etears={}
 screen_time=30
 screen_msg=levels[level_i].name

 -- gen first room
 -- last player direction
 lx,ly=1,0
 -- current room
 ri=ceil(rnd(gridh))
 rj=ceil(rnd(gridw))
 level,rooms=genlevel(ri,rj,nb_rooms)
 -- last room
 lri,lrj=ri,rj
 gen_room(ri,rj)
end

-- global init
function _init()
	build_items()
	debug=false
	anims={}
	doors={}
 messages={}
 circles={}
 level_i=1
 reset(levels[level_i].size)
 current=level[rj][ri]
end

function sort_y(t)
 function _y(e)
  return e.y
 end
 qsort(t,1,#t,_y)
end

function draw_all()
 local as={p}
 for e in all(doors) do
  if (e.draw) then
   e:draw()
  else draw(e)
  end
 end
 for ee in all({cr.emies,
                cr.rocks,
                cr.elts,
                cr.items}) do
  for e in all(ee) do
   add(as,e)
  end
 end
 sort_y(as)
 for a in all(as) do
  if a.draw == nil then
   draw(a)
  else
   a:draw()
  end
 end

 for t in all(etears) do
  t:draw()
 end
 for t in all(tears) do
  t:draw()
 end
end

function roomcolor(v)
 cmap={}
 cmap[-1]=5 -- unseen=grey
 cmap[r_classic]=12 -- blue
 cmap[r_boss]=8  -- red
 cmap[r_item]=10 -- yellow
 cmap[r_secret]=13 -- blue grey
 cmap[r_evil]=9 -- orange
 return cmap[v] or 0
end

function draw_bosslife()
	if (cr.emies==nil) return
 local b = cr.emies[1]
 if b then
  local ratio=b.life/b.maxlife
  if ratio>0 then
   rectfill(10,33,117,38,0)
   rectfill(11,34,
            11+105*ratio,37,8)
  end
 end
end

function draw_msg()
 if #messages > 0 then
  local message=messages[1][1]
  local timer=messages[1][2]
  messages[1][2] -= 1
  if timer>0 then
    local x,y=28,35
    local nlines=#message
    rect(x-1,y-1,128-x+1,
	     y+8*nlines+1,7)
    rectfill(x,y,128-x,
	         y+8*nlines,0)
   for i=0,nlines-1 do
    local c=7
    if (i==0) c=10
    print(message[i+1],
          x+1,y+2+i*8,c)
   end
  else
   del(messages,messages[1])
  end
 end
end

-- main draw
function _draw()
 cls()
 
 if screen_time > 0 then
 	local x=64-#screen_msg/2*4
  print(screen_msg,x,60,7)
  return
 end

 if p.life<=0 and
    p.blife<=0 and
    p.lives<=0 then
  draw_gameover()
  print("game over",48,60,7)
  return
 end

 draw_dwalls(cr.theme)
 mmap()

 draw_all()
 if cr.type == r_boss then
  draw_bosslife()
 end

 draw_msg()

 pal()
 
 draw_hud()
 draw_anims()
end

-- change room if necessary
function upd_room()
 if p.y<24 then
  gen_room(ri-1,rj)
  p.x,p.y = 64,106
 end
 if p.y>112 then
  gen_room(ri+1,rj)
  p.x,p.y = 64,32
 end
 if p.x<4 then
  gen_room(ri,rj-1)
  p.x,p.y = 116,68
 end
 if p.x>124 then
  gen_room(ri,rj+1)
  p.x,p.y = 12,68
 end
end

function draw_gameover()
 for c in all(circles) do
  circfill(c.x,c.y,c.r,12)
  circ(c.x,c.y,c.r,7)
 end
 spr(s_isaac,58,70,2,2)
end

function upd_gameover()
 while #circles<20 do
  add(circles, {
   x=rnd(143)-15,
   y=-rnd(20),
   vx=0,
   vy=rnd(0.5),
   r=rnd(15),
   c=4+flr(rnd(12))
  })
 end
 for c in all(circles) do
  c.x+=c.vx
  c.y+=c.vy
  if c.y>126 then
   del(circles,c)
  end
 end
end

function upd_elts()
 for i in all(cr.items) do
 	if hit(p,i) then
 	 if pickitem(i) then
    add(messages,{{i.n,i.d},120})
    add(p.mine, i)
    del(cr.items, i)
    sfx(0)
   end
 	end
 end
 for e in all(cr.elts) do  
  if hit(p,e) then
   local take=false
   if p.maxlife-p.life>0 then
    if e.s == s_heart then
     p.life += 1
     take=true
    end
    if e.s == s_hheart then
     p.life += 0.5
     take=true
    end
   end
   if p.maxlife+p.blife<6 then
   	if e.s == s_bheart then
     p.blife += 1
     take=true
    end
   end
   if e.s == s_key then
    p.keys += 1
    take=true
   elseif e.s == s_bomb then
    p.bombs += 1
    take=true
   end
   if take then
    del(cr.elts,e)
    sfx(0)
   end
  end
 end
 p.life=mid(0,p.life,p.maxlife)
end

-- main update
function _update60()
 keys:update()

 if screen_time>0 then
  screen_time-=1
  return
 end
 if p.cooldown>0 then
  p.cooldown-=1
 end
 if p.bcooldown>0 then
  p.bcooldown-=1
 end
 if p.invincible>0 then
  p.invincible-=1
 end
 
 room_timer += 1
 
 if p.life<=0 and
    p.blife<=0 then
  if p.lives <= 0 then
   upd_gameover()
   return
  else
   p.lives -= 1
   p.life    = 1
   p.blife   = 0
   p.maxlife = 1
   p.x,p.y=64,72
   screen_time=60
   screen_msg="  x"..p.lives
   gen_room(lri,lrj)
   drop(p)
  end
 end

 -- move
 p.vx,p.vy = 0,0
 if (keys:held(1)) p.vx+=p.speed
 if (keys:held(2)) p.vy-=p.speed
 if (keys:held(3)) p.vy+=p.speed
 if (keys:held(0)) p.vx-=p.speed
-- local norm=sqrt(p.vx*p.vx-p.vy*p.vy)
--	if norm > 0.0001 then
--		p.vx/=norm*p.speed
--	 p.vy/=norm*p.speed
-- end

 upd_room()

 shoot_tears()
 upd_bomb()
 upd_elts()
 upd_emies()
 upd_tears()
 upd_etears()
 p.move()
end

-->8
-- utils

function ssplit(s,sep)
	local ret={}
	local buff=""
	for i=1,#s do
	 if sub(s,i,i)==sep then
	 	add(ret,buff)
	 	buff=""
	 else
	 	buff = buff..sub(s,i,i)
	 end
	end
	if (buff!="") add(ret,buff)
	return ret
end


-- pick random element in t
function rpick(t)
 local i=flr(rnd(#t))+1
 return t[i]
end

function shuffle(t)
 for i=#t,1,-1 do
  local j=ceil(rnd(i))
  local tmp=t[i]
  t[i]=t[j]
  t[j]=tmp
 end
 return t
end

function revert(t)
 local r={}
 for i=#t,1,-1 do
  add(r,t[i])
 end
 return r
end

-- pick random element in t
-- and remove it
function rrpick(t)
 local i=flr(rnd(#t))+1
 local e=t[i]
 del(t,e)
 return e
end

function hit_rocks(e, r)
 r=r or level[rj][ri]	
	for ro in all(r.rocks) do
		if hit(e,ro) then
			return true
	 end
	end
	return false
end

--take object and make sure it is
-- not on a rock
function drop(e,r)
 r=r or level[rj][ri]
 for j=0,4 do
  for i=0,j+1 do
   local x=e.x+j*16
   local y=e.y+i*16
   local ne={x=x,y=x,w=e.w,h=e.h}
   if not hit_rocks(ne,r) then
    e.x,e.y=x,y
    return
   end
  end
 end
end

itemtc={
 1,2,3,4,
 5,6,7,8,
 9,10,11,10,
 13,14,15,16,
}
bosstc={
 1,2,3,4,
 5,6,7,8,
 9,10,11,8,
 13,14,15,16,
}
nighttc={
 0,0,0,0,
 5,5,6,7,
 6,6,7,6,
 6,5,5,7,
}
eviltc={
 0,0,0,0,
 9,9,14,7,
 14,14,7,14,
 14,9,9,7,
}

-- quick sort
function qsort(t,i,j,op)
 if i >= j then
  return
 end
 local pi = i
 for k=i+1,j do
  if op(t[k]) <= op(t[i]) then
   pi += 1
   t[pi],t[k] = t[k],t[pi]
  end
 end
 t[pi],t[i] = t[i],t[pi]
 qsort(t, i, pi-1, op)
 qsort(t, pi+1, j, op)
end

function dist(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 return sqrt(dx*dx+dy*dy)
end

-- rotate index i over table t
function rot(t, i)
 local k,j=1,i
 while j>t[k][2] and k<=#t do
 	j-=t[k][2]
 	k+=1
 	if (k==#t+1) then
 	  k=1
 	  i=j
 	end
 end
 return t[k][1], i+1
-- i += 1
-- if i > #t then
--  i = 1
-- end
-- return t[i], i
end

-- rotate 2d vec 90 degrees
function rot90(vx, vy)
 return vy, -vx
end

function proj3(i,maxi)
 local k=0
 if i>1 and i<maxi then
  k=1
 elseif i == maxi then
  k=2
 end
 return k
end
-- check if map cell with
-- flag 0 below area
function solida(x,y,w,h)
 for j=flr(x/8),flr((x+w)/8) do
 for i=flr(y/8),flr((y+h)/8) do
  if i>=0 and i<16 and
     j>=0 and j<16 and
     mmget(j,i).bf then
   return true
  end
 end
 end
 return false
end

function touchwhat(x,y,w,h,s)
 local res={}
 for j=flr(x/8),flr((x+w)/8) do
 for i=flr(y/8),flr((y+h)/8) do
  if i>=0 and i<16 and
     j>=0 and j<16 then
   if mmget(j,i).s==s then
    add(res,{i,j})
   end
  end
 end
 end
 return res
end

function touch(x,y,w,h,s)
 return #touchwhat(x,y,w,h,s) != 0
end

function checkdoors(x,y,w,h)
	for j=flr(x/8),flr((x+w)/8) do
 for i=flr(y/8),flr((y+h)/8) do
  if i>=0 and i<16 and
     j>=0 and j<16 then
   local cell = mmget(j,i)
   if cell.locked then
    if p.keys > 0 then
    	p.keys -= 1
    	cell.locked=false
    	cell.s-=1
    end
   end
  end
 end
 end
end


--true if pixel x,y is part
-- of sprite e
function psolid(e,x,y)
 -- coord in sprite
 local xsp = x-(e.x-e.w/2)
 local ysp = y-(e.y-e.h/2)
 -- coordinate in sprite sheet
 local v=1
 if e.s != nil then
  local sx=e.s*8%128 + xsp
  local sy=flr(e.s/16)*8 + ysp
  v = sget(sx, sy)
 end
 return v != 0
end

function pixel_collide(a,b,inter)
 for j=inter.x1,inter.x2 do
 for i=inter.y1,inter.y2 do
  if psolid(a,j,i) and
     psolid(b,j,i) then
     return true
  end
 end
 end
 return false
end

-- bbox intersection
-- then pixel tests inside
-- todo zonea, zoneb
function hit(a,b,zone,pixel)
 zone = zone or 0
 if (pixel==nil) pixel=true
 local aw=a.w/2+zone
 local bw=b.w/2+zone
 local x_left=max(a.x-aw,b.x-bw)
 local x_right=min(a.x+aw,b.x+bw)
 if x_right < x_left then
  return false
 end
 local ah=a.h/2+zone
 local bh=b.h/2+zone
 local y_top=max(a.y-ah,b.y-bh)
 local y_bottom=min(a.y+ah,b.y+bh)
 if y_bottom < y_top then
  return false
 end

 if not pixel then
  return true
 end

 local inter={
  x1=x_left,
  x2=x_right,
  y1=y_top,
  y2=y_bottom
 }
 return pixel_collide(a,b,inter)
end


-- draw element
function draw(e)
 if debug then
  rect(e.x-e.w/2-1,
     	 e.y-e.h/2-1,
       e.x+e.w/2,
       e.y+e.h/2,8)
 end
 spr(e.s,
  e.x-e.w/2,
  e.y-e.h/2,
  e.w/8, e.h/8,
  e.f,
  e.vf)
end

-- print all elements
function prtt(t)
 for e in all(t) do
  print(e)
 end
end

--gen_mat
function _mat(lines, cols, fun)
 local m = {}
 for i=1,lines do
  m[i] = {}
  for j=1,cols do
   m[i][j] = fun()
  end
 end
 return m
end

function _tile()
 return {
  s=0, fx=false, fy=false,
  bf=false
 }
end

__mmap = _mat(16,16,_tile)

--multimset
function mmset(cx,cy,s,w,h,
               fx,fy,cpal,
               locked)
 w = w or 1
 h = h or 1
 fx = fx or false
 fy = fy or false
 for i=0,h-1 do
  for j=0,w-1 do
   local ss=s+j+16*i
   __mmap[cy+i+1][cx+j+1] = {
       s=ss, fx=fx, fy=fy,
       bf=fget(ss,0),
       pal=cpal,
       locked=locked or false
     }
  end
 end
end

function mmget(cx,cy)
 return __mmap[cy+1][cx+1]
end

function mmap()
 for i=1,16 do
  for j=1,16 do
   local c=__mmap[i][j]
   if c.s!=0 then
   	for c1=1,16 do
   	 if c.pal and c.pal[c1] then
	   	 pal(c1, c.pal[c1])
	   	end
    end
    spr(c.s, j*8-8, i*8-8,1,1,
        c.fx,c.fy)
    pal()
   end
  end
 end
end

-- animations
-----------------

function draw_anims()
	for a in all(anims) do
	 if a and costatus(a)!='dead' then
 	 coresume(a)
 	else
 	 del(anims,a)
	 end
	end
end

function add_anims(f)
 add(anims,cocreate(f))
end

function highlight(x,y)
 return function()
 -- minimap coordinates
 local xo,yo=minimapx,minimapy
 x=x or xo+rj*4
 y=y or yo+ri*3
 for i=1,2 do
  for t=1,35 do
   rect(x-i,y-i,
        x+4+i,y+3+i,
       8)
 	 yield()
  end
 end
 end
end

function smoke(sx,sy)
 return function()
 local w=10
 local bb={}
	for i=1,25 do
		while #bb<=10 do
		 local x=flr(rnd(w))
		 local y=flr(rnd(w))
		 local r=flr(rnd(5))
			add(bb,{x,y,r})
		end
		for b in all(bb) do
	 	circ(sx+b[1],sy+b[2],b[3],13)
		end
		for b in all(bb) do
	 	circfill(sx+b[1],sy+b[2],b[3]-1,7)
	 end
		del(bb,bb[1])
		yield()
	end
	end
end

function pentacle(sx,sy)
	return function()
	local r,c,d=15,7,0
	while true do
	 local p={}
	 for t=0,0.9,1/5 do
	  local x=sx+sin(d+t)*r
		 local y=sy+cos(d+t)*r*0.8
		 pset(x,y,c)
		 add(p,{x,y})
		 c+=1
		end
		color(10)
		line(p[1][1],p[1][2],
		     p[3][1],p[3][2])
		line(p[5][1],p[5][2])
		line(p[2][1],p[2][2])
		line(p[4][1],p[4][2])
		line(p[1][1],p[1][2])
	 yield()
	 d+=0.003
	end
 end
end

function text(t,x,y,c,timer)
 return function()
  for i=1,timer do
   if flr(i/30)%2==0 then
    rectfill(x,y-1,x+#t*4-2,y+5,c)
    print(t,x+2,y,1)
   end
   yield()
  end
	end
end

-- keys
keys = { btns={}, ct={} }
function keys:update()
 for i=0,13 do
  if band(btn(),shl(1,i))==shl(1,i) then
   if keys:held(i) then
    keys.btns[i]=2
    keys.ct[i]+=1
   else
    keys.btns[i]=3
   end
  else
   if keys:held(i) then 
    keys.btns[i]=4
   else
    keys.btns[i]=0
    keys.ct[i]=0
   end
  end
 end
end

function keys:held(b) return band(keys.btns[b],2) == 2 end
function keys:down(b) return band(keys.btns[b],1) == 1 end
function keys:up(b) return band(keys.btns[b],4) == 4 end
function keys:pulse(b,r) return (keys:held(b) and keys.ct[b]%r==0) end

-->8
-- level generation

-- return empty and assigned
-- surrounding rooms
function nbgh(i,j,l)
 local cands = {
  {i-1,j}, {i+1,j},
  {i,j-1}, {i,j+1}
 }
 local free={}
 local occupied={}
 for c in all(cands) do
  local i,j=c[1],c[2]
  if i!=0 and j!=0 and
     i!=gridh+1 and
     j!=gridw+1 then
   if l[j][i].type!=0 then
    add(occupied,c)
   else
    add(free,c)
   end
  end
 end
 return free, occupied
end

function find_best(free,l)
	shuffle(free)
 local min_f=free[1]
 local min_occ=4
 for f in all(free) do
  local fi,fj=f[1],f[2]
  ffree,focc=nbgh(fi,fj,l)
  if #focc<min_occ then
   min_occ=#focc
   min_f=f
  end
 end
 return min_f
end

function addroom(l,i,j,nbr,last)
	l[j][i].type=1
	l[j][i].cx=flr(rnd(4))
	l[j][i].cy=flr(rnd(4))
	add(last,{i,j})
	-- break branches
	if nbr%4==0 then
		local r=rpick(last)
		i,j=r[1],r[2]
	end
	if nbr > 0 then
		local free,occ=nbgh(i,j,l)
		local tries=0
		while #free==0 do
		 tries+=1
			local o=rpick(last)
			free,occ=nbgh(o[1],o[2],l)
			if (tries>5) return
		end
	 local f=find_best(free,l)
		addroom(l,f[1],f[2],nbr-1,last)
	end
end

function add_sroom(l,last,t,ok,lasti)
	ok=ok or function(adj) return #adj==1 end
	lasti=lasti or #last
	local lastf=last[#last]
	for r=lasti,1,-1 do
		local i,j=last[r][1],last[r][2]
		free,_=nbgh(i,j,l)
		for f in all(free) do
			ffree,focc=nbgh(f[1],f[2],l)
			if ok(focc) then
		 	l[f[2]][f[1]].type=t
				return l[f[2]][f[1]]
			end
			lastf=f
		end
	end
	-- no match:return last free
	l[lastf[2]][lastf[1]].type=t
	l[lastf[2]][lastf[1]].seen=true
	return l[lastf[2]][lastf[1]]
end

function genlevel(ri,rj,nbr)
 local l=_mat(gridw,gridh,_room)
	local last={}
	-- add nbr rooms
	addroom(l,ri,rj,nbr,last)
	l[rj][ri].cx=0
	l[rj][ri].cy=0

	--item room
	local rlast=revert(last)
	local r=add_sroom(l,rlast,r_item)
	r.locked=level_i>1
	r.items={rrpick(items)}

	--secret room
	r=add_sroom(l,rlast,r_secret,
	 function(adj)
	  return #adj>=2
	 end)
	if r then
	 if rnd() > 0.05 then
 		r.elts={rpick(all_pickups)}
 	else
 		r.items={rrpick(items)}
 	end	
 end

	--boss room
	r=add_sroom(l,last,r_boss)
	if level_i == 4 then
	 r.boss=_boss(it_lives)
	else
	 r.boss=rrpick(all_bosses)
	end
	return l, last
end



-- room generation
----------------------

function floorspr(v)
 if v==0 or v==s_emy or v==s_fly then
  return levels[level_i].tile
 end
 return levels[level_i].tile+v-4
end

function set_floor(r,cpal)
 local cx=7*r.cx
 local cy=5*r.cy
 -- todo feels messy
 setrocks=r.rocks==nil
 if (setrocks) r.rocks={}
 for i=1,5 do
  for j=1,7 do
   local v=mget(cx+j-1,cy+i-1)
   local ss=floorspr(v)
   local jj=j*2-1
   local ii=(i+1)*2
   -- if rock
   if ss==levels[level_i].tile+4 then
    if setrocks then
     local rock={s=ss,
      x=jj*8+8, y=ii*8+8,
   	  w=16,h=16,
   	  special=rnd(1)>0.9
   	 }
   	 function rock:draw()
   	  if (self.special) pal(14,8)
   	 	draw(self)
   	 	if (self.special) pal()
   	 end
   	 add(r.rocks, rock)
   	end
   	ss=4
   	mmset(jj,ii,
   	 levels[level_i].tile,
   	 2,2, false,false, cpal)
   else
  		mmset(jj,ii, ss, 2,2,
  								false,false, cpal)
   end
   if r.closed then
    if v==s_emy then
     add(r.emies,
        _enemy(jj*8+8,ii*8+8))
    elseif v==s_fly then
     add(r.emies,
        _fly(jj*8+8,ii*8+8))
    end
   end
  end
 end
 if r.boss and r.closed then
  r.boss.x=64
  r.boss.y=70
  r.boss.life=r.boss.maxlife
  r.emies={r.boss}
 end
end

function seerooms(i,j)
 local nbgh = {
  {i-1,j}, {i+1,j},
  {i,j-1}, {i,j+1}
 }
 for c in all(nbgh) do
  if 0<c[2] and c[2]<=gridw and
     0<c[1] and c[1]<=gridh then
   local r=level[c[2]][c[1]]
   if r.type != r_secret then
    r.seen=true
   end
  end
 end
end

function set_doors(i,j)
 local rj,ri=j,i
	local r=level[rj][ri]
	local _,cands=nbgh(ri,rj,level)
 for c in all(cands) do
  local i,j=c[1],c[2]
  local cr=level[j][i]
  if cr.type!=0 and
     cr.type!=r_secret then
   local cpal={}
   if cr.type==r_item or
   				r.type==r_item then
   	cpal[5]=10
   end
   if cr.type==r_boss or
       r.type==r_boss then
   	cpal[5]=8
   end
   local bbox=doorbb[j-rj][i-ri]
	  local shift=0
	  if (r.emies!=nil and #r.emies!=0) shift=1
	  if (cr.locked) shift=2
	  if (r.type==r_secret) shift=3
	  //mmset(bbox.cj, bbox.ci,
   //      bbox.s+shift*bbox.w/8,
   //      bbox.w/8, bbox.h/8,
   //      bbox.x>100, bbox.y>100,
   //      cpal,cr.locked)
   bbox.s+=shift*bbox.w/8
   //bbox.x=bbox.cj*8
   //bbox.y=bbox.ci*8
   bbox.f=bbox.x>100
   bbox.vf=bbox.y>100
   add(doors,bbox) 
  end
 end
end

function gen_room(i, j)
 tears={}
 etears={}
 ri,rj=i,j
 cr=level[rj][ri]
 cr.theme=levels[level_i].theme
 cr.seen=true
 cr.visited=true
 --cr.emies=nil
 cr.no_hit=true
 
 seerooms(i,j)

 local cpal={}
 if cr.type == r_secret then
  cpal=nighttc
 elseif cr.type == r_evil then
  cpal=eviltc
 elseif cr.type == r_item then
  cpal=itemtc
 elseif cr.type == r_boss then
  cpal=bosstc
 end
 
 set_floor(cr,cpal)
 set_walls(cr.theme,cpal)
 set_doors(ri,rj)

 -- set current room coord
 lri,lrj=ri,rj
 room_timer=0
 add_anims(highlight())
end

-- draw walls behind doors
function draw_dwalls(theme)
 --right
 spr(theme+2,15*8,8*8,1,1,true)
 spr(theme+2,15*8,9*8,1,1,true)
 --left
 spr(theme+2,0,8*8,1,1)
 spr(theme+2,0,9*8,1,1)
 --top
 spr(theme+1,7*8,3*8)
 spr(theme+1,8*8,3*8)
 --bottom
 spr(theme+1,7*8,14*8,1,1,false,true)
 spr(theme+1,8*8,14*8,1,1,false,true)
end

function set_walls(theme,cpal) 
 --corners
 mmset( 0, 3,theme,1,1,false,false,cpal)
 mmset(15, 3,theme,1,1,true ,false,cpal)
 mmset( 0,14,theme,1,1,false,true ,cpal)
 mmset(15,14,theme,1,1,true ,true ,cpal)
 --sides
 for i=4,13 do
  mmset(0,i,theme+2,1,1,false,false,cpal)
  mmset(15,i,theme+2,1,1,true,false,cpal)
 end
 --ups and downs
 for j=1,14 do
  mmset(j,3,theme+1,1,1,false,false,cpal)
  mmset(j,14,theme+1,1,1,false,true,cpal)
 end
end


-->8
-- ressources

bomb_cooldown=90
bomb_zone=3

r_empty=0
r_classic=1
r_boss=2
r_item=3
r_secret=4
r_evil=5

--sprites
s_heart=16
s_hheart=17
s_bheart=32
s_bomb=33
s_bomba=48
s_bombb=49
s_key=34
s_trap=2
s_floor=4
s_isaac=64
s_emy=49
s_fly=96


function _level(n,s,t,tl)
 return {
  name=n, size=s,
  theme=t,tile=tl,
 }
end
//wall theme
l_garden=196
l_crypt=199
l_game=202
l_cemetery=205
l_womb=250
l_crystal=253
//floor theme
ft_garden=4
ft_tile=10
levels={
 _level("isaac mini ˇ",
        3,l_game,ft_tile),
 _level("the crypt",
        5,l_crypt,ft_tile),
 _level("cristal cave",
        7,l_crystal,36),
 _level("the garden",
        9,l_garden,ft_garden),
}

screen_time=120
screen_msg="isaac picobirth"

--function heart(x, y)
-- return {s=4,x=x,y=y,w=8,h=8}
--end

function _bomb(x, y)
 return {s=s_bombb, x=x, y=y,
  w=8, h=8, timer=bomb_cooldown}
end

function _pickup(s)
 return {s=s,x=64,y=70,w=8,h=8}
end

all_pickups={
 _pickup(s_heart),
 _pickup(s_hheart),
 _pickup(s_bheart),
 _pickup(s_bomb),
 _pickup(s_key)
}

function _room()
 return {
  type=0,
  seen=false,
  visited=false,
  closed=true,
  locked=false,
  emies={},
  elts={},
  items={},
  cx=0,cy=0
 }
end


function _boss(b)
 b.life=b.maxlife
 b.x=64
 b.y=64
 return b
end

zelda = {
 n="zelda",
 s=72,
 w=16,h=16,
 a=1,
 anim={{72,5},//72,72,72,72,
       {74,5}},//74,74,74,74},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0.6
}
function zelda.shoot()
end


monstro = {
 n="monstro",
 s=104,
 w=16,h=16,
 a=1,
 anim={{104,3},//104,104,
       {106,5},//106,106,106,106,
       {106,2}},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0.6
}
function monstro.shoot()
end

evil_isaac = {
 n="evil_isaac",
 s=108,
 w=16,
 h=16,
 a=1,
 anim={{108,5},//108,108,108,108,
       {110,5}},//110,110,110,110},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0.6
}
function evil_isaac.shoot(vx,vy,d)
	if rnd(1)<0.01 then
	for i=1,10 do
	 add(etears, _tear(
	  evil_isaac.x,evil_isaac.y,
	  vx+rnd(0.3), vy+rnd(0.3),3,8))
	end
	end
end


it_lives = {
 n="it_lives",
 s=76,
 w=16,
 h=16,
 a=1,
 anim={{76,5},//76,76,76,76,
       {78,5}},//78,78,78,78},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0
}
function it_lives.shoot(vx,vy,d)
	if rnd(1)<0.1 then
	 add(etears, _tear(
	  it_lives.x,it_lives.y,
	  vx, vy,3,8))
	end
end

all_bosses={
 _boss(zelda),
 _boss(monstro),
 _boss(evil_isaac),
}

-->8
--enemies

function _fly(x,y)
 --todo use _enemy
 local e = {
  life=0.1,
  s=s_fly,
  x=x, y=y,
  w=8, h=8,
  a=1,
  -- sprite sequence
  anim = {{96,1},{97,1}},
  f=true,
  damage=0.5,
  speed=0.3,
  tsize=1
 }
 function e:draw()
   pal(12,8)
   draw(self)
   pal()
 end
 function e:shoot()
 end
 return e 
end


function _enemy(x,y)
 local e = {
  life=1,
  s=64,
  x=x,y=y,
  w=16,h=16,
  a=1,
  -- sprite sequence
  anim = p.anim,
  f=true,
  damage=0.5,
  speed=0.3,
  tsize=2,
 }
 function e:draw()
   pal(12,8)
   draw(self)
   pal()
 end
 function e.shoot(vx,vy,d)
  if d > 10 then
   if rnd(1) < 0.01 then
   	add(etears, 
   	 _tear(e.x,e.y,vx,vy,
   	       e.tsize,8))
   end
  end
 end
 return e 
end

function drop_pickup(r,x,y,pickups)
 x=x or 64
 y=y or 70
 pickups=pickups or all_pickups
 local e=rpick(pickups)
	e.x,e.y=x,y
 drop(e,r)
 add(r.elts,e)
 add_anims(smoke(e.x-4,e.y-4))
end

function cleared(r)
 if r.type == r_boss then
  add(r.rocks,{s=s_trap,
               x=64,y=56,
               w=16,h=16})
  add(r.items, rrpick(items))
  room_timer=0
 else
  drop_pickup(r)
 end
 set_doors(ri,rj)
end

function move_enemy(e)
 -- motion
 local d=dist(p,e)
 local vx=(p.x-e.x)/d
 local vy=(p.y-e.y)/d
	
	e.shoot(vx,vy,d)
	
	vx*=e.speed
	vy*=e.speed
  
 -- check collision with others
 local ne={x=e.x+vx,y=e.y+vy}
 local move=true
 for e2 in all(cr.emies) do
  if e != e2 then
   dee = dist(ne,e2)
   if dee < 5 then
    move=false
    vx=(e2.x-ne.x)/(dee*3)
    vy=(e2.y-ne.y)/(dee*3)
    break
   end
  end
 end
 -- check collision with elts
 ne={x=e.x+vx,y=e.y+vy}
 for el in all(cr.elts) do
  dee = dist(ne,el)
  if dee < 5 then
   move=false
   vx=(el.x-ne.x)/(dee*3)/5
   vy=(el.y-ne.y)/(dee*3)/5
   el.x+=vx*15
   el.y+=vy*15
   break
  end
 end
 if move then
  if d > 5 then
   -- go toward isaac
   e.x+=vx
   e.y+=vy
  else
   -- hit isaac and bounce
   p:hurt(e.damage)
   p.vx=vx*5
   p.vy=vy*5
   e.x-=vx*15
   e.y-=vy*15
  end
 else
  -- avoid others
  e.x-=vx*5
  e.y-=vy*5
 end
 if vx!=0 or e.vy!=0 then
  e.s,e.a = rot(e.anim, e.a)
 end
 e.f=vx>0
end

function upd_emies()
 cr.closed=(cr.emies!=nil and #cr.emies!=0)
 
 for e in all(cr.emies) do
  -- death
  if e.life <= 0 then
   sfx(2)
   del(cr.emies, e)
   if #cr.emies==0 then
    cleared(cr)
   end
  end

  if room_timer > 30 then
   move_enemy(e)
  elseif e.s==s_fly or
         e.s ==s_fly+1 then
   -- todo feels messy
   e.s,e.a = rot(e.anim, e.a)
  end
 end
end

-->8
-- items

function _item(n,px,py,w,h,def)
 local i={n=n,s=s,d=def,px=px,py=py,
          x=64,y=72,w=w,h=h}
 i.cor=cocreate(pentacle(64,75))
 function i:draw()
  if self.cor and
    costatus(self.cor)!='dead'
   then
		  coresume(self.cor)
		end
 	sspr(px,py,w,h,64-w/2,72-h/2)
 end
 return i
end

s_items="mushroom,0,64,10,11,all stats up!\
;holy mantle,11,64,11,13,holy shield\
;proptosis,23,64,13,12,mega tears\
;brimstone,24,77,12,12,blood laser\
;20/20,114,77,12,18,double shot!\
;the poop,102,64,9,10,plop\
;the mind,88,64,13,13,i know all\
;the halo,1,77,14,7,all stats up\
;red key,1,85,14,9,the upside-down\
;the onion,37,64,15,14,more tears\
;godhead,37,64,10,15,god tear\
;the spoon,16,78,7,14,run!\
;dead cat,111,64,16,12,11 lives\
;the whore,63,64,13,12,curse up\
;chocobar,77,65,9,12,health up\
;ipecac,53,75,9,12,explosive tears\
;the flee,37,79,14,6,friends!\
;pyromaniac,63,77,14,13,love bombs\
;fixme,24,90,14,5,i've seen it all\
"

function build_items()
	items={}	
	for s in all(ssplit(s_items,';')) do
		fields = ssplit(s,',')
		add(items,_item(
		 fields[1],
			fields[2],
			fields[3],
			fields[4],
			fields[5],
			fields[6]
		))
	end
end

function h_trate(v)
 p.tear_rate += (v or 0)
 add_anims(highlight(statsx,14))
end

function h_speed()
 p.speed += (v or 0)
 add_anims(highlight(statsx+8,14))
end

function h_damage(v)
	p.tsize += (v or 0)
 add_anims(highlight(statsx+16,14))
end

function pickitem(e)
 if e.n=="mushroom" then
  p.maxlife += 1
  p.life  = p.maxlife
  p.tsize *= 1.5
  h_damage()
  h_speed(0.2)
  h_trate(0.2)
  return true
 end
 if e.n=="20/20" then
  p.double_shot=true
  return true
 end
 if e.n=="proptosis" then
  p.proptosis=true
  h_damage(p.tsize)
  return true
 end
 if e.n=="holy mantle" then
  p.holy_mantle=true
  return true
 end
 if e.n=="the mind" then
  p.mind=true
  p.curse_night=true
  return true
 end
 if e.n=="the onion" then
  h_trate(2)
  return true
 end
 if e.n=="the spoon" then
  p.speed+=0.3
  return true
 end
 if e.n=="dead cat" then
  p.lives=9
  p.maxlife=1
  p.life=1
  p.blife=0
  return true
 end
 if e.n=="chocobar" then
  p.maxlife += 1
  p.life += 1
  return true
 end
 if e.n=="the halo" then
  p.maxlife += 1
  h_damage(1)
  h_trate(0.5)
  h_speed(0.2)
  return true
 end
 if e.n=="the whore" then
  p.whore=true
  p.tcolor=upd_tear_color()
  return true
 end
 if e.n=="godhead" then
  p.god=true
  p.tcolor=upd_tear_color()
  return true
 end
 if e.n=="ipecac" then
  p.ipecac=true
  p.tcolor=upd_tear_color()
  p.tear_rate=0.5
  h_trate()
  h_damage(3)
  return true
 end
 if e.n=="red key" then
  for i=1,3 do
   local k=flr(rnd(#rooms))
   local ok = function(occ)
   	return true
   end
   add_sroom(level,rooms,r_evil,ok)
  end
  set_doors(ri,rj)
  return true
 end
 if e.n=="pyromaniac" then
 	p.pyromaniac=true
 end
 if e.n=="the poop" then
  -- do nothing
  return true
 end
 return false
end
-->8
--tears

function upd_tear_color()
 local c=7
 if (p.whore and p.life<=1) c=8
 if (p.god) c=12
 if (p.ipecac) c=11
 return c
end

function explosion(x,y,r,c)
 c = c or p.tcolor
 r = r or 1
 return function()
 local nbdir=4
	for t=1,10 do
  for dir=0,nbdir-1 do
   local angle=((0.5+dir)/nbdir)
   local x=x+t*sin(angle)
   local y=y+t*cos(angle)
   circfill(x,y,r,c)
   circ(x,y,r,5)
  end
  yield()
 end
 end
end

-- update enemy tears
function upd_etears()
	for t in all(etears) do
		t.x += t.vx
		t.y += t.vy
		killit=false
		if t.x < 4 or t.x > 124
   or t.y < 28 or t.y > 116 then
  	killit=true
  end
		if hit(t,p) then
			p:hurt(0.5)
			killit=true
		end
		if killit then
			del(etears,t)
   add_anims(explosion(t.x,t.y))
		end
	end
end

-- update shooting tears
function upd_tears()
 for t in all(tears) do
  local killit=false
  t.x += t.vx
  t.y += t.vy
  if p.proptosis and
     t.size > 1 then
   t.size-=0.1
  end
  if t.x<4 or t.x>124
   or t.y<28 or t.y>116 then
   killit=true
  end
  t.y+=4
  if (hit_rocks(t)) killit=true
  t.y-=4
  local closest=nil
  local min_d=500
  for e in all(cr.emies) do
   local d=dist(t,e)
   -- if e >0 ?
   if d<min_d then
    min_d=d
    closest=e
   end
   if hit(e,t) then
    sfx(1)
    if room_timer > 30 then
     e.life-=p.damage()
     e.x += t.vx*6*e.speed
     e.y += t.vy*6*e.speed
    end
    killit=true
    break
   end
  end
  if p.god and 
     killit==false and
     closest then
   t.x+=(closest.x-t.x)/min_d   
   t.y+=(closest.y-t.y)/min_d
  end
  if killit then
   del(tears,t)
   if p.ipecac then
   	bomb_it(t)
   else
    add_anims(explosion(t.x,t.y))
   end
  end
 end
end

function _tear(x,y,vx,vy,size,c)
 vx=vx or lx
 vy=vy or ly
 spd=spd or 1.3
 local t={
  x=x or p.x, y=y or p.y-4,
  vx=vx*spd, vy=vy*spd,
  w=p.tsize, h=p.tsize,
  size=size or p.tsize,
  c=c or p.tcolor
 }
 function t.draw()
  circfill(t.x,t.y,t.size,t.c)
  circ(t.x,t.y,t.size,5)
 end
 return t
end

function shoot_tears()
 if (p.cooldown<=0 and
     keys:held(4)) then
  --todo lx,ly not normalized
  if p.double_shot then
   local px,py=rot90(lx,ly)
   add(tears,_tear(p.x-px*3,
                   p.y-py*3))
   add(tears,_tear(p.x+px*3,
                   p.y+py*3))
  else
   add(tears,_tear())
  end
  p.cooldown=60/p.tear_rate
 end
end


-->8
-- bomb

doorbb={}
doorbb[-1]={}
doorbb[0]={}
doorbb[1]={}
--left
doorbb[-1][0]={x=0.5*8,y=9*8,
               w=8,h=16,
               cj=0,ci=8,
               s=228}
--right
doorbb[1][0]={x=15.5*8,y=9*8,
              w=8,h=16,
              cj=15,ci=8,
              s=228}
--top
doorbb[0][-1]={x=8*8,y=3.5*8,
               w=16,h=8,
               cj=7,ci=3,s=212}
--bottom
doorbb[0][1]={x=8*8,y=14.5*8,
              w=16,h=8,
              cj=7,ci=14,
              s=212}

function bomb_walls(b)
 local _,cands=nbgh(ri,rj,level)
 for c in all(cands) do
  local i,j=c[1],c[2]
  local r=level[j][i]
  if r.type==r_secret then
   local bbox=doorbb[j-rj][i-ri]
   if hit(b,bbox,bomb_zone) then
    sfx(1)
    mmset(flr(bbox.cj),
          flr(bbox.ci),
          bbox.s+3*bbox.w/8,
          bbox.w/8,
          bbox.h/8,
          bbox.x>100,
          bbox.y>100)
   end
  end
 end
end

function bomb_rocks(b)
 for ro in all(cr.rocks) do
  if hit(b,ro,bomb_zone) then
  	del(cr.rocks,ro)
  	if ro.special then
    drop_pickup(cr,
     ro.x,ro.y,{
     _pickup(s_bomb),
     _pickup(s_bheart),
     _pickup(s_key)})
  	end
  end
 end
end

function bomb_people(b)
 -- bomb enemies
 for e in all(cr.emies) do
  if hit(b,e,bomb_zone) then
   e.life -= 5
   end
 end
 -- bomb self
 if hit(b,p,bomb_zone) then
  p:hurt(1)
 end
end

function bomb_it(b)
 add_anims(explosion(b.x,b.y,2,8))
 bomb_walls(b)
 bomb_people(b)
	bomb_rocks(b)	
	sfx(3)
end

function upd_bomb()
 drop_bomb()
 for b in all(cr.elts) do
  -- update sprites
  if b.s==s_bomba or
     b.s==s_bombb then
   b.timer-=1
   if b.timer%4==0then
    if b.s==s_bomba then
     b.s=s_bombb
    elseif b.s==s_bombb then
     b.s=s_bomba
    end
   end
   -- explosion
   if b.timer<0 then
    bomb_it(b)
    --todo fix issue 2 sfx
    del(cr.elts,b)
   end
  end
 end
end

function drop_bomb()
 if (keys:held(5) and
     p.bombs > 0  and
     p.bcooldown<=0) then
  p.bombs -= 1
  add(cr.elts, _bomb(p.x,p.y+2))
  p.bcooldown=bomb_cooldown
 end
end

__gfx__
000000000080000066666666666666663333333333333333333e3333333333330000077777700000766666666666666776666666666666670006666666666000
00000000008077c06555ddddddddddd6333333333333333333ebe333333333330007777ee777700067777777777777706cccccccccccccc0006eeeeeeeeee600
00700700066677776995ddddddddddd63333333333333333333e3333333333330077777777ee770067777777777777706cccccccccccccc0066eeeeeeeeee660
000000000060dddd6995ddddddddddd6333333333333333333333333333333330777e7ee7777777067777777777777706cccccccccccccc00d6eeeeeeeeee660
00005050000000006995555dddddddd633333333333333333333333333e33333077777eee7ee777067777777777777706cccccccccccccc00d6eeeeeeeeee660
0070ddd00c0c05056995995dddddddd63333333333333333333333333ebe3333077ee77777777e7067777777777777706cccccccccccccc00d6eeeeeeeeee660
00000d00c0c00ddd6995995dddddddd633333333333333333333333333e33333077ee7ee7ee7e77067777777777777706cccccccccccccc00d6eeeeeeeeee660
00000000000000d06995995555ddddd63333333333383333333333333333333307e777777ee7e77067777777777777706cccccccccccccc00d6eeeeeeeeee660
00000000000000006995995995ddddd6333333333389833333333333333333330777ee7e7777777067777777777777706cccccccccccccc00d6eeeeeeeeee660
00550550005505506995995995ddddd63333333333b8333333333333333333330077ee7e7ee7e70067777777777777706cccccccccccccc00d6eeeeeeeeee660
05885885050058856995995995555dd63333333333b33333333333333333333300777e777ee7770067777777777777706cccccccccccccc00d66666666666660
05888785050087856995995995995dd633333333333b333333e3333333333333000777777777700067777777777777706cccccccccccccc00d6dddddddddd660
05888850050088506995995995995dd633333333333333333ebe333333333e33000007494470000067777777777777706cccccccccccccc006dddddddddddd60
00588500005085006995995995995556333333333333333333e333333333ebe3000044494444000067777777777777706cccccccccccccc006dddddddddddd60
0005500000055000699599599599599633333333333333333333333333333e33000004444440000067777777777777706cccccccccccccc00dddddddddddddd0
00000000000000006666666666666666333333333333333333333333333333330000000000000000700000000000000570000000000000070000000000000000
00000000000000000000000000000000dddddddddddddddddddddddddddddddd0007700000000000775555555555557775555755555555570000000000000000
00550550000010000000000007707700dddeeeeddddddddddddddddddddddddd007d770770077700777777777777777757777577775777750005555555550000
05cc5cc5000010000000000078878870dddddddeeddddddddddddddddddddddd007d7777d7777700777777777777777757777577775777750055eee5eee55500
05ccc7c500555500aaa0000078788870dddddddddddddddddddddddedddddddd077d7e7d77dd7770777777777777777757777577775777750555eeeeeeee5500
05cccc5005557750a9aaaaaa78888870ddddddddddddddddddddeeddeeeeeddd07dd7e7777d77e705777777777777777557775777757777555ee5ee5e5555550
005cc50005555750aaa99a9a07888700eeeedddeeeeedddddddeddddddeddddd07dd7ee77dd7ee70577777777777777775555755557755575eee5ee55555ee55
00055000055555509990090900787000dddddddedddddedddddeddddddeddddd77dd7ee7d777ee707777777777777777577775feef577775555555555eeeee55
00000000005555000000000000070000dddddddedddddedddddeeedeeedeeedd7dd77ee7dd7eee705777777777777777577775e8ee57777555555e55eeeeee55
00000000000000000000000000000000dddeeeeeeeededeedddddddddddddddd7dd7ee7dd77ee7007777777777777777577775ee8e57777505eeeee55eeeee55
00008000000080000770770007707700ddddedddddddddddddddddddddeddddd7dd7e77dd7eee7707777777777777777555775feef577775555eeeee55555550
00001000000010007887777077777770ddddedddddeddddddeeeeeeeddeedddd7d77e7ddd7ee7770777777777777777775555755557755575e55eeee5555e550
00555500008888007878777077777770ddddeeeedeeedeeeddddddeddddddddd777e77dd77ee7777577777777777777777777577775577755ee55ee555eeee55
05557750088877807888777077777770ddddddddddddddddddddddddddeddddd077e77dd7ee77ee7577777777777777757777577775777755eeee5555eeeee55
05555750088887800788770007777700ddddddddddddddddddddddddeeeeeeed00777ddd7ee77ee757777777777777775777757777577775555eeeee5eeeee50
05555550088888800078700000777000dddddddddddddddddddddddddddddddd000777777e7777e7777777777777777757777577775777750055eeee555ee550
00555500008888000007000000070000dddddddddddddddddddddddddddddddd0000000007777777777777777777777775557755557755570005555555555500
00000555555000000000055555500000000005555550000000000555555000000009809999098000000980999909870700058505250020000005850525020000
00005ffffff5000000005ffffff5000000005ffffff5000000005ffffff500000009899889998707000989988999870700058505250020000000585052502000
0005ffffffff50000005ffffffff50000005ffffffff50000005ffffffff50000000997887990707000099788799077700055555555020000000555555555200
005ffffffffff500005ffffffffff500005ffffffffff500005ffffffffff5000000997777990777000099777799007000055888885520000000558888855200
005f57ffff57f500005f57ffff57f500005f57ffff57f500005f57ffff57f5007777778999998070777777899999807000558888888550000005588888885500
005f55ffff55f500005f55ffff55f500005f55ffff55f500005f55ffff55f5007877878888889870787787888888987000588558558850000005887787788500
005fcc5555ccf500005fcc5555ccf500005fcc5555ccf500005fcc5555ccf5007777778999999970777777899999988002588888888855000025888888888550
0005cf5555fc50000005cf5555fc50000005cf5555fc50000005cf5555fc50007777778999999880777777899999888802588855588855000025888777888550
00005ffffff5000000005ffffff5000000005ffffff5000000005ffffff500007777778999998888777777899999988805558855588585000055588757885850
0005f555555f50000000055555500000000055555550000000005555555000007777778888999888777777888899987905855888885550000058558888855500
000555ffff55500000005ffff5f5000000005fff5f5000000005f5fff5f500007777778998888879777777899888897800555555555000000005555555550000
000005ffff500000000005f5ff500000000005fff5500000000055ffff5000007777778888999978777777888899997800005588850000000000055888500000
000005f55f5000000000005ff5000000000005ff5f500000000005f55f5000007877878999988978787787899999997000005855525000000000058555250000
00000550055000000000005555000000000000555500000000000550555000007777778999899870777777899998897000005850050000000000005005250000
00000000000000000000000000000000000000000000000000000000000000008888888000999970888888800089987000000500000000000000000000500000
00000000000000000000000000000000000000000000000000000000000000000009999000000070000000000099990000000000000000000000000000000000
00000000000000000070070007700070008880000008880000888000000888000000000000000000000005555555000000000555555000000000055555500000
07700770000000000700007070000007088888555588888008888855558888800000000000000000000555ff6555500000005777777500000000577777750000
775775777700007707000070700000070800888888880080080088888888008000000000000000000055fffff566550000057777777750000005777777775000
75577557757007570077770007777770000588888888500000058888888850000000000550000000005666fff666f55000577777777775000057777777777500
077887707778877707800870078008700058888888888500005888888888850000000555555500000556766ff676ff5500575777775775000057577777577500
0008800000088000077007700770077000585788885785000058588888588500000055fff555500055666665ff666ff500575577775575000057557777557500
0000000000000000ee7777eeee7777ee005855888855850000585588885585000005765ff57655005fffff555ff6666500578855558875000057885555887500
0000000000000000e000000e00000000005899555599850000589955559985000056665ff666f5505ff55f5855556ff500058755557850000005875555785000
0000000000000000700000077000000700059c5555c9500000059c5555c95000055ff555f6ffff555f555558758555f505555777777500000000577777755550
0500005005000050070000707700007700005cccccc5000000005cccccc500005566f585ff666ff55f588788888855f505755555555555500555555555555750
005005000050050007000070070000700005c555555c500000005555555000005ff55585555556650565558787555f5505557888878757500575788887875550
50088000000880050077770000777700000555cccc5550000005c5ccc5c500005f557885887855f505ff5555555ff55000057787777755500555778777775000
05588550055885500780087007800870000005cccc500000000055cccc5000005ff55788788855f50055ffffffff550000d5777777775d0000d5777777775d00
00055005500550000770077007700770000005c55c500000000005c55c500000556f555555555ff500055555555550000ddd57755775ddd000dd57755775dd00
0050050000500500ee7777eeee7777ee00000550055000000000055055500000055ffffffffff5550000000000000000000d555dd775d000000d577dd555d000
0500005005000050e00000000000000000000000000000000000000000000000000000000000050000000000000000000000d000000000000000555ddddd0000
00055550000000055500000000000000800000555500000000000000000000005555500000000000000000000000005000000050500000000000000000000000
005877750000005d7d500000000000000800055bb550000000555555555555058585855555000055555550000000057500000005000505000000005555000500
058878885000055cdc55000000555550000005bbbb50555505aaaa5775cccc05588855588550005444445000000057a750000000000050000000055665500550
058878875000555cdc555008055777550000055bbb555bb5005aa575575cc50588588558885000545454500000057aaa75000000050000000000566666550550
578777777505dcccdcccd508057765750000005bbbb5bb55005a57575575c50055555558885500544444500000057aaa75000000545500000005566666655550
577788778505cddddddd75000577557550000055bbb5bb500005775555775000000005588885055451145500000577a775000000554450000005666667665500
587888788505dcccdcccd50055777775555000557bb57550000057755775000000005588888505111c1115000000565650000005445545000555566655766500
558788785500555cdc5550055587778558550557777777550000555555550000555558888885055ccccc1500005557a75550005455544450056555665d556500
055555555000055cdc5500058558885588500575577755750000058888500000588888888885005c666c5500057aa575aa750055444445500056655655d56650
005d6fd50000005cdc5000055555555455000575577755750000005885000000558888888855005ccccc5000057aa757aa750005555555000556665665557750
000555500000005cdc500000058888555800057cc777cc750000000550000000055888888550005c666c500057aa75057aa75000000000005656675575005500
000000000000005dcd5000000555555500000557c757c7550000000000000000005555555500005ccccc500057a7500057a75000000000000555550050000000
00000000000000055500000000000000000000555777550000000055555550000000000000000055555550005555000005555000000000000000000000000000
00055555555550000000000000008888000000005555500000000577777765000000500500000000000000000000000000000000000000000000055005500000
00555aaaaaa555000055500000088558800000000000000000000577777765000055005950000000000000000000000000000000000000000000500000550000
055aaa9999aaa5500544450000085555800000005050050500000055555550000599559995000000000000000000000000000000000000000005000000005000
059aa555555aa95054494450088885588880000505600650500005222222250059977a7795000000000000000000000000000000000000000005555555555000
0559aaaaaaaa95505499945088555555558805055665566550500522666665005975575599500000000000000000000000000000000000000055675005675500
00555999999555005499945008888558888005050556855050500522677775005958858857955000000000000000000000000000000000000056777556777500
000555555555500054494450085555555580000500588500500005226eeee5005a5878885a995000000000000000000000000000000000000057777557777500
0000000000000000054445008558555585580000500550050000052266666500595888885a955000000000000000000000000000000000000005775005775000
00555500000000000054500085888558885800000000000000000522222225000575888577950000000000000000000000000000000000000000550000550000
055885500000000000545000855855558558000000000000000000555555500559a75857a9500000000000000000000000000000000000000000000000000000
0588885555555000005450000855588555800000000000000000000000000000559775a999500000000000000000000000000000000000000000000000000000
05855885855555000054500000888008880000000000000000000000000000000059979955500000000000000000000000000000000000000000000000000000
05585588888888000054500000000000000000000000000000000000000000000055555500000000000000000000000000000000000000000000000000000000
05855885858885000054500000555500055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05888855558585000055500005550055550055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0558855005555500000000005e575575e50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500000000000000000057ee55ee750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000005550055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000770077007700770033bbbbb3bbb3bbbbbbbbbb3c17777777c777777cc77c7cc75cccccccccccccccccccccc5eddde777dde7777e77eedd77
00077000770000007700770077007700bbbb8b33bbbbbb8bb8bb3b3c71cccccc7cccccc07cc07cc7c5ccccccccccccccccccccc5eedee77eddde77ee777ed777
000770007700000007007000077770003bbbbbbbbbbbb8bbb3bb3b3c7c1cc1117cccccc07cc07cc7cc5cccccccccccccccccccc577eeeeedeeddeee7d77ee77e
00077000770000000777700007878000bbb4bbbbb4bbbbbbbbb8b33c7cc17777c000000c7cc0c007ccc5ccccccccccccccccccc577777edd77eedd77deeeeeee
00007000700000000878700007777077bb4bbbbbbbbbbbbbb4bbb3cc7cc11ccc777cc7777cc0c777cccc5cccccccccccccccccc5e7777edd7eedde77ee777eed
00007000700000000777707700777777bbbbb8bbb333bbb33b4bb3cc7cc171ccccc07ccc7cc07cc7ccccc5ccccccccccccccccc57ee7eeeeeedd7eee7ee77edd
000077777000000000777777007777003bbbbb3333c33333bbbbb33c7cc17c1c000cc0007cc07cc7cccccc5cccccccccccccccc5e7eeede7ddd77ed77eeeeeee
00007878700000000067670000606000bbbbbb3cccccccccbbb8bb3cc11c7cc577777777c00c7cc7ccccccc555555555ccccccc5777eddee7777ed777edde77e
000077777000000077007700770077000005555bb55550000005555995555000000555588555500050511111111111500000000017777777c777777cc77c7cc7
0000077700770000770077007700770000551111111155000055dddd5ddd55000055dddddddd550005011111111115000000000071cccccc7cccccc07cc07cc7
000007777770000007777000070070000051111111111500005dddd5ddddd500005dddd55dddd5000550111111111550000000007c1cc1117cccccc07cc07cc7
000007777770000008787000077770000051111111111500005dddd5ddddd500005ddd5555ddd5000005111111111500000000007cc17777c000000c7cc0c007
000007777770000007777077078780000051111111111500005dddd5ddddd500005dddd55dddd50005555dd111dd1550000000007cc11ccc777cc7777cc0c777
000070700707000000777777077770770051111111116500005ddddd5dddd500005dddd55dddd50000555555d555d500000000007cc171ccccc07ccc7cc07cc7
000000000000000000676700007777770051161116666500005ddddd5dddd500005dddddddddd5000005dd5d5d5d5000000000007cc17c1c000cc0007cc07cc7
0000000000000000000000000067670055566666666665555555555555555555555555555555555555555dd55515505500000000c11c7cc577777777c00c7cc7
00000000000000007700770077007700000000050000000500000005500000050000000000000000cccccccccccccccccaaaaaaa0bbbbbbbbbbbbbbbb3449443
00077000770000007700770077007700000000050000000500000005555000050000000000000000cccaaccaaccaaccaccaa9aaabb33b33b3b33b33bb3499493
00077000770000000700700007777000055555550555555505555555115555050000000000000000cc9aa9aaaaaaaaaaccaaaaaab344444444444444bb494493
000770007700000007777000078780005511111655ddddd555ddddd51111d5550000000000000000caaaaaaaaaa9aaaacaaaaaa9b349994449999994b3494993
00007000700000000878700007777077511111665dddddd55dddddd51111dd550000000000000000caaaaaaaaaaaaaaacaaaaaaabb49449999444499b3494993
00007000700000000777707700777777511116665dddddd55dddddd511111d550000000000000000ccaa9aaaaaaaa9aaccaa9aaab349494444999944bb494433
00007777700000000077777700777700511116665dddddd55dd5ddd511115d550000000000000000ccaaaaaaa9aaaaaaccaaaaaab344949943944994b3499493
00007878700000000067670000606000b1111666955dd5558d5555d5111dd5dd0000000000000000c9aaaaaaaaaaaaaacaaaaaaabb44949393333399b3449443
00007777700000007700770077007700b11116669dd55dd58d5555d5111dd5d5000000000000000088787777eeeee88eeeee8877e7fffffffffffff7ffffffff
00000777007700007700770077007700511111665dddddd55dd5ddd51111dd55000000000000000078887778eeee88eeeee88877ee7fffff7fffff7d7ffffffe
00000777777000000777700007007000511111665dddddd55dddddd5111115550000000000000000777788888888ee8888887887ee77ffff7ffff7dd77ffffee
00000777777000000878700007777000511111165dddddd55dddddd51115dd550000000000000000777778eee88eeeee88777787eeee7777777f7ddd777ffeee
000007777770000007777077078780005511111655ddddd555ddddd51155d5050000000000000000877778eeee88eeeee8877788eeee6666777eeddd7777eeee
00007070070700000077777707777077055555550555555505555555555000050000000000000000e8878eee8eee888eee887888eee7766677eeeddd777d7eee
00000000000000000067670000777777000000050000000500000005000000050000000000000000ee888eee78e87788eee88888ee7776667eeeeedd77ddd7ee
00000000000000000000000000676700000000050000000500000005000000050000000000000000eee8eee777877778eeeeee87e7777766eeeeeeed7ddddd7e
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888eeeeee888777777888eeeeee888eeeeee888eeeeee888eeeeee888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88ee88eee88ee888ee88778887788ee8e8ee88ee888ee88ee8eeee88ee888ee88888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8eeee8eee8eeeee8ee8777778778eee8e8ee8eee8eeee8eee8eeee8eeeee8ee88888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8eeee8eee8eee888ee8777788778eee888ee8eee888ee8eee888ee8eeeee8ee88888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8eeee8eee8eee8eeee8777778778eeeee8ee8eeeee8ee8eee8e8ee8eeeee8ee88888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee8eee888ee8777888778eeeee8ee8eee888ee8eee888ee8eeeee8ee888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee8eeeeeeee8777777778eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888
1111111116161616177711c11111111116161616177711c111711111111111111111111111111111111111111111111111111111111111111111111111111111
1111111116161161111111c11111111116161666111111c111771111111111111111111111111111111111111111111111111111111111111111111111111111
1111111116661616177711c11171111116661116177711c111711111111111111111111111111111111111111111111111111111111111111111111111111111
111111111666161611111ccc171111111666166611111ccc17711111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111111666116616661666117116161111111116161171111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616661616171116161111111116161117111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111111111661161616161661171111611111111116661117111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616161616171116161171111111161117111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661666166116161666117116161711111116661171111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee1eee1e1e1eee1ee11111117711661111116611111666116616661666166611111111161611111616111111111616111116161111111111111111
11111e1e1e1111e11e1e1e1e1e1e1111117116111777161111111616161616661616161611111111161617771616111111111616177716161111111111111111
11111ee11ee111e11e1e1ee11e1e1111177116661111166611111661161616161661166111111111116111111161111111111666111116661111111111111111
11111e1e1e1111e11e1e1e1e1e1e1111117111161777111611111616161616161616161611711111161617771616117111111116177711161171111111111111
11111e1e1eee11e111ee1e1e1e1e1111117716611111166116661666166116161666166617111111161611111616171111111666111116661711111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111616161611111cc1111111111616161611111cc111111111166616661666166616661111166611661666166611111166116611661611166111661616
1111111116161616177711c11111111116161616177711c111111111116111611666161116161777161616161666161611111611161616161611161616161616
1111111116161161111111c11111111116161666111111c111111111116111611616166116611111166116161616166111111611161616161611161616161616
1111111116661616177711c11171111116661116177711c111711111116111611616161116161777161616161616161611111611161616161611161616161666
111111111666161611111ccc171111111666166611111ccc17111111116116661616166616161111166616611616166616661166166116611666166616611666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111aaaaaaaaaaaaaaaaaaaaaaaaa111111111111111111111111111111111111111111111111111111111117111111111111111111111111111
1666161116111111a666a666aa66a6a6a6a6a666a166111111771111111111111111111111111111111111111111111111117711111111111111111111111111
1616161116111111a6a6aa6aa6aaa6a6a6a6a6a6a611177711711111111111111111111111111111111111111111111111117771111111111111111111111111
1666161116111111a666aa6aa6aaa66aa6a6a666a666111117711111111111111111111111111111111111111111111111117777111111111111111111111111
1616161116111111a6aaaa6aa6aaa6a6a6a6a6aaa116177711711111111111111111111111111111111111111111111111117711111111111111111111111111
1616166616661666a6aaa666aa66a6a6aa66a6aaa661111111771111111111111111111111111111111111111111111111111171111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111166111116161666166616661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611111116161611161616161161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666111116661661166616611161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111116111116161611161616161161117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111661166616161666161616161161171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111166111116161616166616661666166611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611111116161616161116161616116111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666111116661666166116661661116111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111116111116161616161116161616116111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111661166616161616166616161616116117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111166111116661166166616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611111116161616166616161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666111116611616161616611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111116111116161616161616161171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111661166616661661161616661711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111166111116161666161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611111116161611161611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666111116611661166611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111116111116161611111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111661166616161666166611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111111666116611661166117116661171111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616111611171116161117111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111111111661161616661666171116611117111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161611161116171116161117111111111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661666166116611661117116661171111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666111116111666166616661111166611111666166616161611166616661666111111111111111111111111111111111111111111111111111111111111
11111616111116111161161116111777161611111666161616161611116116111611111111111111111111111111111111111111111111111111111111111111
11111661111116111161166116611111166111111616166611611611116116611661111111111111111111111111111111111111111111111111111111111111
11111616111116111161161116111777161611111616161616161611116116111611111111111111111111111111111111111111111111111111111111111111
11111666117116661666161116661111166611711616161616161666166616111666111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661111161611111c111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116161111161617771c111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116611111116111111ccc1ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116161111161617771c1c111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661171161611111ccc111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888828882228882822882228222888888888888888888888888888888888888888882888222822282888882822282288222822288866688
82888828828282888888828888828828882888828882888888888888888888888888888888888888888882888282828282888828828288288282888288888888
82888828828282288888822288228828882888228822888888888888888888888888888888888888888882228222822282228828822288288222822288822288
82888828828282888888828288828828882888828882888888888888888888888888888888888888888882828882828282828828828288288882828888888888
82228222828282228888822282228288822282228222888888888888888888888888888888888888888882228882822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0001000000000000010100000000010100000000000000000101000000000101000000000000000001010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101000000000000000001010000010101010000000000000100010101010101010100000000000001000100010101010101
__map__
0006000600060000080606066000000000060000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600080608000606080008000806003100000060000000000600080000060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000060006000006080008000806000600080006000008063106000000310808083100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600080608000606080008000806006000000031000008000600000000060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000600060000600606060800000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000060006310000060000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008080808080000000660060000000008310800000000000800000006080000000806000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008086008080000066006600600000006080600000000080808000000003108310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008080808080000000660060000000008310800000000000800000006080000000806000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000031060006000000060000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606080008060600060600060600000600060006000000000000000031060806080631000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080008080800060600060600060406060631060000003100000008060000000608000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000006000000000000031000000000606600606000000060806000000060006000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080008080800060600060600063106060600060000310631000008060000000608000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606080008060600060600060600000600060006000000000000000031060806080631000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000006000000000006080000000000080000000600000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000060006000000086000600800006008000860000000006000000000003106310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008310831080000000608060000000600060006000600603160000606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000060006000000086000600800006008000860000000006000000000003106310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000006000000000006080000000000080000000600000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000f05013050150501a0501f05022050250502c050320503405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001814014150101500d1500b1300a1300911000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b15021150231501e150161501f150251501f150181501e15026150211501b1301a130221302013018110181100000000000000000000000000000000000000000000000000000000000000000000000
000200000d340096400f650147300f3401035012350133501636017360173501664016640206300b6200b62005320053100b31002510066000160004600036000360002600006000060000600006000060000600
000500001dd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
