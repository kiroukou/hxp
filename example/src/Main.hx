class Main {
    static function main() {
        var numbers = [for(i in 0...100) Std.random(100)];
        Sys.println("unsorted : "+numbers);

        numbers = bubbleSort(numbers, function(a, b){ return b - a;} );
        Sys.println("sorted : "+numbers);
    }

    static function bubbleSort<T>(sortArray:Array<T>, compare:T->T->Int):Array<T>
    {
        var size = sortArray.length;
        for( i in 0...size-1 )
        {
            var sorted = true;
            var a = sortArray[i];
            for( j in i+1...size )
            {
                var b = sortArray[j];
                if( compare(a, b) < 0 )
                {
                    sortArray[i] = b;
                    sortArray[j] = a;
                    //to avoid array access over i every loop
                    a = b;
                    sorted = false;
                }
            }
            if( sorted )
                break;
        }
        return sortArray;
    }
}
