local anim8 = require('anim8')

function love.load()
   spritesheet = love.graphics.newImage('data/player/grid.png');
   local g = anim8.newGrid(16, 24, spritesheet:getWidth(), spritesheet:getHeight())
   player = {
      spritesheet = spritesheet,
      x = 0,
      y = 0,
      speed = 100,
      y_velocity = 0,
      animations = {
         still = anim8.newAnimation(g(1,1), 1),
         left = anim8.newAnimation(g('1-3',1, '3-1',1), 0.1),
         right = anim8.newAnimation(g('1-3',2, '3-1',2), 0.1)
      }
   }
   player.animation = player.animations.still
   gravity = 400
   jump_height = 100

   winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
end
 
function love.draw()
   love.graphics.rectangle("fill", 0, 0, winW, winH)
   love.graphics.translate(winW / 2, winH / 2)
   --love.graphics.draw(player.spritesheet, player.x, -player.y, 0, 1, 1)
   --print (player.spritesheet, player.x, -player.y)
   player.animation:draw(player.spritesheet, player.x, player.y, 0, 2, 2)
end

function love.update(dt)
   if love.keyboard.isDown(" ") then
      if player.y_velocity == 0 then
         player.y_velocity = jump_height
      end
   end
   if love.keyboard.isDown("right") then
      player.animation = player.animations.right
      player.x = player.x + player.speed * dt
   elseif love.keyboard.isDown("left") then
      player.animation = player.animations.left
      player.x = player.x - player.speed * dt
   else
      player.animation = player.animations.still
   end
   player.animation:update(dt)

   if player.y_velocity ~= 0 then
      player.y = player.y - player.y_velocity * dt
      player.y_velocity = player.y_velocity - gravity * dt
      
      if player.y > 0 then
         player.y_velocity = 0
         player.y = 0
      end
   end
end
