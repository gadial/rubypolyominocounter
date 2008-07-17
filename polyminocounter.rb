class Square
	include comparable
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
end

class Grid
	def initialize(dimensions)
		@dimensions=dimensions
	end
	def origin
		return Square.new([0]*@dimensions)
	end
	def << (square)
	end
end

class RedelmeierAlgorithm
	attr_accessor :n, :d, :grid, :count
	def initialize(n,d)
		self.n=n
		self.d=d
	end

	def run
          self.grid=Grid.new(d)
          untried_set=[grid.origin]
          self.count=[0]*n
          recurse(0,untried_set)
	end

	def recurse(current_size,untried_set)
		while not untried_set.empty?
			new_square=untried_set.pop
			new_untried_set=grid.modify_untried_set(untried_set,new_square)
			self.grid << new_square
			current_size+=1
			self.count[current_size]+=1
			recurse(current_size,new_untried_set) unless current_size>=self.n
		end
	end
	def print_results
		puts count.inspect
	end
end