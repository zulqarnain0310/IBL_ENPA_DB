SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*
AUTHOR - MAMTA (DF627)
DATE - 25-06-24
PURPOSE - THIS CODE INSERT AND UPDATE THE RECORDS OF SP'S LIST AND STORES REFERENCE SERVER, SCHEMA, DB, TABLES, AND COLUMNS INFO ETC 
*/

CREATE PROC [dbo].[SPTableDependencyInUp]
AS
BEGIN
    -- Drop temporary tables if they exist
    DROP TABLE IF EXISTS #ProcList;
    DROP TABLE IF EXISTS #SPDependency;
    DROP TABLE IF EXISTS #ErrorSp;
    DROP TABLE IF EXISTS #Temp;
    DROP TABLE IF EXISTS #FinalTemp;
    DROP TABLE IF EXISTS #MainTbl;
    DROP TABLE IF EXISTS #ErrorTbl;

    -- Create temporary table #ProcList
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS SrNo,
           sp.object_id AS ObjectID,
           sp.schema_id AS SchemaID,
           sc.name + '.' + sp.name AS SpName,
           sp.type_desc,
           sp.create_date,
           sp.modify_date
    INTO #ProcList
    FROM sys.procedures sp
    JOIN sys.schemas sc ON sc.schema_id = sp.schema_id
    WHERE sp.type = 'P';

    -- Create table #SPDependency
    CREATE TABLE #SPDependency
    (
        referencing_minor_id INT,
        referenced_server_name NVARCHAR(256),
        referenced_database_name NVARCHAR(256),
        referenced_schema_name NVARCHAR(256),
        referenced_entity_name NVARCHAR(256),
        referenced_minor_name NVARCHAR(256),
        referenced_id INT,
        referenced_minor_id INT,
        referenced_class TINYINT,
        is_caller_dependent BIT,
        is_updated BIT,
        is_selected BIT,
        is_all_columns_found BIT,
        SPName VARCHAR(1000),
        CreateSPDate DATETIME,
        ModifiedSPDate DATETIME,
        ObjectID INT,
        SchemaID INT
    );

    DECLARE @CntMax INT = (SELECT COUNT(SrNo) FROM #ProcList);
    DECLARE @StrtCnt INT = 1;

    WHILE (@StrtCnt <= @CntMax)
    BEGIN
        DECLARE @ObjectID INT = (SELECT ObjectID FROM #ProcList WHERE SrNo = @StrtCnt);
        DECLARE @SchemaID INT = (SELECT SchemaID FROM #ProcList WHERE SrNo = @StrtCnt);
        DECLARE @procname VARCHAR(500) = (SELECT SpName FROM #ProcList WHERE SrNo = @StrtCnt);
        DECLARE @create_date DATETIME = (SELECT create_date FROM #ProcList WHERE SrNo = @StrtCnt);
        DECLARE @modify_date DATETIME = (SELECT modify_date FROM #ProcList WHERE SrNo = @StrtCnt);

        BEGIN TRY
            INSERT INTO #SPDependency
            SELECT
                referencing_minor_id,
                referenced_server_name,
                referenced_database_name,
                referenced_schema_name,
                referenced_entity_name,
                referenced_minor_name,
                referenced_id,
                referenced_minor_id,
                referenced_class,
                is_caller_dependent,
                is_updated,
                is_selected,
                is_all_columns_found,
                @procname,
                @create_date,
                @modify_date,
                @ObjectID,
                @SchemaID
            FROM sys.dm_sql_referenced_entities (@procname, 'OBJECT')
			WHERE is_ambiguous!=1;
        END TRY
        BEGIN CATCH
            SELECT ERROR_MESSAGE();
        END CATCH

        SET @StrtCnt = @StrtCnt + 1;
    END

    -- Delete old entries from SpTableDependencyDtls
    DELETE FROM DBO.SpTableDependencyDtls WHERE CAST(ProcessDateTime AS DATE) = CAST(GETDATE() AS DATE);

    -- Insert new entries into SpTableDependencyDtls
    INSERT INTO DBO.SpTableDependencyDtls
    (
        MainDBName,
        ServerName,
        ServerType,
        ReferencedDBName,
        ReferencedTableName,
        ReferencedSchemaName,
        ReferencedColumnName,
        IsUpdate,
        IsSelect,
        IsAllColumnsFound,
        IsCallerDependent,
        SpName,
        SpCreatedDate,
        SpModifiedDate,
        TableCreatedDate,
        TableModifiedDate,
        ObjectID,
        SchemaID,
		ProcessDateTime
    )
    SELECT DISTINCT
        DB_NAME() AS MainDBName,
        COALESCE(SPD.referenced_server_name, @@SERVERNAME) AS ServerName,
        CASE WHEN S.is_linked = 1 THEN 'Linked Server' ELSE 'Current Server' END AS ServerType,
        COALESCE(SPD.referenced_database_name, DB_NAME()) AS ReferencedDBName,
        SPD.referenced_entity_name AS ReferencedTableName,
        COALESCE(SPD.referenced_schema_name, SCHEMA_NAME(T.schema_id)) AS ReferencedSchemaName,
        SPD.referenced_minor_name AS ReferencedColumnName,
        is_updated,
        is_selected,
        is_all_columns_found,
        is_caller_dependent,
        SPName,
        CreateSPDate,
        ModifiedSPDate,
        T.create_date AS TableViewCreatedDate,
        T.modify_date AS TableViewModifiedDate,
        SPD.ObjectID,
        SPD.SchemaID,
		GETDATE()
    FROM #SPDependency SPD
    JOIN SYS.servers S ON S.name = COALESCE(SPD.referenced_server_name, @@SERVERNAME)
    LEFT OUTER JOIN sys.objects T ON SPD.referenced_id = T.object_id;

    -- Prepare temp table with missing table details
    SELECT DISTINCT 
        ServerName,
        ReferencedDBName,
        CASE WHEN ReferencedSchemaName = '' THEN 'DBO' ELSE ISNULL(ReferencedSchemaName, 'DBO') END AS ReferencedSchemaName,
        ReferencedTableName 
    INTO #Temp
    FROM DBO.SpTableDependencyDtls 
    WHERE CAST(ProcessDateTime AS DATE) = CAST(GETDATE() AS DATE)
    AND TableCreatedDate IS NULL 
    AND IsCallerDependent <> 1;

    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rn, * 
    INTO #FinalTemp 
    FROM #Temp;

    CREATE TABLE #MainTbl
    (
        dbname VARCHAR(MAX),
        schemaname VARCHAR(MAX),
        tablename VARCHAR(MAX),
        create_date DATE,
        modify_date DATE,
        rnno INT
    );

    CREATE TABLE #ErrorTbl
    (
        ErrorMsg VARCHAR(MAX)
    );

    DECLARE @cnt INT = 1;
    DECLARE @totalcnt INT = (SELECT COUNT(*) FROM #FinalTemp);

    WHILE (@cnt <= @totalcnt)
    BEGIN
        DECLARE @dbname VARCHAR(MAX) = (SELECT ReferencedDBName FROM #FinalTemp WHERE rn = @cnt);
        DECLARE @tablename VARCHAR(MAX) = (SELECT ReferencedTableName FROM #FinalTemp WHERE rn = @cnt);
        DECLARE @schemaname VARCHAR(MAX) = (SELECT ReferencedSchemaName FROM #FinalTemp WHERE rn = @cnt);

        BEGIN TRY
            DECLARE @query VARCHAR(MAX) =
                'SELECT ''' + @dbname + ''', s.name, o.name, o.create_date, o.modify_date, ' + CAST(@cnt AS VARCHAR(MAX)) + 
                ' FROM ' + @dbname + '.sys.objects o JOIN sys.schemas s ON s.schema_id = o.schema_id WHERE o.name = ''' + @tablename + ''' AND s.name = ''' + @schemaname + '''';

            INSERT INTO #MainTbl
            EXEC (@query);
        END TRY
        BEGIN CATCH
            INSERT INTO #ErrorTbl
            SELECT 'TABLE DOES NOT EXISTS';
        END CATCH

        SET @cnt = @cnt + 1;
    END

    -- Update SpTableDependencyDtls with table creation and modification dates
    UPDATE sp
    SET TableCreatedDate = M.create_date, TableModifiedDate = M.modify_date
    FROM DBO.SpTableDependencyDtls sp
    JOIN #MainTbl M ON M.dbname = sp.ReferencedDBName AND M.tablename = sp.ReferencedTableName;

    -- Drop temporary tables
    DROP TABLE IF EXISTS #ProcList;
    DROP TABLE IF EXISTS #SPDependency;
    DROP TABLE IF EXISTS #ErrorSp;
    DROP TABLE IF EXISTS #Temp;
    DROP TABLE IF EXISTS #FinalTemp;
    DROP TABLE IF EXISTS #MainTbl;
    DROP TABLE IF EXISTS #ErrorTbl;
END;
GO