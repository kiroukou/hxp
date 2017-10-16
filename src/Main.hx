
package;

import tink.json.*;
import tink.Json.*;

typedef TargetNode = {
    @:optional var libs : Array<String>;
    @:json('if') @:optional var _if : String;
}

typedef BuildNode = {
    @:optional var flags : Array<String>;
    @:optional var defines : Array<String>;
    @:optional var dependencies : Map<String,String>;
    var sources:Array<String>;
    @:json('if') @:optional var _if : String;
}

typedef FilesNode = {
    @:optional var config : { path:String, template:String};
    @:optional var data : String;
    @:json('if') @:optional var _if : String; 
}

typedef AppNode = {
    var name : String;
    @:json('package') var _package : String;
    var output : String;
    var main : String;
    @:optional var neko : TargetNode;
    @:optional var php : TargetNode;
    @:optional var libs : Array<String>;
    @:json('if') @:optional var _if : String;
    @:optional var files : FilesNode;
}

typedef ProjectNode = {
    var name : String;
    @:optional var version : String;
    @:optional var author : String;
    var app : AppNode;
    var build : BuildNode;
    @:json('if') @:optional var _if : String;
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
        var jsonContent = sys.io.File.getContent("rsc/project.json");
        parse(jsonContent);
    }

    function parse(json:String)
    {
        var app : {project:ProjectNode} = tink.Json.parse(json);
        generateHxml(app.project);
    }

    function generateHxml(project:ProjectNode)
    {
        var context = new NodeContext();
        for( define in project.build.defines )
        {
            context.appendHxml("-D "+define);
        }
        for( flag in project.build.flags )
        {
            context.appendHxml(flag);
        }

        if( project.app.libs != null )
        {
            for( lib in project.app.libs )
            {
                context.appendHxml("-lib "+lib);
            }
        }

        context.appendHxml("-main "+project.app.main);
        for( path in project.build.sources )
        {
            context.appendHxml("-cp "+path);
        }

        if( project.app.neko != null )
        {
            generateTarget(Neko, context.clone(), project, project.app.neko);
        }

        if( project.app.php != null )
        {
            generateTarget(Php, context.clone(), project, project.app.php);
        }
        
        var path = Sys.getCwd();
        for( target in appTargets.keys() )
        {
            var f = sys.io.File.write(path+"/"+project.name+"_"+target+".hxml", false);
            f.writeString(appTargets.get(target).hxmlBuffer);
            f.flush();
            f.close();
        }

    }
//TODO make this more generic
//maybe a map to store the targets configurations?
    function generateTarget(target:BuildTarget, context:NodeContext, project:ProjectNode, config:TargetNode)
    {
        var cmd = "", out = "";
        switch(target)
        {
            case Neko: cmd = "neko"; out = project.app.output+""+project.app.name+".n";
            case Php: cmd = "php"; out = project.app.output;
        }
        context.appendHxml("-"+cmd+" "+out);
        if(config.libs != null )
        {
            for( lib in config.libs )
            {
                context.appendHxml("-lib "+lib);
            }
        }
        appTargets.set(Std.string(target), context);
        return context;
    }

    function generatePhp(context:NodeContext, project:ProjectNode, config:TargetNode)
    {
        var ext = ".n";
        context.appendHxml("-php "+project.app.output+""+project.app.name+""+ext);
        if(config.libs != null )
        {
            for( lib in config.libs )
            {
                context.appendHxml("-lib "+lib);
            }
        }
        appTargets.set("php", context);
        return context;
    }

    public static function main()
    {
        new Main();
    }
}