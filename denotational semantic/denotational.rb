class Number < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        false
    end

end



class Add < Struct.new(:left, :right)
    
    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    
    def reducible?
        true
    end

    def reduce(environment) 
        if left.reducible? 
            Add.new(left.reduce(environment), right)
        elsif right.reducible? 
            Add.new(left, right.reduce(environment))
        else
            Number.new(left.value + right.value)
        end
    end

end

class Multiply < Struct.new(:left, :right)
    def to_s
        "#{left} * #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment) 
        if left.reducible? 
            Multiply.new(left.reduce(environment), right)
        elsif right.reducible? 
            Multiply.new(left, right.reduce(environment))
        else
            Number.new(left.value * right.value)
        end
    end

end


class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        false
    end

end

class LessThan < Struct.new(:left, :right)
    def to_s
        "#{left} < #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment) 
        if left.reducible? 
            LessThan.new(left.reduce(environment), right)
        elsif right.reducible? 
            LessThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value < right.value)
        end
    end
end

class Variable < Struct.new(:name)

    def to_s
        name.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment) 
        environment[name]
    end

end


class DoNothing
    def to_s
        'do-nothing'
    end

    def inspect
        "<<#{self}>>"
    end

    def ==(other_statement) 
        other_statement.instance_of?(DoNothing)
    end

    def reducible?
        false
    end

end

class Assign < Struct.new(:name, :expression) 
    def to_s
        "#{name} = #{expression}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end


    def reduce(environment)
        if expression.reducible?
            [Assign.new(name, expression.reduce(environment)), environment]
        else  
            [DoNothing.new, environment.merge({name => expression})]
        end
    end
end


class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if (#{condition}) {#{consequence}} else {#{alternative}}"
    end
    
    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if condition.reducible?
            [If.new(condition.reduce(environment), consequence, alternative), environment]
        else
            case condition
            when Boolean.new(true)
                [consequence, environment]
            when Boolean.new(false)
                [alternative, environment]
            end
        end
    end
end

class Sequence < Struct.new(:first, :second)
    def to_s
        "#{first}; #{second}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        case first
        when DoNothing.new
            [second, environment]
        else 
            reduced_first, reduced_environment = first.reduce(environment)
            [Sequence.new(reduced_first, second), reduced_environment]
        end
    end
end


# while(cond) {body} => if (cond) {body; while(cond) {body} } else {do-nothing}
class While < Struct.new(:condition, :body) 
    def to_s
        "while (#{condition}) { #{body} )"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
    end
end





class Number
    def evaluate(environment)
        self
    end
end

class Boolean
    def evaluate(environment)
        self
    end
end

class Variable
    def evaluate(environment)
        environment[name]
    end
end

class Add
    def evaluate(environment)
        Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
    end
end

class Multiply
    def evaluate(environment)
        Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
    end
end

class LessThan
    def evaluate(environment)
        Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
    end
end

class Assign
    def evaluate(environment) 
        environment.merge({name => expression.evaluate(environment)})
    end
end

class DoNothing
    def evaluate(environment)
        environment
    end
end

class If
    def evaluate(environment) 
        case condition.evaluate(environment)
        when Boolean.new(true)
            consequence.evaluate(environment)
        when Boolean.new(false)
            alternative.evaluate(environment)
        end
    end
end


class Sequence
    def evaluate(environment) 
        second.evaluate(first.evaluate(environment))
    end
end


class While
    def evaluate(environment)
        case condition.evaluate(environment)
        when Boolean.new(true)
            evaluate(body.evaluate(environment))
        when Boolean.new(false)
            environment
        end
    end
end

class Number
    def to_ruby
        "-> e { #{value.inspect} }"
    end
end

class Boolean
    def to_ruby
        "-> e { #{value.inspect} }"
    end
end

# proc = eval(Number.new(5).to_ruby)
# proc.call({})


class Variable
    def to_ruby
        "-> e { e[#{name.inspect}] }"
    end
end


proc = eval(Variable.new(:x).to_ruby)
puts proc.call({ x: 7})

#3
# -> e { -> e {}}

class Add
    def to_ruby 
        "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
    end
end

class Multiply
    def to_ruby 
        "-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
    end
end

class LessThan
    def to_ruby 
        "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
    end
end

environment = { x: 3}


proc = eval(Add.new(Variable.new(:x), Number.new(1)).to_ruby)
puts proc.call(environment)

proc = eval(LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby)
puts proc.call(environment)

class Assign
    def to_ruby
        "-> e { e.merge({ #{name.inspect} => #{expression.to_ruby}.call(e) }) }"
    end
end

statement = Assign.new(:y, Add.new(Variable.new(:x), Number.new(1)))
proc = eval(statement.to_ruby)
puts proc.call({ x: 3})

class DoNothing
    def to_ruby
        "-> e {e}"
    end
end

class If 
    def to_ruby
        "-> e { if (#{condition.to_ruby}).call(e) " +
        "then (#{consequence.to_ruby}).call(e) " +
        "else (#{alternative.to_ruby}).call(e) " +
        "end }"
    end
end

class Sequence
    def to_ruby
        "-> e { (#{second.to_ruby}).call(#{first.to_ruby}.call(e)) }"
    end
end

class While
    def to_ruby
        "-> e { while (#{condition.to_ruby}).call(e); " +
        "  e = (#{body.to_ruby}).call(e); " +
        "end;  e }"
    end
end

statement =
While.new(
    LessThan.new(Variable.new(:x), Number.new(5)),
    Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
)

proc = eval(statement.to_ruby)
puts proc.call({ x: 1})
