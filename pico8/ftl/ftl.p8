pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
s_shield=6
s_engine=7
s_o2    =8
s_med   =9
s_cloak =10
s_weapon=11

hull=7

modules={{1,2,6},
         {1,2,7},
         {0,1,8},
         {0,1,9},
         {2,3,11}}

no={0,16,false}

reactors={2,6}
weapons={{2,18,true}, no, no}

meteors={}
s_meteors={36,37,38}

anims={}

enemy = {
 x=80,
 y=40
}

function _init()
 stream= {}
end

function add_anims(f)
 add(anims, cocreate(f))
end

function _update_meteor()
 local rx=rnd(1)*128
 if (rx<64) then
  rx=rx-64 
	else
	 rx=rx+64
	end
	if (rnd(1) > 0.005) then
	 add(meteors, {
	  s=s_meteors[flr(rnd(3)+1)],
	  x=rx,y=rx,
	  dx=rnd(8)-4,dy=rnd(8)-4
	 })
	end
	for m in all(meteors) do
	 m.x+=m.dx
	 m.y+=m.dy
	 if (-200>m.x) or (m.x>200) or
	 		(-200>m.y) or (m.y>200) then
	  del(meteors,m)
	 end
	end
end

index=6

function slash(x,y)
 x=x or 80
 y=y or 60
 return function()
	 for i=1,10 do
	  line(x+rnd(6)-3,y+rnd(6)-3,
	       x+40+rnd(6)-3,y-20+rnd(6)-3,
	       7)
	 end
	end
end


function update_keys()
	if btnp(⬅️) and index>1 then
	  index-=1
	end
	local m=#modules+#weapons
	if btnp(➡️) and index<m-1 then
	  index+=1
	end
	if btnp(⬆️) then
	 if index < #modules then
   local m=modules[index]
   if m[1] < m[2] and
      reactors[1]>=1 then
    reactors[1]-=1
    m[1]+=1
   end
  else
   local k=index-#modules+1
   if weapons[k][3]==false and
    reactors[1]>=weapons[k][1] then
     weapons[k][3]=true
     reactors[1]-=weapons[k][1]
     modules[#modules][1]+=weapons[k][1]
   else
    add_anims(slash())
   end
  end
	end
	if btnp(⬇️) then
	 if index<#modules then
   local m=modules[index]
   if m[1]>0 then
    reactors[1]+=1
    m[1]-=1
   end
  else
   local k=index-#modules+1
   if weapons[k][3] then
     weapons[k][3]=false
     reactors[1]+=weapons[k][1]
     modules[#modules][1]-=weapons[k][1]
   end
  end
	end
end

function update_enemy()
 dx=cos(t()/2)*3
	dy=sin(t()/2)*3
	for i=1,100 do
	 stream[i]=sin(i/40+t())/2
	end
	if stream[1] > 0.48 then
		add_anims(slash(15,90))
	end
end

function _update60()
	_update_meteor()
	update_keys()
	update_enemy()
end


function draw_reactor(y)
	for i=1,reactors[2] do
	 spr(1,0,y-i*3)
	 if i != 1 then
	 --	spr(2,8,y+4-i*3)
	  spr(2,8,y+2-i*3)
	 end
	end
	for i=1,reactors[1] do
	 rect(1,y-i*3+1,
	      6,y-i*3+2,11)
	 if i != reactors then
	 	spr(3,8,y+2-i*3)
	 end
	end
end

function draw_modules(y)
	for i=1,#modules do
	 local mi=modules[i]
	 spr(mi[3], 8+8*i, y-5)
	 spr(4, 5+8*i, y+3)
	 for a=1,mi[2] do
	 	spr(5,10+8*i,y-5-a*3)
	 end
	 for a=1,mi[1] do
   rect(11+8*i,y-4-a*3,
        12+8*i,y-4-a*3,11)
	 end
	end
end

function draw_weapons(y)
	for i=1,#weapons do
	 local s=weapons[i][2]
	 if not weapons[i][3] then
	  pal(7,5)
	 end
		spr(s,#modules*8+i*17,
		      y-14,2,2)
		pal()
	end	
end

function draw_hull()
 spr(20,5,5,2,1)
 for i=1,10 do
  spr(22,18+i*5,5)
  if i<=hull then
   rect(19+i*5,6,
        20+i*5,10,11)
  end
 end
end

function draw_hud(y)
 draw_hull()
 draw_reactor(y)
	draw_modules(y)
	draw_weapons(y)
	draw_select()
end

function bckgrnd()
 local cc={0,1}
	for x=1,128 do
		for y=1,128 do
		 c=sin(x/128)+cos(y/128)
		 c=ceil(c*#cc)%#cc+1
			pset(x,y,cc[c])
		end
	end
end

function draw_meteor()
	for m in all(meteors) do
		spr(m.s, m.x, m.y)
	end
end

function draw_select()
 if index>0 and index<#modules then
  circ(11+index*8,119,5,8)
  --rect(7+index*8,124,
  --     16+index*8,125,8)
 end
 if index>=#modules and
    index<#modules+#weapons then
  --circ(-46+index*20,114,10,11)
 	local shift=16+#modules*8
 	local i=(index-#modules)*17
 	rect(shift+i,105,
 	     shift+i+17,122,8)
 end
end

function draw_stream()
 local c=8
 if (stream[1] < -0.49) c=9
 line(20,16,20,24,c)
 print(stream[1])
 for i=1,#stream do
  c=8
  if (stream[i] < -0.40) c=9
 	pset(20+i,20+stream[i]*4,c)
 end
end

function draw_enemy()
 draw_stream()
 spr(64,enemy.x+dx,
        enemy.y+dy,4,4)
 circ(96+dx,56+dy,18,8)
 circ(96+dx,56+dy,20,8)
 circ(96+dx,56+dy,22,8)
end

function draw_me()
 spr(68,10,60,8,4)
 for i=1,modules[1][1] do
	 //circ(36,75,35,12)
	 circ(36,75,31+i*2,12)
	end
end

function _draw()
 cls()
 bckgrnd()
  
 draw_enemy()
 draw_meteor()
 draw_me()
 
 for c in all(anims) do
  if (not coresume(c)) then
   del(anims,c)
  end
 end

 
 draw_hud(120)
end

__gfx__
00000000055555500550000007700000000000700550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000051111115005500000077000000000700511500000b00bb000000b0000bbb0000000bb000000000000b00000000000000000000000000000000000000
007007005111111500055000000770007777777705500000000b000000b0bb000b0b0000000bb00000bbbb000bbbbb0000000000000000000000000000000000
0007700005555550000050000000700000000000000000000b0bbb000b00bbb00b0b0bb00bbbbbb00b00b0b00bbbbbb000000000000000000000000000000000
00077000000000000000500000007000000000000000000000000b000b00bbb00b0b00b00bbbbbb00b0bb0b00b00000000000000000000000000000000000000
0070070000000000000000000000000000000000000000000b0bb00000b0bb000b0b0b00000bb00000bbbb000bbbbb0000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000b0000bbb0bb0000bb000000000000bbbbbb000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555555555555000077777777777700000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000
05111111111111500711111111111170070707070700700077770000080880800000000000000000000000000000000000000000000000000000000000000000
51111111111111157111111111111117070707070700700077770000008008000000000000000000000000000000000000000000000000000000000000000000
51111111111111157771111111111117077707070700700077770000080880800000000000000000000000000000000000000000000000000000000000000000
51111111111111157111111111111117070707070700700077770000080880800000000000000000000000000000000000000000000000000000000000000000
51111111111111157771177777777717070707770770770077770000008008000000000000000000000000000000000000000000000000000000000000000000
51111111111111157111177111171117000000000000000007700000080880800000000000000000000000000000000000000000000000000000000000000000
51111111111111157111177777771117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51111111111111157111111111111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51111111111111157111111111111117000055000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000
51111111111111157117171777771117005555000005500000055050000000000000000000000000000000000000000000000000000000000000000000000000
51111111111111157111711171711117005555500055550000555500000000000000000000000000000000000000000000000000000000000000000000000000
51111111111111157117171777771117055555500055550000555500000000000000000000000000000000000000000000000000000000000000000000000000
51111111111111157111111111111117055555000055500000055000000000000000000000000000000000000000000000000000000000000000000000000000
05111111111111500711111111111170005555000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555555555555000077777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000a56656666666666655000055558000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000a56656666666666655000005000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000a56665566666666655055555500000000000000000000000000000000000000000000000000000000000000000000
000000009a4000000000049a000000000000566655ddddddddd5505d555550000000000000000000000000000000000000000000000000000000000000000000
000000009a4000000000049a00000000000005dd555dddd55555555ddddd55550000000000000000000000000000000000000000000000000000000000000000
000000599a4000000000049aa60000000000055555555555dddddddddddddddd5500000555590000000000000000000000000000000000000000000000000000
000009599a40000000000499a6a000000000055555ddddddddd66666666666666555500050000000000000000000000000000000000000000000000000000000
00009959a400000000000049a6aa0000000005555dd5dd655dd655ddd65555dd66dd555555555555550000000000000000000000000000000000000000000000
00009959a400000000005049a6aa0000000555565dd55d6555565555565555dd6666ddddddddddddd55000000000000000000000000000000000000000000000
00009959a405000000008049a6aa0000005556665d555d6555565555565555dd6d566666666666666d5500000000000000000000000000000000000000000000
00009955a40809900000655966aa00000055666656555d6555565555566666666d5665555555555666d500000000000000000000000000000000000000000000
00009999a556955900006059aaaa00000055dddd56555d6555565555565555dd6d566555555dddd5666500000000000000000000000000000000000000000000
00009999a506955909999059aaaa00000005dddd5665dd6555d65555d65555dd6d566555555dddd5666500000000000000000000000000000000000000000000
0000dcc9a500955995555959accc0000000555555566666666666666665555dd6d566555555dddd5666500000000000000000000000000000000000000000000
000099c9a559955995555959acaa0000000555555566666666666666665555dd66566555555dddd5666500000000000000000000000000000000000000000000
000099c9a9a9988999999949acaa00000005dddd5665dd6555d65555d65555dd66566555555dddd5666500000000000000000000000000000000000000000000
000099c9a911111111111149acaa00000055dddd56555d65555655555666666666566555555dddd5666500000000000000000000000000000000000000000000
000099c9a955156556515549acaa00000055666656555d6555565555565555dd6656655555555556666500000000000000000000000000000000000000000000
000099c9a955156556515549acaa00000055566656555d65555655555655555d6666666666666666665500000000000000000000000000000000000000000000
000099c9a955156556515549acaa00000005555656555d6555565555565555dd6666dddddddddddddd5000000000000000000000000000000000000000000000
000099c9aa55156556515549acaa0000000005555665dd6555d6555d566666666555555555555555550000000000000000000000000000000000000000000000
000099c99aa999999999944aacaa0000000005555666666666666666666665555555000050000000000000000000000000000000000000000000000000000000
000099c999aa99999999449aacaa00000000055555666666666655dddddd55000000000555590000000000000000000000000000000000000000000000000000
000009d9999a00444400499a9c900000000005dd5555555555566555555550000000000000000000000000000000000000000000000000000000000000000000
0000009d999a00000000499ad900000000005ddd5566666666555000005000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000a5666566666666666500005555c000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000a566556666ddd6d665000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000a5665ddddddddddd55000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000111111111111111111110001111111111111111111100000000000111111111100000000000000000000000000000000000000000001111111111
00000000000111111111111111111100000111111111111111111100000000000111111111100000000000000000000000000000000000000000001111111111
00000000000111111111111111111000000011111111111111111100000000000111111111100000000000000000000000000000000000000000001111111111
00000000000111111111111111110000000001111111111111111100000000000111111111110000000000000000000000000000000000000000011111111111
00000000001111111111111177100770007700177111771117711177000770007711177111110000000000000000000000000000000000000000011111111111
000000707071717117111117bb707bb707bb707bb717bb717bb717bb707777077771777711110000000000000000000000000000000000000000011111111111
000000707071717117111117bb707bb707bb707bb717bb717bb717bb707777077771777711111000000000000000000000000000000000000000111111111110
000000777171717117111117bb707bb707bb707bb717bb717bb717bb707777077771777711111000000000000000000000000000000000000000111111111110
000000707171717117111117bb707bb707bb707bb717bb717bb717bb707777077771777711111100000000000000000000000000000000000001111111111110
000000707177717717711107bb707bb707bb707bb707bb717bb717bb707777077771777711111100000000000000000000000000000000000001111111111100
00000000111111111111100077000770007700077000771117711177100770007701177111111110000000000000000000000000000000000011111111111100
00000001111111111111000000000000000000000000011111111111110000000000111111111110000000000000000000000000000000000011111111111000
00000001111111111110000000000000000000000000001111111111110000000000011111111111000000000000000000000000000000000111111111110000
00000011111111111100000000000000000000000000000111111111111000000000011111111111100000000000000000000000000000001111111111110000
00000111111111111000000000000000000000000000000011111111111100000000001111111111110000000000000000000000000000011111111111100000
00000111111111110000000000000000000000000000000001111111111100000000000111111111111000000000000000000000000000111111111111000000
00001111111111100000000000000000000000000000000000111111111110000000000111111111111100000000000000000000000001111111111111000000
00011111111111000000000000000000000000000000000000011111111111000000000011111111111111000000000000000000000111111111111110000000
00111111111110000000000000000000000000000000000000001111111111100000000001111111111111110000000000000000011111111111111100000000
00111111111100000000000000000000000000000000000000000111111111100000000000111111111111111100000000000001111111111111111000000000
01111111111000000000000000000000000000000000000000000011111111110000000000011111111111111111100000001111111111111111110000000000
01111111110000000000000000001111111110000000000000000001111111111000000000001111111111111111111111111111111111111111100000000000
01111111100000000000000001111111111111110000000000000000111111111100000000000111111111111111111111111111111111111111000000000001
01111111000000000000000111111111111111111100000000000000011111111110000000000011111111111111111155111111111111111110000000000011
01111110000000000000011111111111111111111111000000000000001111111111000000000001111111111111115555111111111111111100000000000111
01111100000000000001111111111111111111111111110000000000000111111111100000000000011111111111115555511111111111110000000000001111
01111000000000000011111111111111111111111111111000000000000011111111110000000000001111111111155555511111111111100000000000011111
01110000000000001111111111111111111111111111111110000000000001111111111000000000000011111111155555111111111110000000000000111111
01100000000000011111111111111111111111111111111111000000000000111111111100000000000001111111115555111111111100000000000001111111
01000000000000111111111111111111111111111111111111100000000000011111111110000000000000011111111111111111110000000000000011111111
00000000000011111111111111111111111111111111111111111000000000001111111111000000000000000011111111111110000000000000000111111111
00000000000111111111111111111111011111111111111111111100000000000111111111100000000000000000000000000000000000000000001111111111
00000000001111111111111111000000000000011111111111111110000000000011111111110000000000000000000000000000000000000000011111111110
00000000011111111111111000000000000000000011111111111111000000000001111111111100000000000000000000000000000000000001111111111100
00000000111111111111100000000000000000000000111111111111100000000000111111111110000000000000000000000000000000000011111111111000
00000001111111111111000000000000000000000000011111111111110000000000011111111111000000000000000000000000000000000111111111110000
00000011111111111100000000000000000000000000000111111111111000000000001111111111110000000000000000000000000000011111111111100000
00000111111111111000000000000000000000000000000011111111111100000000000111111111111000000000000000000000000000111111111111000000
000011111111111000000000000000f0000000000000000000111111111110000000000011111111111110000000000000000000000011111151111110000000
00011111111111000000000000000000000000000000000000011111111111000000000001111111111111100000000000000000001111111155151100000000
00111111111110000000000000000000000000000000000000001111111111100000000000111111111111111000000000000000111111111555511000000000
01111111111100000000000000000000000000000000000000000111111111110000000000011111111111119a4100000000049a111111111555510000000000
01111111111000000000000000000111111100000000000000000011111111111000000000001111111111119a4111111111149a111111111155100000000000
01111111110000000000000000111111111111100000000000000001111111111100000000000111111111599a4111111111149aa61111111111000000000001
01111111100000000000000011111111111111111000000000000000111111111100000000000011111119599a41111111111499a6a111111110000000000001
0111111100000000000000111111111111111111111000000000000001111111111000000000000111119959a411111111111149a6aa11111100000000000011
0111111000000000000011111111111111111111111110000000000000111111111100000000000011119959a411111111115149a6aa11111000000000000111
0111111000000000000111115511111111111111111111000000000000111111111110000000000001119959a415111111118149a6aa11110000000000001111
0111110000000000001111155551111111111111111111100000000000011111111110000000000000119955a41819911111655966aa11100000000000001111
0111100000000000551111155551111111111111111111110000000000001111111111000000000000019999a556955911115555aaaa11000000000000011111
0111100000000005555111155511111111111111111111111000000000001111111111100000000000009999a516955919995555aaaa10000000000000111111
0111000000000005555111115111111111111111111111111100000000000111111111100000000000005cc9a511955995555559accc00000000000000111111
01100000000000055511111111111111111111111111111111000000000000111111111100000000000055c5a559955995555559acaa00000000000001111111
0110000000000011511111111111111111111115511111111110000000000011111111110000000000055559a9a9988999999949acaa00000000000001111111
0100000000000011111111111111111111111155551111111110000000000001111111111000000000055559a911111111111149acaa00000000000011111111
01000000000001111111111111111111111111555511111111110000000000011111111110000000000055c9a955156556515549acaa00000000000011111111
01000000000001111111111111111111111111555111111111110000000000011111111111000000000099c9a955156556515549acaa00000000000111111111
00000000000011111111111111111111111111151111111111111000000000001111111111000000000099c9a955156556515549acaa00000000000111111111
00000000000011111111111111111111111111111111111111111000000000001111111111000000000099c9aa55156556515549acaa00000000000111111111
00000000000011155511111111111111111111111111111111111000000000001111111111100000000099c99aa999999999944aacaa00000000001111111111
00000000000111555555555555555511111111111111111111111100000000001111111111100000000099c999aa99999999449aacaa00000000001111111111
0000000000011a566566666666666551111555581111111111111100000000001111111111100000000009d9999a00444400499a9c9000000000001111111111
0000000000011a5665666666666665511111511111111111111111000000000011111111111000000000009d999a00001000499ad90000000000001111111111
0000000000011a566655666666666551555555111111111111111100000000000111111111100000000000000000000000000000000000000000001111111111
00000000000111566655ddddddddd5515d5555511111111111111100000000001111111111100000000000000000000010000000000000000000055111111111
0000000000011115dd555dddd55555555ddddd555511111111111100000000001111111111100000000000000000000111000000000000000000555511111111
00000000000111155555555555dddddddddddddddd55111115555900000000001111111111100000000000000000001111100000000000000000555511111111
00000000000011155555ddddddddd666666666666665555111511000000000001111111111100000000000000000011111110000000000000000555111111111
0000000000001115555dd5dd655dd655ddd65555dd66dd5555555555555500001111111111000000000000000000111111111000000000000000050111111111
0000000000001555565dd55d6555565555565555dd6666ddddddddddddd550001111111111000000000000000001111111111100000000000000000111111111
0100000000005556665d555d6555565555565555dd6d566666666666666d55011111111111000000000000000011111111111110000000000000000111111111
01000000000055666656555d6555565555566666666d5665555555555666d5011111111110000000000000000111111111111111000000000000000011111111
01000000000055dddd56555d6555565555565555dd6d566555555dddd56665011111111110000000000000001111111111111111100000000000000011111111
01100000000005dddd5665dd6555d65555d65555dd6d566555555dddd56665111111111100000000000000011111111111111111110000000000000001111111
0110000000000555555566666666666666665555dd6d566555555dddd56665111111111100000000000000111111111111111111111000000000000001111111
0111000000000555555566666666666666665555dd66566555555dddd56665111111111000000000000001111111111111111111111100000000000000111111
01111000000005dddd5665dd6555d65555d65555dd66566555555dddd56665111111111000000000000011111111111111111111111110000000000000111111
01111000000055dddd56555d65555655555666666666566555555dddd56665111111110000000000000111111111111111111111111111000000000000011111
01111100000055666656555d6555565555565555dd66566555555555566665111111100000000000001111111111111111111111111111100000000000001111
01111110000055566656555d65555655555655555d66666666666666666655111111100000000000011111111111111111111111111111110000000000001111
01111110000005555656555d6555565555565555dd6666dddddddddddddd51111111000000000000111111111111111111111111111111111000000000000111
0111111100000005555665dd6555d6555d5666666665555555555555555511111110000000000001111111111111111111111111111111111100000000000011
01111111100000055556666666666666666666655555550000500000111111111100000000000011111111111111111111111111111111111110000000000001
01111111110000055555666666666655dddddd550000000005555901111111111100000000f00111111111111111111111111111111111111111000000000001
0111111111100005dd55555555555665555555500000000000000011111111111000000000001111111111111111111111111111111111111111100000000000
011111111111005ddd55666666665550000050000000000000000111111111110000000000011111111111111111000000000111111111111111110000000000
0011111111111a5666566666666666500005555c0f0000f0000f1111111111100000000000111111111111111050000000000000111111111111111000000000
0001111111111a566556666ddd6d6650000000000000000000011111111111f00000000f01111111111111100055050000000000001111111111111100000000
0000111111111a5665ddddddddddd55000f000f000000000001111111111100000f0000011111111111110000555500000000000000011111111111110000000
00000111111111555555555555555500000000000000000011111111111100000000000111111111111000000555500000000000000000111111111111000000
000000111111111555000f0000000000000000000000000111111111111000000000001111111111110000000055000000000000000000011111111111100000
00000001111111111111000000000000000000000000011111111111110000000000011111111111000000000000000000000000000000000111111111110000
00000000111111111111100000000000000000000000111111111111100000000000111111111110000000000000000000000000000000000011111111111000
00000000011111111111111000000000000000000011111111111111000000000001111111111100000000000000000000000000000000000001111111111100
00000000001111111111111111000000000000011111111111111110000000000011111111110000000000000000000000000000000000000000011111111110
00000000000111111111111111111111011111111111111111111100000000000111111111100000000000000000000000000000000000000000001111111111
00000000000011111111111111111111111111111111111111111000000000001111111111000000000000000011111111111110000000000000000111111111
01000000000000111111111111111111111111111111111111100000000000011111111110000000000000011111111111111111110000000000000011111111
01100000000000011111111111111111111111111111111111000000000000111111111100000000000001111111111111111111111100000000000001111111
01110000000000001111111111111111111111111111111110000000000001111111111000000000000011111111111111111111111110000000000000111111
01111000000000000011111111111111111111111111111000000000000011111111110000000000001111111111111111111111111111100000000000011111
05555550000000000001111111111111111111111111110000000000000111111111100000000000011111111111111111111111111111110000000000001111
51111115000000000000011111111111111111111111000000000000001111111111000000000001111111111111111111111111111111111100000000000111
51111115055000000000000111111111111111111100000000000000011111111110000000000011111111111111111111111111111111111110000000000011
05555551105500000000000001111111111111110000000000000000111111111100000000000111111111111111111111111111111111111111000000000001
51111115110550000000000000001111111110000000000000000001111551111007777777777771111177777777777711111777777777777111100000000000
51111115155050000000000000050000000000000000000000000011115115110071111111111117111711111111111170007111111111111711110000000000
05555551115550000000000000055050000000000000000000000111111551100711111111111111717111111111111117071111111111111171111000000000
51111115111550000005500000555500000000000000000000001111111551100777111111111111717111111111111117071111111111111171111100000000
51111115155151000051150000511500000000000000000000011111115bb5000711111111111111717111111111111117071111111111111171111110000000
05555551115551100005500000055000000000000000000000111111111550000777117777777771717111111111111117071111111111111171111111000000
51111115111551110005500000055000000550000005500001155111111550000711117711117111717111111111111117071111111111111171111111000000
5111111515515111105bb500005bb500005115000051150011511511115bb5000711117777777111717111111111111117071111111111111171111111100000
05555551115551111105500000055000000550000005500118855811111550000711111111111111707111111111111117071111111111111171111111110000
5bbbbbb5111551111110000000000000000000000000001181111181110000000711111111111111707111111111111117071111111111111171111111110000
5bbbbbb5177151111b11bb000000b0000bbb0000000bb118111111181b0000000711717177777111707111111111111117071111111111111171111111111000
0555555011775111111b100000b0bb000b0b0000000bb18111bbbb118bbbbb000711171117171111707111111111111117071111111111111171111111111100
5bbbbbb5111771111b1bbb000b00bbb00b0b0bb00bbbbbb11b11b1b18bbbbbb00711717177777111707111111111111117071111111111111171111111111100
5bbbbbb50771711111111b100b00bbb00b0b00b00bbbbbb11b1bb1b18b0000000711111111111111707111111111111117071111111111111171111111111110
05555550017771111b1bb11100b0bb000b0b0b00011bb18111bbbb118bbbbb000071111111111117000711111111111170007111111111111700111111111110
0000000000177111111111111000b0000bbb0bb0111bb181111111108bbbbbb00017777777777770000077777777777700000777777777777000111111111110
00000000001171111111111111000000000000011111155811111118000000000111111111110000000000000000000000000000000000000000011111111111
00000000001171111117111111170000000700111117555181171180000700000111111111110000000000000000000000000000000000000000011111111111
00000000000111111171111111710000007001111175555518788800007000000111111111110000000000000000000000000000000000000000011111111111
00000000000117777777777777777777777777777777777777777777777770000111111111100000000000000000000000000000000000000000001111111111
00000000000111111111111111111100000111111155555111111100000000000111111111100000000000000000000000000000000000000000001111111111
00000000000111111111111111111110001111111115555111111100000000000111111111100000000000000000000000000000000000000000001111111111

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102030405060708090a0b0c0d0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112131415161718191a1b1c1d1e1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2122232425262728292a2b2c2d2e2f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132333435363738393a3b3c3d3e3f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000