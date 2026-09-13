// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppConfigRecordCollection on Isar {
  IsarCollection<AppConfigRecord> get appConfigRecords => this.collection();
}

const AppConfigRecordSchema = CollectionSchema(
  name: r'AppConfigRecord',
  id: 9038486186527517863,
  properties: {
    r'acceptedTermsVersion': PropertySchema(
      id: 0,
      name: r'acceptedTermsVersion',
      type: IsarType.long,
    ),
    r'dataHoraAceiteTermos': PropertySchema(
      id: 1,
      name: r'dataHoraAceiteTermos',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _appConfigRecordEstimateSize,
  serialize: _appConfigRecordSerialize,
  deserialize: _appConfigRecordDeserialize,
  deserializeProp: _appConfigRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _appConfigRecordGetId,
  getLinks: _appConfigRecordGetLinks,
  attach: _appConfigRecordAttach,
  version: '3.3.2',
);

int _appConfigRecordEstimateSize(
  AppConfigRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _appConfigRecordSerialize(
  AppConfigRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.acceptedTermsVersion);
  writer.writeDateTime(offsets[1], object.dataHoraAceiteTermos);
}

AppConfigRecord _appConfigRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppConfigRecord();
  object.acceptedTermsVersion = reader.readLong(offsets[0]);
  object.dataHoraAceiteTermos = reader.readDateTimeOrNull(offsets[1]);
  object.id = id;
  return object;
}

P _appConfigRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appConfigRecordGetId(AppConfigRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appConfigRecordGetLinks(AppConfigRecord object) {
  return [];
}

void _appConfigRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  AppConfigRecord object,
) {
  object.id = id;
}

extension AppConfigRecordQueryWhereSort
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QWhere> {
  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppConfigRecordQueryWhere
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QWhereClause> {
  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterWhereClause>
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

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterWhereClause> idBetween(
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
}

extension AppConfigRecordQueryFilter
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QFilterCondition> {
  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  acceptedTermsVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'acceptedTermsVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  acceptedTermsVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'acceptedTermsVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  acceptedTermsVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'acceptedTermsVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  acceptedTermsVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'acceptedTermsVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  dataHoraAceiteTermosIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dataHoraAceiteTermos'),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  dataHoraAceiteTermosIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dataHoraAceiteTermos'),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  dataHoraAceiteTermosEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dataHoraAceiteTermos',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  dataHoraAceiteTermosGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dataHoraAceiteTermos',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  dataHoraAceiteTermosLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dataHoraAceiteTermos',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  dataHoraAceiteTermosBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dataHoraAceiteTermos',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
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

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
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

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterFilterCondition>
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
}

extension AppConfigRecordQueryObject
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QFilterCondition> {}

extension AppConfigRecordQueryLinks
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QFilterCondition> {}

extension AppConfigRecordQuerySortBy
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QSortBy> {
  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  sortByAcceptedTermsVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedTermsVersion', Sort.asc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  sortByAcceptedTermsVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedTermsVersion', Sort.desc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  sortByDataHoraAceiteTermos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHoraAceiteTermos', Sort.asc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  sortByDataHoraAceiteTermosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHoraAceiteTermos', Sort.desc);
    });
  }
}

extension AppConfigRecordQuerySortThenBy
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QSortThenBy> {
  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  thenByAcceptedTermsVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedTermsVersion', Sort.asc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  thenByAcceptedTermsVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedTermsVersion', Sort.desc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  thenByDataHoraAceiteTermos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHoraAceiteTermos', Sort.asc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy>
  thenByDataHoraAceiteTermosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataHoraAceiteTermos', Sort.desc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension AppConfigRecordQueryWhereDistinct
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QDistinct> {
  QueryBuilder<AppConfigRecord, AppConfigRecord, QDistinct>
  distinctByAcceptedTermsVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'acceptedTermsVersion');
    });
  }

  QueryBuilder<AppConfigRecord, AppConfigRecord, QDistinct>
  distinctByDataHoraAceiteTermos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataHoraAceiteTermos');
    });
  }
}

extension AppConfigRecordQueryProperty
    on QueryBuilder<AppConfigRecord, AppConfigRecord, QQueryProperty> {
  QueryBuilder<AppConfigRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppConfigRecord, int, QQueryOperations>
  acceptedTermsVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'acceptedTermsVersion');
    });
  }

  QueryBuilder<AppConfigRecord, DateTime?, QQueryOperations>
  dataHoraAceiteTermosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataHoraAceiteTermos');
    });
  }
}
