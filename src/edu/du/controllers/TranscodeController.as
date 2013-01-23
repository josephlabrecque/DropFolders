package edu.du.controllers {
	import flash.filesystem.FileStream;
	
	import spark.components.Label;
	import spark.components.TextArea;

	public class TranscodeController {
		import flash.desktop.NativeProcess;
		import flash.desktop.NativeProcessStartupInfo;
		import flash.events.NativeProcessExitEvent;
		import flash.events.ProgressEvent;
		import flash.events.IOErrorEvent;
		import flash.filesystem.File;
		import flash.filesystem.FileStream;
		import flash.filesystem.FileMode;
		
		import mx.core.FlexGlobals;
		import mx.controls.Alert;
		
		private var hbCLI:String;
		private var nativeProcess:NativeProcess;
		private var nativeProcessStartupInfo:NativeProcessStartupInfo;
		private var outputLabel:TextArea;
		private var hb:File;
		private var processingFilePath:String;
		private var destinationFilePath:String;
		private var destinationArgs:String;
		private var exitCode:Number;
		private var pathDivider:String;
		private var currentObject:Object;
		
		public function TranscodeController() {
			if(FlexGlobals.topLevelApplication.os == "win"){
				hbCLI = "HandBrake.exe";
			}else{
				hbCLI = "HandBrakeCLI";
			}
			pathDivider = FlexGlobals.topLevelApplication.pathDivider;
			hb = File.applicationDirectory;
			hb = hb.resolvePath("HandBrake" + pathDivider + hbCLI);
			nativeProcess = new NativeProcess();
			nativeProcessStartupInfo = new NativeProcessStartupInfo();
			outputLabel = FlexGlobals.topLevelApplication.outputLabel;
		}
		public function processRunning():Boolean {
			return nativeProcess.running;
		}
		public function invokeHB(i:String, o:String, a:String):void {
			trace("invokeHB: ",i,o,a)
			nativeProcessStartupInfo.executable = hb;
			
			outputLabel.text = "";
			currentObject = FlexGlobals.topLevelApplication.fileController.fileQueue[0];
			processingFilePath = i;
			destinationFilePath = o;
			destinationArgs = a;
			//var argStr:String = "-i " + i + " -o " + o + " " + a;
			
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs.push("-i");
			processArgs.push(i);
			processArgs.push("-o");
			processArgs.push(o);
			var argArray:Array = a.split(" ");
			for(var j:int = 0; j<argArray.length-1; j++){
				processArgs.push(argArray[j]);
			}
			
			nativeProcessStartupInfo.arguments = processArgs;
			
			nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			nativeProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
			nativeProcess.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
			
			nativeProcess.start(nativeProcessStartupInfo);
			outputLabel.text = "BEGIN ENCODE";
		}
		public function killHB():void {
			nativeProcess.exit();
			outputLabel.appendText("\nKILLED BY USER");
		}
		
		private function onOutputData(e:ProgressEvent):void {
			outputLabel.appendText(nativeProcess.standardOutput.readUTFBytes(nativeProcess.standardOutput.bytesAvailable));
		}
		
		private function onErrorData(e:ProgressEvent):void {
			outputLabel.appendText(nativeProcess.standardError.readUTFBytes(nativeProcess.standardError.bytesAvailable)); 
		}
		
		private function onExit(e:NativeProcessExitEvent):void {
			exitCode = e.exitCode;
			outputLabel.appendText("\nEND ENCODE");
			
			var proc:File = new File(processingFilePath);
			var dest:File = new File(destinationFilePath);
			var target:File;
			var today:Date = new Date();
			var path:String = String(today.getDate()+1) + pathDivider + today.getHours();
			
			if(e.exitCode == 0){
				if(dest.exists){
					FlexGlobals.topLevelApplication.fileController.removeFile(processingFilePath, true);
					writeLog();
				}else{
					//Alert.show("Something weird just happened. File has been moved to the desktop.", "ERROR CODE: "+e.exitCode);
					if(proc.exists){
						target = new File();
						target = target.resolvePath(currentObject.d + pathDivider + "RejectedFiles" + pathDivider + path + pathDivider + proc.name);
						proc.moveTo(target, true);
					}
					FlexGlobals.topLevelApplication.fileController.removeFile(processingFilePath, false);
					writeLog(path);
				}
				
			}else{
				if(proc.exists){
					target = new File();
					target = target.resolvePath(currentObject.d + pathDivider + "RejectedFiles" + pathDivider + path + pathDivider + proc.name);
					proc.moveTo(target, true);
				}
				FlexGlobals.topLevelApplication.fileController.removeFile(processingFilePath, false);
				writeLog(path);
			}
		}
		private function writeLog(p:String=null):void {
			var proc:File = new File(processingFilePath);
			var log:File;
			var today:Date = new Date();
			var path:String = String(today.getDate()+1) + pathDivider + today.getHours();
			if(p != null){
				log = new File();
				log = log.resolvePath(currentObject.d + pathDivider + "RejectedFiles" + pathDivider + path + pathDivider + proc.name + "_rejected.log");
			}else{
				log = File.applicationStorageDirectory;
				log = log.resolvePath("process.log");
			}
			var logStream:FileStream = new FileStream();
			logStream.open(log, FileMode.WRITE);
			logStream.writeUTFBytes("DropFolders " + FlexGlobals.topLevelApplication.versionLabel.text + "\n\r\n\r");
			logStream.writeUTFBytes("\n\r-----------------------------------\n\r");
			logStream.writeUTFBytes("\n\r");
			logStream.writeUTFBytes("\n\r" + outputLabel.text + "\n\r");
			logStream.writeUTFBytes("\n\r");
			logStream.writeUTFBytes("\n\r-----------------------------------\n\r");
			logStream.writeUTFBytes("\n\rINPUT: " + processingFilePath + "\n\r");
			logStream.writeUTFBytes("\n\rOUTPUT: " + destinationFilePath + "\n\r");
			logStream.writeUTFBytes("\n\rARGUMENTS: " + destinationArgs + "\n\r");
			logStream.writeUTFBytes("\n\rEXIT CODE: " + String(exitCode));
			logStream.close();
		}
		
		private function onIOError(e:IOErrorEvent):void {
			outputLabel.appendText(e.toString());
		}
	}
}