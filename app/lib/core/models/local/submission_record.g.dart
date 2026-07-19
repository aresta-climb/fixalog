// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSubmissionRecordCollection on Isar {
  IsarCollection<SubmissionRecord> get submissionRecords => this.collection();
}

const SubmissionRecordSchema = CollectionSchema(
  name: r'SubmissionRecord',
  id: -7139399540097331255,
  properties: {
    r'dataInclusao': PropertySchema(
      id: 0,
      name: r'dataInclusao',
      type: IsarType.dateTime,
    ),
    r'enviadoNuvem': PropertySchema(
      id: 1,
      name: r'enviadoNuvem',
      type: IsarType.bool,
    ),
    r'hashAssinatura': PropertySchema(
      id: 2,
      name: r'hashAssinatura',
      type: IsarType.string,
    ),
    r'idProtocolo': PropertySchema(
      id: 3,
      name: r'idProtocolo',
      type: IsarType.string,
    ),
    r'idSessao': PropertySchema(
      id: 4,
      name: r'idSessao',
      type: IsarType.string,
    ),
    r'nomeProtocolo': PropertySchema(
      id: 5,
      name: r'nomeProtocolo',
      type: IsarType.string,
    ),
    r'pdfPath': PropertySchema(id: 6, name: r'pdfPath', type: IsarType.string),
    r'protobufPath': PropertySchema(
      id: 7,
      name: r'protobufPath',
      type: IsarType.string,
    ),
  },

  estimateSize: _submissionRecordEstimateSize,
  serialize: _submissionRecordSerialize,
  deserialize: _submissionRecordDeserialize,
  deserializeProp: _submissionRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'idSessao': IndexSchema(
      id: 5989576124550947893,
      name: r'idSessao',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'idSessao',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _submissionRecordGetId,
  getLinks: _submissionRecordGetLinks,
  attach: _submissionRecordAttach,
  version: '3.3.2',
);

int _submissionRecordEstimateSize(
  SubmissionRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.hashAssinatura.length * 3;
  bytesCount += 3 + object.idProtocolo.length * 3;
  bytesCount += 3 + object.idSessao.length * 3;
  bytesCount += 3 + object.nomeProtocolo.length * 3;
  bytesCount += 3 + object.pdfPath.length * 3;
  bytesCount += 3 + object.protobufPath.length * 3;
  return bytesCount;
}

void _submissionRecordSerialize(
  SubmissionRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.dataInclusao);
  writer.writeBool(offsets[1], object.enviadoNuvem);
  writer.writeString(offsets[2], object.hashAssinatura);
  writer.writeString(offsets[3], object.idProtocolo);
  writer.writeString(offsets[4], object.idSessao);
  writer.writeString(offsets[5], object.nomeProtocolo);
  writer.writeString(offsets[6], object.pdfPath);
  writer.writeString(offsets[7], object.protobufPath);
}

SubmissionRecord _submissionRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubmissionRecord();
  object.dataInclusao = reader.readDateTime(offsets[0]);
  object.enviadoNuvem = reader.readBool(offsets[1]);
  object.hashAssinatura = reader.readString(offsets[2]);
  object.id = id;
  object.idProtocolo = reader.readString(offsets[3]);
  object.idSessao = reader.readString(offsets[4]);
  object.nomeProtocolo = reader.readString(offsets[5]);
  object.pdfPath = reader.readString(offsets[6]);
  object.protobufPath = reader.readString(offsets[7]);
  return object;
}

P _submissionRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _submissionRecordGetId(SubmissionRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _submissionRecordGetLinks(SubmissionRecord object) {
  return [];
}

void _submissionRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  SubmissionRecord object,
) {
  object.id = id;
}

extension SubmissionRecordByIndex on IsarCollection<SubmissionRecord> {
  Future<SubmissionRecord?> getByIdSessao(String idSessao) {
    return getByIndex(r'idSessao', [idSessao]);
  }

  SubmissionRecord? getByIdSessaoSync(String idSessao) {
    return getByIndexSync(r'idSessao', [idSessao]);
  }

  Future<bool> deleteByIdSessao(String idSessao) {
    return deleteByIndex(r'idSessao', [idSessao]);
  }

  bool deleteByIdSessaoSync(String idSessao) {
    return deleteByIndexSync(r'idSessao', [idSessao]);
  }

  Future<List<SubmissionRecord?>> getAllByIdSessao(
    List<String> idSessaoValues,
  ) {
    final values = idSessaoValues.map((e) => [e]).toList();
    return getAllByIndex(r'idSessao', values);
  }

  List<SubmissionRecord?> getAllByIdSessaoSync(List<String> idSessaoValues) {
    final values = idSessaoValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'idSessao', values);
  }

  Future<int> deleteAllByIdSessao(List<String> idSessaoValues) {
    final values = idSessaoValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'idSessao', values);
  }

  int deleteAllByIdSessaoSync(List<String> idSessaoValues) {
    final values = idSessaoValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'idSessao', values);
  }

  Future<Id> putByIdSessao(SubmissionRecord object) {
    return putByIndex(r'idSessao', object);
  }

  Id putByIdSessaoSync(SubmissionRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'idSessao', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIdSessao(List<SubmissionRecord> objects) {
    return putAllByIndex(r'idSessao', objects);
  }

  List<Id> putAllByIdSessaoSync(
    List<SubmissionRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'idSessao', objects, saveLinks: saveLinks);
  }
}

extension SubmissionRecordQueryWhereSort
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QWhere> {
  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SubmissionRecordQueryWhere
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QWhereClause> {
  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhereClause>
  idSessaoEqualTo(String idSessao) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'idSessao', value: [idSessao]),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterWhereClause>
  idSessaoNotEqualTo(String idSessao) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'idSessao',
                lower: [],
                upper: [idSessao],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'idSessao',
                lower: [idSessao],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'idSessao',
                lower: [idSessao],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'idSessao',
                lower: [],
                upper: [idSessao],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SubmissionRecordQueryFilter
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QFilterCondition> {
  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  dataInclusaoEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dataInclusao', value: value),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  dataInclusaoGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dataInclusao',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  dataInclusaoLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dataInclusao',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  dataInclusaoBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dataInclusao',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  enviadoNuvemEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enviadoNuvem', value: value),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'hashAssinatura',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'hashAssinatura',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'hashAssinatura',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'hashAssinatura',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'hashAssinatura',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'hashAssinatura',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'hashAssinatura',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'hashAssinatura',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hashAssinatura', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  hashAssinaturaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'hashAssinatura', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'idProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'idProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'idProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'idProtocolo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'idProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'idProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'idProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'idProtocolo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'idProtocolo', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idProtocoloIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'idProtocolo', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'idSessao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'idSessao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'idSessao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'idSessao',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'idSessao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'idSessao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'idSessao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'idSessao',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'idSessao', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  idSessaoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'idSessao', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nomeProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nomeProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nomeProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nomeProtocolo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nomeProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nomeProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nomeProtocolo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nomeProtocolo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nomeProtocolo', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  nomeProtocoloIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nomeProtocolo', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pdfPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pdfPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pdfPath', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  pdfPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pdfPath', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'protobufPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'protobufPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'protobufPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'protobufPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'protobufPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'protobufPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'protobufPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'protobufPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'protobufPath', value: ''),
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterFilterCondition>
  protobufPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'protobufPath', value: ''),
      );
    });
  }
}

extension SubmissionRecordQueryObject
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QFilterCondition> {}

extension SubmissionRecordQueryLinks
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QFilterCondition> {}

extension SubmissionRecordQuerySortBy
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QSortBy> {
  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByDataInclusao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataInclusao', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByDataInclusaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataInclusao', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByEnviadoNuvem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enviadoNuvem', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByEnviadoNuvemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enviadoNuvem', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByHashAssinatura() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashAssinatura', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByHashAssinaturaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashAssinatura', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByIdProtocolo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idProtocolo', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByIdProtocoloDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idProtocolo', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByIdSessao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idSessao', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByIdSessaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idSessao', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByNomeProtocolo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nomeProtocolo', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByNomeProtocoloDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nomeProtocolo', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByPdfPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfPath', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByPdfPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfPath', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByProtobufPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protobufPath', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  sortByProtobufPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protobufPath', Sort.desc);
    });
  }
}

extension SubmissionRecordQuerySortThenBy
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QSortThenBy> {
  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByDataInclusao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataInclusao', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByDataInclusaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataInclusao', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByEnviadoNuvem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enviadoNuvem', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByEnviadoNuvemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enviadoNuvem', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByHashAssinatura() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashAssinatura', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByHashAssinaturaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashAssinatura', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByIdProtocolo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idProtocolo', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByIdProtocoloDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idProtocolo', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByIdSessao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idSessao', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByIdSessaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idSessao', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByNomeProtocolo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nomeProtocolo', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByNomeProtocoloDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nomeProtocolo', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByPdfPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfPath', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByPdfPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfPath', Sort.desc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByProtobufPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protobufPath', Sort.asc);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QAfterSortBy>
  thenByProtobufPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protobufPath', Sort.desc);
    });
  }
}

extension SubmissionRecordQueryWhereDistinct
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct> {
  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByDataInclusao() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataInclusao');
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByEnviadoNuvem() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enviadoNuvem');
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByHashAssinatura({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'hashAssinatura',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByIdProtocolo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idProtocolo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByIdSessao({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idSessao', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByNomeProtocolo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'nomeProtocolo',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByPdfPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pdfPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SubmissionRecord, SubmissionRecord, QDistinct>
  distinctByProtobufPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protobufPath', caseSensitive: caseSensitive);
    });
  }
}

extension SubmissionRecordQueryProperty
    on QueryBuilder<SubmissionRecord, SubmissionRecord, QQueryProperty> {
  QueryBuilder<SubmissionRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SubmissionRecord, DateTime, QQueryOperations>
  dataInclusaoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataInclusao');
    });
  }

  QueryBuilder<SubmissionRecord, bool, QQueryOperations>
  enviadoNuvemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enviadoNuvem');
    });
  }

  QueryBuilder<SubmissionRecord, String, QQueryOperations>
  hashAssinaturaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashAssinatura');
    });
  }

  QueryBuilder<SubmissionRecord, String, QQueryOperations>
  idProtocoloProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idProtocolo');
    });
  }

  QueryBuilder<SubmissionRecord, String, QQueryOperations> idSessaoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idSessao');
    });
  }

  QueryBuilder<SubmissionRecord, String, QQueryOperations>
  nomeProtocoloProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nomeProtocolo');
    });
  }

  QueryBuilder<SubmissionRecord, String, QQueryOperations> pdfPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pdfPath');
    });
  }

  QueryBuilder<SubmissionRecord, String, QQueryOperations>
  protobufPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protobufPath');
    });
  }
}
