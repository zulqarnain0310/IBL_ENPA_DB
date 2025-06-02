SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*  CREATED BY DF627 ON 24-05-24 FOR THE PURPOSE OF IDENTIFYING DEPENDENCY OF THE TABLES */

CREATE PROC [dbo].[DependencyTablesInUp]
AS
BEGIN
    -- Finding the dependency of any table irrespective of the database on the same server
    -- and this can be used for identifying one more thing that
    -- if one table we are using of another db then that should be common
    -- in all the sps of the current database as well
 
    INSERT INTO DBO.TableDependencyDtls
    SELECT 
        ServerName,
        CASE 
            WHEN is_linked = 1 THEN 'Linked DB Server' 
            ELSE 'Main DB Server' 
        END AS ServerType,
        DbName AS [Db Name],
        ObjectID,
        SchemaID,
        referencing_object AS [Sp Name],
        ISNULL(referenced_schema_name, 'dbo') + '.' + referenced_entity_name AS [Table Name],
        [Sp Created Date],
        [Sp Modified Date],
        CASE 
            WHEN is_linked = 1 THEN 'Information not available'
            WHEN DbName <> DB_NAME() THEN 'Information not available'
            ELSE [Table Info] 
        END AS [Table Info],
        CASE 
            WHEN is_linked = 1 THEN 'Information not available' 
            ELSE [Database Info] 
        END AS [Database Info],
        GETDATE() AS ProcessDate
    FROM 
        (
            SELECT  
                CASE 
                    WHEN referenced_server_name IS NULL THEN @@SERVERNAME 
                    ELSE referenced_server_name 
                END AS ServerName,
                SCHEMA_NAME(op.schema_id) + '.' + OBJECT_NAME(referencing_id) AS referencing_object,
                COALESCE(referenced_database_name, DB_NAME()) AS DbName,
                referenced_schema_name,
                referenced_entity_name,
                op.create_date AS [Sp Created Date],
                op.modify_date AS [Sp Modified Date],
                CASE 
                    WHEN sd.name IS NULL THEN 'Database does not exist' 
                    ELSE 'Database exists' 
                END AS [Database Info],
                CASE 
                    WHEN t.name IS NULL THEN 'Table does not exist' 
                    ELSE 'Table exists' 
                END AS [Table Info],
                op.object_id AS ObjectID,
                op.schema_id AS SchemaID
            FROM 
                sys.sql_expression_dependencies s
                JOIN sys.objects op ON op.object_id = s.referencing_id
                LEFT JOIN sys.databases sd ON sd.name = COALESCE(referenced_database_name, DB_NAME())
                LEFT JOIN sys.objects t ON t.object_id = s.referenced_id
				WHERE s.is_ambiguous!=1--ADDED ON 02/07/24
                -- Uncomment and modify the below lines for specific filtering
                -- WHERE OBJECT_NAME(referencing_id) LIKE '%dummy%'
                -- WHERE referenced_entity_name LIKE '%customerbasicdetail%'
        ) A
    JOIN sys.servers s ON s.name = A.ServerName;

    
END;
GO