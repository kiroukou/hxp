package;

import Types;
import ParserContext;

class Main
{
    public function new(file:String, target:BuildTarget, vars:Array<String>)
    {
        var context = new ParserContext(target);
        context.setCurrentPath(Sys.getCwd());
        //
        for( v in vars )
            context.setVariable(v, true);
        
        switch(target)
        {
            case Php: context.setVariable("php", true);
            case Neko: context.setVariable("neko", true);
        }
        //
        var jsonContent = sys.io.File.getContent(file);
        parse(context, jsonContent);
    }

    function parse(context:ParserContext,json:String)
    {
        var app : {project:ProjectNode} = tink.Json.parse(json);
        parseProject(context, app.project);
    }

    function loadDependency(context:ParserContext, path:String)
    {
        var currentPath = context.getCurrentPath();
        var newPath = currentPath+path;
        context.setCurrentPath(newPath);

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
            trace("node.ifCond = "+node.ifCond);
            var eval = new Eval(context);
            for( cond in node.ifCond.keys() )
            {
                var result = eval.evaluate(cond);
                trace("cond = "+cond);
                trace("result = "+result);
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
        
        if( node.app.dependencies != null )
        {
            for( dep in node.app.dependencies )
            {
                loadDependency(context, dep);
            }
        }

        var path = Sys.getCwd();
        var f = sys.io.File.write(path+"/"+node.name+"_"+context.getTarget()+".hxml", false);
        
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
        
        write("-main "+context.getMain());

        switch(context.getTarget()) {
            case Neko: 
                if( node.app.neko == null )
                    throw "Neko node must be defined";
                write("-neko "+node.app.neko.output);
            case Php:
                if( node.app.php == null )
                    throw "Php node must be defined";
                write("-php "+node.app.php.output);
        }

        f.flush();
        f.close();
    }


    public static function main()
    {
        new Main("rsc/project.hxp", Neko, []);
    }
}