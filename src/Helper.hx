
enum Platform {
    MAC;
    WINDOWS;
    LINUX;
    UNKNOWN;
}

class Helper
{
    public static var PLATFORM = {
			if (new EReg ("window", "i").match (Sys.systemName ())) 
            {
				WINDOWS;
			} 
            else if (new EReg ("linux", "i").match (Sys.systemName ())) 
            {		
				LINUX;
			} 
            else if (new EReg ("mac", "i").match (Sys.systemName ())) 
            {
				MAC;
			}
            else
            {
                UNKNOWN;
            }
		};

    public static function isAbsolute (path:String):Bool 
    {
		if (StringTools.startsWith (path, "/") || StringTools.startsWith (path, "\\")) 
        {
			return true;
		}
		return false;
	}

	public static function isRelative (path:String):Bool 
    {
		return !isAbsolute (path);
	}

    public static function tryFullPath (path:String):String 
    {
		try
        {
			return sys.FileSystem.fullPath (path);
		} catch (e:Dynamic) {
			return expand (path);
		}
	}

    public static function normalizeDirectoryPath(path:String):String
    {
        if( !StringTools.endsWith(path, "/") ) path += "/";
        return path;
    }

    public static function getFileDirectory(filePath:String):String
    {
        if( sys.FileSystem.isDirectory(filePath) )
            return filePath;
        var path = filePath;
        var path = path.substr(0, path.lastIndexOf('/'));
        return normalizeDirectoryPath(path);
    }

    public static function combine (firstPath:String, secondPath:String):String 
    {
		if (firstPath == null || firstPath == "")
         {
			return secondPath;
		}
        else if (secondPath != null && secondPath != "") 
        {
			if (PLATFORM == WINDOWS) 
            {
				if (secondPath.indexOf (":") == 1) 
                {
					return secondPath;
				}
			}
            else 
            {
				if (secondPath.substr (0, 1) == "/") 
                {
					return secondPath;
				}
			}
			
			var firstSlash = (firstPath.substr (-1) == "/" || firstPath.substr (-1) == "\\");
			var secondSlash = (secondPath.substr (0, 1) == "/" || secondPath.substr (0, 1) == "\\");
			
			if (firstSlash && secondSlash) 
            {
				return firstPath + secondPath.substr (1);
			} 
            else if (!firstSlash && !secondSlash) 
            {
				return firstPath + "/" + secondPath;
			} 
            else 
            {
				return firstPath + secondPath;
			}
		} 
        else
        {
			return firstPath;	
		}
	}
	
	public static function escape (path:String):String 
    {
		if (PLATFORM != WINDOWS) 
        {
			path = StringTools.replace (path, " ", "\\ ");
			return expand (path);
		}
		return expand (path);
	}
	
	public static function expand (path:String):String 
    {
		if (path == null)
			path = "";
		
		if (PLATFORM != WINDOWS)
        {
			if (StringTools.startsWith (path, "~/")) 
            {
				path = Sys.getEnv ("HOME") + "/" + path.substr (2);	
			}
		}
		return path;
	}
}