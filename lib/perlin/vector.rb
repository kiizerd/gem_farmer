module ExceptionForMatrix # :nodoc:
  class ErrDimensionMismatch < StandardError
    def initialize(val = nil)
      if val
        super(val)
      else
        super("Dimension mismatch")
      end
    end
  end

  class ErrNotRegular < StandardError
    def initialize(val = nil)
      if val
        super(val)
      else
        super("Not Regular Matrix")
      end
    end
  end

  class ErrOperationNotDefined < StandardError
    def initialize(vals)
      if vals.is_a?(Array)
        super("Operation(#{vals[0]}) can't be defined: #{vals[1]} op #{vals[2]}")
      else
        super(vals)
      end
    end
  end

  class ErrOperationNotImplemented < StandardError
    def initialize(vals)
      super("Sorry, Operation(#{vals[0]}) not implemented: #{vals[1]} op #{vals[2]}")
    end
  end
end

module CoercionHelper # :nodoc:
  #
  # Applies the operator +oper+ with argument +obj+
  # through coercion of +obj+
  #
  private def apply_through_coercion(obj, oper)
    coercion = obj.coerce(self)
    raise TypeError unless coercion.is_a?(Array) && coercion.length == 2
    coercion[0].public_send(oper, coercion[1])
  rescue
    raise TypeError, "#{obj.inspect} can't be coerced into #{self.class}"
  end

  #
  # Helper method to coerce a value into a specific class.
  # Raises a TypeError if the coercion fails or the returned value
  # is not of the right class.
  # (from Rubinius)
  #
  def self.coerce_to(obj, cls, meth) # :nodoc:
    return obj if obj.kind_of?(cls)
    raise TypeError, "Expected a #{cls} but got a #{obj.class}" unless obj.respond_to? meth
    begin
      ret = obj.__send__(meth)
    rescue Exception => e
      raise TypeError, "Coercion error: #{obj.inspect}.#{meth} => #{cls} failed:\n" \
                       "(#{e.message})"
    end
    raise TypeError, "Coercion error: obj.#{meth} did NOT return a #{cls} (was #{ret.class})" unless ret.kind_of? cls
    ret
  end

  def self.coerce_to_int(obj)
    coerce_to(obj, Integer, :to_int)
  end

  def self.coerce_to_matrix(obj)
    coerce_to(obj, Matrix, :to_matrix)
  end

  # Returns `nil` for non Ranges
  # Checks range validity, return canonical range with 0 <= begin <= end < count
  def self.check_range(val, count, kind)
    canonical = (val.begin + (val.begin < 0 ? count : 0))..
                (val.end ? val.end + (val.end < 0 ? count : 0) - (val.exclude_end? ? 1 : 0)
                         : count - 1)
    unless 0 <= canonical.begin && canonical.begin <= canonical.end && canonical.end < count
      raise IndexError, "given range #{val} is outside of #{kind} dimensions: 0...#{count}"
    end
    canonical
  end

  def self.check_int(val, count, kind)
    val = CoercionHelper.coerce_to_int(val)
    if val >= count || val < -count
      raise IndexError, "given #{kind} #{val} is outside of #{-count}...#{count}"
    end
    val
  end
end

module ConversionHelper # :nodoc:
  #
  # Converts the obj to an Array. If copy is set to true
  # a copy of obj will be made if necessary.
  #
  private def convert_to_array(obj, copy = false) # :nodoc:
    case obj
    when Array
      copy ? obj.dup : obj
    when Vector
      obj.to_a
    else
      begin
        converted = obj.to_ary
      rescue Exception => e
        raise TypeError, "can't convert #{obj.class} into an Array (#{e.message})"
      end
      raise TypeError, "#{obj.class}#to_ary should return an Array" unless converted.is_a? Array
      converted
    end
  end
end

class Vector
  include Enumerable
  include ExceptionForMatrix
  include CoercionHelper
  extend ConversionHelper
  #INSTANCE CREATION

  attr_reader :elements
  protected :elements

  #
  # Creates a Vector from a list of elements.
  #   Vector[7, 4, ...]
  #
  def Vector.[](*array)
    new convert_to_array(array, false)
  end

  #
  # Creates a vector from an Array.  The optional second argument specifies
  # whether the array itself or a copy is used internally.
  #
  def Vector.elements(array, copy = true)
    new convert_to_array(array, copy)
  end

  #
  # Returns a standard basis +n+-vector, where k is the index.
  #
  #    Vector.basis(size:, index:) # => Vector[0, 1, 0]
  #
  def Vector.basis(size:, index:)
    raise ArgumentError, "invalid size (#{size} for 1..)" if size < 1
    raise ArgumentError, "invalid index (#{index} for 0...#{size})" unless 0 <= index && index < size
    array = Array.new(size, 0)
    array[index] = 1
    new convert_to_array(array, false)
  end

  #
  # Return a zero vector.
  #
  #    Vector.zero(3) # => Vector[0, 0, 0]
  #
  def Vector.zero(size)
    raise ArgumentError, "invalid size (#{size} for 0..)" if size < 0
    array = Array.new(size, 0)
    new convert_to_array(array, false)
  end

  #
  # Vector.new is private; use Vector[] or Vector.elements to create.
  #
  def initialize(array)
    # No checking is done at this point.
    @elements = array
  end

  # ACCESSING

  #
  # :call-seq:
  #   vector[range]
  #   vector[integer]
  #
  # Returns element or elements of the vector.
  #
  def [](i)
    @elements[i]
  end
  alias element []
  alias component []

  #
  # :call-seq:
  #   vector[range] = new_vector
  #   vector[range] = row_matrix
  #   vector[range] = new_element
  #   vector[integer] = new_element
  #
  # Set element or elements of vector.
  #
  def []=(i, v)
    raise FrozenError, "can't modify frozen Vector" if frozen?
    if i.is_a?(Range)
      range = Matrix::CoercionHelper.check_range(i, size, :vector)
      set_range(range, v)
    else
      index = Matrix::CoercionHelper.check_int(i, size, :index)
      set_value(index, v)
    end
  end
  alias set_element []=
  alias set_component []=
  private :set_element, :set_component

  private def set_value(index, value)
    @elements[index] = value
  end

  private def set_range(range, value)
    if value.is_a?(Vector)
      raise ArgumentError, "vector to be set has wrong size" unless range.size == value.size
      @elements[range] = value.elements
    elsif value.is_a?(Matrix)
      raise ErrDimensionMismatch unless value.row_count == 1
      @elements[range] = value.row(0).elements
    else
      @elements[range] = Array.new(range.size, value)
    end
  end

  # Returns a vector with entries rounded to the given precision
  # (see Float#round)
  #
  def round(ndigits=0)
    map{|e| e.round(ndigits)}
  end

  #
  # Returns the number of elements in the vector.
  #
  def size
    @elements.size
  end

  #--
  # ENUMERATIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Iterate over the elements of this vector
  #
  def each(&block)
    return to_enum(:each) unless block_given?
    @elements.each(&block)
    self
  end

  #
  # Iterate over the elements of this vector and +v+ in conjunction.
  #
  def each2(v) # :yield: e1, e2
    raise TypeError, "Integer is not like Vector" if v.kind_of?(Integer)
    raise TypeError, "Float is not like Vector" if v.kind_of?(Float)
    raise ErrDimensionMismatch if size != v.size
    return to_enum(:each2, v) unless block_given?
    size.times do |i|
      yield @elements[i], v[i]
    end
    self
  end

  #
  # Collects (as in Enumerable#collect) over the elements of this vector and +v+
  # in conjunction.
  #
  def collect2(v) # :yield: e1, e2
    raise TypeError, "Integer is not like Vector" if v.kind_of?(Integer)
    raise ErrDimensionMismatch if size != v.size
    return to_enum(:collect2, v) unless block_given?
    Array.new(size) do |i|
      yield @elements[i], v[i]
    end
  end

  #--
  # PROPERTIES -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns whether all of vectors are linearly independent.
  #
  #   Vector.independent?(Vector[1,0], Vector[0,1])
  #   #  => true
  #
  #   Vector.independent?(Vector[1,2], Vector[2,4])
  #   #  => false
  #
  def Vector.independent?(*vs)
    vs.each do |v|
      raise TypeError, "expected Vector, got #{v.class}" unless v.is_a?(Vector)
      raise ErrDimensionMismatch unless v.size == vs.first.size
    end
    return false if vs.count > vs.first.size
    Matrix[*vs].rank.eql?(vs.count)
  end

  #
  # Returns whether all of vectors are linearly independent.
  #
  #   Vector[1,0].independent?(Vector[0,1])
  #   # => true
  #
  #   Vector[1,2].independent?(Vector[2,4])
  #   # => false
  #
  def independent?(*vs)
    self.class.independent?(self, *vs)
  end

  #
  # Returns whether all elements are zero.
  #
  def zero?
    all?(&:zero?)
  end

  #
  # Makes the matrix frozen and Ractor-shareable
  #
  def freeze
    @elements.freeze
    super
  end

  #
  # Called for dup & clone.
  #
  private def initialize_copy(v)
    super
    @elements = @elements.dup unless frozen?
  end


  #--
  # COMPARING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns whether the two vectors have the same elements in the same order.
  #
  def ==(other)
    return false unless Vector === other
    @elements == other.elements
  end

  def eql?(other)
    return false unless Vector === other
    @elements.eql? other.elements
  end

  #
  # Returns a hash-code for the vector.
  #
  def hash
    @elements.hash
  end

  #--
  # ARITHMETIC -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Multiplies the vector by +x+, where +x+ is a number or a matrix.
  #
  def *(x)
    case x
    when Numeric
      els = @elements.collect{|e| e * x}
      self.class.elements(els, false)
    when Vector
      raise ErrOperationNotDefined, ["*", self.class, x.class]
    else
      apply_through_coercion(x, __method__)
    end
  end

  #
  # Vector addition.
  #
  def +(v)
    case v
    when Vector
      raise ErrDimensionMismatch if size != v.size
      els = collect2(v) {|v1, v2|
        v1 + v2
      }
      self.class.elements(els, false)
    when Matrix
      Matrix.column_vector(self) + v
    else
      apply_through_coercion(v, __method__)
    end
  end

  #
  # Vector subtraction.
  #
  def -(v)
    case v
    when Vector
      raise ErrDimensionMismatch if size != v.size
      els = collect2(v) {|v1, v2|
        v1 - v2
      }
      self.class.elements(els, false)
    when Matrix
      Matrix.column_vector(self) - v
    else
      apply_through_coercion(v, __method__)
    end
  end

  #
  # Vector division.
  #
  def /(x)
    case x
    when Numeric
      els = @elements.collect{|e| e / x}
      self.class.elements(els, false)
    when Matrix, Vector
      raise ErrOperationNotDefined, ["/", self.class, x.class]
    else
      apply_through_coercion(x, __method__)
    end
  end

  def +@
    self
  end

  def -@
    collect {|e| -e }
  end

  #--
  # VECTOR FUNCTIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Returns the inner product of this vector with the other.
  #   Vector[4,7].inner_product Vector[10,1] # => 47
  #
  def inner_product(v)
    raise ErrDimensionMismatch if size != v.size

    p = 0
    each2(v) {|v1, v2|
      p += v1 * v2
    }
    p
  end
  alias_method :dot, :inner_product

  #
  # Returns the cross product of this vector with the others.
  #   Vector[1, 0, 0].cross_product Vector[0, 1, 0]  # => Vector[0, 0, 1]
  #
  # It is generalized to other dimensions to return a vector perpendicular
  # to the arguments.
  #   Vector[1, 2].cross_product # => Vector[-2, 1]
  #   Vector[1, 0, 0, 0].cross_product(
  #      Vector[0, 1, 0, 0],
  #      Vector[0, 0, 1, 0]
  #   )  #=> Vector[0, 0, 0, 1]
  #
  def cross_product(*vs)
    raise ErrOperationNotDefined, "cross product is not defined on vectors of dimension #{size}" unless size >= 2
    raise ArgumentError, "wrong number of arguments (#{vs.size} for #{size - 2})" unless vs.size == size - 2
    vs.each do |v|
      raise TypeError, "expected Vector, got #{v.class}" unless v.is_a? Vector
      raise ErrDimensionMismatch unless v.size == size
    end
    case size
    when 2
      Vector[-@elements[1], @elements[0]]
    when 3
      v = vs[0]
      Vector[ v[2]*@elements[1] - v[1]*@elements[2],
        v[0]*@elements[2] - v[2]*@elements[0],
        v[1]*@elements[0] - v[0]*@elements[1] ]
    else
      rows = self, *vs, Array.new(size) {|i| Vector.basis(size: size, index: i) }
      Matrix.rows(rows).laplace_expansion(row: size - 1)
    end
  end
  alias_method :cross, :cross_product

  #
  # Like Array#collect.
  #
  def collect(&block) # :yield: e
    return to_enum(:collect) unless block_given?
    els = @elements.collect(&block)
    self.class.elements(els, false)
  end
  alias_method :map, :collect

  #
  # Like Array#collect!
  #
  def collect!(&block)
    return to_enum(:collect!) unless block_given?
    raise FrozenError, "can't modify frozen Vector" if frozen?
    @elements.collect!(&block)
    self
  end
  alias map! collect!

  #
  # Returns the modulus (Pythagorean distance) of the vector.
  #   Vector[5,8,2].r # => 9.643650761
  #
  def magnitude
    Math.sqrt(@elements.inject(0) {|v, e| v + e.abs2})
  end
  alias_method :r, :magnitude
  alias_method :norm, :magnitude

  #
  # Like Vector#collect2, but returns a Vector instead of an Array.
  #
  def map2(v, &block) # :yield: e1, e2
    return to_enum(:map2, v) unless block_given?
    els = collect2(v, &block)
    self.class.elements(els, false)
  end

  class ZeroVectorError < StandardError
  end
  #
  # Returns a new vector with the same direction but with norm 1.
  #   v = Vector[5,8,2].normalize
  #   # => Vector[0.5184758473652127, 0.8295613557843402, 0.20739033894608505]
  #   v.norm # => 1.0
  #
  def normalize
    n = magnitude
    raise ZeroVectorError, "Zero vectors can not be normalized" if n == 0
    self / n
  end

  #
  # Returns an angle with another vector. Result is within the [0..Math::PI].
  #   Vector[1,0].angle_with(Vector[0,1])
  #   # => Math::PI / 2
  #
  def angle_with(v)
    raise TypeError, "Expected a Vector, got a #{v.class}" unless v.is_a?(Vector)
    raise ErrDimensionMismatch if size != v.size
    prod = magnitude * v.magnitude
    raise ZeroVectorError, "Can't get angle of zero vector" if prod == 0
    dot = inner_product(v)
    if dot.abs >= prod
      dot.positive? ? 0 : Math::PI
    else
      Math.acos(dot / prod)
    end
  end

  #--
  # CONVERTING
  #++

  #
  # Creates a single-row matrix from this vector.
  #
  def covector
    Matrix.row_vector(self)
  end

  #
  # Returns the elements of the vector in an array.
  #
  def to_a
    @elements.dup
  end

  #
  # Return a single-column matrix from this vector
  #
  def to_matrix
    Matrix.column_vector(self)
  end

  def elements_to_f
    warn "Vector#elements_to_f is deprecated", uplevel: 1
    map(&:to_f)
  end

  def elements_to_i
    warn "Vector#elements_to_i is deprecated", uplevel: 1
    map(&:to_i)
  end

  def elements_to_r
    warn "Vector#elements_to_r is deprecated", uplevel: 1
    map(&:to_r)
  end

  #
  # The coerce method provides support for Ruby type coercion.
  # This coercion mechanism is used by Ruby to handle mixed-type
  # numeric operations: it is intended to find a compatible common
  # type between the two operands of the operator.
  # See also Numeric#coerce.
  #
  def coerce(other)
    case other
    when Numeric
      return Matrix::Scalar.new(other), self
    else
      raise TypeError, "#{self.class} can't be coerced into #{other.class}"
    end
  end

  #--
  # PRINTING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #++

  #
  # Overrides Object#to_s
  #
  def to_s
    "Vector[" + @elements.join(", ") + "]"
  end

  #
  # Overrides Object#inspect
  #
  def inspect
    "Vector" + @elements.inspect
  end
end
