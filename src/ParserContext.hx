import Types;

class ParserContext 
{
    var path:String;
    var target:BuildTarget;
    var variables:haxe.ds.StringMap<Bool>;
    //
    var defines:haxe.ds.StringMap<Bool>;
    var arguments:Array<String>;
    var libraries:Array<String>;
    var sources:Array<String>;
    var mainClass:String;

    public function new(?pTarget:BuildTarget, ?from:ParserContext)
    {
        if( from != null )
        {
            this.defines = from.getDefines();
            this.variables = from.getVariables();
            this.target = from.getTarget();
            this.arguments = from.getArguments();
            this.libraries = from.getLibraries();
            this.mainClass = from.getMain();
            this.sources = from.getSources();
            this.path = from.getCurrentPath();
        }
        else
        {
            if( pTarget == null ) throw "A target must be defined";
            this.target = pTarget;
            this.defines = new haxe.ds.StringMap();
            this.variables = new haxe.ds.StringMap();
            this.arguments = [];
            this.libraries = [];
            this.sources = [];
            this.mainClass = "";
            this.path;
        }
    }

    public function setCurrentPath(path:String)
    {
        this.path = path;
    }
    public function getCurrentPath()
    {
        return this.path;
    }

    public function getTarget():BuildTarget
    {
        return this.target;
    }

    public function hasVariable(name:String):Bool 
    {
        return this.variables.get(name.toLowerCase()) == true;
    }

    public function setMain(className:String)
    {
        this.mainClass = className;
    }

    public function setVariable(name:String, value:Bool)
    {
        this.variables.set(name.toLowerCase(), value);
    }

    public function isDefined(name:String):Bool
    {
        var v = this.defines.get(name);
        return ( v != null && v == true ) ? true : false;
    }

    public function addArgument(name:String)
    {
        this.arguments.push(name);
    }

    public function addLibrary(name:String) 
    {
        this.libraries.push(name);
    }

    public function addSource(source:String)
    {
        this.sources.push(getCurrentPath()+source);
    }

    public function addDefine(name:String, value:Bool) 
    {
        this.defines.set(name, value);
    }

    public function getDefines():haxe.ds.StringMap<Bool> 
    {
        return Reflect.copy(this.defines);
    }

    public function getVariables():haxe.ds.StringMap<Bool> 
    {
        return Reflect.copy(this.variables);
    }

    public function getMain()
    {
        return this.mainClass;
    }

    public function getSources()
    {
        return this.sources.copy();
    }

    public function getArguments()
    {
        return this.arguments.copy();
    }

    public function getLibraries()
    {
        return this.libraries.copy();
    }

    public function clone():ParserContext
    {
        var c = new ParserContext(this);
        return c;
    }
}