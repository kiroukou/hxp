package;

import Types;
import ParserContext;
import tink.cli.*;
import tink.Cli;

class Main
{
    var cmd:BuildCommand;
    var file:String;
    public function new(cmd:BuildCommand, file:String, context:ParserContext)
    {
        this.cmd = cmd;
        this.file = file;
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
        //trace('$currentPath , $dependencyPath');
        var newPath = Helper.combine(currentPath,dependencyPath);
        //trace(newPath);
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
        parseConditional(context, node, parseBuildNode);
    }

    //function length<T:{var length(default, null):Int;}>(o:T)
    function parseConditional<B, T:{var ifCond : Map<String, B>;}>(context:ParserContext, node:T, process:ParserContext->B->Void)
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
                    process(context, node);
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
        parseConditional(context, node, parseBuildNode);
        parseCommands(context, node);
    }

    function parseCommands(context:ParserContext, node:BuildNode)
    {
        if( node.prebuild != null )
        {
            if( node.prebuild.command != null ) 
                context.addPrebuildCommand(node.prebuild.command);

            parseConditional(context, node.prebuild, function(c, n:HookNode) {
                if( n.command != null ) 
                    context.addPrebuildCommand(n.command);
            });
        }

        if( node.postbuild != null )
        {
            if( node.postbuild.command != null ) 
                context.addPostbuildCommand(node.postbuild.command);

            parseConditional(context, node.postbuild, function(c, n:HookNode) {
                if( n.command != null ) 
                    context.addPostbuildCommand(n.command);
            });
        }
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
            case BUILD: 
                var hxmlFile = processBuild(context, node);
                executeHxml(hxmlFile);
            case INSTALL: 
                processInstall(context);
            case RUN: 
                var hxmlFile = processBuild(context, node);
                executeHxml(hxmlFile);

                switch(context.getTarget()) 
                {
                    case Neko: 
                        runCommand("neko "+context.getBinaryPath());
                    case Php:
                        Sys.println("Php project can't be run automatically");
                }
        }
    }

    function runCommand(cmd:String)
    {
        var process = new sys.io.Process(cmd);
        var output = process.stdout.readAll ().toString ();
        var error = process.stderr.readAll ().toString ();
        process.exitCode ();
        process.close ();
        Sys.println(output);
        Sys.println(error);
    }

    function executeHxml(hxmlFile:String)
    {
        var process = new sys.io.Process("haxe "+hxmlFile);
        var output = process.stdout.readAll ().toString ();
        var error = process.stderr.readAll ().toString ();
        process.exitCode ();
        process.close ();
        Sys.println(output);
        Sys.println(error);
    }

    function processBuild(context:ParserContext, node:ProjectNode) 
    {
        var path = context.getCurrentPath();

        var outFileName =   context.getOutput();
        if( outFileName == null ) 
            outFileName = path+"/"+node.name+"_"+context.getTarget()+".hxml";
        
        var f = sys.io.File.write(outFileName, false);
        function write(v) {
            f.writeString(v+"\n");
        }

        for( cmd in context.getPrebuildCommands() )
            write("-cmd "+cmd);

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
                context.setBinaryPath(Helper.combine(path, node.app.neko.output));
                write("-neko "+context.getBinaryPath());
            case Php:
                if( node.app.php == null )
                    throw "Php node must be defined";
                if( node.app.php.main != null )
                    context.setMain(node.app.php.main);
                
               context.setBinaryPath(Helper.combine(path, node.app.php.output));
                write("-php "+context.getBinaryPath());
        }
        write("-main "+context.getMain());

        for( cmd in context.getPostbuildCommands() )
            write("-cmd "+cmd);

        f.flush();
        f.close();

        return outFileName;
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
            Sys.println(error);
        }  
    }


    public static function main()
    {
        var cmd = new HxpArgsCommand();
        try 
        {
            Cli.process(Sys.args(), cmd).handle( function(o) {
                var context = new ParserContext(cmd.getTarget());
                //we have to think path from the current config file
                var executionPath:String = Helper.getFileDirectory(Sys.getCwd()+''+cmd.getFile());
                //Sys.println("executionPath:"+executionPath);
                context.setCurrentPath(executionPath);
                
                if( cmd.debug )
                {
                    context.setVariable("debug", true);
                    context.addArgument("-debug");
                }

                for( v in cmd.getVariables() )
                    context.setVariable(v, true);
                for(d in cmd.defines)
                    context.addDefine(d, true);
                
                if( !sys.FileSystem.exists(cmd.getFile()) )
                    throw "First argument must be the project file XXXXX.hxp";

                context.setOutput(cmd.getOutput());
                new Main(cmd.getCommand(), cmd.getFile(), context);
            });
        } catch( e:Dynamic ) {
            Sys.println("HXP Error : "+e);
            Sys.println(haxe.CallStack.toString(haxe.CallStack.callStack()));
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            //Sys.println(Cli.getDoc(cmd));
        }
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

    inline static var DEFAULT_PROJECT_FILE = "project.hxp";
	public function new() 
    {
        variables = [];
        defines = [];
        file = null;
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
	public function run(rest:Rest<String>) 
    {
        command = switch(rest.shift().toLowerCase())
        {
            case "run": BuildCommand.RUN;
            case "install": BuildCommand.INSTALL;
            case "build": BuildCommand.BUILD;
            default: throw "Unknown command.  Must be install|run|build";
        }
        
        var arg = rest.shift();
        //Sys.println("arg : "+arg);
        if( file == null ) 
        {
            var realFile =  Helper.combine(Sys.getCwd(), arg);
            //Sys.println("file ====="+realFile);
            if( sys.FileSystem.exists(realFile) ) 
            {
                //Sys.println("the project file is "+realFile);
                file = arg;
                arg = rest.shift();
            }
            else
            {
                //Sys.println("Default project file name is used");
                file = DEFAULT_PROJECT_FILE;
            }
        } 

        target = switch(arg.toLowerCase() ) {
            case "php": variables.push("php"); Php;
            case "neko": variables.push("neko"); Neko;
            default: throw "unknown platform "+arg;//TODO improve
        }
        variables = variables.concat(rest);
    }
}

