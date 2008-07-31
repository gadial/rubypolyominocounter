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
		@squares=[]
	end
	def origin
		return Square.new([0]*@dimensions)
	end
	def << (square)
		@squares << square
		@squares.uniq!
	end
	def remove_square(square)
		squares.delete(square)
	end
	def new_neighbors(square)
		#neighbors of square that are not neighbors of any other polyomino square
		#assumes square is not yet in the polyomino
		old_neighbors=@squares.collect{|s| s.neighbors}.flatten.uniq
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
#   		puts "new recursion with untried_set: #{untried_set.inspect}"
		while not untried_set.empty?
			new_square=untried_set.pop
#  			puts "current polyomino: #{self.grid.squares.inspect}, adding: #{new_square.inspect}"
			new_untried_set=add_square(untried_set,new_square)
			self.count[current_size-1]+=1
			self.polyominoes[current_size-1] << self.grid.squares.dup
			recurse(current_size+1,new_untried_set) unless current_size>=self.n
			self.grid.remove_square(new_square)
		end
	end
	def print_results
#		puts self.polyominoes[3].inspect
		puts count.inspect
	end
end

test=RedelmeierAlgorithm.new(10,3)
test.counts_tree_polyominoes=true
test.run.print_results

