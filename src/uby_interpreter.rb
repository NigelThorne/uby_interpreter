require "ruby_parser"
require "sexp_processor"

class UbyInterpreter < SexpInterpreter
	VERSION = "1.0.0"
    attr_accessor :parser
    attr_accessor :env

    def initialize
        super 

        self.parser = Ruby20Parser.new
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

    def process_block s, scope=nil
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

        class Scope
            attr_reader :context
            def initialize c
                @hash = {}
                @context = c
            end            
            def [] k
                @hash.fetch(k){ self.context[k] || raise("unknown varaible #{k}") }
            end

            def []= k,v
                @hash[k] = v
            end
        end

        def [] k
            @scope[k]
        end

        def []= k,v
            @scope[k] = v
        end

        def scope
            @scope = Scope.new @scope
            yield
        ensure
            @scope = @scope.context
        end

        def initialize
            @scope = Scope.new nil
        end
    end

end
