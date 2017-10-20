# hxp
project manager for haxe

The goal was initially to make a build too for the Sugoi web Framework project : https://github.com/bablukid/sugoi

# Features
Allows to declare one entry point for several targets. Currently supported targets are Neko and Php, but this is (and will be more easily) modular  

Usage
# the following 3 command lines call are equivalent.
haxelib run hxp neko
haxelib run hxp build neko
haxelib run hxp -f project.hxp neko

This command will build the hxml file depending on the project.hxp configuration.


# Install
## the following commands allow to init the project and install automatically the haxelib libraries the project depends on
haxelib run hxp install php -f rsc/project.hxp
haxelib run hxp install neko -f rsc/project.hxp
haxelib run hxp install neko
