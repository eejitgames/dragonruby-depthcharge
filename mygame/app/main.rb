$gtk.reset
$gtk.hide_cursor

require 'app/nokia.rb'

def tick args
  # using both samples/99_genre_lowrez/nokia_3310 and samples/02_input_basics/07_managing_scenes (with some modification) as an initial sort of starting point/template
  args.state.current_scene ||= :title_scene
  current_scene = args.state.current_scene

  case current_scene
  when :title_scene
    tick_title_scene args
  when :game_scene
    tick_game_scene args
  when :game_over_scene
    tick_game_over_scene args
  end

  if args.state.next_scene
    args.state.current_scene = args.state.next_scene
    args.state.next_scene = nil
  end
end

def tick_title_scene args
  args.audio[:title] ||= {
    input: 'sounds/title-theme.ogg',  # Filename
    x: 0.0, y: 0.0, z: 0.0,           # Relative position to the listener, x, y, z from -1.0 to 1.0
    gain: 1.0,                        # Volume (0.0 to 1.0)
    pitch: 1.0,                       # Pitch of the sound (1.0 = original pitch)
    paused: false,                    # Set to true to pause the sound at the current playback position
    looping: true,                    # Set to true to loop the sound/music until you stop it
  }
  args.audio[:play] ||= {
    input: 'sounds/game-play.ogg',    # Filename
    x: 0.0, y: 0.0, z: 0.0,           # Relative position to the listener, x, y, z from -1.0 to 1.0
    gain: 0.9 ,                        # Volume (0.0 to 1.0)
    pitch: 1.0,                       # Pitch of the sound (1.0 = original pitch)
    paused: true,                     # Set to true to pause the sound at the current playback position
    looping: true,                    # Set to true to loop the sound/music until you stop it
  }
  args.audio[:lost] ||= {
    input: 'sounds/you-lost.ogg',    # Filename
    x: 0.0, y: 0.0, z: 0.0,           # Relative position to the listener, x, y, z from -1.0 to 1.0
    gain: 0.9 ,                        # Volume (0.0 to 1.0)
    pitch: 1.0,                       # Pitch of the sound (1.0 = original pitch)
    paused: true,                     # Set to true to pause the sound at the current playback position
    looping: false,                    # Set to true to loop the sound/music until you stop it
  }
  # puts60 "sounds that are paused: #{args.audio.select { |_, sound| sound[:paused] == true }.length}"
  args.nokia.labels << { x: 43, y: 45, text: "DEPTH CHARGE", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
  args.nokia.labels << { x: 4, y: 38, text: "To move left or right", size_enum: NOKIA_FONT_TI, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: TINY_NOKIA_FONT_PATH }
  args.nokia.labels << { x: 4, y: 32, text: "use WASD or ARROWS", size_enum: NOKIA_FONT_TI, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: TINY_NOKIA_FONT_PATH }
  args.nokia.labels << { x: 4, y: 24, text: "Press down first to", size_enum: NOKIA_FONT_TI, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: TINY_NOKIA_FONT_PATH }
  args.nokia.labels << { x: 4, y: 18, text: "launch a depthcharge", size_enum: NOKIA_FONT_TI, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: TINY_NOKIA_FONT_PATH }
  args.nokia.labels << { x: 42, y: 9, text: "Let's Go !", size_enum: NOKIA_FONT_TI, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: TINY_NOKIA_FONT_PATH }
  args.nokia.borders << { x: 19, y: 3, w: 45, h: 8, a: 255 }

  if args.inputs.keyboard.key_up.space || args.inputs.keyboard.key_up.enter
    args.audio[:title].paused = true
    args.audio[:title].playtime = 0
    args.audio[:play].paused = false
    args.state.next_scene = :game_scene
    set_defaults args if args.state.defaults_set != true
  end
end

def tick_game_scene args
  args.state.score = 9999 if args.state.score > 9999
  args.nokia.labels  << { x: 1, y: 47, text: "#{(args.state.game_time/60).round}", size_enum: NOKIA_FONT_SM, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
  args.nokia.labels  << { x: 84, y: 47, text: "#{args.state.score}", size_enum: NOKIA_FONT_SM, alignment_enum: 2, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }

  if !args.inputs.keyboard.has_focus && args.state.tick_count != 0
    args.audio[:play].paused = true
    args.state.game_paused = true
    args.nokia.labels << { x: 42, y: 47, text: "PAUSED", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH } unless args.state.game_over == true
    draw_ship_sprite args
    draw_sub_bombs args
    draw_subs args
  else
    args.audio[:play].paused = false unless args.state.ship.state != :alive
    args.state.game_paused = false
  end

  if args.state.score >= 500 && args.state.bonus == false
    args.state.bonus = true
    args.state.game_time += args.state.bonus_time
  end

  if args.state.game_time < 0
    args.state.game_time = 0
    args.state.game_over = true
    args.audio[:play].playtime = 0
    args.audio[:play].paused = true
  end

  if args.state.game_paused == false && args.state.game_over == false
    if args.state.ship.state == :alive
      args.state.game_time -= 1
      args.state.game_tick_count += 1
    end
    if args.state.ship.state == :hit
      args.state.ship.y -= 1 if args.state.tick_count.zmod? 15
    end
    game_loop args
  else
    args.audio[:play].paused = true
    draw_stuff args
  end

  if args.inputs.keyboard.key_up.space || args.inputs.keyboard.key_up.enter || args.state.ship.y < 30 || args.state.game_over == true
    args.state.ship.state = :sunk
    args.audio[:play].playtime = 0
    args.audio[:play].paused = true
    args.state.next_scene = :game_over_scene
  end
end

def game_loop args
  move_ship_sprite args if args.state.tick_count.zmod? args.state.ship.speed # same as args.state.tick_count % args.state.ship.speed == 0
  draw_ship_sprite args
  move_subs args if args.state.tick_count.zmod? 2
  release_sub_bomb args if args.state.tick_count.zmod? 60
  draw_sub_bombs args
  explode_sub_bombs args if args.state.tick_count.zmod? 60
  move_sub_bombs args if args.state.tick_count.zmod? 60
  launch_barrels args
  draw_barrels args
  check_barrels_hit_subs args
  move_barrels args
  draw_subs args
  unpark_subs args if args.state.tick_count.zmod? 300
  show_barrels args
  show_sub_hit_count_bonus args
end

def check_barrels_hit_subs args
  a = args.state.subs.select { |s| s[:state] == :move }
  b = args.state.barrels.select { |b| b[:state] == :water }
  l = a.length
  i = 0
  while i < l
    collision = args.state.barrels.find { |b| b.intersect_rect? a[i] }
    if collision
      args.state.sub_hit_count_bonus += 1
      a[i].state = :park
      a[i].x = -10
      collision.state = :park
      collision.x = -10
      collision.y = 41
      collision.r = NOKIA_BG_COLOR.r
      collision.g = NOKIA_BG_COLOR.g
      collision.b = NOKIA_BG_COLOR.b
      collision.flip_horizontally = false
      collision.offset = 1
      collision.angle = 0
      case a[i].y
      when 30
        args.state.score += 10
      when 24
        args.state.score += 20
      when 18
        args.state.score += 50
      when 12
        args.state.score += 80
      when 6
        args.state.score += 100
      end 
    end
    i += 1
  end
end

def show_sub_hit_count_bonus args
  if args.state.sub_hit_count_bonus > 42
    args.state.sub_hit_count_bonus = 42
    args.state.score += 1000
  end
  args.state.sub_hit_count_bonus.each do |i|
    args.nokia.primitives << { x: (i * 4 + 1 < 82 ? i * 4 + 1 : (i - 21) * 4 + 1) , y: (i < 21 ? 1 : 3), w: 2, h: 1, path: :pixel, r: NOKIA_FG_COLOR.r, g: NOKIA_FG_COLOR.g, b: NOKIA_FG_COLOR.b}
  end
end

def show_barrels args
  return if args.state.game_over || args.state.game_paused
  loop = (args.state.barrels.select { |b| b[:state] == :park }.length > 6 ? 6 : args.state.barrels.select { |b| b[:state] == :park }.length)
  loop.each do |i|
    args.nokia.primitives << { x: i * 4 + 30, y: 44, w: 3, h: 2, path: :pixel, r: NOKIA_BG_COLOR.r, g: NOKIA_BG_COLOR.g, b: NOKIA_BG_COLOR.b}
  end
end

def draw_stuff args
  draw_ship_sprite args
  draw_sub_bombs args
  draw_barrels args
  draw_subs args
  show_sub_hit_count_bonus args
end

def move_ship_sprite args
  return unless args.state.ship.state == :alive && !args.nokia.keyboard.down
  args.state.ship.x -= 1 if args.nokia.keyboard.left
  args.state.ship.x += 1 if args.nokia.keyboard.right
  args.state.ship.x = 66 if args.state.ship.x > 66
  args.state.ship.x = 1 if args.state.ship.x < 1
end

def draw_ship_sprite args
  args.nokia.primitives << { x: args.state.ship.x, y: args.state.ship.y, w: 17, h: 6, path: 'sprites/ship_gray.png' }
  args.nokia.primitives << { x: 0, y: 0, w: 84, h: 36, r: NOKIA_BG_COLOR.r, g: NOKIA_BG_COLOR.g, b: NOKIA_BG_COLOR.b, primitive_marker: :solid }
end

def tick_game_over_scene args
  args.nokia.labels  << { x: 1, y: 47, text: "#{(args.state.game_time/60).round}", size_enum: NOKIA_FONT_SM, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
  args.nokia.labels  << { x: 84, y: 47, text: "#{args.state.score}", size_enum: NOKIA_FONT_SM, alignment_enum: 2, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
  args.nokia.labels << { x: 42, y: 47, text: "GAME OVER", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
  draw_stuff args

  if args.inputs.keyboard.key_up.space || args.inputs.keyboard.key_up.enter
    args.audio[:title].paused = false
    args.state.next_scene = :title_scene
    args.state.defaults_set = false
  end
end

def move_barrels args
  return unless args.state.tick_count.zmod? 6
  args.state.barrels.each do |barrel|
    next if barrel.state == :park
    case barrel.state
    when :air
      barrel.x -= barrel.offset * (barrel.flip_horizontally == true ? -1 : 1) 
      barrel.y -= 1
      if barrel.y < 39
        barrel.offset = 0
      end
      if barrel.y < 37
        barrel.state = :water
      end
    when :water
      if barrel.y == 36
        barrel.y = 34
        barrel.r = NOKIA_FG_COLOR.r
        barrel.g = NOKIA_FG_COLOR.g
        barrel.b = NOKIA_FG_COLOR.b
      else
        barrel.y -= 1 if args.state.tick_count.zmod? 60
      end
      if args.state.tick_count.zmod? 60
        if barrel.flip_horizontally == true
          barrel.angle -= 90
        else
          barrel.angle += 90 
        end
      end
    end
    if barrel.y < 0 
      barrel.y = 41
      barrel.x = -10
      barrel.state = :park
      barrel.r = NOKIA_BG_COLOR.r
      barrel.g = NOKIA_BG_COLOR.g
      barrel.b = NOKIA_BG_COLOR.b
      barrel.angle = 0
      barrel.flip_horizontally = false
      barrel.offset = 1
    end  
  end
end

def launch_barrels args 
  return unless args.nokia.keyboard.down && args.state.ship.state == :alive && args.state.barrels.select { |b| b[:state] == :park }.length >= 1
  if args.nokia.keyboard.left && ((args.state.tick_count - args.state.barrel_left) > 180) && args.state.ship.x > 6
    args.state.barrel_left = args.state.tick_count
    args.state.barrels.each do |barrel|
      if barrel.state == :park
        barrel.x = args.state.ship.x - 4
        barrel.state = :air
        break
      end
    end  
  end

  if args.nokia.keyboard.right && ((args.state.tick_count - args.state.barrel_right) > 180) && args.state.ship.x < 61
    args.state.barrel_right = args.state.tick_count
    args.state.barrels.each do |barrel|
      if barrel.state == :park
        barrel.x = args.state.ship.x + 18
        barrel.flip_horizontally = true
        barrel.state = :air
        break
      end
    end   
  end
end

def draw_barrels args
  args.nokia.primitives << args.state.barrels
end

def move_subs args
  a = args.state.subs
  l = a.length
  i = 0
  while i < l
    move_single_sub(args, a[i]) if (args.state.tick_count.zmod? a[i].s) && a[i].state == :move
    i += 1
  end
end

def unpark_subs args
  # change this to start at the deepest water, also only unpark one seb, then return
  a = args.state.subs
  l = a.length
  i = 0
  while i < l
    if a[i].state == :park
      break if i == 4 && rand < 0.2 # the topmost sub unparks less often
      unpark_sub(args, a[i])
      break
    end
    i += 1
  end
end

def unpark_sub(args, sub)
  sub.state = :move
  if rand < 0.5
    sub.x = 84
    sub.flip_horizontally = true
  else
    sub.x = -10
    sub.flip_horizontally = false
  end
end

def move_sub_bombs args
  args.state.sub_bombs.each do |bomb|
    bomb.flip_horizontally = !bomb.flip_horizontally
    bomb.y += 1
  end
end

def explode_sub_bombs args
  args.state.sub_bombs.each do |bomb|
    if bomb.y > 33
      args.state.sub_bombs = args.state.sub_bombs - [bomb]
      if bomb.x >= args.state.ship.x + 1 && bomb.x <= args.state.ship.x + 14 && args.state.ship.state == :alive
        args.state.ship.state = :hit
        args.audio[:play].paused = true
        args.audio[:lost].paused = false
      end
      explode_bomb(args, bomb)
    end
  end
end

def draw_sub_bombs args
  args.nokia.primitives << args.state.sub_bombs
end

def release_sub_bomb args
  # check if a sub is on the move, if it is check if it's in a certain range on the x axis, maybe rng now to decide should it release a bomb to float up
  args.state.subs.each do |sub|
    next unless sub.state == :move && sub.x > 1 && sub.x < 81 # only a sub moving in this range can potentially attack the ship
    release_bomb(args, sub) if args.state.sub_bombs.length < args.state.sub_bombs_maximum && (rand < (sub.y == 30 ? 0.3 : 0.15))
  end
end

def release_bomb(args, sub)
  args.state.sub_bombs << { x: sub.x, y: sub.y, w: 2, h: 2, path: "sprites/bomb.png", flip_horizontally: sub.flip_horizontally }
end

def explode_bomb(args, bomb)
end

def move_single_sub(args, sub)
  # multiple sprites inspiration from 03_rendering_sprites/01_animation_using_separate_pngs sample
  unless args.state.game_paused
    sub.path = "sprites/sub_gray_#{sub.start.frame_index frame_count: 4, hold_for: sub.hold, repeat: true}.png"
    sub.x += sub[:flip_horizontally] ? -1 : 1
    sub.state = :park if sub.x < -10 || sub.x > 84
  end
end

def draw_subs args
  args.nokia.primitives << args.state.subs
end

def new_bomb_explosion args
  { x: -10, y: 33, w: 10, h: 5, path: "sprites/explosion_0.png", flip_horizontally:  rand < 0.5, state: :park, start: args.state.game_tick_count }
end

def new_sub(args, coor_y, speed)
  { x: -10, y: coor_y, w: 10, h: 5, path: "sprites/sub_gray.png", s: speed * 4, flip_horizontally: rand < 0.5, state: :park, start: [0, 1, 3].sample * 30, hold: 30 + speed * 10 }
end

def new_barrel args
  { x: -10, y: 41, w: 3, h: 2, path: :pixel, r: NOKIA_BG_COLOR.r, g: NOKIA_BG_COLOR.g, b: NOKIA_BG_COLOR.b, angle: 0, state: :park, offset: 1 }
end

def set_defaults args
  args.state.defaults_set = true
  args.state.game_time = 60.seconds
  args.state.bonus_time = 45.seconds
  args.state.score = 0
  args.state.barrels_maximum = 6
  args.state.game_over = false
  args.state.bonus = false
  args.state.ship.state = :alive
  args.state.ship.speed = 6
  args.state.ship.x = 33
  args.state.ship.y = 36
  args.state.game_paused = false
  args.state.sub_bombs_maximum = 10
  args.state.game_tick_count = args.state.tick_count
  args.state.subs = 5.map { |i| new_sub(args, (i * 6) + 6, 5 - i)}
  args.state.bomb_explosions = 10.map { |i| new_bomb_explosion args}
  args.state.barrels = args.state.barrels_maximum.map { |i| new_barrel args}
  args.state.sub_hit_count_bonus = 0
  args.state.barrel_right = 0
  args.state.barrel_left = 0
  args.state.sub_bombs = []
end
