package sqlite;

#if nodejs

typedef Database = sqlite.impl.nodejs.SqliteDatabase;

#elseif (js && !nodejs)

typedef Database = sqlite.impl.browser.SqliteDatabase;

#elseif cpp

typedef Database = sqlite.impl.cpp.SqliteDatabase;

#elseif sys

typedef Database = sqlite.impl.sys.SqliteDatabase;

#else

typedef Database = sqlite.impl.fallback.SqliteDatabase;

#end
