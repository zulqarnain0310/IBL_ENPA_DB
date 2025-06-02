SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*
AUTHOR - MAMTA (DF627)
DATE - 25-06-24
PURPOSE - FOR RETRIEVING THE DETAILS OF THE SP AND ITS DEPENDENCIES 
*/

CREATE PROC [dbo].[GetSPTableDependency]
AS
BEGIN
    -- Drop temporary tables if they exist
    DROP TABLE IF EXISTS #ColumnDetail;
    DROP TABLE IF EXISTS #SPTableInfo;

    -- Create temporary table #ColumnDetail
    SELECT DISTINCT 
        SpName,
        MIN(CAST(IsAllColumnsFound AS INT)) AS IsAllColumnsFound 
    INTO #ColumnDetail
    FROM DBO.SpTableDependencyDtls 
    WHERE CAST(ProcessDateTime AS DATE) = DATEADD(DD,-1,CAST(GETDATE() AS DATE))
    GROUP BY SpName;

    -- Create temporary table #SPTableInfo
    SELECT 
        MainDBName,
        ServerName,
        ServerType,
        ReferencedDBName,
        ReferencedSchemaName,
        ReferencedTableName,
        ReferencedColumnName,
        SpName,
        CASE 
            WHEN IsCallerDependent = 1 THEN 'Referenced Table Name is the SP Name' 
        END AS NestedSPName,
        CASE 
            WHEN IsUpdate = 0 AND IsSelect = 0 THEN 'NA' 
            WHEN IsUpdate = 0 AND IsSelect = 1 THEN 'SELECT'
            WHEN IsUpdate = 1 AND IsSelect = 0 THEN 'UPDATE'
            WHEN IsUpdate = 1 AND IsSelect = 1 THEN 'INUP' 
        END AS SPType,
        CAST(NULL AS VARCHAR(MAX)) AS ColumnInfo,
        SpCreatedDate,
        SpModifiedDate,
        TableCreatedDate,
        TableModifiedDate,
        ProcessDateTime 
    INTO #SPTableInfo
    FROM DBO.SpTableDependencyDtls 
    WHERE CAST(ProcessDateTime AS DATE) = DATEADD(DD,-1,CAST(GETDATE() AS DATE));

    -- Update ColumnInfo in #SPTableInfo based on #ColumnDetail
    UPDATE #SPTableInfo
    SET ColumnInfo = CASE 
                         WHEN C.IsAllColumnsFound = 0 THEN 'ALL COLUMNS MIGHT NOT BE DISPLAYED SO PLEASE CHECK SP TOO'
                         WHEN C.IsAllColumnsFound = 1 THEN 'ALL COLUMNS ARE DISPLAYED' 
                     END
    FROM #SPTableInfo S
    JOIN #ColumnDetail C ON S.SpName = C.SpName;

    -- Select data from #SPTableInfo
    SELECT * FROM #SPTableInfo
    ORDER BY SpName;

    -- Drop temporary tables
    DROP TABLE IF EXISTS #ColumnDetail;
    DROP TABLE IF EXISTS #SPTableInfo;
END;
GO