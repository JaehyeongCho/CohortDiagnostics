test_that("Cohort diagnostics in incremental mode", {
  skip_if(skipCdmTests, "cdm settings not configured")

  cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTable)
  # Next create the tables on the database
  CohortGenerator::createCohortTables(
    connectionDetails = connectionDetails,
    cohortTableNames = cohortTableNames,
    cohortDatabaseSchema = cohortDatabaseSchema,
    incremental = FALSE
  )

  # Generate the cohort set
  CohortGenerator::generateCohortSet(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTableNames = cohortTableNames,
    cohortDefinitionSet = cohortDefinitionSet,
    incremental = FALSE
  )


  firstTime <- system.time(
    executeDiagnostics(
      cohortDefinitionSet = cohortDefinitionSet,
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      vocabularyDatabaseSchema = vocabularyDatabaseSchema,
      tempEmulationSchema = tempEmulationSchema,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTable,
      cohortIds = cohortIds,
      exportFolder = file.path(folder, "export"),
      databaseId = dbms,
      runInclusionStatistics = TRUE,
      runBreakdownIndexEvents = TRUE,
      runTemporalCohortCharacterization = TRUE,
      runIncidenceRate = TRUE,
      runIncludedSourceConcepts = TRUE,
      runOrphanConcepts = TRUE,
      runTimeSeries = TRUE,
      runCohortRelationship = TRUE,
      minCellCount = minCellCountValue,
      incremental = TRUE,
      incrementalFolder = file.path(folder, "incremental"),
      temporalCovariateSettings = temporalCovariateSettings
    )
  )

  expect_true(file.exists(file.path(
    folder, "export", paste0("Results_", dbms, ".zip")
  )))

  # We now run it with all cohorts without specifying ids - testing incremental mode
  secondTime <- system.time(
    executeDiagnostics(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      tempEmulationSchema = tempEmulationSchema,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTableNames = cohortTableNames,
      cohortDefinitionSet = cohortDefinitionSet,
      exportFolder = file.path(folder, "export"),
      databaseId = dbms,
      runInclusionStatistics = TRUE,
      runBreakdownIndexEvents = TRUE,
      runTemporalCohortCharacterization = TRUE,
      runIncidenceRate = TRUE,
      runIncludedSourceConcepts = TRUE,
      runOrphanConcepts = TRUE,
      runTimeSeries = TRUE,
      runCohortRelationship = TRUE,
      minCellCount = minCellCountValue,
      incremental = TRUE,
      incrementalFolder = file.path(folder, "incremental"),
      temporalCovariateSettings = temporalCovariateSettings
    )
  )
  # generate sqlite file
  sqliteDbPath <- tempfile(fileext = ".sqlite")
  createMergedResultsFile(dataFolder = file.path(folder, "export"), sqliteDbPath = sqliteDbPath)
  expect_true(file.exists(sqliteDbPath))

  # File exists
  expect_error(createMergedResultsFile(dataFolder = file.path(folder, "export"), sqliteDbPath = sqliteDbPath))

  # Test zip works
  DiagnosticsExplorerZip <- tempfile(fileext = "de.zip")
  unlink(DiagnosticsExplorerZip)
  on.exit(unlink(DiagnosticsExplorerZip))
  createDiagnosticsExplorerZip(outputZipfile = DiagnosticsExplorerZip, sqliteDbPath = sqliteDbPath)

  expect_true(file.exists(DiagnosticsExplorerZip))
  # already exists
  expect_error(createDiagnosticsExplorerZip(outputZipfile = DiagnosticsExplorerZip, sqliteDbPath = sqliteDbPath))
  # Bad filepath
  expect_error(createDiagnosticsExplorerZip(outputZipfile = "foo", sqliteDbPath = "sdlfkmdkmfkd"))
  output <- read.csv(file.path(folder, "export", "temporal_covariate_value.csv"))

  expect_true(is.numeric(output$sum_value[2]))
  expect_true(is.numeric(output$mean[2]))
})
