require "./src/uby_interpreter"

gem 'minitest'
require 'minitest/autorun'

class TestUbyInterpreter < MiniTest::Test
	attr_accessor :int

	def setup
		self.int = UbyInterpreter.new
	end

	def assert_eval exp, src, msg = nil
		assert_equal exp, int.eval(src), msg
	end

	def test_sanity
		assert_eval 3, "3"
		assert_eval 7, "3 + 4"
	end

    def test_if
        assert_eval 42, "if true then 42 else 24 end"
    end

    def test_if_falsy
        assert_eval 24, "if false then 41 else 24 end"
    end
 
    def test_lvar
        assert_eval 42, "x = 42; x"        
    end

    def test_defn
        assert_eval nil, <<-EOM
            def double n
                2 * n
            end
        EOM

        assert_eval 42, "double(21)"

    end

    def define_fib
        assert_eval nil, <<-EOM
            def fib n
                if n <= 2 
                    1
                else
                    fib(n-2) + fib(n-1)
                end
            end
        EOM
    end

    def test_fib
        define_fib

        assert_eval 8, "fib(6)"        
    end

    def test_while_sum_of_fibs
        define_fib

        assert_eval 1+1+2+3+5+8+13+21+34+55, <<-EOM
            n = 1
            sum = 0
            while n <= 10
                sum += fib(n)
                n = n + 1
            end
            sum
        EOM
    end
end

