
package;

import tink.json.*;
import tink.Json.*;

typedef CondNode = {
    @:json('if') var ifCond : Map<String, CondNode>;
}

typedef ConfigNode = {
    > CondNode,
    ?libs : Array<String>,
    ?flags : Array<String>,
    ?defines : Array<String>,
    ?sources : Array<String>
}

typedef BuildNode = {
    > ConfigNode,
    ?dependencies : Map<String,String>,
}

typedef TargetNode = {
    > ConfigNode,
    var output : String;
    @:optional var main : String;
    @:json('package') var packageName : String;
}

typedef AppNode = {
    > ConfigNode,
    name : String,
    ?dependencies : Array<String>,
    ?main : String,
    ?neko : TargetNode,
    ?php : TargetNode,
}

typedef ProjectNode = {
    name : String,
    version : String,
    ?author : String,
    app : AppNode,
    build : BuildNode
}

class NodeContext 
{
    public var defines(get, null):haxe.ds.StringMap<Bool>;
    public var hxmlBuffer(get, null):String;

    public function new(?from:NodeContext)
    {
        if( from != null )
        {
            this.defines = from.defines;
            this.hxmlBuffer = from.hxmlBuffer;
        }
        else
        {
            this.defines = new haxe.ds.StringMap();
            this.hxmlBuffer = "";
        }
    }

    public function isDefined(name:String):Bool
    {
        var v = this.defines.get(name);
        return ( v != null && v == true ) ? true : false;
    }

    public function addDefine(name:String, value:Bool) 
    {
        this.defines.set(name, value);
    }

    public function appendHxml(command:String) 
    {
        this.hxmlBuffer += command;
        this.hxmlBuffer += "\n";
    }

    function get_defines():haxe.ds.StringMap<Bool> 
    {
        return Reflect.copy(this.defines);
    }

    function get_hxmlBuffer():String 
    {
        return Std.string(hxmlBuffer);
    }

    public function clone():NodeContext
    {
        var c = new NodeContext();
        c.defines = Reflect.copy(this.defines);
        c.hxmlBuffer = Std.string(this.hxmlBuffer);
        return c;
    }
}

enum BuildTarget {
    Neko;
    Php;
}

class Main
{
    var appTargets:Map<String, NodeContext>;
    public function new()
    {
        appTargets = new Map();
        var jsonContent = sys.io.File.getContent("rsc/project.hxp");
        parse(jsonContent);
    }

    function parse(json:String)
    {
        var context = new NodeContext();
        var app : {project:ProjectNode} = tink.Json.parse(json);
        parseProject(context, app.project);
    }

    function loadDependency(context:NodeContext, path:String)
    {
        var current = Sys.getCwd();
        var json = sys.io.File.getContent(current+path);
        var node : BuildNode = tink.Json.parse(json);
        return node;
    }

    function parseDefines(context:NodeContext, node:ConfigNode)
    {
        if( node.defines != null )
        {
            for( define in node.defines )
            {
                context.appendHxml("-D "+define);
            }
        }
    }

    function parseFlags(context:NodeContext, node:ConfigNode)
    {
        if( node.flags != null )
        {
            for( flag in node.flags )
            {
                context.appendHxml(flag);
            }
        }
    }

    function parseLibs(context:NodeContext, node:ConfigNode)
    {
        if( node.libs != null )
        {
            for( lib in node.libs )
            {
                context.appendHxml("-lib "+lib);
            }
        }
    }

    function parseSources(context:NodeContext, node:ConfigNode)
    {
        if( node.sources != null )
        {
            for( src in node.sources )
            {
                context.appendHxml("-cp "+src);
            }
        }
    }

    function parseDependency(context:NodeContext, node:BuildNode)
    {
        parseLibs(context, node);
        parseFlags(context, node);
        parseDefines(context, node);
        parseSources(context, node);
    }

    function parseProject(context:NodeContext, node:ProjectNode)
    {
        parseLibs(context, node.app);
        parseFlags(context, node.build);
        parseDefines(context, node.build);
        parseSources(context, node.build);

        if( node.app.main != null ) 
        {
            context.appendHxml("-main "+node.app.main);
        }
        
        if( node.build.dependencies != null )
        {
            for( dep in node.build.dependencies )
            {
                var n = loadDependency(context, dep);
                parseDependency(context, n);
            }
        }

        if( node.app.neko != null )
        {
            generateTarget(Neko, context.clone(), node.app.neko);
        }

        if( node.app.php != null )
        {
            generateTarget(Php, context.clone(), node.app.php);
        }
        
        var path = Sys.getCwd();
        for( target in appTargets.keys() )
        {
            var f = sys.io.File.write(path+"/"+node.name+"_"+target+".hxml", false);
            f.writeString(appTargets.get(target).hxmlBuffer);
            f.flush();
            f.close();
        }
    }

    function generateTarget(target:BuildTarget, context:NodeContext, config:TargetNode)
    {
        var out = config.output;
        var cmd = switch(target) {
            case Neko: "neko";
            case Php: "php";
        }

        context.appendHxml("-"+cmd+" "+out);
        if(config.libs != null )
        {
            for( lib in config.libs )
            {
                context.appendHxml("-lib "+lib);
            }
        }

        if( config.main != null ) 
            context.appendHxml("-main "+config.main);

        appTargets.set(Std.string(target), context);
        return context;

    }

    public static function main()
    {
        new Main();
    }
}