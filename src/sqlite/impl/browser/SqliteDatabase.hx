package sqlite.impl.browser;

import js.Syntax;
import js.lib.Promise as JsPromise;
import promises.Promise;
import sqlite.SqliteError;
import sqlite.SqliteResult;
import sqlite.impl.DatabaseBase;

class SqliteDatabase extends DatabaseBase {
    private var _databaseId:Null<Int> = null;
    private var _closed:Bool = true;

    public override function open():Promise<SqliteResult<Bool>> {
        return call("open", {
            filename: filename,
            openMode: openMode == null ? null : Type.enumConstructor(openMode)
        }, result -> {
            var id:Dynamic = Reflect.field(result, "databaseId");
            if (id != null) {
                _databaseId = Std.int(id);
            }
            _closed = false;
            return true;
        });
    }

    public override function exec(sql:String):Promise<SqliteResult<Bool>> {
        return call("exec", withDatabase({ sql: sql }), _ -> true);
    }

    public override function get(sql:String, ?param:Dynamic):Promise<SqliteResult<Dynamic>> {
        return call("get", withDatabase({ sql: sql, params: normalizeParams(param) }), result -> Reflect.field(result, "data"));
    }

    public override function run(sql:String, ?param:Dynamic):Promise<SqliteResult<Dynamic>> {
        return call("run", withDatabase({ sql: sql, params: normalizeParams(param) }), result -> Reflect.field(result, "data"));
    }

    public override function all(sql:String, ?param:Dynamic):Promise<SqliteResult<Array<Dynamic>>> {
        return call("all", withDatabase({ sql: sql, params: normalizeParams(param) }), result -> cast Reflect.field(result, "data"));
    }

    public override function close():Promise<SqliteResult<Bool>> {
        if (_closed) {
            return Promise.resolve(new SqliteResult(this, true));
        }
        return call("close", withDatabase({}), _ -> {
            _closed = true;
            _databaseId = null;
            return true;
        });
    }

    private function withDatabase(payload:Dynamic):Dynamic {
        Reflect.setField(payload, "databaseId", _databaseId);
        return payload;
    }

    private function normalizeParams(param:Dynamic):Dynamic {
        if (param == null) return null;
        return switch (Type.typeof(param)) {
            case TClass(Array): param;
            case _: [param];
        }
    }

    private function call<T>(method:String, payload:Dynamic, readData:Dynamic->T):Promise<SqliteResult<T>> {
        return new Promise((resolve, reject) -> {
            var bridge:Dynamic = Syntax.code("globalThis.haxeSqlite3");
            if (bridge == null || !Reflect.isFunction(Reflect.field(bridge, "call"))) {
                reject(new SqliteError("Error", "Missing browser SQLite bridge: globalThis.haxeSqlite3.call"));
                return;
            }

            try {
                var jsPromise:JsPromise<Dynamic> = Reflect.callMethod(bridge, Reflect.field(bridge, "call"), [method, payload]);
                jsPromise.then(result -> {
                    var sqliteResult = new SqliteResult(this, readData(result));
                    applyStats(sqliteResult, result);
                    resolve(sqliteResult);
                    return null;
                }, error -> {
                    reject(toSqliteError(error));
                    return null;
                });
            } catch (error:Dynamic) {
                reject(toSqliteError(error));
            }
        });
    }

    private function applyStats<T>(target:SqliteResult<T>, source:Dynamic):Void {
        var lastID:Dynamic = Reflect.field(source, "lastID");
        if (lastID != null) target.lastID = Std.int(lastID);
        var changes:Dynamic = Reflect.field(source, "changes");
        if (changes != null) target.changes = Std.int(changes);
    }

    private function toSqliteError(error:Dynamic):SqliteError {
        if ((error is SqliteError)) return cast error;
        var name = Reflect.field(error, "name");
        var message = Reflect.field(error, "message");
        if (name == null) name = "Error";
        if (message == null) message = Std.string(error);
        return new SqliteError(Std.string(name), Std.string(message));
    }
}
