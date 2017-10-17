import ParserContext;

class Eval
{
    var parser:hscript.Parser;
    var interp:hscript.Interp;
    var context:ParserContext;

    public function new(context:ParserContext)
    {
        this.context = context;
        parser = new hscript.Parser();
        interp = new hscript.Interp();
        
        var variables = context.getVariables();
        for( v in variables.keys() )
            interp.variables.set(v, variables.get(v));
    }

    public function evaluate(expr:String):Bool
    {
        var ast = parser.parseString(expr);
        var res = try interp.execute(ast) catch(e:Dynamic) false;
        return cast(res, Bool);
    }
}