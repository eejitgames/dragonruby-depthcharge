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
    gain: 1.0,                        # Volume (0.0 to 1.0)
    pitch: 1.0,                       # Pitch of the sound (1.0 = original pitch)
    paused: true,                     # Set to true to pause the sound at the current playback position
    looping: true,                    # Set to true to loop the sound/music until you stop it
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
  args.nokia.solids  << { x: 0, y: 0, w: 84, h: 36 }
  args.nokia.labels  << { x: 1, y: 47, text: "#{(args.state.game_time/60).round}", size_enum: NOKIA_FONT_SM, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
  args.nokia.labels  << { x: 84, y: 47, text: "#{args.state.score}", size_enum: NOKIA_FONT_SM, alignment_enum: 2, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }

  if !args.inputs.keyboard.has_focus && args.state.tick_count != 0
      args.audio[:play].paused = true
      args.state.game_paused = true
      args.nokia.labels << { x: 42, y: 47, text: "PAUSED", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
      draw_ship_sprite args
      draw_sub_bombs args
      draw_subs args
    else
      args.audio[:play].paused = false
      args.state.game_paused = false
    if args.state.game_time < 0
      args.state.game_time = 0
      args.state.game_over = true
    else
      args.state.game_time -= 1
      args.state.game_tick_count += 1
      args.state.score += 1
      if args.state.score >= 500 && args.state.bonus == false
        args.state.bonus = true
        args.state.game_time += args.state.bonus_time
      end
      args.state.score = 9999 if args.state.score > 9999
    end
    move_ship_sprite args if args.state.tick_count.zmod? args.state.ship_speed # same as args.state.tick_count % args.state.ship_speed == 0
    draw_ship_sprite args
    unless args.state.game_over
      move_subs args if args.state.tick_count.zmod? 2
    end
    release_sub_bomb args if args.state.tick_count.zmod? 60
    draw_sub_bombs args
    explode_sub_bombs args if args.state.tick_count.zmod? 60
    move_sub_bombs args if args.state.tick_count.zmod? 60
    draw_subs args
    unpark_subs args if args.state.tick_count.zmod? 300
  end

  if args.inputs.keyboard.key_up.space || args.inputs.keyboard.key_up.enter
    args.audio[:play].playtime = 0
    args.audio[:play].paused = true
    args.state.next_scene = :game_over_scene
  end
end

def move_ship_sprite args
  args.state.ship_x -= 1 if args.nokia.keyboard.left
  args.state.ship_x += 1 if args.nokia.keyboard.right
  args.state.ship_x = 66 if args.state.ship_x > 66
  args.state.ship_x = 1 if args.state.ship_x < 1
end

def draw_ship_sprite args
  args.nokia.sprites << { x: args.state.ship_x, y: 36, w: 17, h: 6, path: 'sprites/ship_gray.png' }
end

def tick_game_over_scene args
  args.nokia.labels << { x: 42, y: 47, text: "GAME OVER", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }

  if args.inputs.keyboard.key_up.space || args.inputs.keyboard.key_up.enter
    args.audio[:title].paused = false
    args.state.next_scene = :title_scene
    args.state.defaults_set = false
  end
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
    args.state.sub_bombs = args.state.sub_bombs - [bomb] if bomb.y > 33
  end
end

def draw_sub_bombs args
  args.nokia.sprites << args.state.sub_bombs
end

def release_sub_bomb args
  # check if a sub is on the move, if it is check if it's in a certain range on the x axis, maybe rng now to decide should it release a bomb to float up
  args.state.subs.each do |sub|
    next unless sub.state == :move && sub.x > 1 && sub.x < 81 && sub.x % 2 == 0 # only a sub moving in this range can potentially attack the ship
    release_bomb(args, sub) if rand < 0.15
  end
end

def release_bomb(args, sub)
  args.state.sub_bombs << { x: sub.x, y: sub.y, w: 2, h: 2, path: "sprites/bomb.png", flip_horizontally: sub.flip_horizontally }
end

def move_single_sub(args, sub)
  # multiple sprites inspiration from 03_rendering_sprites/01_animation_using_separate_pngs sample
  unless args.state.game_paused
    sub.path = "sprites/sub_gray_#{sub.start.frame_index 4, sub.hold, true, args.state.game_tick_count}.png"
    if sub[:flip_horizontally]
      sub.x -= 1
      if sub.x < -10
        sub.x = 84
        sub.state = :park
      end
    else
      sub.x += 1
      if sub.x > 84
        sub.x = -10
        sub.state = :park
      end
    end
  end
end

def draw_subs args
  args.nokia.sprites << args.state.subs
end

def new_sub(args, coor_y, speed)
  s = speed * 4
  if rand < 0.5
    { x: 84, y: coor_y, w: 10, h: 5, path: "sprites/sub_gray.png", s: s, flip_horizontally: true, state: :park, start: [0, 1, 3].sample * 30, hold: 30 + s * 3 }
  else
    { x: -10, y: coor_y, w: 10, h: 5, path: "sprites/sub_gray.png", s: s, flip_horizontally: false, state: :park, start: [0, 1, 3].sample * 30, hold: 30 + s * 3 }
  end
end

def set_defaults args
  args.state.defaults_set = true
  args.state.game_time = 60.seconds
  args.state.bonus_time = 45.seconds
  args.state.score = 0
  args.state.barrels_maximum = 6
  args.state.barrels = 6
  args.state.game_over = false
  args.state.bonus = false
  args.state.ship_state = :alive
  args.state.ship_speed = 4
  args.state.ship_x = 33
  args.state.game_paused = false
  args.state.game_tick_count = args.state.tick_count
  args.state.subs = 5.map { |i| new_sub(args, (i * 6) + 6, 5 - i)}
  args.state.sub_bombs = []
end