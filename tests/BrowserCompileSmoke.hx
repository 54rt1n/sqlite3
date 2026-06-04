import sqlite.Database;

class BrowserCompileSmoke {
    static function main() {
        var db = new Database(":memory:");
        db.open().then(_ -> {
            return db.all("select 1 as value");
        }).then(result -> {
            trace(result.data);
            return null;
        }, error -> {
            trace(error);
            return null;
        });
    }
}
