INPUT_TIMEOUT = 5

def render_ui
  [480, 40, 320, 680, 192, 0, 192, 128].solid
end

def init_field
  Array.new(10) {
    Array.new(20)
  }
end

def render_block(x, y, type)
  origin_x = 480
  origin_y = 40
  block_size = 32
  [origin_x + x * block_size, origin_y + block_size * y, block_size, block_size, "blocks/#{type}.png"].sprite
end

def render_field(field)
  field.each.with_index.flat_map { |column, x|
    column.each.with_index.map { |type, y|
      render_block(x, y, type) if type
    }
  }.compact
end

def render_tetromino(t)
  t.positions.map { |p|
    render_block(p.x, p.y, t.type)
  }
end

def random_type
  %i[blue darkgray gray green lightblue orange pink purple red red2 white].sample
end

def random_shape
  [
    [[-1, 0], [0, 0], [1, 0], [2, 0]]
  ].sample
end

Tetromino = Struct.new(:position, :shape, :type) do
  def positions
    shape.map { |x, y| [position.x + x, position.y + y] }
  end

  def colliding?(field)
    positions.any? { |p| p.y < 0 || p.x < 0 || p.x > 9 || field[p.x][p.y]  }
  end

  def in_direction(dir)
    Tetromino.new([position.x + dir.x, position.y + dir.y], shape, type)
  end
end

def setup_next_block(args)
  args.state.current_block = nil
  args.state.next_block_tick = args.state.tick_count + 1.seconds
end

def setup(args)
  args.state.field = init_field
  setup_next_block(args)
  args.state.next_sink_tick = 0
  args.state.sink_interval = 90
  args.state.next_move_possible_tick = 0
end

def process_input(args)
  args.state.input_direction = args.inputs.keyboard.directional_vector
  args.state.input_direction.y = 0 if args.state.input_direction && args.state.input_direction.y > 0
end

def create_new_block_if_needed(args)
  return unless args.state.current_block.nil?

  if args.state.tick_count >= args.state.next_block_tick
    args.state.current_block = Tetromino.new([4, 19], random_shape, random_type)
    args.state.next_sink_tick = args.state.tick_count + args.state.sink_interval
  end
end

def handle_move(args)
  return unless args.state.current_block && args.state.input_direction && args.state.tick_count >= args.state.next_move_possible_tick

  if args.state.input_direction.y < 0
    args.state.next_sink_tick = [args.state.next_sink_tick, args.state.tick_count + 5].min
  else
    next_position = args.state.current_block.in_direction(args.state.input_direction)
    args.state.current_block = next_position unless next_position.colliding?(args.state.field)
  end
  args.state.next_move_possible_tick = args.state.tick_count + INPUT_TIMEOUT
end

def handle_block_sink(args)
  return unless args.state.current_block && args.state.tick_count >= args.state.next_sink_tick

  next_position = args.state.current_block.in_direction([0, -1])
  if next_position.colliding?(args.state.field)
    args.state.current_block.positions.each do |p|
      args.state.field[p.x][p.y] = args.state.current_block.type
    end

    setup_next_block(args)
  else
    args.state.current_block = next_position
    args.state.next_sink_tick = args.state.tick_count + args.state.sink_interval
  end
end

def calc(args)
  create_new_block_if_needed(args)
  handle_move(args)
  handle_block_sink(args)
end

def render(args)
  args.outputs.background_color = [0, 0, 0, 255]
  args.outputs.primitives << render_ui
  args.outputs.primitives << render_field(args.state.field)
  args.outputs.primitives << render_tetromino(args.state.current_block) if args.state.current_block
end

def tick(args)
  setup(args) if args.state.tick_count.zero?
  process_input(args)
  calc(args)
  render(args)
end
