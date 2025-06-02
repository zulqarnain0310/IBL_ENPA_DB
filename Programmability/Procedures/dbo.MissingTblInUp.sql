SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/* CREATED BY DF627 on 23-05-24 FOR IDENTIFYING TABLES THAT DO NOT EXIST ANYMORE BUT STILL USED IN THE SP  */

CREATE PROC [dbo].[MissingTblInUp]
AS
BEGIN
    -- This query identifies tables that do not exist anymore but are still used in the SP.
    -- It also defines whether the database exists or not.

    -- Temporary table to hold intermediate results
    DROP TABLE IF EXISTS #Temp;

    SELECT 
        ServerName,
        CASE 
            WHEN S.is_linked = 1 THEN 'Linked Server' 
            ELSE 'Primary Server' 
        END AS ServerType,
        referenced_database_name AS [Database Name],
        referencing_entity_name AS [SP Name],
        TableName,
        A.create_date AS [SP Created Date],
        A.modify_date AS [SP Modified Date],
        'Physical/Temporary Table does not exist' AS [Table Detail],
        CASE 
            WHEN SD.name IS NULL THEN 'Database does not exist in the ' + @@SERVERNAME + ' SERVER' 
            ELSE 'Database exists in the ' + @@SERVERNAME + ' SERVER' 
        END AS [Database Detail],
        GETDATE() AS ProcessDate,
        ObjectID,
        SchemaID
    INTO #Temp
    FROM (
        SELECT  
            CASE 
                WHEN referenced_server_name IS NULL THEN @@SERVERNAME 
                ELSE referenced_server_name 
            END AS ServerName,
            SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(sed.referencing_id) AS referencing_entity_name,
            ISNULL(sed.referenced_schema_name, 'Dbo') + '.' + sed.referenced_entity_name AS TableName,
            CASE 
                WHEN referenced_database_name IS NULL THEN DB_NAME() 
                ELSE referenced_database_name 
            END AS referenced_database_name,
            sp.create_date,
            sp.modify_date,
            O.object_id AS ObjectID,
            O.schema_id AS SchemaID
        FROM sys.objects AS o
        INNER JOIN sys.sql_expression_dependencies AS sed ON sed.referencing_id = o.object_id
        INNER JOIN sys.procedures sp ON sp.object_id = sed.referencing_id AND sp.type = 'P'
        LEFT JOIN INFORMATION_SCHEMA.COLUMNS SC ON SC.TABLE_NAME = referenced_entity_name
        WHERE o.type = 'P' AND referenced_id IS NULL AND SC.TABLE_NAME IS NULL
		AND sed.is_caller_dependent=0 AND sed.is_ambiguous!=1
    ) A
    LEFT JOIN sys.databases SD ON SD.name = A.referenced_database_name
    JOIN sys.servers S ON S.name = A.ServerName
    --WHERE referenced_database_name NOT LIKE '%split%'
    ORDER BY referencing_entity_name;

    -- Temporary tables for processing
    DROP TABLE IF EXISTS #TempCust;
    DROP TABLE IF EXISTS #Temp1;
    DROP TABLE IF EXISTS #Temp2;

    SELECT DISTINCT 
        [Database Name] + '.' + TableName AS FullTableName,
        TableName,
        NULL AS [TblDetail]
    INTO #TempCust 
    FROM #Temp t
    JOIN sys.databases db ON db.name = t.[Database Name] AND db.name <> DB_NAME();

    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS SrNo,
        * 
    INTO #Temp1 
    FROM #TempCust;

    CREATE TABLE #TblExists (
        SrNo INT,
        TblCnt INT
    );

    DROP TABLE IF EXISTS #TblNotExists;

    CREATE TABLE #TblNotExists (
        SrNo INT,
        TblCnt INT
    );

    DECLARE @Cnt INT = 1;
    DECLARE @Total INT = (SELECT COUNT(SrNo) FROM #Temp1);

    WHILE (@Cnt <= @Total)
    BEGIN
        DECLARE @Rn INT = (SELECT SrNo FROM #Temp1 WHERE SrNo = @Cnt);
        DECLARE @TblName VARCHAR(500) = (SELECT FullTableName FROM #Temp1 WHERE SrNo = @Rn);

        BEGIN TRY
            DECLARE @Query VARCHAR(500) = 'INSERT INTO #TblExists SELECT ' + CAST(@Rn AS VARCHAR(100)) + ', COUNT(*) FROM ' + SPACE(1) + @TblName;
            EXEC (@Query);
        END TRY
        BEGIN CATCH
            INSERT INTO #TblNotExists
            SELECT @Rn, 0;
        END CATCH

        SET @Cnt = @Cnt + 1;
    END;

    DELETE t
    FROM #Temp1 t1
    JOIN #TblExists t2 ON t2.SrNo = t1.SrNo
    JOIN #Temp t ON t.TableName = t1.TableName;

    INSERT INTO DBO.MissingTbl (
        ServerName,
        ServerType,
        DbName,
        ObjectID,
        SchemaID,
        SpName,
        TableName,
        SpCreatedDate,
        SpModifiedDate,
        TableInfo,
        DatabaseInfo,
        ProcessDate
    )
    SELECT  
        ServerName,
        ServerType,
        [Database Name],
        ObjectID,
        SchemaID,
        [SP Name],
        TableName,
        [SP Created Date],
        [SP Modified Date],
        [Table Detail],
        [Database Detail],
        ProcessDate
    FROM #Temp;

    -- Cleanup temporary tables
    DROP TABLE IF EXISTS #Temp;
    DROP TABLE IF EXISTS #Temp1;
    DROP TABLE IF EXISTS #Temp2;
    DROP TABLE IF EXISTS #TempCust;
    DROP TABLE IF EXISTS #TblExists;
    DROP TABLE IF EXISTS #TblNotExists;
END;
GO