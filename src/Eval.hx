import ParserContext;

class Interp extends hscript.Interp 
{
    override function resolve( id : String ) : Dynamic {
		var l = locals.get(id);
		if( l != null )
			return l.r;
		var v = variables.get(id);
		if( v == null && !variables.exists(id) )
			v = false;
		return v;
	}
}

class Eval
{
    var parser:hscript.Parser;
    var interp:hscript.Interp;
    var context:ParserContext;

    public function new(context:ParserContext)
    {
        this.context = context;
        parser = new hscript.Parser();
        interp = new Interp();
        
        var variables = context.getVariables();
        for( v in variables.keys() )
            interp.variables.set(v, variables.get(v));
    }

    public function evaluate(expr:String):Bool
    {
        var ast = parser.parseString(expr);
        var res = try interp.execute(ast) catch(e:Dynamic) { trace("Error : "+e); false; }
        return cast(res, Bool);
    }
}