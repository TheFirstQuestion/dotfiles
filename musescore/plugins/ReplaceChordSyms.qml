import MuseScore 3.0
import QtQuick 2.0

MuseScore {
    version: "1.0";
    description: "Replaces chord symbols"
    menuPath: "Plugins.ReplaceChordSyms."

    id: replaceChordSyms

    Component.onCompleted : {
        if (mscoreMajorVersion >= 4) {
            replaceChordSyms.title = "Replace Chord Symbols"
        }
     }


    function setCursorToTime(cursor, time) {
        cursor.rewind(0);
        while (cursor.segment) {
            var current_time = cursor.tick;
            if (current_time >= time) {
                return true;
            }
            cursor.next();
        }
        cursor.rewind(0);
        return false;
    }

    function findheadlen(harmony){								
		var str = harmony;							
		var t = str.substr(1,1);							
		if ((t == "b") || (t == "#")){							
			return 2;						
		}							
		else{							
			return 1;						
		}							
	}
    
    
    function findhead(str){
        var headlen = findheadlen(str);					
        return str.substr(0,headlen);					
    }

    function replaceChordSymbols(cursor, segment) {
        var toreplace = "G#";
        var rwith = "Ab";

        var headlen = findheadlen(toreplace);	
        var rhead = toreplace.substr(0,headlen)
        var rtail = toreplace.substr(headlen)
        headlen = findheadlen(rwith);	
        var whead = rwith.substr(0,headlen)
        var wtail = rwith.substr(headlen)
        
                     
        //console.log ("rhead = ", rhead)
        //console.log ("rtail = ", rtail)
        //console.log ("whead = ", whead)
        //console.log ("wtail = ", wtail)
        
        while (segment) {
            var aCount = 0;
            var annotation = segment.annotations[aCount];

            while (annotation) {
                if (annotation.type == Element.HARMONY) {
                    var head = "";
                    var tail = ""
                    var slashtail = "";
                    var harmony = annotation;
                    var str = harmony.text;
                    if (str != ""){
                        // find slashtail
                        var slashtail = "";
                        var n = str.search("/");					
                        if (n > -1) {
                            slashtail = str.substr(n);
                            head = str.substr(0,n);
                            //console.log ("slashtail = ", slashtail)  
                            //console.log ("head = ", head)          
                        }
                        // relevant cases:
                        // rhead != whead -> global enharmonic substitution
                        if (rhead != whead){
                            //no tail? global head replace
                            if (rtail == "" && wtail == ""){
                                var slen = findheadlen(str);	
                                var hhead = str.substr(0,slen)
                                var htail = str.substr(slen)
                                //console.log ("str = ", str)
                                //console.log ("hhead = ", hhead)
                                //console.log ("htail = ", htail)
                                if(hhead == rhead) {
                                    harmony.text = whead + htail;
                                    console.log ("Replacing " + toreplace + " with " + whead + htail + " at tick " + segment.tick)
                                }
                            }
                            else {
                                var str = harmony.text;
                                var n = str.search("/");					
                                if (n > -1) str = str.substr(0,n);

                                if(str == toreplace) {
                                    if (slashtail.length > 0)   harmony.text = rwith + slashtail;
                                    else harmony.text = rwith;
                                    console.log ("Replacing " + toreplace + slashtail + " with " + rwith + slashtail + " at tick " + segment.tick)
                                }
                            } 
                        }
                        // rhead = whead & rtail != wtail -> tail substitution
                        else{
                            // no slash was found in the input
                            //if (head == ""){
                                headlen = findheadlen(str);					
                                head = str.substr(0,headlen);					
                            //}        
                            //console.log ('head = ', head);	
                            //tail = str.substr(headlen,(str.length - headlen))					
                            tail = str.substr(headlen);
                            //console.log ('139 tail = ', tail);	
                            var n = tail.search("/");					
                            slashtail = "";
                            if (n > -1) {
                                slashtail = tail.substr(n);
                                tail = tail.substr(0,n);
                            }
                            //console.log ('146 tail = ', tail);
                            if(tail == rtail) {
                                harmony.text = head + wtail + slashtail;
                                console.log ("Replacing " + str + " with " + head + wtail + slashtail + " at tick " + segment.tick)
                            } // if(tail == rtail)
                        } // end else	
                    }// end if str
                }// end annotation.type == Element.HARMONY
                annotation = segment.annotations[++aCount];
            } // end while annotation   
            segment = segment.next;    
        } // end while segment    
    } // end function

function smartQuit() {
		
		if (mscoreMajorVersion < 4) {Qt.quit()}
		else {quit()}
	}//smartQuit
    

    onRun: {
        if (typeof curScore === 'undefined') {
            smartQuit();
        }
        
        var cursor = curScore.newCursor();
        cursor.rewind(0); // beginning of score									
    
        var segment = curScore.firstSegment();
        
        curScore.startCmd();
        replaceChordSymbols(cursor, segment)    
        curScore.endCmd();
        
        smartQuit()    
        } // end onRun					
}
