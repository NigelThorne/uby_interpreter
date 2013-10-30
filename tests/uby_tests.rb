require "minitest/autorun"
require "ruby_parser"
require "sexp_processor"


class UbyInterpreter < SexpInterpreter
	VERSION = "1.0.0"
    attr_accessor :parser
    attr_accessor :env

    def initialize
        super 

        self.parser = Ruby19Parser.new
        self.env = Environment.new
    end

    def eval src
        process(parse(src))        
    end

    def parse src 
        self.parser.process(src)
    end

    def process_lit s
        s.last
    end

    def process_call s
        _, recv, msg, *args = s

        recv = process recv
        args.map!{ |sub| process sub }

        if recv
            recv.send(msg, *args)  #HACK
        else
            self.env.scope do
                decls, body = self.env[msg]

                decls.rest.zip(args).each do |name,val| 
                    self.env[name] = val
                end

                process_block s(:block, *body)
            end
        end
    end

    def process_if s
        _, c, t, f = s

        c = process c

        if(c)
            process t
        else
            process f
        end
    end

    def process_block s
        result = nil
        s.rest.each do |sub|
            result = process sub
        end
        result
    end

    def process_lasgn s
        _, var, val = s

        self.env[var] = process val
    end

    def process_lvar s
        self.env[s.last]
    end

    def process_defn s
        _, n, args, *body = s

        self.env[n] = [args, body]
        nil
    end

    def process_while s
        _, cond, *body, _ = s

        while( process cond )
            process_block s(:block, *body)
        end
    end

    def process_true s
        true
    end

    def process_false s
        false
    end


    class Environment    
        def [] k
            self.all[k]
        end

        def []= k,v
            @env.last[k] = v
        end

        def all
            @env.inject(&:merge)
        end

        def scope
            @env.push({})
            yield
        ensure
            @env.pop
        end

        def initialize
            @env=[{}]
        end
    end

end

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

