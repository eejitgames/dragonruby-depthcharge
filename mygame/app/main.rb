$gtk.reset

require 'app/nokia.rb'

def tick args
  # using both samples/99_genre_lowrez/nokia_3310 and
  # samples/02_input_basics/07_managing_scenes (with some modification)
  # as an initial sort of starting point/template
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
  args.nokia.labels << { x: 43, y: 47, text: "DEPTH CHARGE", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }

  if args.inputs.mouse.click
    args.state.next_scene = :game_scene
    set_defaults args if args.state.defaults_set != true
  end
end

def tick_game_scene args
  args.nokia.solids  << { x: 0, y: 0, w: 84, h: 36 }
  args.nokia.labels  << { x: 1, y: 47, text: "#{(args.state.game_time/60).round}", size_enum: NOKIA_FONT_SM, alignment_enum: 0, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
  args.nokia.labels  << { x: 84, y: 47, text: "#{args.state.score}", size_enum: NOKIA_FONT_SM, alignment_enum: 2, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }

  if !args.inputs.keyboard.has_focus && args.state.tick_count != 0
      args.state.game_paused = true
      args.nokia.labels << { x: 42, y: 47, text: "PAUSED", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }
      draw_ship_sprite args
    else
      args.state.game_paused = false
    if args.state.game_time < 0
      args.state.game_time = 0
      args.state.game_over = true
    else
      args.state.game_time -= 1
      args.state.score += 1
      if args.state.score >= 500 && args.state.bonus == false
        args.state.bonus = true
        args.state.game_time += args.state.bonus_time
      end
      args.state.score = 9999 if args.state.score > 9999
    end
    move_ship_sprite args if args.state.tick_count % args.state.ship_speed == 0
    draw_ship_sprite args
  end

  if args.inputs.mouse.click
    args.state.next_scene = :game_over_scene
  end
end

def move_ship_sprite args
  args.state.ship_x -= 1 if args.nokia.keyboard.left
  args.state.ship_x += 1 if args.nokia.keyboard.right
  args.state.ship_x = 66 if args.state.ship_x > 66
  args.state.ship_x = 1 if args.state.ship_x < 1

  args.audio[:boat] = nil
  args.audio[:boat] = {
  input: 'sounds/boat.ogg',       # Filename
  x: 0.0, y: 0.0, z: 0.0,         # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 1.0,                      # Volume (0.0 to 1.0)
  pitch: 1.0,                     # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: true,                  # Set to true to loop the sound/music until you stop it
  }
end

def draw_ship_sprite args
  args.nokia.sprites << { x: args.state.ship_x, y: 36, w: 17, h: 6, path: 'sprites/ship_gray.png' }
  # args.nokia.sprites << { x: args.state.ship_x, y: 36, w: 17, h: 6, path: 'sprites/ship_harsh.png' }
  # args.nokia.sprites << { x: args.state.ship_x, y: 36, w: 17, h: 6, path: 'sprites/ship_original.png' }
  # args.nokia.sprites << { x: 42, y: 30, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 24, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 18, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 12, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  args.nokia.sprites << { x: 42, y: 6, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 6, w: 10, h: 5, path: 'sprites/sub_harsh.png' }
  # args.nokia.sprites << { x: 42, y: 6, w: 10, h: 5, path: 'sprites/sub_original.png' }
  # args.nokia.sprites << { x: 42, y: 0, w: 10, h: 5, path: 'sprites/sub_gray.png' }
end

def tick_game_over_scene args
  args.nokia.labels << { x: 42, y: 47, text: "GAME OVER", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }

  # args.audio.delete(:boat)
  # args.audio[:boat] = nil

  if args.inputs.mouse.click
    args.state.next_scene = :title_scene
    args.state.defaults_set = false
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

  args.audio[:boat] = {
  input: 'sounds/boat.ogg',       # Filename
  x: 0.0, y: 0.0, z: 0.0,         # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 1.0,                      # Volume (0.0 to 1.0)
  pitch: 1.0,                     # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: true,                  # Set to true to loop the sound/music until you stop it
  }
end