require 'pp'
class Game
  attr_accessor :board
  def initialize
    args = read_args
    @board = Board.new(args[0])
    parse_file(args[1])
  end
  
  def parse_file(file_name)
   File.readlines(file_name).each do |line|
     if line.size > 3
       parse_file_line(line)
     end
   end
  end
  
  def parse_file_line(line)
    c = line.split.map {|x| x.upcase.ord - 64}
    start_x = c[0]
    start_y = c[1]
    end_x = c[2]
    end_y = c[3]
    length_y = (start_y - end_y).abs
    length_x = (start_x - end_x).abs
    start_s = start_x, start_y
    start_e = end_x, end_y
    length = 0
    orientation = nil

    if length_y == 0
      length = length_x + 1
      orientation = "vertical"
    else
      length = length_y + 1
      orientation = "horizontal"
    end

    if start_y < end_y || start_x < end_x
      start = start_s
    elsif start_y > end_y || start_x > end_x
      start = start_e 
    end
    
    @board.paint_ship(start[0], start[1],  length, orientation)
  end
  
  def read_args
    begin
      unless ARGV[0].to_i.integer?
        raise StandardError, 'First argument must be an integer'
      end
      if ARGV.size != 2
        raise StandardError, 'Wrong number of arguments, must have board size and filename'
      elsif ARGV[0].to_i < 5 || ARGV[0].to_i > 26
        raise StandardError, 'Board size must be at least 5x5 and no greater than 26x26'
      end
      
      [ARGV[0].to_i, ARGV[1]]
    end
  end
  
  def prompt
    print "> "
    $stdin.gets.upcase
  end
  
  def hit_stats(x, y)
    100.00 * x / y
  end
  
  def print_help
    puts "Possible commands:\n" +
         "board - displays the user's board\n" +
         "ships - displays the placement of the ships\n" +
         "fire r c - fires a missile at the cell at [r, c]\n" +
         "stats - prints out the game statistics\n" +
         "quit - exits the game"
  end
  
  def play
    hits = 0
    total_missiles = 0
    
    while true
      input = prompt
      if input.include? "FIRE"
        puts "> #{input}"
        ar = input.split
        is_hit = @board.fire("#{ar[1]}", "#{ar[2]}")
        is_sunk = @board.ships_hit
        @board.printboard(true)
        total_missiles += 1
        if is_hit
          hits += 1
          puts "Hit!"
        end
        if is_sunk
          puts "Sunk!"
          if @board.win?
            puts "You win!"
            false
          end
        end
      elsif input.include? "SHIPS"
        @board.printboard(false)
      elsif input.include? "STATS"
        puts hit_stats(hits, total_missiles)
      elsif input.include? "HELP"
        print_help
      end
    end
  end

end

class Cell
  attr_reader :label
  def initialize(label)
    @label = label
  end
  
  def to_s
    @label
  end
  
  def fired_at!
    udpate_cell()
  end
  
end

class Water_Cell < Cell
  def initialize
    super("~")
  end
  def update_cell
    @label = "O"
  end
end


class Ship < Cell
  
  def initialize(label)
    super(label)
  end
  def update_cell
    @label = "X"
  end
  def hide
    @label = "~"
  end
  
end
  

class Board
  def initialize(size)
    @boardsize = size
    @board = build_board
    @ship_count = 0
    @ship_cell_label = {}
    @ship_groups = {}
  end
  
  
  def boardrange_h
    range_end = (@boardsize + 64).chr
    ('A'..range_end).to_a.unshift(" ")
  end
  
  def boardrange_v
    boardrange_h.shift
  end
  
  def build_board
    ar = Array.new(@boardsize) { Array.new(@boardsize) }
    fill_water(ar)
  end
  
  def fill_water(ar)
    ar.each do |x|
      x.collect!{ |i| i =  Water_Cell.new}
    end
    ar
  end
  
  def printboard(hide_ships)
    r = 'A'
    puts boardrange_h.join(" ")
    
    @board.each do |row|
      row_string = row.join(" ")
      row_string.gsub!(/[^XO~ ]/, '~') if hide_ships
      print "#{r} " + row_string
      puts
      r = r.next
    end
  end
  
  def paint_cell(x, y, cell)
    @board[x][y] = cell
  end
  
  def paint_ship(x, y, length, orientation)
    label = (65 + @ship_count).chr
    @ship_count += 1
    puts " #{x} : #{y} : #{length} : #{label}"
    if orientation == "vertical"
      length.times do
        paint_cell(x, y, Ship.new(label) )
        x += 1
      end
    else
      length.times do
        paint_cell(x, y, Ship.new(label) )
        y += 1
      end
    end
    @ship_groups[label] = length
  end
  
  def fire row, column
    puts "#{row}, #{column}"
    x = row.ord - 65
    y = column.ord - 65
    puts "#{x}, #{y}"
    cell = @board[x][y]
    label = cell.label
    cell.fired_at!(true)
    if cell.class == Ship
      new_val = @ship_groups[label].to_i - 1
      @ship_groups[label] = new_val
      true
    end
  end
  
  def ships_hit
    pp @ship_groups
    sunk = @ship_groups.has_value?(0)
    @ship_groups.delete_if {|key, value| value == 0}
    sunk
  end
  
  def win?
    @ship_groups.empty?
  end

end

g = Game.new
board = g.board
board.printboard(true)
g.play
board.printboard(true)
