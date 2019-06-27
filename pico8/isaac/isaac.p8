pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- game: isaac
-- author: log0
-- 
--todo:
-- room doors based on types
-- blue heart
-- boss patterns
-- crystal cave
-- final boss
-- hold shoot always same dir ?
-- pack items and usde sspr
-- item combinations
-- push bomb with tears
-- pickup drop animation
--bugs:
-- fix first level_gen hang
-- diagonal move should be 1
-- tear speed depends on speed
-- fix palette of emies at night
-- boss different when reentering
-- fix boss missing sometimes


function begin()end
p = {
 life    = 3,
 maxlife = 3,
 bombs   = 9,
 keys    = 1,
 speed   = 1,
 lives   = 0,
 -- position
 x=64, y=72,
 -- cell width.height
 wx=2, wy=2,
 --sprite
 s = 64,
 -- sprite sequence
 anim = {66,66,66,66,66,
         70,70,70,70,70,
         68,68,68,68,68,
         70,70,70,70,70},
 -- anim index
 a = 1,
 -- flip sprite
 f = false,
 -- gauge
 invincible=0,
 cooldown=0,
 bcooldown=0,
 -- tear properties
 tear_rate=2,
 tsize=3,
 tcolor=7,
 -- items state
 double_shot=false,
 proptosis=false,
 holy_mantle=false,
 mind=true,
 whore=false,
 god=false,
 ipecac=false,
 mine={},
 -- curse
 curse_night=false,
}
 
-- move player
function p.move()
 local r=level[rj][ri]
 p.s=64
 if p.vx!=0 or p.vy!=0 then
  p.s,p.a = rot(p.anim, p.a)
 end
 p.f=p.vx>0
 local nx=p.x+p.vx
 local ny=p.y+p.vy
	if solida(nx-4,p.y,7,6) then
  nx=p.x
 end
 if solida(p.x-4,ny,7,6) then
  ny=p.y
 end
 local newpx={s=p.s,
  x=nx,y=p.y,
  wx=0.8,wy=0.8}
 local newpy={s=p.s,
  x=p.x,y=ny,
  wx=0.8,wy=0.8}
 local dohitx=false
 local dohity=false
 for ro in all(r.rocks) do
  if hit(newpx,ro,-1) then
   dohitx=true
  end
  if hit(newpy,ro,-1) then
   dohity=true
  end
 end
 if not dohitx then
  p.x=nx
 end
 if not dohity then
  p.y=ny
 end

 local np={x=nx,y=ny}
 for el in all(r.elts) do
  local dee=dist(np,el)
  if dee<5 then
   local vx,vy=0,0
   if dee!=0 then
    vx=(el.x-p.x)/dee
    vy=(el.y-p.y)/dee
   end
   el.x+=vx
   el.y+=vy
   break
  end
 end
 
 -- update last player dir
 if p.vx!=0 or p.vy!=0 then
  --todo normalize
  lx,ly=p.vx,p.vy
 end
 
 --todo fix trap is 2x2
 if touch(p.x-4,p.y,8,8,s_trap) then
  level_i += 1
  reset(levels[level_i].size)
 end
 
 --todo fix touching locked doors
 if touch(nx-4,ny,8,8,216) or
    touch(nx-4,ny,8,8,217) or
    touch(nx-4,ny,8,8,230) or
    touch(nx-4,ny,8,8,246)
 then
  if #level[rj][ri].emies==0 and
     p.keys > 0 then
   p.keys-=1
   local cands = {
    {ri-1,rj}, {ri+1,rj},
    {ri,rj-1}, {ri,rj+1}
   }
   for c in all(cands) do
    local i,j=c[1],c[2]
    level[j][i].locked=false
   end
   gen_room(ri,rj)
  end
 end
end

-- draw the minimap
function draw_minimap()
 for i=1,5 do
 for j=1,5 do
  local r=level[j][i]
  if r.type!=0 and
     (r.seen or p.mind) then
   local c=7
   local t=r.type
   if not r.visited and
      t==s_classic then
    t = -1
   end
   c=roomcolor(t)
   rect(95+i*4,3+j*3,
        95+i*4+4,3+j*3+3,5)
   rectfill(95+i*4+1,3+j*3+1,
            95+i*4+3,3+j*3+2,c)
  end
 end
 end         
 rect(95+ri*4-1,3+rj*3-1,
      95+ri*4+5,3+rj*3+4,7)
end


function draw_hud()
 --drawlife
 local fullhp=flr(p.life)
 local x,y=8,4
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
 if p.lives>0 then
  print("x"..p.lives,0,y+2,8)
 end
 --draw bombs
 local xb=57
 spr(s_bomb, xb, y)
 print(":"..p.bombs,xb+8,y+2,7)
 --draw keys
 spr(s_key, xb+21, y)
 print(":"..p.keys,xb+30,y+2,7)
 -- draw stats
 local x,y=4,16
 local si,sp,tr=p.tsize,p.speed,p.tear_rate
 sspr(8,4,4,4,  x   ,y)
 print(":"..tr, x+4    ,y,7)
 x+=21
 sspr(12,0,4,4, x   ,y)
 print(":"..sp, x+4 ,y,12)
 x+=20
 sspr(8,0,4,4,  x   ,y)
 print(":"..si, x+4 ,y,8)
end


function reset(nb_rooms)
 gridw,gridh=5,5
 p.x,p.y=64,72

 tears = {}
 level=genlevel(nb_rooms)

 screen_time=30
 screen_msg=levels[level_i].name

 -- gen first room
 -- last player direction
 lx,ly=1,0
 -- current room
 ri,rj=3,3
 -- last room
 lri,lri=3,3
 gen_room(ri,rj)
end

-- global init
function _init()
 particles={}
 messages={}
 circles={}
 level_i=1
 reset(levels[level_i].size)
 r=level[rj][ri]
end

function sort_y(t)
 function _y(e)
  return e.y
 end
 qsort(t,1,#t,_y)
end

-- fixme draw everything like this
function draw_all()
 local r=level[rj][ri]
 local as={p}
 for e in all(r.emies) do
  add(as,e)
 end
 for ro in all(r.rocks) do
 	add(as,ro)
 end
 for e in all(r.elts) do
 	add(as,e)
 end
 sort_y(as)
 if p.holy_mantle and
    r.no_hit then
  circ(p.x-1,p.y+4, 4, 12)
  circ(p.x-1,p.y+4, 6, 13)
 end
 for a in all(as) do
  if a.draw == nil then
   draw(a)
  else
   a:draw()
  end
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

function draw_bosslife(r)
 local b = r.emies[1]
 if b then
  local ratio=b.life/b.maxlife
  if ratio > 0 then
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
  if timer > 0 then
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
          x+1,y+2+i*8,
          c)
   end
  else
   del(messages,messages[1])
  end
 end
end

-- main draw
function _draw()
 cls()
 pal()
 
 if screen_time > 0 then
  print(screen_msg,48,60,7)
  return
 end

 if p.life<=0 and p.lives<=0 then
  draw_gameover()
  print("game over",48,60,7)
  return
 end

 local r=level[rj][ri]

 --if --p.curse_night or
 if r.type == r_secret then
  nightpal()
 elseif r.type == r_evil then
  evilpal()
 else
  pal(12,roomcolor(r.type))
 end
 
 draw_dwalls(levels[level_i].theme)
 mmap()

 draw_all()
 draw_tears(t)
 if r.type == r_boss then
  draw_bosslife(r)
 end

 draw_msg()

 pal()
 
 --item tracker
 for i=1,#p.mine do
  spr(p.mine[#p.mine-i+1],
     (i-1)*16,112,
     2,2)
 end
 draw_minimap()
 draw_hud()
end

-- change room if necessary
function upd_room()
 if p.y<24 then
  gen_room(ri,rj-1)
  p.x,p.y = 64,106
 end
 if p.y>112 then
  gen_room(ri,rj+1)
  p.x,p.y = 64,32
 end
 if p.x<4 then
  gen_room(ri-1,rj)
  p.x,p.y = 116,68
 end
 if p.x>124 then
  gen_room(ri+1,rj)
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

function upd_elts(r)
 for e in all(r.elts) do  
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
   if e.s == s_key then
    p.keys += 1
    take=true
   elseif e.s == s_bomb then
    p.bombs += 1
    take=true
   elseif pickitem(e) then
    add(messages, {{e.n,e.d},120})
    add(p.mine, e.s)
    take=true
   end
   if take then
    del(r.elts,e)
    sfx(0)
   end
  end
 end
 p.life=mid(0,p.life,p.maxlife)
end

-- main update
function _update60()
 keys:update()

 if screen_time > 0 then
  screen_time-=1
  return
 end
 if p.cooldown > 0 then
  p.cooldown-=1
 end
 if p.bcooldown > 0 then
  p.bcooldown-=1
 end
 if p.invincible > 0 then
  p.invincible-=1
 end
 
 room_timer += 1
 
 if p.life<=0 then
  if p.lives<=0 then
   upd_gameover()
   return
  else
   p.lives -= 1
   p.life =1
   p.maxlife=1
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

 upd_room()

 local r=level[rj][ri]

 shoot_tears()
 upd_bomb(r)
 upd_elts(r)
 upd_emies()
 upd_tears()
 update_particles()
 p.move()
end

-->8
-- utils

-- pick random element in t
function rpick(t)
 local i=flr(rnd(#t))+1
 return t[i]
end

-- pick random element in t
-- and remove it
function rrpick(t)
 local i=flr(rnd(#t))+1
 local e=t[i]
 del(t,e)
 return e
end

function drop(e)
 for j=0,4 do
  for i=0,j+1 do
   local x=e.x+j*8
   local y=e.y+i*8
   if not solida(x-(e.wx*8)/2,
                 y-(e.wy*8)/2,
               e.wx*8,
               e.wy*8) then
    e.x,e.y=x,y
    return
   end
  end
 end
end

nighttc={
 0,0,0,0,
 5,5,6,7,
 6,6,7,6,
 6,5,5,7,
}
function nightpal()
 for c=1,16 do
  pal(c-1,nighttc[c])
 end
end

eviltc={
 0,0,0,0,
 9,9,14,7,
 14,14,7,14,
 14,9,9,7,
}
function evilpal()
 for c=1,16 do
  pal(c-1,eviltc[c])
 end
end

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
 i += 1
 if i > #t then
  i = 1
 end
 return t[i], i
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


--true if pixel x,y is part
-- of sprite e
function psolid(e,x,y)
 -- coord in sprite
 local xsp = x-(e.x-e.wx*4)
 local ysp = y-(e.y-e.wy*4)
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
 --pixel = pixel or true
 local aw=a.wx*4+zone
 local bw=b.wx*4+zone
 local x_left=max(a.x-aw,b.x-bw)
 local x_right=min(a.x+aw,b.x+bw)
 if x_right < x_left then
  return false
 end
 local ah=a.wy*4+zone
 local bh=b.wy*4+zone
 local y_top=max(a.y-ah,b.y-bh)
 local y_bottom=min(a.y+ah,b.y+bh)
 if y_bottom < y_top then
  return false
 end

 if (not pixel) return true
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
  rect(e.x-e.wx*8/2-1,
     	 e.y-e.wy*8/2-1,
       e.x+e.wx*8/2,
       e.y+e.wy*8/2,8)
 end
 spr(e.s,
  e.x-e.wx*8/2,
  e.y-e.wy*8/2,
  e.wx, e.wy,
  e.f)
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
               fx,fy)
 w = w or 1
 h = h or 1
 fx = fx or false
 fy = fy or false
 for i=0,h-1 do
  for j=0,w-1 do
   local ss=s+j+16*i
   __mmap[cy+i+1][cx+j+1] = {
       s=ss, fx=fx, fy=fy,
       bf=fget(ss,0)
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
    spr(c.s, j*8-8, i*8-8,1,1,
        c.fx,c.fy)
   end
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

-- check if door lead to
-- boss room
function isnextboss(doors,l)
 for d in all(doors) do
  if l[d[2]][d[1]].type == 2 then
   return true
  end
 end
 return false
end

-- add secret room
-- 2 doors
function addsecret(last,l)
 for r in all(last) do
  ri,rj=r[1],r[2]
  free,_=nbgh(ri,rj,l)
  for f in all(free) do
   _,doors=nbgh(f[1],f[2],l)   
   if #doors>=2 and
    not isnextboss(doors,l)
    then
    l[f[2]][f[1]].type=4
    return f[1],f[2]
   end
  end
 end
 --fixme what if no slot found
end

-- add special room
-- (only one door)
function addsroom(f,l,t)
 local doors={}
 local fi,fj=f[1],f[2]
 -- while not 1 door
 while #doors!=1 do
  -- check free room with 1 door
  local free,occ=nbgh(fi,fj,l)
  for c in all(free) do
   fi,fj=c[1],c[2]
   _,doors=nbgh(fi,fj,l)
   if #doors==1 then
    -- found
    break
   end
  end
  -- if no free room ok
  -- start from rand occupied
  -- room around
  if #doors!=1 then
   f=rpick(occ)
   local t=l[f[2]][f[1]].type
   while t!=1 do
    f=rpick(occ)
   end
   fi,fj=f[1],f[2]
  end
 end
 -- add room
 l[fj][fi].type = t
 return fi,fj
end

function _room()
 return {
  type=0,
  seen=false,
  visited=false,
  closed=true,
  locked=false,
  emies={},
  elts={},
  cx=0,
  cy=0,
 }
end

-- rpick an existing room
-- and add a room next to it
function addroom(l, last, t)
 t = t or r_classic
 local tries=0
 local r=rpick(last)
 local free,_=nbgh(r[1],r[2],l)
 while r.type==r_boss or
       #free==0 do
  tries += 1
  r=rpick(last)
  free,_=nbgh(r[1],r[2],l)
  if (tries>5) return
 end
 c=rpick(free)
 -- add room
 l[c[2]][c[1]].type=t
 l[c[2]][c[1]].cx=flr(rnd(5))
 l[c[2]][c[1]].cy=flr(rnd(3))
 add(last,c)
end

--simple level generation
function genlevel(nbr)
 local l=_mat(gridw,gridh,_room)
 
 -- start with central room
 local cj=ceil(gridw/2)
 local ci=ceil(gridh/2)
 l[cj][ci].type = r_classic
 local last={{ci,cj}}
 nbr -= 1

 -- keep adding rooms
 while #last!=nbr do
  addroom(l, last)
 end

 -- add item room
 -- (close to first room)
 local f={ci,cj}
 ii,ij=addsroom(f,l,r_item)
 if level_i > 1 then
  l[ij][ii].locked=true
 end
 l[ij][ii].elts={
  rrpick(items),
 }
 
 -- add boss room
 -- (close to last room)
 local f=last[#last]
 ii,ij=addsroom(f,l,r_boss)
 --l[ij][ii].cx=0
 --l[ij][ii].cy=3
 l[ij][ii].emies={
  rrpick(all_bosses)
 }
 
 -- add secret room
 i,j=addsecret(last,l)
 drop_pickup(l[j][i])
 
 return l
end

function floorspr(v)
 if v==0 or v==s_emy or v==s_fly then
  return levels[level_i].tile
 end
 return levels[level_i].tile+v-4
end

function set_floor(r)
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
   if ss==8 then
    if setrocks then
     local rock={s=ss, x=jj*8+8,
   	  y=ii*8+8,
   	  wx=2,wy=2,
   	  special=rnd(1)>0.5
   	 }
   	 function rock:draw()
   	  if (self.special) pal(9,8)
   	 	draw(self)
   	 	if (self.special) pal()
   	 end
   	 add(r.rocks, rock)
   	end
   	ss=4
   end
   mmset(jj, ii, ss, 2, 2)
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
 if r.type==r_boss and r.closed then
  local boss=rpick(all_bosses)
  add(r.emies,boss)   
 end
end

function clearroom(r)
 r.emies={}
 r.no_hit=true
 set_floor(r)
end

function seerooms(i,j)
 local nbgh = {
  {i-1,j}, {i+1,j},
  {i,j-1}, {i,j+1}
 }
 for c in all(nbgh) do
  if 0<c[2] and c[2]<=gridh and
     0<c[1] and c[1]<=gridw then
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
   local bbox=doorbb[i-ri][j-rj]
	  local shift=0
	  if (#r.emies!=0) shift=1
	  if (cr.locked) shift=2
	  mmset(bbox.cj, bbox.ci,
         bbox.s+shift*bbox.wx,
         bbox.wx, bbox.wy,
         bbox.x>100, bbox.y>100)
  end
 end
end

function gen_room(i, j)
 tears={}
 local r=level[j][i]
 r.seen=true
 r.visited=true
 clearroom(r)

 seerooms(i,j)
 set_walls(levels[level_i].theme)
 set_doors(i,j)

 if r.type==r_boss and
    r.closed==false then
  -- add trap
  mmset(7,6,s_trap,2,2)
 end

 -- set current room coord
 lri,lrj=ri,rj
 ri,rj=i,j
 r=level[rj][ri]
 room_timer=0
 particles={}
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

function draw_walls(theme)
 function dwall(i,j, theme)
  local x=proj3(i,16)
  local y=proj3(j,12)
  local ss=theme+x+16*y
  spr(ss,(i-1)*8,(j+2)*8)
 end
 theme = theme or 196
 for i=1,16 do
  dwall(i,1,theme)
  dwall(i,12,theme)
 end
 for j=2,11 do
  dwall(1,j,theme)
  dwall(16,j,theme)
 end
end

function set_walls(theme)
 --corners
 mmset(0,3,theme)
 mmset(15,3,theme,1,1,true)
 mmset(0,14,theme,1,1,false,true)
 mmset(15,14,theme,1,1,true,true)
 --sides
 for i=4,13 do
  mmset(0,i,theme+2)
  mmset(15,i,theme+2,1,1,true)
 end
 --ups and downs
 for j=1,14 do
  mmset(j,3,theme+1)
  mmset(j,14,theme+1,1,1,false,true)
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
s_bomb=33
s_bomba=48
s_bombb=49
s_key=34
s_trap=2
s_tile=6
s_floor=4
s_block=34
s_isaac=64
s_emy=49
s_fly=96

l_garden=196
l_crypt=199
l_game=202
l_cemetery=205

function _level(n,s,t,tl)
 return {
  name=n, size=s,
  theme=t,tile=tl,
 }
end

ft_garden=4
ft_tile=10
levels={
 _level("isaac.p8",6,l_garden,4),
 _level("the crypt",8,l_crypt,10),
 _level("the game",10,l_game,10),
 _level("the cemetery",6,l_cemetery,10),
}

screen_time=120
screen_msg="isaac.p8"

function heart(x, y)
 return {s=4, x=x, y=y,
  wx=1, wy=1}
end

function _bomb(x, y)
 return {s=s_bombb, x=x, y=y,
  wx=1, wy=1, timer=bomb_cooldown}
end


all_pickups={
 s_heart,
 s_hheart,
 s_bomb,
 s_key
}

function _boss(b)
 b.life=b.maxlife
 b.x=64
 b.y=64
 return b
end

zelda = {
 s=72,
 wx=2,
 wy=2,
 a=1,
 anim={72,72,72,72,72,
       74,74,74,74,74},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0.6
}
monstro = {
 s=104,
 wx=2,
 wy=2,
 a=1,
 anim={104,104,104,
       106,106,106,106,106,
       106,106},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0.6
}
evil_isaac = {
 s=108,
 wx=2,
 wy=2,
 a=1,
 anim={108,108,108,108,108,
       110,110,110,110,110},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0.6
}
it_lives = {
 s=76,
 wx=2,
 wy=2,
 a=1,
 anim={76,76,76,76,76,
       78,78,78,78,78},
 maxlife=4,
 f=true,
 damage=0.5,
 speed=0
}

all_bosses={
 _boss(zelda),
 _boss(monstro),
 _boss(evil_isaac),
 _boss(it_lives),
}

-->8
--enemies

function _fly(x,y)
 local e = {
  life=0.1,
  s=s_fly,
  x=x,
  y=y,
  wx=1,
  wy=1,
  a=1,
  -- sprite sequence
  anim = {96,97},
  f=true,
  damage=0.5,
  speed=0.3
 }
 function e:draw()
   pal(12,8)
   draw(self)
   pal()
 end
 return e 
end


function _enemy(x,y)
 local e = {
  life=1,
  s=64,
  x=x,
  y=y,
  wx=2,
  wy=2,
  a=1,
  -- sprite sequence
  anim = p.anim,
  f=true,
  damage=0.5,
  speed=0.3
 }
 function e:draw()
   pal(12,8)
   draw(self)
   pal()
 end
 return e 
end

function drop_pickup(r, x,y)
 x=x or 64
 y=y or 70
 local pickup=rpick(all_pickups)
 local e={s=pickup,
          x=x,y=y,
          wx=1,wy=1}
 drop(e)
 add(r.elts,e)
end

function cleared(r)
 if r.type == r_boss then
  -- add trap
  mmset(7,6,s_trap,2,2)
  add(r.elts, rrpick(items))
 else
  drop_pickup(r)
 end
 set_doors(ri,rj)
end

function move_enemy(e)
 local r=level[rj][ri]
 -- motion
 local d=dist(p,e)
 local vx=(p.x-e.x)/d*e.speed
 local vy=(p.y-e.y)/d*e.speed
  
 -- check collision with others
 local ne={x=e.x+vx,y=e.y+vy}
 local move=true
 for e2 in all(r.emies) do
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
 for el in all(r.elts) do
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
   if not (p.holy_mantle and
           r.no_hit) and
      p.life > 0 and
      p.invincible==0 then
    sfx(1)
    p.life -= e.damage
    p.invincible=20
   end
   r.no_hit=false
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
 local r=level[rj][ri]
 r.closed=#r.emies!=0
 
 for e in all(r.emies) do
  -- death
  if e.life <= 0 then
   sfx(2)
   del(r.emies, e)
   if #r.emies==0 then
    cleared(r)
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

function _item(n,s,d,x,y)
 x = x or 64
 y = y or 72
 return {n=n, s=s, d=d,
         x=x, y=y,
         wx=2, wy=2}
end

--item
items={
 _item('mushroom',128,'all stats up!'),
 _item('holy mantle',130,'holy shield'),
 _item('proptosis',132,'mega tears'),
 _item('brimstone',134,'blood laser'),
 _item('godhead',136,'god tears'),
 _item('20/20',138,'double shot'),
 _item('the poop',140,'plop!'),
 _item('the mind',142,'i know all'),
 _item('the halo',160,'all stats up'),
 _item('red key',162,'the upside-down'),
 _item('the onion',164,'more tears'),
 _item('the spoon',166,'run!'),
 _item('dead cat',168,'9 lives'),
 _item('the whore',170,'curse up'),
 _item('chocobar',172,'health up'),
 _item('ipecac',174,'explosive shot')
}

function pickitem(e)
 if e.n=="mushroom" then
  p.maxlife +=1
  p.life  = p.maxlife
  p.tsize *= 1.5
  p.speed += 0.2
  p.tear_rate += 0.2
  return true
 end
 if e.n=="20/20" then
  p.double_shot=true
  return true
 end
 if e.n=="proptosis" then
  p.proptosis=true
  p.tsize *= 2
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
  p.tear_rate+=2
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
  return true
 end
 if e.n=="chocobar" then
  p.maxlife += 1
  p.life += 1
  return true
 end
 if e.n=="the halo" then
  p.maxlife += 1
  p.tsize += 1
  p.tear_rate += 0.5
  p.speed += 0.2
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
  p.tsize+=5
  return true
 end
 if e.n=="red key" then
  last={}
  for j=1,#level do
   for i=1,#level[j] do
    local r=level[j][i]
    if r.type!=0 then
     add(last, {i,j})
    end
   end
  end
  addroom(level,last,r_evil)
  addroom(level,last,r_evil)
  addroom(level,last,r_evil)
  set_doors(ri,rj)
  return true
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

function draw_tears()
 local c=p.tcolor
 for t in all(tears) do
  circfill(t.x,t.y,t.size,c)
  circ(t.x,t.y,t.size,5)
 end
 for p in all(particles) do
  circfill(p.x,p.y,p.r,p.c)
  circ(p.x,p.y,p.r,p.cc)
 end
end

function update_particles()
 for p in all(particles) do
  p.x += p.spd.x
  p.y += p.spd.y
  p.t -= 1
  if (p.t < 0) del(particles,p)
 end
end


function explode(x,y,r,c)
 c = c or p.tcolor
 r = r or 1
 local nbdir=4
 for dir=0,nbdir-1 do
  local angle=((0.5+dir)/nbdir)
  add(particles,{
   x=x,
   y=y,
   t=10,
   r=r,
   c=c,
   cc=5,
   spd={
    x=sin(angle),
    y=cos(angle)
   }
  })
 end
end

-- update shooting tears
function upd_tears()
 local r=level[rj][ri]
 for t in all(tears) do
  local killit=false
  t.x += t.vx
  t.y += t.vy
  if p.proptosis and
     t.size > 1 then
   t.size-=0.1
  end
  if solida(t.x,t.y+4,
   t.size/2,
   t.size/2) then
   killit=true
  end
  if t.x < 0 or t.x > 128
   or t.y < 24 or t.y > 120 then
   killit=true
  end
  local closest=nil
  local min_d=500
  local hitt=false
  for e in all(r.emies) do
   local d=dist(t,e)
   -- if e >0 ?
   if d<min_d then
    min_d=d
    closest=e
   end
   if hit(e,t) then
    sfx(1) 
    if room_timer > 30 then
     e.life-=t.size/5
    end
    e.x += t.vx*2
    e.y += t.vy*2
    killit=true
    hitt=true
    break
   end
  end
  if p.god and 
     hitt==false and
     closest then
   t.x+=(closest.x-t.x)/min_d   
   t.y+=(closest.y-t.y)/min_d
  end
  if killit then
   del(tears,t)
   explode(t.x,t.y)
   if p.ipecac then
   	bomb_it(t)
   end
  end
 end
end

function shoot_tears()
 if (p.cooldown<=0 and
     keys:held(4)) then
  local w=flr(p.tsize/8)
  --todo lx,ly not normalized
  if p.double_shot then
   local px,py=rot90(lx,ly)
   add(tears, {
    x=p.x-px*3, y=p.y-4-py*3,
    vx=lx*1.3, vy=ly*1.3,
    wx=w,wy=w,
    size=p.tsize})
   add(tears, {
    x=p.x+px*3, y=p.y-4+py*3,
    vx=lx*1.3, vy=ly*1.3,
    wx=w,wy=w,
    size=p.tsize})
  else
   add(tears, {
    x=p.x, y=p.y-4,
    vx=lx*1.3, vy=ly*1.3,
    wx=w,wy=w,
    size=p.tsize})
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
               wx=1,wy=2,
               cj=0,ci=8,
               s=228}
--right
doorbb[1][0]={x=15.5*8,y=9*8,
              wx=1,wy=2,
              cj=15,ci=8,
              s=228}
--top
doorbb[0][-1]={x=8*8,y=3.5*8,
               wx=2,wy=1,
               cj=7,ci=3,s=212}
--bottom
doorbb[0][1]={x=8*8,y=14.5*8,
              wx=2,wy=1,
              cj=7,ci=14,
              s=212}

function bomb_walls(b)
 local _,cands=nbgh(ri,rj,level)
 for c in all(cands) do
  local i,j=c[1],c[2]
  local r=level[j][i]
  if r.type==r_secret then
   local bbox=doorbb[i-ri][j-rj]
   if hit(b,bbox,bomb_zone) then
    sfx(1)
    mmset(flr(bbox.cj),
          flr(bbox.ci),
          bbox.s+3*bbox.wx,
          bbox.wx,
          bbox.wy,
          bbox.x>100,
          bbox.y>100)
   end
  end
 end
end

function bomb_rocks(b)
 local r=level[rj][ri]
 for ro in all(r.rocks) do
  if hit(b,ro,bomb_zone) then
  	if ro.special then
    drop_pickup(r,ro.x,ro.y)
  	end
  	del(r.rocks,ro)
  end
 end
end

function bomb_people(b)
 local r=level[rj][ri]
 -- bomb enemies
 for e in all(r.emies) do
  if hit(b,e,bomb_zone) then
   e.life -= 5
   end
 end
 -- bomb self
 if hit(b,p) then
  p.life-=1
  sfx(2)
 end
end

function bomb_it(b)
 local r=level[rj][ri]
 bomb_walls(b)
 bomb_people(b)
	bomb_rocks(b)	
	sfx(3)
end

function upd_bomb(r)
 drop_bomb()
 for b in all(r.elts) do
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
    explode(b.x,b.y,2,8)
    bomb_it(b)
    --todo fix issue 2 sfx
    del(r.elts,b)
   end
  end
 end
end

function drop_bomb()
 if (keys:held(5) and
     p.bombs > 0  and
     p.bcooldown<=0) then
  p.bombs -= 1
  local r=level[rj][ri]
  add(r.elts, _bomb(p.x,p.y+2))
  p.bcooldown=bomb_cooldown
 end
end

__gfx__
000000000080000066666666666666663333333333333333333e3333333333330000077777700000766666666666666776666666666666676777777777777776
00000000008077c06000ddddddddddd6333333333333333333ebe333333333330007777ee777700067777777777777706cccccccccccccc07677777777777760
00700700066677776550ddddddddddd63333333333333333333e3333333333330077777777ee770067777777777777706cccccccccccccc077dddddddddddd00
000000000060dddd6550ddddddddddd6333333333333333333333333333333330777e7ee7777777067777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550000dddddddd633333333333333333333333333e33333077777eee7ee777067777777777777706cccccccccccccc077dddddddddddd00
007007000c0c00006550550dddddddd63333333333333333333333333ebe3333077ee77777777e7067777777777777706cccccccccccccc077dddddddddddd00
00000000c0c000006550550dddddddd633333333333333333333333333e33333077ee7ee7ee7e77067777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550000ddddd63333333333383333333333333333333307e777777ee7e77067777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550550ddddd6333333333389833333333333333333330777ee7e7777777067777777777777706cccccccccccccc077dddddddddddd00
00550550005505506550550550ddddd63333333333b8333333333333333333330077ee7e7ee7e70067777777777777706cccccccccccccc077dddddddddddd00
05885885050058856550550550000dd63333333333b33333333333333333333300777e777ee7770067777777777777706cccccccccccccc077dddddddddddd00
05888785050087856550550550550dd633333333333b333333e3333333333333000777777777700067777777777777706cccccccccccccc077dddddddddddd00
05888850050088506550550550550dd633333333333333333ebe333333333e33000007494470000067777777777777706cccccccccccccc077dddddddddddd00
00588500005085006550550550550006333333333333333333e333333333ebe3000044494444000067777777777777706cccccccccccccc077dddddddddddd00
0005500000055000655055055055055633333333333333333333333333333e33000004444440000067777777777777706cccccccccccccc07600000000000060
00000000000000006666666666666666333333333333333333333333333333330000000000000000700000000000000570000000000000076000000000000006
00000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeee77777ee777eeeeeeeeeeeeeeeed77777777777777d
00550550000010000000000007707700000000000000000000000000000000000000000000000000eeeeee7777ee7777eeeeeeeeeeeeeeee7d777777777777d0
05cc5cc5000010000000000078878870000000000000000000000000000000000000000000000000eeeeeee7eee77777eee777eeee777eee77dddddddddddd00
05ccc7c500555500aaa0000078788870000000000000000000000000000000000000000000000000eeeeeeeee7777777ee77777ee77777ee77dddddddddddd00
05cccc5005557750a9aaaaaa788888700000000000000000000000000000000000000000000000007eeeeeeeee777777e77777777777777e77dd777dd777dd00
005cc50005555750aaa99a9a0788870000000000000000000000000000000000000000000000000077eeeeeeeeee7ee7e77777777777777e77d7777777777d00
00055000055555509990090900787000000000000000000000000000000000000000000000000000777eeeeeeeeeeeeee77777777777777e77d7777777777d00
00000000005555000000000000070000000000000000000000000000000000000000000000000000777eeeeeeeeeeddde67777777777776e77d7777777777d00
00000000000000000000000000000000000000000000000000000000000000000000000000000000e777eeeeeeedddddee677777777776ee77d6777777776d00
00008000000080000770770007707700000000000000000000000000000000000000000000000000eeeeeeeeeeddddddeee6777777776eee77dd67777776dd00
00001000000010007887777077777770000000000000000000000000000000000000000000000000ddddeeeeeddddddeeeee67777776eeee77ddd677776ddd00
00555500008888007878777077777770000000000000000000000000000000000000000000000000ddeeedddeeeeeeeeeeeee677776eeeee77dddd6776dddd00
05557750088877807888777077777770000000000000000000000000000000000000000000000000deeeeeddde77777eeeeeee6776eeeeee77ddddd66ddddd00
05555750088887800788770007777700000000000000000000000000000000000000000000000000ee7eeeeeeee7777eeeeeeee66eeeeeee77dddddddddddd00
05555550088888800078700000777000000000000000000000000000000000000000000000000000777eeeeeeee7777eeeeeeeeeeeeeeeee7d000000000000d0
005555000088880000070000000700000000000000000000000000000000000000000000000000007777eeeeeeee77eeeeeeeeeeeeeeeeeed00000000000000d
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555000000000555555000000000055555500000
07700770000000000000000000000000000000000000000000000000000000000000000000000000000555ff6555500000005777777500000000577777750000
775775777700007700000000000000000000000000000000000000000000000000000000000000000055fffff566550000057777777750000005777777775000
75577557757007570000000000000000000000000000000000000000000000000000000550000000005666fff666f55000577777777775000057777777777500
077887707778877700000000000000000000000000000000000000000000000000000555555500000556766ff676ff5500575777775775000057577777577500
0008800000088000000000000000000000000000000000000000000000000000000055fff555500055666665ff666ff500575577775575000057557777557500
00000000000000000000000000000000000000000000000000000000000000000005765ff57655005fffff555ff6666500578855558875000057885555887500
00000000000000000000000000000000000000000000000000000000000000000056665ff666f5505ff55f5855556ff500058755557850000005875555785000
0000000000000000000000000000000000000000000000000000000000000000055ff555f6ffff555f555558758555f505555777777500000000577777755550
00000000000000000000000000000000000000000000000000000000000000005566f585ff666ff55f588788888855f505755555555555500555555555555750
00000000000000000000000000000000000000000000000000000000000000005ff55585555556650565558787555f5505557888878757500575788887875550
00000000000000000000000000000000000000000000000000000000000000005f557885887855f505ff5555555ff55000057787777755500555778777775000
00000000000000000000000000000000000000000000000000000000000000005ff55788788855f50055ffffffff550000d5777777775d0000d5777777775d00
0000000000000000000000000000000000000000000000000000000000000000556f555555555ff500055555555550000ddd57755775ddd000dd57755775dd00
0000000000000000000000000000000000000000000000000000000000000000055ffffffffff5550000000000000000000d555dd775d000000d577dd555d000
0000000000000000000000000000000000000000000000000000000000000000005555555555550000000000000000000000ddddd55500000000555ddddd0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000005550000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000500000000
0000005555000000000005d7d5000000000000000000800000000088880000000000000000000000000000000000000000050500000000000000005750000000
0000058777500000000055cdc5500000000005555500000000000885588000000055555555555500000000000000000000005000505000000000057a75000000
0000588788850000000555cdc55500000080557775500000000008555580000005aaaa5775cccc5000000550055000000000000005000000000057aaa7500000
0000588788750000005dcccdcccd500000805776575000000008888558888000005aa575575cc50000005000005500000000005000000000000057aaa7500000
0005787777775000005cddddddd7500000005775575500000088555555558800005a57575575c500000500000000500000000545500000000000577a77500000
0005777887785000005dcccdcccd5000000557777755550000088885588880000005775555775000000555555555500000000554450000000000056565000000
0005878887885000000555cdc5550000005558777855855000085555555580000000577557750000005567500567550000005445545000000005557a75550000
0005587887855000000055cdc5500000005855888558850000855855558558000000555555550000005677755677750000054555444500000057aa575aa75000
0000555555550000000005cdc5000000005555555545500000858885588858000000058888500000005777755777750000055444445500000057aa757aa75000
000005d6fd500000000005cdc500000000005888855580000085585555855800000000588500000000057750057750000000555555500000057aa75057aa7500
0000005555000000000005dcd500000000005555555000000008555885558000000000055000000000005500005500000000000000000000057a7500057a7500
00000000000000000000005550000000000000000000000000008880088800000000000000000000000000000000000000000000000000000555500000555500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000055bb550000000000000055500000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005bbbb50555500000000544450000000000000000000000000555550000000000000555555500000000000000000000
000555555555500000555500000000000055bbb555bb500000005449445000000000005555000500005858585555500000000544444500000000555555500000
00555aaaaaa5550005588550000000000005bbbb5bb5500000005499945000000000055665500550005588855588550000000545454500000005777777650000
055aaa9999aaa550058888555555500000055bbb5bb5000000005499945000000000566666550550005885885588850000000544444500000005777777650000
059aa555555aa9500585588585555550000557bb5755000000005449445000000005566666655550000555555588855000005545114550000000555555500000
0559aaaaaaaa95500558558888888850005577777775500000000544450000000005666667665500000000005588885000005111c11150000005222222250000
005559999995550005855885858885500057557775575000000000545000000005555666557665000000000558888850000055ccccc150000005226666650000
0005555555555000058888555585850000575577755750000000005450000000056555665d5565000005555588888850000005c666c550000005226777750000
000000000000000005588550055555000057cc777cc7500000000054500000000056655655d566500005888888888850000005ccccc500000005226eeee50000
0000000000000000005555000000000000557c757c755000000000545000000005566656655577500005588888888550000005c666c500000005226666650000
000000000000000000000000000000000005557775500000000000545000000056566755750055000000558888885500000005ccccc500000005222222250000
00000000000000000000000000000000000005555500000000000054500000000555550050000000000005555555500000000555555500000000555555500000
00000000000000000000000000000000000000000000000000000055500000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c05000c0005000000050000000533bbbbb3bbb3bbbbbbbbbb3017777777c777777cc77c7cc75cccccccccccccccccccccc55555555566655666555d5555
c06c60c508000805000c06050ccccc05bbbb8b33bbbbbb8bb8bb3b3071cccccc7cccccc07cc07cc7c5ccccccccccccccccccccc55566665555555555566d6555
00c0c0050c060c0506c8c605086668053bbbbbbbbbbbb8bbb3bb3b307c1cc1117cccccc07cc07cc7cc5cccccccccccccccccccc5566666655566665166ddddd5
c06c60c508000805060c00050ccccc05bbb4bbbbb4bbbbbbbbb8b3307cc17777c000000c7cc0c007ccc5ccccccccccccccccccc55666666556d66d65666d6655
0c0c0c05000c00050000000500000005bb4bbbbbbbbbbbbbb4bbb3507cc11ccc777cc7777cc0c777cccc5cccccccccccccccccc556666665dddddddd666d6655
55555555555555555555555555555555bbbbb8bbb333bbb33b4bb3507cc171ccccc07ccc7cc07cc7ccccc5ccccccccccccccccc55666666516d66d6566ddddd5
00c0c80500000005000000050c000c053bbbbb3333533333bbbbb3307cc17c1c000cc0007cc07cc7cccccc5cccccccccccccccc55555555516d66d65555d5555
000600050068600506666605c60006c5bbbbbb3000000000bbb8bb30c11c7cc577777777c00c7cc7ccccccc555555555ccccccc55555555555d55d55115d5155
0066600500c0c005066c6605008680050005555bb55550000005555995555000000555588555500050511111111111500000000017777777c777777cc77c7cc7
000600050068600506666605c60006c500551111111155000055dddd5ddd55000055dddddddd550005011111111115000000000071cccccc7cccccc07cc07cc7
08c0c00500000005000000050c000c050051111111111500005dddd5ddddd500005dddd55dddd5000550111111111550000000007c1cc1117cccccc07cc07cc7
555555555555555555555555555555550051111111111500005dddd5ddddd500005ddd5555ddd5000005111111111500000000007cc17777c000000c7cc0c007
0c0c0c05cc606cc5000000058ccccc850051111111111500005dddd5ddddd500005dddd55dddd50005555dd111dd1550000000007cc11ccc777cc7777cc0c777
c0ccc8c566606665000800050c000c050051111111116500005ddddd5dddd500005dddd55dddd50000555555d555d500000000007cc171ccccc07ccc7cc07cc7
0cc8cc0500000005000000050c0c0c050051161116666500005ddddd5dddd500005dddddddddd5000005dd5d5d5d5000000000007cc17c1c000cc0007cc07cc7
c8ccc0c566606665008080050c000c0555566666666665555555555555555555555555555555555555555dd55515505500000000c11c7cc577777777c00c7cc7
0c0c0c05cc606cc5000000058ccccc850000000500000005000000055000000500000000000000000000000000000000000000000bbbbbbbbbbbbbbbb3449443
55555555555555555555555555555555000000050000000500000005555000050000000000000000000000000000000000000000bb33b33b3b33b33bb3499493
00000005000000050000000500000005055555550555555505555555115555050000000000000000000000000000000000000000b344444444444444bb494493
0ccccc050000000500000005000000055511111655ddddd555ddddd51111d5550000000000000000000000000000000000000000b349994449999994b3494993
0c020c05000000050000000500000005511111665dddddd55dddddd51111dd550000000000000000000000000000000000000000bb49449999444499b3494993
0ccccc05000000050000000500000005511116665dddddd55dddddd511111d550000000000000000000000000000000000000000b349494444999944bb494433
00000005000000050000000500000005511116665dddddd55dd5ddd511115d550000000000000000000000000000000000000000b344949943944994b3499493
55555555555555555555555555555555b1111666955dd5558d5555d5111dd5dd0000000000000000000000000000000000000000bb44949393333399b3449443
00000005000000050000000500000005b11116669dd55dd58d5555d5111dd5d50000000000000000000000000000000000000000000000000000000000000000
00000005000000050000000500000005511111665dddddd55dd5ddd51111dd550000000000000000000000000000000000000000000000000000000000000000
00000005000000050000000500000005511111665dddddd55dddddd5111115550000000000000000000000000000000000000000000000000000000000000000
00000005000000050000000500000005511111165dddddd55dddddd51115dd550000000000000000000000000000000000000000000000000000000000000000
000000050000000500000005000000055511111655ddddd555ddddd51155d5050000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555055555550555555505555555555000050000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000050000000500000005000000050000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000050000000500000005000000050000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077077000770770007707700000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000
00000000788788707887887078878870000000000000000000000000000001000000077700000000000000000007770000000000000000000000000000000000
000000007878887078788870787888700000000000000000000000000005555000700707000000aaa00000007007070000000000000000000000000000000000
000000007888887078888870788888700000000000000000000000000055577500000707000000a9aaaaaa000007070000000000000000000000000000000000
000000000788870007888700078887000000000000000000000000000055557500700707000000aaa99a9a007007070000000000000000000000000000000000
00000000007870000078700000787000000000000000000000000000005555550000077700000099900909000007770000000000000000000000000000000000
00000000000700000007000000070000000000000000000000000000000555500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555555000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005ccc57775aaa5000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005ccc57775aaa5000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555555000000000000
700000000000000000000000000000000cc0000000000008000008880000000000000000000000000000000000000000000000000005ccc50000000000000000
070000000000000000000000077c00c000c0000000000008008000080000000000000000000000000000000000000000000000000005ccc50000000000000000
0070000000000000000000000777700000c000000000006660000088000000000000000000000000000000000000000000000000000555550000000000000000
0700000000000000000000000dddd0c000c000000000000600800008000000000000000000000000000000000000000000000000000000000000000000000000
700000000000000000000000000000000ccc00000000000000000888000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33bbbbb3bbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb3bbbbb33
bbbb8b33bbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8b33b8bbbb
3bbbbbbbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbbbb3
bbb4bbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbbbbb4bbb
bb4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4bb
bbbbb8bbb333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3bb8bbbbb
3bbbbb33335333333353333333533333335333333353333333533333335333333353333333533333335333333353333333533333335333333353333333bbbbb3
bbbbbb34444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444443bbbbbb
bbbbbb343333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333333333343bbbbbb
b8bb3b34333333333333333333ebe33333333333333333333333333333ebe33333333333333333333333333333ebe33333333333333333333333333343b3bb8b
b3bb3b343333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333333333343b3bb3b
bbb8b3343333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333433b8bbb
b4bbb35433333333333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333453bbb4b
3b4bb3543333333333333333333333333ebe33333333333333333333333333333ebe33333333333333333333333333333ebe33333333333333333333453bb4b3
bbbbb33433333333333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333433bbbbb
bbb8bb34333333333338333333333333333333333333333333383333333333333333333333333333333833333333333333333333333333333338333343bb8bbb
bbbbbb34333333333389833333333333333333333333333333898333333333333333333333333333338983333333333333333333333333333389833343bbbbbb
b8bb3b343333333333b8333333333333333333333333333333b8333333333333333333333333333333b8333333333333333333333333333333b8333343b3bb8b
b3bb3b343333333333b3333333333333333333333333333333b3333333333333333333333333333333b3333333333333333333333333333333b3333343b3bb3b
bbb8b33433333333333b333333e333333333333333333333333b333333e333333333333333333333333b333333e333333333333333333333333b3333433b8bbb
b4bbb35433333333333333333ebe333333333e3333333333333333333ebe333333333e3333333333333333333ebe333333333e333333333333333333453bbb4b
3b4bb354333333333333333333e333333333ebe3333333333333333333e333333333ebe3333333333333333333e333333333ebe33333333333333333453bb4b3
bbbbb33433333333333333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333433bbbbb
bbb8bb34333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333343bb8bbb
bbbbbb34333e33333333333333333333333333333333377777733333333e33333333333333333777777333333333333333333333333e33333333333343bbbbbb
b8bb3b3433ebe3333333333333333333333333333337777ee777733333ebe333333333333337777ee7777333333333333333333333ebe3333333333343b3bb8b
b3bb3b34333e33333333333333333333333333333377777777ee7733333e3333333333333377777777ee77333333333333333333333e33333333333343b3bb3b
bbb8b334333333333333333333333333333333333777e7ee7777777333333333333333333777e7ee7777777333333333333333333333333333333333433b8bbb
b4bbb3543333333333e333333333333333333333377777eee7ee77733333333333e33333377777eee7ee777333333333333333333333333333e33333453bbb4b
3b4bb354333333333ebe33333333333333333333377ee77777777e73333333333ebe3333377ee77777777e733333333333333333333333333ebe3333453bb4b3
bbbbb3343333333333e333333333333333333333377ee7ee7ee7e7733333333333e33333377ee7ee7ee7e77333333333333333333333333333e33333433bbbbb
bbb8bb343333333333333333333333333338333337e777777ee7e773333333333333333337e777777ee7e7733333333333383333333333333333333343bb8bbb
bbbbbb34333333333333333333333333338983333777ee7e7777777333333333333333333777ee7e777777733333333333898333333333333333333343bbbbbb
b8bb3b3433333333333333333333333333b833333377ee7e7ee7e73333333333333333333377ee7e7ee7e7333333333333b83333333333333333333343b3bb8b
b3bb3b3433333333333333333333333333b3333333777e777ee77733333333333333333333777e777ee777333333333333b33333333333333333333343b3bb3b
bbb8b33433e333333333333333333333333b3333333777777777733333e3333333333333333777777777733333333333333b333333e3333333333333433b8bbb
b4bbb3543ebe333333333e33333333333333333333333749447333333ebe333333333e33333337494473333333333333333333333ebe333333333e33453bbb4b
3b4bb35433e333333333ebe33333333333333333333344494444333333e333333333ebe33333444944443333333333333333333333e333333333ebe3453bb4b3
bbbbb3343333333333333e33333333333333333333333444444333333333333333333e33333334444443333333333333333333333333333333333e33433bbbbb
bbb8bb34333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333343bb8bbb
bbbbbb3533333333333333333333333333333333333e3333333333333333333333555555333e3333333333333333333333333333333333333333333353bbbbbb
b8bb3b353333333333333333333333333333333333ebe333333333333333333335ffffff53ebe333333333333333333333333333333333333333333353b3bb8b
b555555533333333333333333333333333333333333e333333333333333333335ffffffff53e333333333333333333333333333333333333333333335555555b
5511111633333333333333333333333333333333333333333333333333333335ffffffffff533333333333333333333333333333333333333333333361111155
51111166333333333333333333333333333333333333333333e3333333333335f57ffff57f53333333e333333333333333333333333333333333333366111115
5111166633333333333333333333333333333333333333333ebe333333333335f55ffff55f5333333ebe33333333333333333333333333333333333366611115
51111666333333333333333333333333333333333333333333e3333333333335fcc5555ccf53333333e333333333333333333333333333333333333366611115
b1111666333333333338333333333333333833333333333333333333333333335cf5555fc533333333333333333333333338333333333333333833336661111b
b11116663333333333898333333333333389833333333333333333333333333335ffffff5333333333333333333333333389833333333333338983336661111b
511111663333333333b833333333333333b833333333333333333333333333335f555555f5333333333333333333333333b833333333333333b8333366111115
511111663333333333b333333333333333b33333333333333333333333333333555ffff555333333333333333333333333b333333333333333b3333366111115
5111111633333333333b333333333333333b333333e333333333333333333333335ffff533e333333333333333333333333b333333333333333b333361111115
55111116333333333333333333333333333333333ebe333333333e3333333333335f55f53ebe333333333e333333333333333333333333333333333361111155
355555553333333333333333333333333333333333e333333333ebe3333333333355335533e333333333ebe33333333333333333333333333333333355555553
bbbbb335333333333333333333333333333333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333333533bbbbb
bbb8bb35333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333353bb8bbb
bbbbbb34333e33333333333333333333333333333333377777733333333e33333333333333333777777333333333333333333333333e33333333333343bbbbbb
b8bb3b3433ebe3333333333333333333333333333337777ee777733333ebe333333333333337777ee7777333333333333333333333ebe3333333333343b3bb8b
b3bb3b34333e33333333333333333333333333333377777777ee7733333e3333333333333377777777ee77333333333333333333333e33333333333343b3bb3b
bbb8b334333333333333333333333333333333333777e7ee7777777333333333333333333777e7ee7777777333333333333333333333333333333333433b8bbb
b4bbb3543333333333e333333333333333333333377777eee7ee77733333333333e33333377777eee7ee777333333333333333333333333333e33333453bbb4b
3b4bb354333333333ebe33333333333333333333377ee77777777e73333333333ebe3333377ee77777777e733333333333333333333333333ebe3333453bb4b3
bbbbb3343333333333e333333333333333333333377ee7ee7ee7e7733333333333e33333377ee7ee7ee7e77333333333333333333333333333e33333433bbbbb
bbb8bb343333333333333333333333333338333337e777777ee7e773333333333333333337e777777ee7e7733333333333383333333333333333333343bb8bbb
bbbbbb34333333333333333333333333338983333777ee7e7777777333333333333333333777ee7e777777733333333333898333333333333333333343bbbbbb
b8bb3b3433333333333333333333333333b833333377ee7e7ee7e73333333333333333333377ee7e7ee7e7333333333333b83333333333333333333343b3bb8b
b3bb3b3433333333333333333333333333b3333333777e777ee77733333333333333333333777e777ee777333333333333b33333333333333333333343b3bb3b
bbb8b33433e333333333333333333333333b3333333777777777733333e3333333333333333777777777733333333333333b333333e3333333333333433b8bbb
b4bbb3543ebe333333333e33333333333333333333333749447333333ebe333333333e33333337494473333333333333333333333ebe333333333e33453bbb4b
3b4bb35433e333333333ebe33333333333333333333344494444333333e333333333ebe33333444944443333333333333333333333e333333333ebe3453bb4b3
bbbbb3343333333333333e33333333333333333333333444444333333333333333333e33333334444443333333333333333333333333333333333e33433bbbbb
bbb8bb34333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333343bb8bbb
bbbbbb343333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333333333343bbbbbb
b8bb3b34333333333333333333ebe33333333333333333333333333333ebe33333333333333333333333333333ebe33333333333333333333333333343b3bb8b
b3bb3b343333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333333333343b3bb3b
bbb8b3343333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333433b8bbb
b4bbb35433333333333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333453bbb4b
3b4bb3543333333333333333333333333ebe33333333333333333333333333333ebe33333333333333333333333333333ebe33333333333333333333453bb4b3
bbbbb33433333333333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333333433bbbbb
bbb8bb34333333333338333333333333333333333333333333383333333333333333333333333333333833333333333333333333333333333338333343bb8bbb
bbbbbb34333333333389833333333333333333333333333333898333333333333333333333333333338983333333333333333333333333333389833343bbbbbb
b8bb3b343333333333b8333333333333333333333333333333b8333333333333333333333333333333b8333333333333333333333333333333b8333343b3bb8b
b3bb3b343333333333b3333333333333333333333333333333b3333333333333333333333333333333b3333333333333333333333333333333b3333343b3bb3b
bbb8b33433333333333b333333e333333333333333333333333b333333e333333333333333333333333b333333e333333333333333333333333b3333433b8bbb
b4bbb35433333333333333333ebe333333333e3333333333333333333ebe333333333e3333333333333333333ebe333333333e333333333333333333453bbb4b
3b4bb354333333333333333333e333333333ebe3333333333333333333e333333333ebe3333333333333333333e333333333ebe33333333333333333453bb4b3
bbbbb33433333333333333333333333333333e3333333333333333333333333333333e3333333333333333333333333333333e333333333333333333433bbbbb
bbb8bb34333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333343bb8bbb
bbbbbb34444444444444444444444444444444444444444444444444555666666666655544444444444444444444444444444444444444444444444443bbbbbb
3bbbbb33335333333353333333533333335333333353333333533333335116111666653333533333335333333353333333533333335333333353333333bbbbb3
bbbbb8bbb333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b3511111111165b3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3b333bbb3bb8bbbbb
bb4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb511111111115bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4bb
bbb4bbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4511111111115bbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbbbbb4bbb
3bbbbbbbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbb511111111115bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbbbb3
bbbb8b33bbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbb5511111111558bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8bbbbbbb8b33b8bbbb
33bbbbb3bbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb5555bb5555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbb3bbbbb33
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001000000000000010100000000010100000000000000000101000000000101000000000101010101010101010101010000000001010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101000000000000000001010000010101010000000000000100010101010101010100000000000001000100000000000000
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
__sfx__
000100000f05013050150501a0501f05022050250502c050320503405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001814014150101500d1500b1300a1300911000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b15021150231501e150161501f150251501f150181501e15026150211501b1301a130191301813018110181100000000000000000000000000000000000000000000000000000000000000000000000
000200000d340096400f650147300f34010350123501335016360173601735016640166400b6300b6200b62005320053100b31002510066000160004600036000360002600006000060000600006000060000600
