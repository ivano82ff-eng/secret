// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StoredEnvelopesTable extends StoredEnvelopes
    with TableInfo<$StoredEnvelopesTable, StoredEnvelope> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredEnvelopesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciphertextMeta = const VerificationMeta(
    'ciphertext',
  );
  @override
  late final GeneratedColumn<String> ciphertext = GeneratedColumn<String>(
    'ciphertext',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chatId,
    sender,
    createdAt,
    ciphertext,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'envelopes';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredEnvelope> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('ciphertext')) {
      context.handle(
        _ciphertextMeta,
        ciphertext.isAcceptableOrUnknown(data['ciphertext']!, _ciphertextMeta),
      );
    } else if (isInserting) {
      context.missing(_ciphertextMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredEnvelope map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredEnvelope(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      ciphertext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ciphertext'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $StoredEnvelopesTable createAlias(String alias) {
    return $StoredEnvelopesTable(attachedDatabase, alias);
  }
}

class StoredEnvelope extends DataClass implements Insertable<StoredEnvelope> {
  final String id;
  final String chatId;
  final String sender;
  final DateTime createdAt;
  final String ciphertext;
  final String status;
  const StoredEnvelope({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.createdAt,
    required this.ciphertext,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chat_id'] = Variable<String>(chatId);
    map['sender'] = Variable<String>(sender);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['ciphertext'] = Variable<String>(ciphertext);
    map['status'] = Variable<String>(status);
    return map;
  }

  StoredEnvelopesCompanion toCompanion(bool nullToAbsent) {
    return StoredEnvelopesCompanion(
      id: Value(id),
      chatId: Value(chatId),
      sender: Value(sender),
      createdAt: Value(createdAt),
      ciphertext: Value(ciphertext),
      status: Value(status),
    );
  }

  factory StoredEnvelope.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredEnvelope(
      id: serializer.fromJson<String>(json['id']),
      chatId: serializer.fromJson<String>(json['chatId']),
      sender: serializer.fromJson<String>(json['sender']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      ciphertext: serializer.fromJson<String>(json['ciphertext']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chatId': serializer.toJson<String>(chatId),
      'sender': serializer.toJson<String>(sender),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'ciphertext': serializer.toJson<String>(ciphertext),
      'status': serializer.toJson<String>(status),
    };
  }

  StoredEnvelope copyWith({
    String? id,
    String? chatId,
    String? sender,
    DateTime? createdAt,
    String? ciphertext,
    String? status,
  }) => StoredEnvelope(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    sender: sender ?? this.sender,
    createdAt: createdAt ?? this.createdAt,
    ciphertext: ciphertext ?? this.ciphertext,
    status: status ?? this.status,
  );
  StoredEnvelope copyWithCompanion(StoredEnvelopesCompanion data) {
    return StoredEnvelope(
      id: data.id.present ? data.id.value : this.id,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      sender: data.sender.present ? data.sender.value : this.sender,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      ciphertext: data.ciphertext.present
          ? data.ciphertext.value
          : this.ciphertext,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredEnvelope(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('sender: $sender, ')
          ..write('createdAt: $createdAt, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, chatId, sender, createdAt, ciphertext, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredEnvelope &&
          other.id == this.id &&
          other.chatId == this.chatId &&
          other.sender == this.sender &&
          other.createdAt == this.createdAt &&
          other.ciphertext == this.ciphertext &&
          other.status == this.status);
}

class StoredEnvelopesCompanion extends UpdateCompanion<StoredEnvelope> {
  final Value<String> id;
  final Value<String> chatId;
  final Value<String> sender;
  final Value<DateTime> createdAt;
  final Value<String> ciphertext;
  final Value<String> status;
  final Value<int> rowid;
  const StoredEnvelopesCompanion({
    this.id = const Value.absent(),
    this.chatId = const Value.absent(),
    this.sender = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ciphertext = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredEnvelopesCompanion.insert({
    required String id,
    required String chatId,
    required String sender,
    required DateTime createdAt,
    required String ciphertext,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chatId = Value(chatId),
       sender = Value(sender),
       createdAt = Value(createdAt),
       ciphertext = Value(ciphertext),
       status = Value(status);
  static Insertable<StoredEnvelope> custom({
    Expression<String>? id,
    Expression<String>? chatId,
    Expression<String>? sender,
    Expression<DateTime>? createdAt,
    Expression<String>? ciphertext,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (sender != null) 'sender': sender,
      if (createdAt != null) 'created_at': createdAt,
      if (ciphertext != null) 'ciphertext': ciphertext,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredEnvelopesCompanion copyWith({
    Value<String>? id,
    Value<String>? chatId,
    Value<String>? sender,
    Value<DateTime>? createdAt,
    Value<String>? ciphertext,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return StoredEnvelopesCompanion(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      ciphertext: ciphertext ?? this.ciphertext,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (ciphertext.present) {
      map['ciphertext'] = Variable<String>(ciphertext.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredEnvelopesCompanion(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('sender: $sender, ')
          ..write('createdAt: $createdAt, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoredEnvelopesTable storedEnvelopes = $StoredEnvelopesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [storedEnvelopes];
}

typedef $$StoredEnvelopesTableCreateCompanionBuilder =
    StoredEnvelopesCompanion Function({
      required String id,
      required String chatId,
      required String sender,
      required DateTime createdAt,
      required String ciphertext,
      required String status,
      Value<int> rowid,
    });
typedef $$StoredEnvelopesTableUpdateCompanionBuilder =
    StoredEnvelopesCompanion Function({
      Value<String> id,
      Value<String> chatId,
      Value<String> sender,
      Value<DateTime> createdAt,
      Value<String> ciphertext,
      Value<String> status,
      Value<int> rowid,
    });

class $$StoredEnvelopesTableFilterComposer
    extends Composer<_$AppDatabase, $StoredEnvelopesTable> {
  $$StoredEnvelopesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredEnvelopesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredEnvelopesTable> {
  $$StoredEnvelopesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredEnvelopesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredEnvelopesTable> {
  $$StoredEnvelopesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$StoredEnvelopesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredEnvelopesTable,
          StoredEnvelope,
          $$StoredEnvelopesTableFilterComposer,
          $$StoredEnvelopesTableOrderingComposer,
          $$StoredEnvelopesTableAnnotationComposer,
          $$StoredEnvelopesTableCreateCompanionBuilder,
          $$StoredEnvelopesTableUpdateCompanionBuilder,
          (
            StoredEnvelope,
            BaseReferences<
              _$AppDatabase,
              $StoredEnvelopesTable,
              StoredEnvelope
            >,
          ),
          StoredEnvelope,
          PrefetchHooks Function()
        > {
  $$StoredEnvelopesTableTableManager(
    _$AppDatabase db,
    $StoredEnvelopesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredEnvelopesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredEnvelopesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredEnvelopesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> ciphertext = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredEnvelopesCompanion(
                id: id,
                chatId: chatId,
                sender: sender,
                createdAt: createdAt,
                ciphertext: ciphertext,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chatId,
                required String sender,
                required DateTime createdAt,
                required String ciphertext,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => StoredEnvelopesCompanion.insert(
                id: id,
                chatId: chatId,
                sender: sender,
                createdAt: createdAt,
                ciphertext: ciphertext,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredEnvelopesTable, StoredEnvelope>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StoredEnvelopesTable,
                    StoredEnvelope
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredEnvelopesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredEnvelopesTable,
      StoredEnvelope,
      $$StoredEnvelopesTableFilterComposer,
      $$StoredEnvelopesTableOrderingComposer,
      $$StoredEnvelopesTableAnnotationComposer,
      $$StoredEnvelopesTableCreateCompanionBuilder,
      $$StoredEnvelopesTableUpdateCompanionBuilder,
      (
        StoredEnvelope,
        BaseReferences<_$AppDatabase, $StoredEnvelopesTable, StoredEnvelope>,
      ),
      StoredEnvelope,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoredEnvelopesTableTableManager get storedEnvelopes =>
      $$StoredEnvelopesTableTableManager(_db, _db.storedEnvelopes);
}
