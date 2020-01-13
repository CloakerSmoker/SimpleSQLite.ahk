# SimpleSQLite.ahk
I got fed up with low-quality, poorly written SQLite3 wrappers for AHK, so I went and wrote my own nice and simple one.

## How to use
Just download a copy of SQLite3.dll from the official website [here](https://www.sqlite.org/), or use the version in the repo, it's up to you to decide if you want to trust the copy I included.

Put SQLite3.dll into the same folder as SimpleSQLite.ahk, and then `#Include` SimpleSQLite.ahk into your main script.

To connect to a DB, pass the path to the constructor of the `SQLite3Connector` class.
Ex:
```
DB := new SQLite3Connector("C:\Path\To\My\DBFile.db")
```

And now call one of the 3 (three; yes, you heard that right) user methods of the `SQLite3Connector` class.

### Methods
`.Close()`: Has SQLite close the DB, the `SQLite3Connector` object this is called on will no longer function.

`.Execute(Statement)`: Takes an SQL statement as the only parameter, and returns an array of records the given statement returned.

`.PreparedExecute(Statement, Params*)`: Takes an SQL statement with places for parameters (with `?` used as the placeholder), and parameters for the given statement.

The statement is prepared before running, meaning it is pre-compiled, and should be safe against SQL injection.

### Return values
`.Execute` and `.PreparedExecute` both return arrays of results, however, unlike other DB libraries, this one returns an object, where {Key: Value} is {ColumnName: ColumnValue}. 

This is because I think it's much more readable to use text indexes compared to a blind numerical index into some array.

## Note(s)
I haven't implemented Unicode support yet, so expect odd/no results with Unicode DBs.

Oddly enough, this only works on 64 bit, Unicode AHK. I know that's dumb, I'll add Unicode DB support eventually.

32 bit support will never happen.