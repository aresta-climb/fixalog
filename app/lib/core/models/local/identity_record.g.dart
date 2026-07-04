// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIdentityRecordCollection on Isar {
  IsarCollection<IdentityRecord> get identityRecords => this.collection();
}

const IdentityRecordSchema = CollectionSchema(
  name: r'IdentityRecord',
  id: -2303143554673215988,
  properties: {
    r'clubeAssociacao': PropertySchema(
      id: 0,
      name: r'clubeAssociacao',
      type: IsarType.string,
    ),
    r'dataRegistro': PropertySchema(
      id: 1,
      name: r'dataRegistro',
      type: IsarType.dateTime,
    ),
    r'nome': PropertySchema(id: 2, name: r'nome', type: IsarType.string),
  },

  estimateSize: _identityRecordEstimateSize,
  serialize: _identityRecordSerialize,
  deserialize: _identityRecordDeserialize,
  deserializeProp: _identityRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _identityRecordGetId,
  getLinks: _identityRecordGetLinks,
  attach: _identityRecordAttach,
  version: '3.3.2',
);

int _identityRecordEstimateSize(
  IdentityRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clubeAssociacao.length * 3;
  bytesCount += 3 + object.nome.length * 3;
  return bytesCount;
}

void _identityRecordSerialize(
  IdentityRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.clubeAssociacao);
  writer.writeDateTime(offsets[1], object.dataRegistro);
  writer.writeString(offsets[2], object.nome);
}

IdentityRecord _identityRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IdentityRecord();
  object.clubeAssociacao = reader.readString(offsets[0]);
  object.dataRegistro = reader.readDateTime(offsets[1]);
  object.id = id;
  object.nome = reader.readString(offsets[2]);
  return object;
}

P _identityRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _identityRecordGetId(IdentityRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _identityRecordGetLinks(IdentityRecord object) {
  return [];
}

void _identityRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  IdentityRecord object,
) {
  object.id = id;
}

extension IdentityRecordQueryWhereSort
    on QueryBuilder<IdentityRecord, IdentityRecord, QWhere> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IdentityRecordQueryWhere
    on QueryBuilder<IdentityRecord, IdentityRecord, QWhereClause> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterWhereClause> idBetween(
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

extension IdentityRecordQueryFilter
    on QueryBuilder<IdentityRecord, IdentityRecord, QFilterCondition> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'clubeAssociacao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'clubeAssociacao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'clubeAssociacao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'clubeAssociacao',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'clubeAssociacao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'clubeAssociacao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'clubeAssociacao',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'clubeAssociacao',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'clubeAssociacao', value: ''),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  clubeAssociacaoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'clubeAssociacao', value: ''),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  dataRegistroEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dataRegistro', value: value),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  dataRegistroGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dataRegistro',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  dataRegistroLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dataRegistro',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  dataRegistroBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dataRegistro',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
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

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
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

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nome',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nome',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nome',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nome',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nome',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nome',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nome',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nome',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nome', value: ''),
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterFilterCondition>
  nomeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nome', value: ''),
      );
    });
  }
}

extension IdentityRecordQueryObject
    on QueryBuilder<IdentityRecord, IdentityRecord, QFilterCondition> {}

extension IdentityRecordQueryLinks
    on QueryBuilder<IdentityRecord, IdentityRecord, QFilterCondition> {}

extension IdentityRecordQuerySortBy
    on QueryBuilder<IdentityRecord, IdentityRecord, QSortBy> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  sortByClubeAssociacao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clubeAssociacao', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  sortByClubeAssociacaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clubeAssociacao', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  sortByDataRegistro() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataRegistro', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  sortByDataRegistroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataRegistro', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> sortByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }
}

extension IdentityRecordQuerySortThenBy
    on QueryBuilder<IdentityRecord, IdentityRecord, QSortThenBy> {
  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  thenByClubeAssociacao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clubeAssociacao', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  thenByClubeAssociacaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clubeAssociacao', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  thenByDataRegistro() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataRegistro', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy>
  thenByDataRegistroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataRegistro', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QAfterSortBy> thenByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }
}

extension IdentityRecordQueryWhereDistinct
    on QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> {
  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct>
  distinctByClubeAssociacao({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'clubeAssociacao',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct>
  distinctByDataRegistro() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataRegistro');
    });
  }

  QueryBuilder<IdentityRecord, IdentityRecord, QDistinct> distinctByNome({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nome', caseSensitive: caseSensitive);
    });
  }
}

extension IdentityRecordQueryProperty
    on QueryBuilder<IdentityRecord, IdentityRecord, QQueryProperty> {
  QueryBuilder<IdentityRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IdentityRecord, String, QQueryOperations>
  clubeAssociacaoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clubeAssociacao');
    });
  }

  QueryBuilder<IdentityRecord, DateTime, QQueryOperations>
  dataRegistroProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataRegistro');
    });
  }

  QueryBuilder<IdentityRecord, String, QQueryOperations> nomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nome');
    });
  }
}
