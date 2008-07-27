#!/usr/bin/env ruby

require 'optparse'
require 'set'

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
	def <=> (other)
		self.coords <=> other.coords
	end
	def inspect
		coords.inspect
	end
end

class Grid
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

	def new_neighbors(square)
		#neighbors of square that are not neighbors of any other polyomino square
		#assumes square is not yet in the polyomino
		old_neighbors=@squares.collect{|s| s.neighbors}.uniq
		return square.neighbors.reject{|s| old_neighbors.include?(s)}.reject{|s| s<self.origin}
	end
end

class RedelmeierAlgorithm
	attr_accessor :n, :d, :grid, :count
	def initialize(n,d)
		self.n=n
		self.d=d
	end

	def add_square(untried_set,new_square)
		new_untried_set=untried_set.dup
		new_neighbors=self.grid.new_neighbors(new_square)
		new_untried_set+=new_neighbors
		self.grid << new_square
		return new_untried_set
	end

	def run
                self.grid=Grid.new(self.d)
                untried_set=[grid.origin]
                self.count=[0]*self.n
                recurse(1,untried_set)
		return self
	end

	def recurse(current_size,untried_set)
# 		puts "new recursion with untried_set: #{untried_set.inspect}"
		while not untried_set.empty?
			new_square=untried_set.pop
			new_untried_set=add_square(untried_set,new_square)
			self.count[current_size-1]+=1
			recurse(current_size+1,new_untried_set) unless current_size>=self.n
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

options = parse_options
test = RedelmeierAlgorithm.new(options[:n], options[:d])
test.run.print_results unless options[:quiet]
