pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- game: isaac
-- author: ugo jardonnet
-- 
--todo:
-- tile theme
-- crystal cave ?
-- room doors based on types
-- bombs
-- bomb secret room
-- blue rocks
-- blue heart
-- keys
-- item room locked
-- explode when tear hit
-- boss patterns
-- final boss
-- hold shoot always same dir
-- stats hud
-- resurect in previous room
--bugs:
-- fix half heart
-- fix first level_gen hang
-- fix boos missing sometimes
-- diagonal move should be 1
-- tear speed depends on speed
-- fix palette of emies at night
-- fix horizontal shot against rock

p = {
 life    = 1.5,
 maxlife = 3,
 bomb    = 1,
 maxbomb = 3,
 speed   = 1,
 lives=0,
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
 -- items state
 double_shot=false,
 proptosis=false,
 holy_mantle=false,
 mind=true,
 whore=false,
 god=false,
 mine={},
 -- curse
 curse_night=false,
}

function p:draw()
	draw(self)
end
 
-- move player
function p.move()
 p.s = 64
 if (p.vx!=0 or p.vy!=0) then
 	p.s,p.a = rot(p.anim, p.a)
 end
 p.f = p.vx>0
 local nx = p.x+p.vx
 local ny = p.y+p.vy
 if not solida(nx-4,p.y,
               7,6) then
 	p.x=nx
 end
 if not solida(p.x-4,ny,
               7,6) then
 	p.y=ny
 end
 -- update last player dir
 if p.vx!=0 or p.vy!=0 then
  --todo normalize
	 lx,ly=p.vx,p.vy
	end
	
	if touch(p.x-4,p.y,8,8,s_trap) then
		level_i += 1
		reset(levels[level_i].size)
	end
end

-- check if map cell with
-- flag 0 below area
function solida(x,y,w,h)
	for i=flr(x/8),flr((x+w)/8) do
	for j=flr(y/8),flr((y+h)/8) do
		if i>=0 and i<16 and
					j>=0 and j<16 and
					mmget(i,j).bf then
			return true
		end
	end
	end
	return false
end

function touch(x,y,w,h,s)
	for i=flr(x/8),flr((x+w)/8) do
	for j=flr(y/8),flr((y+h)/8) do
		if i>=0 and i<16 and
					j>=0 and j<16 and
					mmget(i,j).s==s then
			return true
		end
	end
	end
	return false	
end

-- draw the minimap
function draw_minimap()
	for i=1,5 do
	for j=1,5 do
		local r=level[j][i]
		if r.type!=0 and
		   (r.seen or p.mind) then
			local c=7
			if i!=ri or j!=rj then
			 local t=r.type
			 if not r.visited and t==1
			 then
			 	t = -1
			 end
			 c=roomcolor(t)
			end
			rect(95+i*4,3+j*3,
			    	95+i*4+4,3+j*3+3,
			     5)
			rectfill(95+i*4+1,3+j*3+1,
			         95+i*4+3,3+j*3+2,
			         c)
		end -- end of !=0 and seen
	end
	end
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
function hit(a,b)
	local ax=a.x-a.wx*4
	local bx=b.x-b.wx*4
	local x_left=max(ax,bx)
	local ax2=a.x+a.wx*4
	local bx2=b.x+b.wx*4
	local x_right=min(ax2,bx2)
	if x_right < x_left then
		return false
	end
	local ay=a.y-a.wy*4
	local by=b.y-b.wy*4
	local y_top=max(ay,by)
	local ay2=a.y+a.wy*4
	local by2=b.y+b.wy*4
	local y_bottom=min(ay2,by2)
	if y_bottom < y_top then
	 return false
	end

	local inter={
		x1=x_left,
		x2=x_right,
		y1=y_top,
		y2=y_bottom
	}
	return pixel_collide(a,b,inter)
end

function draw_hud()
 --drawlife
 local fullhp=flr(p.life)
 local y=4
 for i=1,p.maxlife do
  if i<=fullhp then
  	spr(37,i*8,y,1,1)
  elseif i==fullhp+1 and
  	  p.life-fullhp!=0 then
  	 spr(38,i*8,y,1,1)
		else
			spr(39,i*8,y,1,1)
  end
 end
 if p.lives > 0 then
 	print("x"..p.lives,0,6,8)
 end
 for i=1,p.maxbomb do
  if i<=p.bomb then
  	spr(52, 40+i*8, y)
  end
 end
 print('dmg:'..p.tsize..
 						' spd:'..p.speed..
 					 ' tr:'..p.tear_rate,
 					 8,16,7)
end

function drop_bomb()
 if (keys:held(5) and
     p.bcooldown<=0) then
	 local r=level[rj][ri]
	 add(r.elts, bomb(p.x,p.y))
	 p.bcooldown=bomb_cooldown
	end
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
	ri,rj=3,3
	gen_room(ri,rj)
end

-- global init
function _init()
 messages={}
 level_i=1
 reset(levels[level_i].size)
end

function sort_y(t)
 function _y(e)
  return e.y
 end
 qsort(t,1,#t,_y)
end

-- fixme draw everything like this
function draw_actors()
	local r=level[rj][ri]
	local as = {p}
	for e in all(r.emies) do
		add(as,e)
	end
	sort_y(as)
	if p.holy_mantle and
	   r.no_hit then
		circ(p.x-1,p.y+4, 4, 12)
  circ(p.x-1,p.y+4, 6, 13)
	end
	for a in all(as) do
		a:draw()
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
	 		local nl=#message
	 		rect(x-1,y-1,128-x+1,y+8*nl+1,7)
	 		rectfill(x,y,128-x,y+8*nl,0)
	 	for i=0,nl-1 do
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
  print(screen_msg, 48, 60, 7)
  return
	end
	if p.life<=0 then
		if p.lives <= 0 then
			print("game over", 48, 0, 7)
			--return
		else
			p.lives -= 1
			p.life =1
			p.maxlife=1
		end
	end

	local r=level[rj][ri]

	--if --p.curse_night or
	if r.type == r_secret then
		nightpal()
	end
	if	r.type == r_evil	then
		evilpal()
	end
	
 draw_dwalls(levels[level_i].theme)
 mmap()

	-- draw elements for the room
	for e in all(r.elts) do
		draw(e)
	end
	draw_actors()
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
		p.x,p.y = 118,68
	end
	if p.x>124 then
		gen_room(ri+1,rj)
		p.x,p.y = 12,68
	end
end

function upd_elts()
 local r=level[rj][ri]
	for e in all(r.elts) do		
		if hit(p,e) then
		 if e.s == s_heart then
		  p.life += 1
	  end
	  if e.s == s_bomb then
	  	p.bomb += 1
  	end
		 pickitem(e)
			if e.d then
				add(messages, {{e.n,e.d},120})
			end
			-- only add object with names
			if e.n then
				add(p.mine, e.s)
			end
			del(r.elts,e)
			sfx(0)
		end
	end
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

	if p.life <= 0 then
		--return
	end

 -- move
 p.vx,p.vy = 0,0
	if (keys:held(1)) p.vx+=p.speed
	if (keys:held(2))	p.vy-=p.speed
	if (keys:held(3)) p.vy+=p.speed
	if (keys:held(0)) p.vx-=p.speed

	shoot_tears()
	drop_bomb()
	
	upd_room()
	upd_elts()
	upd_emies()
	upd_tears()
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

function nightpal()
	for c=1,16 do
		pal(c-1,nighttc[c])
	end
end

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

-- draw element
function draw(e)
	spr(e.s,
	 e.x-(e.wx*8)/2,
	 e.y-(e.wy*8)/2,
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
	fx_ = fx_ or false
	fy_ = fy_ or false
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
     j!=gridw+1	then
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
		emies={},
		elts={},
		cx=0,
		cy=0
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
	l[c[2]][c[1]].cx=flr(rnd(4))
	l[c[2]][c[1]].cy=flr(rnd(3))
	add(last,c)
end

--simple level generation
function genlevel(nbr)
	local l=_mat(gridw,gridh,_room)
	
	-- start with central room
	local cj=ceil(gridw/2)
	local ci=ceil(gridh/2)
	l[cj][ci].type=1
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
	addsecret(last,l)
	
	return l
end


function floorspr(v)
	if v==0 or v==53 then
	 return s_floor
	end
	return v
end

function set_floor(r)
 local cx=7*r.cx
	local cy=5*r.cy
 for i=1,5 do
 	for j=1,7 do
   local v=mget(cx+j-1,cy+i-1)
   local ss=floorspr(v)
 	 local jj=j*2-1
 	 local ii=(i+1)*2
   mmset(jj, ii, ss, 2, 2)
   if v==53 and r.closed then
				add(r.emies,
				    _enemy(jj*8+8,ii*8+8))   	
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
	 	if r.type!=s_secret then
	 		r.seen=true
	 	end
		end
	end
end

function set_doors(i,j)
	local r=level[j][i]
	--emies is set in clearroom
	r.closed=#r.emies!=0
	local shift=0
	if r.closed then
		shift=1
	elseif r.type==r_secret then
		shift=3
	end
	if j-1>0 then
		local top=level[j-1][i]
	 if top.type!=r_empty then
	 	if top.type==r_secret then
	 	 mmset(7,3,212+6,2,1)
			else
			 mmset(7,3,212+shift*2,2,1)
	  end
	 end
	end
	if j<gridw then
	 local bottom=level[j+1][i]
	 if bottom.type!=r_empty then
 	 if bottom.type==r_secret then
	 		mmset(7,14,212+6,2,1,false,true)
	  else
			 mmset(7,14,212+shift*2,2,1,false,true)
		 end
		end
	end
	if i-1>0 then
		local left=level[j][i-1]
	 if left.type!=r_empty then
	  if left.type==r_secret then
	   mmset(0,8,228+3,1,2)
	  else
		  mmset(0,8,228+shift,1,2)
		 end
		end
	end
	if i<gridh then
		local right=level[j][i+1]
	 if right.type!=0 then
		 if right.type==4 then
	 	 mmset(15,8,228+3,1,2,true)
		 else
		  mmset(15,8,228+shift,1,2,true)
	  end
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
	ri,rj=i,j
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

bomb_cooldown=20

r_empty=0
r_classic=1
r_boss=2
r_item=3
r_secret=4
r_evil=5

--sprites
s_heart=4
s_hheart=5
s_bomb=52
s_key=36
s_trap=2
s_tile=6
s_floor=32
s_block=34

l_garden=196
l_crypt=199
l_game=202
l_cemetery=205

function _level(n,s,t)
 return {
  name=n, size=s,theme=t
 }
end

levels={
	_level("isaac.p8",6,l_garden),
	_level("the crypt",8,l_crypt),
	_level("the game",10,l_game),
 _level("the cemetery",6,l_cemetery),
}

screen_time=120
screen_msg="isaac.p8"

function heart(x, y)
	return {s=4, x=x, y=y,
	 wx=1, wy=1}
end

function bomb(x, y)
	return {s=52, x=x, y=y,
	 wx=1, wy=1}
end


all_pickups={
	s_heart,
	s_hheart,
	s_bomb,
	s_key
}

function _boss(b)
	function b:draw()
		draw(self)
	end
	b.life=b.maxlife
	b.x=64
	b.y=64
	return b
end

zelda = {
 wx=2,
 wy=2,
 a=1,
 anim={72,72,72,72,72,
 						74,74,74,74,74},
 maxlife=4,
 f=true,
 damage=2,
 speed=0.6
}
monstro = {
 wx=2,
 wy=2,
 a=1,
 anim={104,104,104,
 						106,106,106,106,106,
 						106,106},
 maxlife=4,
 f=true,
 damage=2,
 speed=0.6
}
evil_isaac = {
 wx=2,
 wy=2,
 a=1,
 anim={108,108,108,108,108,
 						110,110,110,110,110},
 maxlife=4,
 f=true,
 damage=2,
	speed=0.6
}
it_lives = {
 wx=2,
 wy=2,
 a=1,
 anim={76,76,76,76,76,
 						78,78,78,78,78},
 maxlife=4,
 f=true,
 damage=2,
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

function _enemy(x,y)
	local e = {
		life=1,
		maxlife=1,
	 s=96,
		x=x,
		y=y,
		wx=2,
		wy=2,
		a=1,
 	-- sprite sequence
  anim = p.anim,
  f=true,
  damage=0.5,
  speed=0.5
	}
	function e:draw()
  	pal(12,8)
  	draw(self)
  	pal()
 end
 return e 
end

function cleared(r)
 if r.type == r_boss then
 	-- add trap
 	mmset(7,6,s_trap,2,2)
  add(r.elts, rrpick(items))
 else
  local pickup=rpick(all_pickups)
 	add(r.elts,{s=pickup,
		            x=64,y=70,
		            wx=1,wy=1})
 end
 set_doors(ri,rj)
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
		
		local d=dist(p,e)
	 local vx=(p.x-e.x)/d*e.speed
		local vy=(p.y-e.y)/d*e.speed
		
		-- check collision with others
	 ne={x=e.x+vx,y=e.y+vy}
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
  --if vx!=0 or vy!=0 then
	 e.s,e.a = rot(e.anim, e.a)
	 --end
	 e.f=vx>0
	end
end

-->8
-- items

function _item(n,s,d,x,y)
	x = x or 64
	y = y or 72
	return {n=n, s=s, d=d, x=x, y=y,
		       wx=2, wy=2}
end

--item
items={
	--_item('mushroom',128,'all stats up!'),
	--_item('holy mantle',130,'holy shield'),
	--_item('proptosis',132,'mega tears'),
	_item('brimstone',134,'blood laser'),
	_item('godhead',136,'god tears'),
	--_item('20/20',138,'double shot'),
	--_item('the poop',140,'plop!'),
	--_item('the mind',142,'i know all'),
	--_item('the halo',160,'all stats up'),
	--_item('red key',162,'the upside-down'),
	--_item('the onion',164,'more tears'),
	--_item('the spoon',166,'run!'),
	_item('dead cat',168,'9 lives'),
	_item('the whore',170,'curse up'),
	--_item('chocobar',172,'health up'),
	_item('ipecac',174,'explosive shot')
}

function pickitem(e)
	if e.n=="mushroom" then
		p.maxlife +=1
		p.life  = p.maxlife
		p.tsize *= 1.5
		p.speed += 0.2
		p.tear_rate += 0.2
	end
	if e.n=="20/20" then
		p.double_shot=true
	end
	if e.n=="proptosis" then
		p.proptosis=true
		p.tsize *= 2
	end
	if e.n=="holy mantle" then
		p.holy_mantle=true
	end
	if e.n=="the mind" then
		p.mind=true
		p.curse_night=true
	end
	if e.n=="the onion" then
		p.tear_rate+=2
	end
	if e.n=="the spoon" then
		p.speed+=0.3
	end
	if e.n=="dead cat" then
		p.lives=9
		p.maxlife=1
		p.life=1
	end
	if e.n=="chocobar" then
		p.maxlife += 1
		p.life += 1
	end
	if e.n=="the halo" then
		p.maxlife += 1
		p.tsize += 1
		p.tear_rate += 0.5
		p.speed += 0.2
	end
	if e.n=="the whore" then
		p.whore=true
	end
	if e.n=="godhead" then
		p.god=true
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
	end
end
-->8
--tears


function draw_tears()
	local c=7
	if (p.whore and p.life<=1) c=8
	if (p.god) c=12
	for t in all(tears) do
	 circfill(t.x,t.y,t.size,c)
	 circ(t.x,t.y,t.size,5)
	end
end

-- update shooting tears
function upd_tears()
	local r=level[rj][ri]
	for t in all(tears) do
		t.x += t.vx
		t.y += t.vy
		if p.proptosis and
		   t.size > 1 then
			t.size-=0.1
		end
		if solida(t.x,t.y,
			t.size/2,
			t.size/2) then
			del(tears,t)
		end
		if t.x < 0 or t.x > 128
		 or t.y < 24 or t.y > 120 then
			del(tears,t)
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
				e.life-=t.size/5
				e.x += t.vx*2
				e.y += t.vy*2
		  del(tears,t)
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


__gfx__
000000000000000066666666666666660000000000000000333e333333333333eeeeee77777ee777766666666666666776666666666666676777777777777776
00000000000000006000ddddddddddd6005505500055055033ebe33333333333eeeeee7777ee777767777777777777706cccccccccccccc07677777777777760
00700700000000006550ddddddddddd60588588505005885333e333333333333eeeeeee7eee7777767777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550ddddddddddd605888785050087853333333333333333eeeeeeeee777777767777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550000dddddddd605888850050088503333333333e333337eeeeeeeee77777767777777777777706cccccccccccccc077dddddddddddd00
00700700000000006550550dddddddd60058850000508500333333333ebe333377eeeeeeeeee7ee767777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550dddddddd600055000000550003333333333e33333777eeeeeeeeeeeee67777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550000ddddd600000000000000003333333333333333777eeeeeeeeeeddd67777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550550ddddd600000000000000003333333333333333e777eeeeeeeddddd67777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550550ddddd600550550000010003333333333333333eeeeeeeeeedddddd67777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550550000dd605cc5cc5000010003333333333333333ddddeeeeedddddde67777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550550550dd605ccc7c50055550033e3333333333333ddeeedddeeeeeeee67777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550550550dd605cccc50055577503ebe333333333e33deeeeeddde77777e67777777777777706cccccccccccccc077dddddddddddd00
00000000000000006550550550550006005cc5000555575033e333333333ebe3ee7eeeeeeee7777e67777777777777706cccccccccccccc077dddddddddddd00
0000000000000000655055055055055600055000055555503333333333333e33777eeeeeeee7777e67777777777777706cccccccccccccc07600000000000060
00000000000000006666666666666666000000000055550033333333333333337777eeeeeeee77ee700000000000000570000000000000076000000000000006
3333333333333333333337777773333300000000000000000000000000000000d77777777777777d4444444444444444eeeeeeeeeeeeeeee0000000000000000
33333333333333333337777ee7777333000000000770770007707700077077007d777777777777d044400000b4bbbb4beeeeeeeeeeeeeeee0000000000000000
33333333333333333377777777ee7733aaa0000078878870788777707777777077dddddddddddd0044040b04bbbbbbbbeee777eeee777eee0000000000000000
33333333333333333777e7ee77777773a9aaaaaa78788870787877707777777077dddddddddddd00440bbbb0bbbbbbbbee77777ee77777ee0000000000000000
3333333333333333377777eee7ee7773aaa99a9a78888870788877707777777077dd777dd777dd0040bbbbbbbbbbb4bbe77777777777777e0000000000000000
3333333333333333377ee77777777e739990090907888700078877000777770077d7777777777d0040bbbbbbbbbbbbbbe77777777777777e0000000000000000
3333333333333333377ee7ee7ee7e7730000000000787000007870000077700077d7777777777d00440bbbbbbbbbbbbbe77777777777777e0000000000000000
333333333338333337e777777ee7e7730000000000070000000700000007000077d7777777777d0040bbbbbbbbbbbbbbe67777777777776e0000000000000000
33333333338983333777ee7e777777730000000000000000000000000000000077d6777777776d00404bbb8b8bbbbbbbee677777777776ee0000000000000000
3333333333b833333377ee7e7ee7e7330000800000008000000000000000000077dd67777776dd0040bbbbb9bbbb4bbbeee6777777776eee0000000000000000
3333333333b3333333777e777ee777330000100000001000000000000000000077ddd677776ddd0040bbbb838bbbbbbbeeee67777776eeee0000000000000000
33333333333b333333377777777773330055550000888800000000000000000077dddd6776dddd00440bbbb3bbbbbbbbeeeee677776eeeee0000000000000000
333333333333333333333749447333330555775008887780000000000000000077ddddd66ddddd0040bbbbbb3bbbbbbbeeeeee6776eeeeee0000000000000000
333333333333333333334449444433330555575008888780000000000000000077dddddddddddd0040bbb4bbbbbbbbbbeeeeeee66eeeeeee0000000000000000
33333333333333333333344444433333055555500888888000000000000000007d000000000000d0440bbbbbbbbbbbbbeeeeeeeeeeeeeeee0000000000000000
3333333333333333333333333333333300555500008888000000000000000000d00000000000000d440bbbbbbbbbbbbbeeeeeeeeeeeeeeee0000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000555ff6555500000005777777500000000577777750000
000000000000000000000000000000000000000000000000000000000000000000000000000000000055fffff566550000057777777750000005777777775000
00000000000000000000000000000000000000000000000000000000000000000000000550000000005666fff666f55000577777777775000057777777777500
000000000000000000000000000000000000000000000000000000000000000000000555555500000556766ff676ff5500575777775775000057577777577500
0000000000000000000000000000000000000000000000000000000000000000000055fff555500055666665ff666ff500575577775575000057557777557500
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
0c0c0c05000c0005000000050000000533bbbbb3bbb3bbbbbbbbbb3417777777c777777cc77c7cc75888888888888888888888855555555566655666555d5555
c06c60c508000805000c06050ccccc05bbbb8b33bbbbbb8bb8bb3b3471cccccc7cccccc07cc07cc78588888888888888888888855566665555555555566d6555
00c0c0050c060c0506c8c605086668053bbbbbbbbbbbb8bbb3bb3b347c1cc1117cccccc07cc07cc7885888888888888888888885566666655566665166ddddd5
c06c60c508000805060c00050ccccc05bbb4bbbbb4bbbbbbbbb8b3347cc17777c000000c7cc0c0078885888888888888888888855666666556d66d65666d6655
0c0c0c05000c00050000000500000005bb4bbbbbbbbbbbbbb4bbb3547cc11ccc777cc7777cc0c77788885888888888888888888556666665dddddddd666d6655
55555555555555555555555555555555bbbbb8bbb333bbb33b4bb3547cc171ccccc07ccc7cc07cc78888858888888888888888855666666516d66d6566ddddd5
00c0c80500000005000000050c000c053bbbbb3333533333bbbbb3347cc17c1c000cc0007cc07cc78888885888888888888888855555555516d66d65555d5555
000600050068600506666605c60006c5bbbbbb3444444444bbb8bb34c11c7cc577777777c00c7cc78888888555555555888888855555555555d55d55115d5155
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
00000000055055000550550005505500000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000
00000000588588505885555055555550000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000
00000000587888505878555055555550000000000000000000555500000000000000000000000000000000000000000000000000000000000000000000000000
00000000588888505888555055555550000000000000000005557750000000000000000000000000000000000000000000000000000000000000000000000000
00000000058885000588550005555500000000000000000005555750000000000000000000000000000000000000000000000000000555550000000000000000
000000000058500000585000005550000000000000000000055555500000000000000000000000000000000000000000000000000005ddd50000000000000000
000000000005000000050000000500000000000000000000005555000000000000000000000000000000000000000000000000000005ddd50000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555555000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555577755555000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555577755555000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555555000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005aaa50000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005aaa50000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555550000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5ccccccccccccccccccccccccccccccccccccccccccccccccccccccc5051111111111150ccccccccccccccccccccccccccccccccccccccccccccccccccccccc5
c5ccccccccccccccccccccccccccccccccccccccccccccccccccccccc501111111111500cccccccccccccccccccccccccccccccccccccccccccccccccccccc5c
cc5cccccccccccccccccccccccccccccccccccccccccccccccccccccc550111111111550ccccccccccccccccccccccccccccccccccccccccccccccccccccc5cc
ccc5ccccccccccccccccccccccccccccccccccccccccccccccccccccc00511111111150ccccccccccccccccccccccccccccccccccccccccccccccccccccc5ccc
cccc5cccccccccccccccccccccccccccccccccccccccccccccccccccc5555dd111dd155cccccccccccccccccccccccccccccccccccccccccccccccccccc5cccc
ccccc5cccccccccccccccccccccccccccccccccccccccccccccccccccc555555d555d5cccccccccccccccccccccccccccccccccccccccccccccccccccc5ccccc
cccccc5cccccccccccccccccccccccccccccccccccccccccccccccccccc5dd5d5d5d5cccccccccccccccccccccccccccccccccccccccccccccccccccc5cccccc
ccccccc555555555555555555555555555555555555555555555555555555dd5551550555555555555555555555555555555555555555555555555555ccccccc
ccccccc576666666666666677666666666666667766666666666666776666666666666677666666666666667766666666666666776666666666666675ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc570000000000000077000000000000005700000000000000770000000000000057000000000000007700000000000000570000000000000075ccccccc
ccccccc576666666666666677666666666666667677777777777777676666666666666676777777777777776766666666666666776666666666666675ccccccc
ccccccc56cccccccccccccc0677777777777777076777777777777606cccccccccccccc0767777777777776067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777076000000000000606cccccccccccccc0760000000000006067777777777777706cccccccccccccc05ccccccc
ccccccc570000000000000057000000000000007600000000000000670000000000000056000000000000006700000000000000770000000000000055ccccccc
ccccccc576666666666666677666666666666667766666666666666776666555555666677666666666666667766666666666666776666666666666675ccccccc
ccccccc5677777777777777067777777777777706cccccccccccccc067775ffffff577706cccccccccccccc0677777777777777067777777777777705ccccccc
c5555555677777777777777067777777777777706cccccccccccccc06775ffffffff57706cccccccccccccc0677777777777777067777777777777705555555c
55111116677777777777777067777777777777706cccccccccccccc0675ffffffffff5706cccccccccccccc06777777777777770677777777777777066111155
51111166677777777777777067777777777777706cccccccccccccc0675f57ffff57f5706cccccccccccccc06777777777777770677777777777777066111115
51111666677777777777777067777777777777706cccccccccccccc0675f55ffff55f5706cccccccccccccc06777777777777770677777777777777066111115
51111666677777777777777067777777777777706cccccccccccccc0675fcc5555ccf5706cccccccccccccc06777777777777770677777777777777066611115
b1111666677777777777777067777777777777706cccccccccccccc06775cf5555fc57706cccccccccccccc0677777777777777067777777777777706666111b
b1111666677777777777777067777777777777706cccccccccccccc067775ffffff577706cccccccccccccc0677777777777777067777777777777706666111b
51111166677777777777777067777777777777706cccccccccccccc06775f555555f57706cccccccccccccc06777777777777770677777777777777066611115
51111166677777777777777067777777777777706cccccccccccccc0677555ffff5557706cccccccccccccc06777777777777770677777777777777066111115
51111116677777777777777067777777777777706cccccccccccccc0677775ffff5777706cccccccccccccc06777777777777770677777777777777061111115
55111116677777777777777067777777777777706cccccccccccccc0677775f55f5777706cccccccccccccc06777777777777770677777777777777061111155
c5555555677777777777777067777777777777706cccccccccccccc067777557755777706cccccccccccccc0677777777777777067777777777777705555555c
ccccccc5677777777777777067777777777777706cccccccccccccc067777777777777706cccccccccccccc0677777777777777067777777777777705ccccccc
ccccccc570000000000000077000000000000007700000000000000570000000000000077000000000000005700000000000000770000000000000075ccccccc
ccccccc576666666666666677666666666666667677777777777777676666666666666676777777777777776766666666666666776666666666666675ccccccc
ccccccc56cccccccccccccc0677777777777777076777777777777606cccccccccccccc0767777777777776067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777077dddddddddddd006cccccccccccccc077dddddddddddd0067777777777777706cccccccccccccc05ccccccc
ccccccc56cccccccccccccc0677777777777777076000000000000606cccccccccccccc0760000000000006067777777777777706cccccccccccccc05ccccccc
ccccccc570000000000000057000000000000007600000000000000670000000000000056000000000000006700000000000000770000000000000055ccccccc
ccccccc576666666666666677666666666666667766666666666666776666666666666677666666666666667766666666666666776666666666666675ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc567777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777706cccccccccccccc067777777777777705ccccccc
ccccccc570000000000000077000000000000005700000000000000770000000000000057000000000000007700000000000000570000000000000075ccccccc
ccccccc555555555555555555555555555555555555555555555555555566666666665555555555555555555555555555555555555555555555555555ccccccc
cccccc5ccccccccccccccccccccccccccccccccccccccccccccccccccc566666666665ccccccccccccccccccccccccccccccccccccccccccccccccccc5cccccc
ccccc5cccccccccccccccccccccccccccccccccccccccccccccccccccc516666666665cccccccccccccccccccccccccccccccccccccccccccccccccccc5ccccc
cccc5ccccccccccccccccccccccccccccccccccccccccccccccccccccc516666666615ccccccccccccccccccccccccccccccccccccccccccccccccccccc5cccc
ccc5cccccccccccccccccccccccccccccccccccccccccccccccccccccc511111666115cccccccccccccccccccccccccccccccccccccccccccccccccccccc5ccc
cc5ccccccccccccccccccccccccccccccccccccccccccccccccccccccc511111111115ccccccccccccccccccccccccccccccccccccccccccccccccccccccc5cc
c5cccccccccccccccccccccccccccccccccccccccccccccccccccccccc551111111155cccccccccccccccccccccccccccccccccccccccccccccccccccccccc5c
5cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5555bb5555cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0001000000000000010100000000010100000000000000000101000000000101000001010000000001010000010101010000010100000101010100000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101000000000000000000000000010101010000000000000000010101010101010100000000000000000100000000000000
__map__
2006200620062020202006202020202000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0620220622200620352020203520202000060022000006060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020062006202020062022200620202206350600000035222222350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0620220622200620352020203520202200060000000006060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2006200620062020202006202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020062006352020202020202020202000000000000006000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202220202020202235222020202222222222000622000000220600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020222222202020200620062020202222062222000000352235000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202220202020202235222020202222222222000622000000220600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0035060006000000000000000000000000000000000006000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000600060006062200220606000000000000003506060606063500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0600060606350622222200222222000000350000000006000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006063506060000000000000000000000000000000006000600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0635060606000622222200222222000035003500000006000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000600060006062200220606000000000000003506060606063500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000f05013050150501a0501f05022050250502c050320503405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001814014150101500d1500b1500a1500915000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b15021150231501e150161501f150251501f150181501e15026150211501b1501a150191501815018150181500000000000000000000000000000000000000000000000000000000000000000000000
