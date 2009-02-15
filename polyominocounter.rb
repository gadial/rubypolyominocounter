#!/usr/bin/env ruby

require 'optparse'
require 'set'
require 'rubygems'
require 'RMagick'
#require 'profile'
class Array
	def count_item(x)
		self.inject(0){|sum, item| x==item ? sum+1 : sum}
	end
	def count_items(items_array)
		self.inject(0){|sum, item| sum+items_array.count_item(item)}
	end
end

class Set
	def to_s
		self.to_a.inspect
	end
end

class Square
	@@neighbors=Hash.new #optimization
	include Comparable
	attr_accessor :coords
	def initialize(coords)
		self.coords=coords
		@my_hash=self.coords.hash
	end
	def calculate_neighbors(cylinder_width = nil)
		neighbors_array=[]
		self.coords.each_index do |i|
			temp_coords=self.coords.dup
			temp_coords[i] +=1
			if cylinder_width and i==1 and temp_coords[i] == cylinder_width
				temp_coords[i] = 0
				temp_coords[i-1] += 1
			end
			neighbors_array << Square.new(temp_coords)

			temp_coords=self.coords.dup
			temp_coords[i] -=1
			if cylinder_width and i==1 and temp_coords[i] < 0
				temp_coords[i] = cylinder_width-1
				temp_coords[i-1] -= 1
			end
			neighbors_array << Square.new(temp_coords)
		end
		return neighbors_array
	end
	def neighbors(cylinder_width = nil)
		@@neighbors[self]||=calculate_neighbors(cylinder_width) #optimization
	end
	def hash
		@my_hash #optimization
# 		return self.coords.hash
	end
	def eql?(other)
		return self.coords==other.coords
	end
	def ==(other)
		return self.coords==other.coords
	end
	def <=> (other)
		self.coords <=> other.coords
	end
	def inspect
		coords.inspect
	end
	def x
		self.coords[1]
	end
	def y
		self.coords[0]
	end
		def Square.draw(gc, x, y, square_size, color)
			gc.fill(color)
			gc.polygon(	x*square_size,y*square_size,
					(x+1)*+square_size,y*square_size,
					(x+1)*square_size,(y+1)*square_size,
					x*square_size,(y+1)*square_size)
	end
end

class Grid
	attr_reader :squares, :cylinder_width
	def initialize(dimensions, cylinder_width)
		@dimensions=dimensions
		@squares = Set.new
		@cylinder_width = cylinder_width
	end
	def origin
		return Square.new([0]*@dimensions)
	end
	def << (square)
		case square
		when Square:	@squares << square
		when Array:	@squares << Square.new(square)
		end
		return self
	end
	def remove_square(square)
		squares.delete(square)
	end

        def to_s
            raise "Cannot visualize non-2D grid" unless @dimensions == 2
            cols = @squares.collect { |sqr| sqr.coords[0] }.max + 1
            rows = @squares.collect { |sqr| sqr.coords[1] }.max + 1
            display_arr = []
            rows.times do
            display_arr << Array.new(cols)
            end

            @squares.each do |sqr|
            display_arr[sqr.coords[1]][sqr.coords[0]] = true
            end

            display_arr.collect do |row|
            row.collect do |col|
                if col
                "x"
                else
                "."
                end
            end.join("")
            end.join("\n")
        end

	def new_neighbors(square)
		#neighbors of square that are not neighbors of any other polyomino square
		#assumes square is not yet in the polyomino
		old_neighbors=@squares.collect{|s| s.neighbors(@cylinder_width)}.flatten.uniq
		return square.neighbors(@cylinder_width).reject{|s| old_neighbors.include?(s) or @squares.include?(s) or s<self.origin}
	end
	def bounding_rect
		raise "Bounding rect too complex in more than 2 dimensions" unless @dimensions == 2
		min_x = self.squares.min{|a,b| a.x <=> b.x}.x
		min_y = self.squares.min{|a,b| a.y <=> b.y}.y
                max_x = self.squares.max{|a,b| a.x <=> b.x}.x
                max_y = self.squares.max{|a,b| a.y <=> b.y}.y
                max_x = [max_x, 3].max
                max_y = [max_y, 3].max
                min_x = [min_x, -3].min
                max_x = self.cylinder_width if self.cylinder_width
                min_x = -1 if self.cylinder_width
		[min_x, min_y, max_x, max_y]
	end
	def draw(square_size, bold = true)
		raise "Cannot draw in more than 2 dimensions" unless @dimensions == 2
		gc = Magick::Draw.new
		gc.stroke('black')
		stroke_width = (bold)?(6):(1)
		gc.stroke_width(stroke_width)

		min_x,min_y,max_x,max_y = bounding_rect
		gc.translate(-1*min_x*square_size, -1*min_y*square_size)
		min_x.upto(max_x) do |x|
			min_y.upto(max_y) do |y|
				color = 'white'
				color = 'blue' if self.cylinder_width and (x == -1 or x == self.cylinder_width)
				Square.draw(gc,x,y,square_size,color)
			end
		end
		self.squares.each do |square|
			x=square.x; y=square.y
			Square.draw(gc, x,y, square_size, 'red')
		end

		canvas = Magick::Image.new(1+square_size*(max_x-min_x+1),1+square_size*(max_y-min_y+1)){self.background_color = 'transparent'}
		gc.draw(canvas)
		canvas.flip
	end
end

class RedelmeierAlgorithm
	attr_accessor :n, :d, :grid, :count, :polyominoes, :counts_tree_polyominoes, :verbose, :graphic, :polyomino_images
	def initialize(options)
		self.n=options[:n]
		self.d=options[:d]
		self.counts_tree_polyominoes=(options[:trees]==true)
		self.verbose=options[:verbose]
		self.graphic = options[:graphic]
		self.polyomino_images = Magick::ImageList.new
		self.grid=Grid.new(self.d,options[:cylinder])
	end

	def add_square(untried_set,new_square)
		new_untried_set=untried_set.dup
		new_neighbors=self.grid.new_neighbors(new_square)
		new_untried_set+=new_neighbors
		self.grid << new_square
# 		new_untried_set.reject!{|s| self.grid.squares.collect{|x| x.neighbors}.flatten.count_item(s)>1} if self.counts_tree_polyominoes
		new_untried_set.reject!{|s| s.neighbors(self.grid.cylinder_width).count_items(self.grid.squares.to_a)>1} if self.counts_tree_polyominoes
		return new_untried_set
	end

	def run
                untried_set=[grid.origin]
                self.count=[0]*self.n
		if self.verbose
			self.polyominoes=[]
			n.times {|i| self.polyominoes[i]=[]}
		end
                recurse(1,untried_set)
		return self
	end

	def recurse(current_size,untried_set)
# 		puts "new recursion with untried_set: #{untried_set.inspect}"
		while not untried_set.empty?
			new_square=untried_set.pop
			new_untried_set=add_square(untried_set,new_square)
			self.count[current_size-1]+=1
			self.polyominoes[current_size-1] << self.grid.squares.dup.to_a.sort if self.verbose
			self.polyomino_images << self.grid.draw(40) if self.graphic
			recurse(current_size+1,new_untried_set) unless current_size>=self.n
			self.grid.remove_square(new_square)
		end
	end
	def print_results
		puts count.inspect
		if self.verbose
                  File.open("polyomino_list_#{algorithm_summary_text}.txt","w") do |file|
                          self.polyominoes.each_index do |i|
#                                   file.puts("Polyominoes of size #{i+1}:")
                                  self.polyominoes[i].each{|x| file.puts(x.inspect)}
                          end
                  end
                end
                if self.graphic
			self.polyomino_images.delay = 100
			self.polyomino_images.write("images/polyomino.png")
                end
	end
	def algorithm_summary_text
		"#{self.n}-#{self.d}-d#{self.counts_tree_polyominoes ? "-trees" : ""}"
	end
end

def parse_options
  options = {}

  opts = OptionParser.new
  opts.on("-q", "--quiet") do
    options[:quiet] = true
  end
  opts.on("-t", "--trees") do
	options[:trees] = true
  end
  opts.on("-n N", "(mandatory)", Integer) do |n|
    options[:n] = n
  end
  opts.on("-d D", "(mandatory)", Integer) do |d|
    options[:d] = d
  end
  opts.on("-v", "--verbose") do
	options[:verbose]=true
  end
  opts.on("-c W", "--cylinder") do |w|
	options[:cylinder]=w.to_i
  end
  opts.on("-g", "--graphic") do
	options[:graphic] = true
  end

  begin
    opts.parse!
    raise unless options[:n] and options[:d]
  rescue
    puts opts
    exit 1
  end

  options
end

if $0 == __FILE__
  options = parse_options
  test = RedelmeierAlgorithm.new(options)
  test.run.print_results unless options[:quiet]
end
