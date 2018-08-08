local Sound = {}
Sound.__index = Sound
Sound.class = 'Sound'

local sound_dir = 'sounds/'

function Sound:new(template)
  local instance = {}
  instance.source_name = template.source_name
  instance.volume = template.volume
  instance.source = love.audio.newSource(sound_dir .. template.source_name, 'static')
  if instance.volume then
    instance.source:setVolume(instance.volume)
  end
  return setmetatable(instance, Sound)
end

function Sound:dup()
  return self --Sound:new(self)
end

Sound.pickup = Sound:new{
  source_name = 'sfx_coin_double3.wav',
}

Sound.heart = Sound:new{
  source_name = 'sfx_coin_double7.wav',
}

Sound.player_hit = Sound:new{
  --source_name = 'Getting_Hurt.wav',
  source_name = 'sfx_wpn_punch4.wav',
}

Sound.enemy_hit = Sound:new{
  source_name = 'Hitting_Enemies.wav',
}

Sound.sword_swing = Sound:new{
  source_name = 'Sword_Swing.wav',
  volume = 0.5,
}

Sound.knife_throw = Sound:new{
  source_name = 'sfx_wpn_sword3.wav',
}

function Sound:replay()
  self.source:stop()
  self.source:play()
end

return Sound

