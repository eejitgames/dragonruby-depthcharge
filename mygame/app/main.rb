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
      draw_subs args
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
    move_subs args
    draw_subs args
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
end

def draw_ship_sprite args
  args.nokia.sprites << { x: args.state.ship_x, y: 36, w: 17, h: 6, path: 'sprites/ship_gray.png' }
  # args.nokia.sprites << { x: 42, y: 30, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 24, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 18, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 12, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 6, w: 10, h: 5, path: 'sprites/sub_gray.png' }
  # args.nokia.sprites << { x: 42, y: 0, w: 10, h: 5, path: 'sprites/sub_gray.png' }
end

def tick_game_over_scene args
  args.nokia.labels << { x: 42, y: 47, text: "GAME OVER", size_enum: NOKIA_FONT_SM, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255, font: NOKIA_FONT_PATH }

  if args.inputs.mouse.click
    args.state.next_scene = :title_scene
    args.state.defaults_set = false
  end
end

def move_subs args
  a = args.state.subs
  l = a.length
  i = 0
  while i < l
    move_single_sub(args, a[i]) if args.state.tick_count % a[i].s == 0
    i += 1
  end
end

def move_single_sub(args, sub)
  # multiple sprites inspiration from 03_rendering_sprites/01_animation_using_separate_pngs sample
  unless args.state.game_paused
    sub.x += 1
  end
  if sub[:s] > 0
    if sub.x > 84
      sub.x = -10 # sub.x = -1280 * rand
      # sub[:s] = 4 * rand + 1
    end
  else
    if sub.x < -128
      sub.x = 1280 * rand + 1280
      sub[:s] = -4 * rand
    end
  end
end

def draw_subs args
  args.nokia.sprites << args.state.subs
end

def new_sub(range_x, coor_y, speed)
  s = speed * 10
  #if rand < 0.5
  #  {
  #    x: ((range_x.randomize :ratio) * -1) - 128,
  #    y: coor_y,
  #    w: 10,
  #    h: 5,
  #    path: "sprites/sub_gray.png",
  #    s: 0.1,
  #    flip_horizontally: true
  #  }
  #else
    {
      x: 0, #(range_x.randomize :ratio) + 1280 + 128,
      y: coor_y,
      w: 10,
      h: 5,
      path: "sprites/sub_gray.png",
      s: s,
      flip_horizontally: false
    }
  #end
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
  args.state.subs = 5.map { |i| new_sub(1280, (i * 6) + 6, 6 - i)}
end