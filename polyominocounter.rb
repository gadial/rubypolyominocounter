#!/usr/bin/env ruby

require 'optparse'
require 'set'

class Array
	def count_item(x)
		self.inject(0){|sum, item| x==item ? sum+1 : sum}
	end
end

class Square
	include Comparable
	attr_accessor :coords
	def initialize(coords)
		self.coords=coords
	end
	def neighbors
		neighbors_array=[]
		self.coords.each_index do |i|
			temp_coords=self.coords.dup
			temp_coords[i] +=1
			neighbors_array << Square.new(temp_coords)

			temp_coords=self.coords.dup
			temp_coords[i] -=1
			neighbors_array << Square.new(temp_coords)
		end
		return neighbors_array
	end
	def hash
		return self.coords.hash
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
end

class Grid
	attr_reader :squares
	def initialize(dimensions)
		@dimensions=dimensions
		@squares = Set.new
	end
	def origin
		return Square.new([0]*@dimensions)
	end
	def << (square)
		@squares << square
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
		old_neighbors=@squares.collect{|s| s.neighbors}.uniq
		return square.neighbors.reject{|s| old_neighbors.include?(s) or @squares.include?(s) or s<self.origin}
	end
end

class RedelmeierAlgorithm
	attr_accessor :n, :d, :grid, :count, :polyominoes, :counts_tree_polyominoes
	def initialize(n,d)
		self.n=n
		self.d=d
		self.counts_tree_polyominoes=false
	end

	def add_square(untried_set,new_square)
		new_untried_set=untried_set.dup
		new_neighbors=self.grid.new_neighbors(new_square)
		new_untried_set+=new_neighbors
		self.grid << new_square
		new_untried_set.reject!{|s| self.grid.squares.collect{|x| x.neighbors}.flatten.count_item(s)>1} if self.counts_tree_polyominoes
		return new_untried_set
	end

	def run
                self.grid=Grid.new(self.d)
                untried_set=[grid.origin]
                self.count=[0]*self.n
				self.polyominoes=[]
				n.times {|i| self.polyominoes[i]=[]}
                recurse(1,untried_set)
		return self
	end

	def recurse(current_size,untried_set)
# 		puts "new recursion with untried_set: #{untried_set.inspect}"
		while not untried_set.empty?
			new_square=untried_set.pop
			new_untried_set=add_square(untried_set,new_square)
			self.count[current_size-1]+=1
			self.polyominoes[current_size-1] << self.grid.squares.dup
			recurse(current_size+1,new_untried_set) unless current_size>=self.n
			self.grid.remove_square(new_square)
		end
	end
	def print_results
		puts count.inspect
	end
end

def parse_options
  options = {}

  opts = OptionParser.new
  opts.on("-q", "--quiet") do
    options[:quiet] = true
  end
  opts.on("-n N", "(mandatory)", Integer) do |n|
    options[:n] = n
  end
  opts.on("-d D", "(mandatory)", Integer) do |d|
    options[:d] = d
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
  test = RedelmeierAlgorithm.new(options[:n], options[:d])
  test.run.print_results unless options[:quiet]
end
