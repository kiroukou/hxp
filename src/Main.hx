package;

import Types;
import ParserContext;
import tink.cli.*;
import tink.Cli;

class Main
{
    var cmd:BuildCommand;
    public function new(cmd:BuildCommand, file:String, context:ParserContext)
    {
        this.cmd = cmd;
        var jsonContent = sys.io.File.getContent(file);
        parse(context, jsonContent);
    }

    function parse(context:ParserContext,json:String)
    {
        var app : {project:ProjectNode} = tink.Json.parse(json);
        parseProject(context, app.project);
    }

    function loadDependency(context:ParserContext, dependencyPath:String)
    {
        var currentPath = context.getCurrentPath();
        var newPath = Helper.combine(currentPath,dependencyPath);
        context.setCurrentPath(Helper.getFileDirectory(newPath));
        
        var json = sys.io.File.getContent(newPath);
        var node : BuildNode = tink.Json.parse(json);
        parseDependency(context, node);

        context.setCurrentPath(currentPath);
        return node;
    }

    function parseDefines(context:ParserContext, node:BuildNode)
    {
        if( node.defines != null )
        {
            for( define in node.defines )
            {
                context.addDefine(define, true);
            }
        }
    }

    function parseFlags(context:ParserContext, node:BuildNode)
    {
        if( node.flags != null )
        {
            for( flag in node.flags )
            {
                context.addArgument(flag);
            }
        }
    }

    function parseLibs(context:ParserContext, node:BuildNode)
    {
        if( node.libs != null )
        {
            for( lib in node.libs )
            {
                context.addLibrary(lib);
            }
        }
    }

    //TODO handle path
    function parseSources(context:ParserContext, node:BuildNode)
    {
        if( node.sources != null )
        {
            for( src in node.sources )
            {
                context.addSource(src);
            }
        }
    }

    function parseDependency(context:ParserContext, node:BuildNode)
    {
        parseLibs(context, node);
        parseFlags(context, node);
        parseDefines(context, node);
        parseSources(context, node);
        parseConditional(context, node);
    }

    function parseConditional(context:ParserContext, node:BuildNode)
    {
        if( node.ifCond != null ) 
        {
            var eval = new Eval(context);
            for( cond in node.ifCond.keys() )
            {
                var result = eval.evaluate(cond);
                if( result )
                {
                    var node = node.ifCond.get(cond);
                    parseBuildNode(context, node);
                }
            }
        }
    }

    function parseBuildNode(context:ParserContext, node:BuildNode)
    {
        parseFlags(context, node);
        parseDefines(context, node);
        parseSources(context, node);
        parseLibs(context, node);
        parseConditional(context, node);
    }

    function parseProject(context:ParserContext, node:ProjectNode)
    {
        parseLibs(context, node.app);
        parseBuildNode(context, node.build);

        if( node.app.main != null ) 
        {
            context.setMain(node.app.main);
        }
        
        if( node.app.includes != null )
        {
            for( dep in node.app.includes )
            {
                loadDependency(context, dep);
            }
        }

        switch( cmd )
        {
            case BUILD: processBuild(context, node);
            case INSTALL: processInstall(context);
        }
    }

    function processBuild(context:ParserContext, node:ProjectNode) 
    {
        var path = Sys.getCwd();
        var outFileName =   context.getOutput();
        if( outFileName == null ) 
            outFileName = path+"/"+node.name+"_"+context.getTarget()+".hxml";
        
        var f = sys.io.File.write(outFileName, false);
        function write(v) {
            f.writeString(v+"\n");
        }

        for(lib in context.getLibraries() )
            write("-lib "+lib);
        for( arg in context.getArguments() )
            write(arg);
        for( src in context.getSources() )
            write("-cp "+src);
        for( def in context.getDefines().keys() )
            write("-D "+def);
        

        switch(context.getTarget()) 
        {
            case Neko: 
                if( node.app.neko == null )
                    throw "Neko node must be defined";
                if( node.app.neko.main != null )
                    context.setMain(node.app.neko.main);
                write("-neko "+node.app.neko.output);
            case Php:
                if( node.app.php == null )
                    throw "Php node must be defined";
                if( node.app.php.main != null )
                    context.setMain(node.app.php.main);
                write("-php "+node.app.php.output);
        }
        write("-main "+context.getMain());

        f.flush();
        f.close();
    }

    function processInstall(context:ParserContext)
    {
        for(lib in context.getLibraries() )
        {
            var process = new sys.io.Process("haxelib", ["install", lib]);
            var output = process.stdout.readAll ().toString ();
			var error = process.stderr.readAll ().toString ();
			process.exitCode ();
			process.close ();
            Sys.println("haxelib install "+lib);
            Sys.println(output);
            //Sys.println("error : "+error);
            
        }  
    }


    public static function main()
    {
        var cmd = new HxpArgsCommand();
        Cli.process(Sys.args(), cmd).handle( function(o) {
            var context = new ParserContext(cmd.getTarget());
            context.setCurrentPath(Sys.getCwd());
            
            if( cmd.debug )
            {
                context.setVariable("debug", true);
                context.addArgument("-debug");
            }

            for( v in cmd.getVariables() )
                context.setVariable(v, true);
            for(d in cmd.defines)
                context.addDefine(d, true);
            //
            if( !sys.FileSystem.exists(cmd.getFile()) )
               throw "First argument must be the project file XXXXX.hxp";

            context.setOutput(cmd.getOutput());
            new Main(cmd.getCommand(), cmd.getFile(), context);
        });
    }
}

//haxelib run hxp project.hxp php -debug
@:alias(false)
class HxpArgsCommand
{
	@:flag('-D')
	public var defines:Array<String>;

    @:flag('-f')
	public var file:String;

    @:flag('-o')
	public var output:Null<String>;
	
    @:flag('-debug')
    public var debug:Bool;
	
    var command:BuildCommand;
    var target:BuildTarget;
    var variables:Array<String>;
	public function new() 
    {
        variables = [];
        defines = [];
        file = "project.hxp";
    }
	
    public function getCommand()
    {
        return command;
    }

    public function getOutput()
    {
        return output;
    }

    public function getFile()
    {
        return file;
    }

    public function getTarget()
    {
        return target;
    }

    public function getVariables()
    {
        return this.variables;
    }

	@:defaultCommand
	public function build(rest:Rest<String>) 
    {
        command = BuildCommand.BUILD;
        target = switch(rest.shift().toLowerCase() ) {
            case "php": variables.push("php"); Php;
            case "neko": variables.push("neko"); Neko;
            default: throw "unknown platform";//TODO improve
        }
        variables = variables.concat(rest);
	}

    @:command
	public function install(rest:Rest<String>) 
    {
        command = BuildCommand.INSTALL;
        target = switch(rest.shift().toLowerCase() ) {
            case "php": variables.push("php"); Php;
            case "neko": variables.push("neko"); Neko;
            default: throw "unknown platform";//TODO improve
        }
        variables = variables.concat(rest);
	}

}

