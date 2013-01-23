package edu.du.controllers {
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.net.FileReference;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	
	public class FileController {
		
		public var runTimer:Timer;
		public var fileQueue:ArrayCollection;
		private var pathDivider:String;
		
		public function FileController() {
			pathDivider = FlexGlobals.topLevelApplication.pathDivider;
			
			runTimer = new Timer(5000);
			runTimer.addEventListener(TimerEvent.TIMER, gatherFiles);
			fileQueue = new ArrayCollection();
			
		}
		private function gatherFiles(e:TimerEvent):void {
			if(FlexGlobals.topLevelApplication.isOK){
				var presets:ArrayCollection = FlexGlobals.topLevelApplication.presetCollection;
				for(var i:uint = 0; i < presets.length; i++){
					var watchDirectory:File = new File(presets[i].watch);
					var destDirectory:File = new File(presets[i].dest);
					var availableFiles:Array = watchDirectory.getDirectoryListing();
					for(var j:uint = 0; j < availableFiles.length; j++){
						if(!availableFiles[j].isDirectory && availableFiles[j].extension != "db" && availableFiles[j].extension != "exe"){
							var rightNow:Date = new Date();
							var source:File = new File(availableFiles[j].nativePath);
							

							var holdingQueue:File = watchDirectory.resolvePath("VideoQueue");
							holdingQueue.createDirectory();
							
							
							var targetString:String = holdingQueue.nativePath + pathDivider + rightNow.time + "_" + availableFiles[j].name;
							var target:File = holdingQueue.resolvePath(targetString);
							
							
							source.moveTo(target, true);
							
							var currentObject:Object = new Object();
							
							//original file name
							currentObject.n = availableFiles[j].name; 
							
							//file location HB reads from
							currentObject.i = targetString;
							
							//destination folder
							currentObject.d = presets[i].dest;
							
							//HB output file 
							currentObject.o = presets[i].dest + pathDivider + availableFiles[j].name.substr(0, availableFiles[j].name.length - availableFiles[j].extension.length) + "mp4";
							
							//HB args
							currentObject.a = presets[i].args;
							
							//preserve original?
							currentObject.p = presets[i].orig;
							
							//original file folder
							currentObject.h = presets[i].watch + pathDivider + "OriginalFiles" + pathDivider + availableFiles[j].name;
							
							fileQueue.addItem(currentObject);
						}
					}
				}
				processFileQueue();
			}
		}
		public function removeFile(f:String, d:Boolean):void {
			if(d){
				if(fileQueue[0].p == "1"){
					var fileDestination:File = new File(fileQueue[0].d);
					fileDestination.resolvePath("OriginalFiles");
					fileDestination.createDirectory();
					
					var originalFile:File = new File(fileQueue[0].h);
					
					var fileToMove:File = new File(fileQueue[0].i);
					fileToMove.moveTo(originalFile, true);
				}else {
					var fileToDelete:File = new File(fileQueue[0].i);
					fileToDelete.deleteFile();
				}
			}
			fileQueue.removeItemAt(0);
		}
		
		private function processFileQueue():void {
			if(fileQueue.length != 0 && !FlexGlobals.topLevelApplication.processRunning() && FlexGlobals.topLevelApplication.isOK){
				FlexGlobals.topLevelApplication.beginProcess(fileQueue[0].i, fileQueue[0].o, fileQueue[0].a);
			}
		}
		
	}
}