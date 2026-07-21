const String couchdbUser =
    String.fromEnvironment('COUCHDB_USER', defaultValue: '');
const String couchdbPassword =
    String.fromEnvironment('COUCHDB_PASSWORD', defaultValue: '');
const bool isDev =
    String.fromEnvironment('IS_DEV', defaultValue: 'true') == 'true';
