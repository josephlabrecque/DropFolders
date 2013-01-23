package edu.du.data {
	import flash.data.SQLStatement;
	
	public class PresetStore {
		import mx.collections.ArrayCollection;
		import flash.data.SQLConnection;
		import flash.data.SQLResult;
		import flash.events.SQLErrorEvent;
		import flash.events.SQLEvent;
		import flash.filesystem.File;
		import mx.core.FlexGlobals;
		import mx.controls.Alert;
		
		private var sqlConnection:SQLConnection;
		private var initComplete:Boolean;
		private var sql:SQLStatement;
		private var config:File;
		
		public function PresetStore() {
			sqlConnection = new SQLConnection();
			sqlConnection.addEventListener(SQLEvent.OPEN, presetsOpen);
			sqlConnection.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			config = File.applicationStorageDirectory.resolvePath("presets.db");
			sqlConnection.openAsync(config);
		}
		
		private function presetsOpen(e:SQLEvent):void {
			sql = new SQLStatement();
			sql.sqlConnection = sqlConnection;
			sql.addEventListener(SQLEvent.RESULT, presetsResult);
			sql.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			sql.text = "CREATE TABLE IF NOT EXISTS presets(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, args TEXT, watch TEXT, orig TEXT DEFAULT '0', dest TEXT);";
			sql.execute();
		}
		private function presetsResult(e:SQLEvent):void {
			sql = new SQLStatement();
			sql.sqlConnection = sqlConnection;
			sql.removeEventListener(SQLEvent.RESULT, readResult);
			sql.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			sql.addEventListener(SQLEvent.RESULT, allSet)
			sql.addEventListener(SQLErrorEvent.ERROR, updateTable);
			sql.text = "SELECT orig FROM presets;";
			sql.execute();
		}
		private function allSet(e:SQLEvent):void {
			sql.removeEventListener(SQLEvent.RESULT, allSet)
			sql.removeEventListener(SQLErrorEvent.ERROR, updateTable);
			readData();
		}
		
		private function updateTable(e:SQLErrorEvent):void {
			sql = new SQLStatement();
			sql.sqlConnection = sqlConnection;
			sql.addEventListener(SQLEvent.RESULT, updateResult);
			sql.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			sql.text = "ALTER TABLE presets ADD orig TEXT DEFAULT '0';"
			sql.execute();
		}
		private function updateResult(e:SQLEvent):void {
			sql.removeEventListener(SQLEvent.RESULT, updateResult);
			sql.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			readData();
		}
		
		
		
		/*
		
		private function writeExamplePreset():void {
			sql = new SQLStatement();
			sql.sqlConnection = sqlConnection;
			sql.addEventListener(SQLEvent.RESULT, writeExamplePresetResult);
			sql.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			sql.text = "INSERT INTO presets(name, watch, dest, args) VALUES('Example Preset', '" + File.applicationStorageDirectory + "', '" + File.applicationStorageDirectory + "', '-w 512 -l 288 --deinterlace=\"slow\" -e x264 -b 1000 -a 1 -E faac -6 stereo -R 44.1 -B 128 -D 0.0 -x ref=2:bframes=3:subq=6:mixed-refs=0:8x8dct=0:trellis=0:weightb=0:no-fast-pskip=1 -v 1')";
			sql.execute();
		}
		private function writeExamplePresetResult(e:SQLEvent):void {
			sql.removeEventListener(SQLEvent.RESULT, writeExamplePresetResult);
			sql.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			FlexGlobals.topLevelApplication.clearPresetValues();
		}
		
		*/
		
		
		public function readData():void {
			sql = new SQLStatement();
			sql.sqlConnection = sqlConnection;
			sql.addEventListener(SQLEvent.RESULT, readResult);
			sql.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			sql.text = "SELECT * FROM presets;";
			sql.execute();
		}
		private function readResult(e:SQLEvent):void {
			sql.removeEventListener(SQLEvent.RESULT, readResult);
			sql.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			var result:SQLResult = sql.getResult();
			FlexGlobals.topLevelApplication.presetCollection = new ArrayCollection();
			if(result.data != null){
				for(var i:int=0; i<=result.data.length-1; i++){
					FlexGlobals.topLevelApplication.presetCollection.addItem({id:result.data[i].id, name:unescape(result.data[i].name), args:unescape(result.data[i].args), watch:result.data[i].watch, dest:result.data[i].dest, orig:result.data[i].orig});
				}
			}
			trace("done");
			FlexGlobals.topLevelApplication.fileController.runTimer.start();
		}
		
		
		
		
		public function writeData(n:String, w:String, d:String, a:String, o:String, i:*=null):void {
			trace("WRITE ", n, w, d, a, i);
			sql = new SQLStatement();
			sql.sqlConnection = sqlConnection;
			sql.addEventListener(SQLEvent.RESULT, writeResult);
			sql.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			if(i != null){
				sql.text = "UPDATE presets SET name='" + escape(n) + "', watch='" + w + "', orig='" + o + "', dest='" + d + "', args='" + escape(a) + "' WHERE id=" + i;
			}else{
				sql.text = "INSERT INTO presets(name, watch, dest, args, orig) VALUES('" + escape(n) + "', '" + w + "', '" + d + "', '" + escape(a) + "', '" + o + "')";
			}
			sql.execute();
		}
		public function writeResult(e:SQLEvent):void {
			trace("Written... ", e);
			sql.removeEventListener(SQLEvent.RESULT, readResult);
			sql.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			FlexGlobals.topLevelApplication.clearPresetValues();
		}
		
		
		
		
		public function deleteData(p:int):void {
			sql = new SQLStatement();
			sql.sqlConnection = sqlConnection;
			sql.addEventListener(SQLEvent.RESULT, writeResult);
			sql.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			sql.addEventListener(SQLEvent.RESULT, writeResult);
			sql.text = "DELETE FROM presets WHERE id=" + p;
			sql.execute();
		}
		public function deleteResult(e:SQLEvent):void {
			trace("DELETED... ", e);
			sql.removeEventListener(SQLEvent.RESULT, readResult);
			sql.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			FlexGlobals.topLevelApplication.clearPresetValues();
		}
		
		
		private function errorHandler(e:SQLErrorEvent):void {
			sql.removeEventListener(SQLEvent.RESULT, readResult);
			sql.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			Alert.show(e.toString());
		}
		
	}
}