class SQLite3 {
	static OK := 0
	static ERROR := 0
	static INTERNAL := 0
	
	static OPEN_READONLY := 0x00000001
	static OPEN_READWRITE := 0x00000002
	static OPEN_CREATE := 0x00000004
	static OPEN_URI := 0x00000040
	static OPEN_MEMORY := 0x00000080
	static OPEN_NOMUTEX := 0x00008000
	static OPEN_FULLMUTEX := 0x00010000
	static OPEN_SHAREDCACHE := 0x00020000
	static OPEN_PRIVATECACHE := 0x00040000
	
	static ROW := 100
	static DONE := 101
}

class SQLite3Connector {
	static DLL := A_LineFile "\..\sqlite3.dll"
	static _ := SQLite3Connector.LoadDLL()
	
	LoadDLL() {
		DllCall("LoadLibrary", "Str", this.DLL, "Ptr")
	}

	__New(DBFilePath) {
		this.PreparedStatements := []
		this.Open(DBFilePath)
		OnExit(this.Delete.Bind(this))
	}
	Delete() {
		this.Close()
		
		for k, pStatementHandle in this.PreparedStatements {
			DllCall(this.DLL "\sqlite3_finalize", "Ptr", pStatementHandle)
		}
	}
	
	Open(DBFilePath) {
		Error := DllCall(this.DLL "\sqlite3_open_v2", "AStr", DBFilePath, "Ptr*", pSQLite3, "Int", SQLite3.OPEN_CREATE | SQLite3.OPEN_READWRITE, "UInt", 0, "UInt")
		this.pSQLite3 := pSQLite3
		
		if (Error != SQLite3.OK) {
			Throw, Exception(this.GetLastError())
		}
	}
	Close() {
		DllCall(this.DLL "\sqlite3_close_v2", "Ptr", this.pSQLite3)
	}
	GetLastError() {
		pErrorText := DllCall(this.DLL "\sqlite3_errmsg", "Ptr", this.pSQLite3, "Ptr")
	
		return StrGet(pErrorText, "UTF-8")
	}
	Execute(Statement) {
		static Callback := RegisterCallback("SQLite3Callback")
	
		Results := []
		pResults := &Results
		ObjAddRef(pResults)
	
		Error := DllCall(this.DLL "\sqlite3_exec", "Ptr", this.pSQLite3, "AStr", Statement, "Ptr", Callback, "Ptr", pResults, "Ptr*", pErrorText, "UInt")
		
		if (Error != SQLite3.OK) {
			Throw, Exception(StrGet(pErrorText, "UTF-8"))
		}
	
		return Results
	}
	PreparedExecute(Statement, Params*) {
		pStatementHandle := this.Prepare(Statement)
		this.Bind(pStatementHandle, Params*)
		return this.Call(pStatementHandle)
	}
	
	Prepare(Statement) {
		Error := DllCall(this.DLL "\sqlite3_prepare_v2", "Ptr", this.pSQLite3, "AStr", Statement, "Int", -1, "Ptr*", pStatementHandle, "UInt", 0, "UInt")
	
		if (Error != SQLite3.OK) {
			Throw, Exception(this.GetLastError())
		}
		
		this.PreparedStatements.Push(pStatementHandle)
		return pStatementHandle
	}
	Bind(pStatementHandle, Params*) {
		for k, Param in Params {
			IsFloat := Conversions.IsFloat(Param)
		
			if (IsFloat || Conversions.IsNumber(Param)) {
				if (IsFloat) {
					Function := "sqlite3_bind_double"
					Type := "Double"
				}
				else {
					Function := "sqlite3_bind_int"
					Type := "Int"
				}
				
				Error := DllCall(this.DLL "\" Function, "Ptr", pStatementHandle, "Int", k, Type, Param, "UInt")
			}
			else {
				Error := DllCall(this.DLL "\sqlite3_bind_text", "Ptr", pStatementHandle, "Int", k, "AStr", Param, "Int", StrLen(Param), "UInt", 0)
			}
		
			if (Error != SQLite3.OK) {
				Throw, Exception(this.GetLastError())
			}
		}
	}
	Call(pStatementHandle) {
		Results := []
		
		loop {
			Result := DllCall(this.DLL "\sqlite3_step", "Ptr", pStatementHandle)
		
			Switch (Result) {
				Case SQLite3.ROW: {
					RecordObject := {}
				
					ColumnCount := DllCall(this.DLL "\sqlite3_data_count", "Ptr", pStatementHandle)
					
					loop, % ColumnCount {
						pColumnName := DllCall(this.DLL "\sqlite3_column_name", "Ptr", pStatementHandle, "Int", A_Index - 1)
						ColumnName := StrGet(pColumnName, "UTF-8")
						
						pColumnText := DllCall(this.DLL "\sqlite3_column_text", "Ptr", pStatementHandle, "Int", A_Index - 1)
						ColumnText := StrGet(pColumnText, "UTF-8")
						
						RecordObject[ColumnName] := ColumnText
					}
					
					Results.Push(RecordObject)
				}
				Case SQLite3.DONE: {
					Break
				}
				Default: {
					Throw, Exception(this.GetLastError())
				}
			}
		}
		
		DllCall(this.DLL "\sqlite3_reset", "Ptr", pStatementHandle)
		
		return Results
	}
}
SQLite3Callback(pResults, NumberOfColumns, PointersToColumnText, PointersToColumnNames) {
	ObjAddRef(pResults)
	Results := Object(pResults)

	RecordObject := {}

	Loop, % NumberOfColumns {
		pColumnText := NumGet(PointersToColumnText + 0, (A_Index - 1) * 8, "Ptr")
		ColumnText := StrGet(pColumnText, "UTF-8")
		
		pColumnName := NumGet(PointersToColumnNames + 0, (A_Index - 1) * 8, "Ptr")
		ColumnName := StrGet(pColumnName, "UTF-8")
		
		RecordObject[ColumnName] := ColumnText
	}
	
	Results.Push(RecordObject)
	ObjRelease(Param)
	
	return SQLite3.OK
}