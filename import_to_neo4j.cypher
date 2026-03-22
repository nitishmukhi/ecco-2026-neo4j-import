// ═══════════════════════════════════════════════════════════════
// Congress Intelligence Platform — Neo4j Import Script
// Generated: 2026-03-22T16:34:30.982993
// Congress: ECCO 2026
// Profile: ecco-2026
//
// INSTRUCTIONS:
//   1. Host CSV files from neo4j_import/ at a public HTTPS URL
//   2. Replace {{BASE_URL}} with your URL prefix
//   3. Run in Neo4j Browser, Workspace, or cypher-shell
// ═══════════════════════════════════════════════════════════════

// Step 1: Constraints
CREATE CONSTRAINT congress_id IF NOT EXISTS FOR (c:Congress) REQUIRE c.congressId IS UNIQUE;
CREATE CONSTRAINT abstract_id IF NOT EXISTS FOR (a:Abstract) REQUIRE a.citationId IS UNIQUE;
CREATE CONSTRAINT author_id IF NOT EXISTS FOR (au:Author) REQUIRE au.authorId IS UNIQUE;
CREATE CONSTRAINT institution_id IF NOT EXISTS FOR (i:Institution) REQUIRE i.institutionId IS UNIQUE;
CREATE CONSTRAINT topic_id IF NOT EXISTS FOR (t:Topic) REQUIRE t.topicId IS UNIQUE;
CREATE CONSTRAINT disease_id IF NOT EXISTS FOR (d:Disease) REQUIRE d.diseaseId IS UNIQUE;
CREATE CONSTRAINT drug_id IF NOT EXISTS FOR (dr:Drug) REQUIRE dr.drugId IS UNIQUE;
CREATE CONSTRAINT drugclass_id IF NOT EXISTS FOR (dc:DrugClass) REQUIRE dc.drugClassId IS UNIQUE;
CREATE CONSTRAINT company_id IF NOT EXISTS FOR (co:Company) REQUIRE co.companyId IS UNIQUE;
CREATE CONSTRAINT studytype_id IF NOT EXISTS FOR (st:StudyType) REQUIRE st.studyTypeId IS UNIQUE;

CREATE FULLTEXT INDEX abstract_title_search IF NOT EXISTS FOR (a:Abstract) ON EACH [a.title];

// Step 2: Nodes
LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_congress.csv' AS row
MERGE (c:Congress {congressId: row.`congressId:ID`})
SET c.name = row.name, c.year = toInteger(row.`year:int`);

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_abstract.csv' AS row
MERGE (a:Abstract {citationId: row.`citationId:ID`})
SET a.presentationNumber = row.presentationNumber, a.sessionType = row.sessionType,
    a.title = row.title, a.authorCount = toInteger(row.`authorCount:int`),
    a.startPage = toInteger(row.`startPage:int`),
    a.backgroundSnippet = row.backgroundSnippet, a.conclusionSnippet = row.conclusionSnippet,
    a.hasFigures = (row.`hasFigures:boolean` = 'true');

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_author.csv' AS row
MERGE (au:Author {authorId: row.`authorId:ID`}) SET au.name = row.name;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_institution.csv' AS row
MERGE (i:Institution {institutionId: row.`institutionId:ID`}) SET i.name = row.name;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_topic.csv' AS row
MERGE (t:Topic {topicId: row.`topicId:ID`}) SET t.name = row.name;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_disease.csv' AS row
MERGE (d:Disease {diseaseId: row.`diseaseId:ID`}) SET d.name = row.name;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_drug.csv' AS row
MERGE (dr:Drug {drugId: row.`drugId:ID`})
SET dr.name = row.name, dr.drugClass = row.drugClass, dr.mechanism = row.mechanism;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_drugclass.csv' AS row
MERGE (dc:DrugClass {drugClassId: row.`drugClassId:ID`}) SET dc.name = row.name;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_company.csv' AS row
MERGE (co:Company {companyId: row.`companyId:ID`}) SET co.name = row.name;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}nodes_studytype.csv' AS row
MERGE (st:StudyType {studyTypeId: row.`studyTypeId:ID`}) SET st.name = row.name;

// Step 3: Relationships
LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_presented_at.csv' AS row
MATCH (a:Abstract {citationId: row.`:START_ID`})
MATCH (c:Congress {congressId: row.`:END_ID`})
MERGE (a)-[:PRESENTED_AT]->(c);

:auto LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_authored.csv' AS row
CALL { WITH row
  MATCH (au:Author {authorId: row.`:START_ID`})
  MATCH (a:Abstract {citationId: row.`:END_ID`})
  MERGE (au)-[r:AUTHORED]->(a) SET r.position = toInteger(row.`position:int`)
} IN TRANSACTIONS OF 5000 ROWS;

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_affiliated_with.csv' AS row
MATCH (au:Author {authorId: row.`:START_ID`})
MATCH (i:Institution {institutionId: row.`:END_ID`})
MERGE (au)-[:AFFILIATED_WITH]->(i);

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_in_topic.csv' AS row
MATCH (a:Abstract {citationId: row.`:START_ID`})
MATCH (t:Topic {topicId: row.`:END_ID`})
MERGE (a)-[:IN_TOPIC]->(t);

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_mentions_disease.csv' AS row
MATCH (a:Abstract {citationId: row.`:START_ID`})
MATCH (d:Disease {diseaseId: row.`:END_ID`})
MERGE (a)-[:MENTIONS_DISEASE]->(d);

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_mentions_drug.csv' AS row
MATCH (a:Abstract {citationId: row.`:START_ID`})
MATCH (dr:Drug {drugId: row.`:END_ID`})
MERGE (a)-[:MENTIONS_DRUG]->(dr);

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_associated_with.csv' AS row
MATCH (a:Abstract {citationId: row.`:START_ID`})
MATCH (co:Company {companyId: row.`:END_ID`})
MERGE (a)-[:ASSOCIATED_WITH]->(co);

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_uses_method.csv' AS row
MATCH (a:Abstract {citationId: row.`:START_ID`})
MATCH (st:StudyType {studyTypeId: row.`:END_ID`})
MERGE (a)-[:USES_METHOD]->(st);

LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_belongs_to_class.csv' AS row
MATCH (dr:Drug {drugId: row.`:START_ID`})
MATCH (dc:DrugClass {drugClassId: row.`:END_ID`})
MERGE (dr)-[:BELONGS_TO_CLASS]->(dc);

:auto LOAD CSV WITH HEADERS FROM '{{BASE_URL}}rels_co_authored.csv' AS row
CALL { WITH row
  MATCH (a1:Author {authorId: row.`:START_ID`})
  MATCH (a2:Author {authorId: row.`:END_ID`})
  MERGE (a1)-[r:CO_AUTHORED_WITH]->(a2) SET r.weight = toInteger(row.`weight:int`)
} IN TRANSACTIONS OF 5000 ROWS;

// Step 4: Verify
MATCH (n) RETURN labels(n)[0] AS label, count(n) AS count ORDER BY count DESC;
MATCH ()-[r]->() RETURN type(r) AS type, count(r) AS count ORDER BY count DESC;
