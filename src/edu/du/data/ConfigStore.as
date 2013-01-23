package edu.du.data {
	public class ConfigStore {
		import flash.filesystem.File;
		import flash.filesystem.FileStream;
		import flash.filesystem.FileMode;
		
		private var configFile:File;
		private var configStream:FileStream;
		private var configSetting:String;
		
		public function ConfigStore() {}
		
		public function writeConfig(hb:String):void {
			configFile = File.applicationStorageDirectory;
			configFile = configFile.resolvePath("config.txt");
			configStream = new FileStream();
			configStream.open(configFile, FileMode.WRITE);
			configStream.writeUTFBytes(hb);
			configStream.close();
		}
		
		public function readConfig():String {
			configFile = File.applicationStorageDirectory;
			configFile = configFile.resolvePath("config.txt");
			if(configFile.exists){
				configStream = new FileStream();
				configStream.open(configFile, FileMode.READ);
				configSetting = configStream.readUTFBytes(configFile.size);
				configStream.close();
			}else{
				configSetting = "";
			}
			return configSetting;
		}
		
	}
}