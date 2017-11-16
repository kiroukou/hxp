
enum BuildTarget {
    Neko;
    Php;
}

enum BuildCommand {
    INSTALL;
    BUILD;
    RUN;
}

enum Platform {
    MAC;
    WINDOWS;
    LINUX;
    UNKNOWN;
}

typedef HookNode = {
    @:json('if') @:optional var ifCond : Map<String, HookNode>;
    @:optional var command : String;
}

typedef BuildNode = {
    @:optional var libs : Array<String>;
    @:optional var flags : Array<String>;
    @:optional var defines : Array<String>;
    @:optional var sources : Array<String>;
    @:json('if') @:optional var ifCond : Map<String, BuildNode>;

    @:optional var prebuild : HookNode;
    @:optional var postbuild : HookNode;
}

typedef TargetNode = {
    //> BuildNode,
    var output : String;
    @:optional var main : String;
}

typedef AppNode = {
    > BuildNode,
    ?includes : Array<String>,
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
