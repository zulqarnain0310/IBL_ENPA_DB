SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/* CREATED BY DF627 on 06-07-24 FOR COMPARING THE STORED PROC CODE OF OLD AND NEW CODE*/

CREATE PROC [dbo].[SpComparisonInUp]
AS
BEGIN
    -- Drop temporary tables if they exist
    DROP TABLE IF EXISTS #SpDtls;
    DROP TABLE IF EXISTS #NewSp;
    DROP TABLE IF EXISTS #ModifiedSp;

    -- Create temporary table with stored procedure details and versioning
    SELECT 
        ObjectID,
        SchemaID,
        Spname,
        SpModifiedDate,
        RN,
        CASE WHEN RN = 1 THEN 'V1' ELSE 'V2' END AS SpVersion 
    INTO #SpDtls 
    FROM (
        SELECT 
            ObjectID,
            SchemaID,
            Spname,
            SpModifiedDate,
            ROW_NUMBER() OVER (ORDER BY SpModifiedDate) RN  
        FROM (
            SELECT DISTINCT 
                ObjectID,
                SchemaID,
                Spname,
                SpModifiedDate 
            FROM [dbo].[SpDtls] 
        ) A
    ) B;

    -- Remove older versions, keeping only the latest two versions
    ;WITH CTE AS (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY objectid, schemaid, spname ORDER BY rn DESC) AS rnno,
            * 
        FROM #SpDtls
    )
    DELETE FROM CTE WHERE rnno > 2;

    -- Handle stored procedures that appear only once
    DROP TABLE IF EXISTS #DeleteSp;
    SELECT 
        ObjectID,
        SchemaID,
        Spname,
        COUNT(*) CNT 
    INTO #DeleteSp 
    FROM #SpDtls 
    GROUP BY ObjectID, SchemaID, Spname
    HAVING COUNT(*) = 1;

    DELETE S 
    FROM #SpDtls S
    JOIN #DeleteSp DS 
        ON DS.ObjectID = S.ObjectID
        AND DS.SchemaID = S.SchemaID
        AND DS.Spname = S.Spname;

    DELETE S 
    FROM [dbo].[SpLogDtls] L
    JOIN #SpDtls S 
        ON S.ObjectID = L.ObjectID
        AND S.SchemaID = L.SchemaID
        AND S.SpModifiedDate = L.SpDateModified_V1;

    -- Handle single row versions
    DROP TABLE IF EXISTS #DeleteSingleRn;
    SELECT 
        ObjectID,
        SchemaID,
        Spname,
        COUNT(*) CNT 
    INTO #DeleteSingleRn 
    FROM #SpDtls 
    GROUP BY ObjectID, SchemaID, Spname
    HAVING COUNT(*) = 1;

    DELETE S 
    FROM #SpDtls S
    JOIN #DeleteSingleRn DS 
        ON DS.ObjectID = S.ObjectID
        AND DS.SchemaID = S.SchemaID
        AND DS.Spname = S.Spname;

    -- Create V1 and V2 date tables
    DROP TABLE IF EXISTS #V1_DATE;
    SELECT 
        ObjectID,
        SchemaID,
        MIN(SpModifiedDate) AS SpModifiedDate,
        Spname 
    INTO #V1_DATE 
    FROM #SpDtls
    GROUP BY ObjectID, SchemaID, Spname;

    DROP TABLE IF EXISTS #V2_DATE;
    SELECT 
        ObjectID,
        SchemaID,
        MAX(SpModifiedDate) AS SpModifiedDate,
        Spname 
    INTO #V2_DATE 
    FROM #SpDtls
    GROUP BY ObjectID, SchemaID, Spname;

    -- Create new and modified stored procedure details tables
    SELECT S.* 
    INTO #NewSp 
    FROM [dbo].[SpDtls] S
    JOIN #SpDtls 
        ON #SpDtls.ObjectID = S.ObjectID
        AND #SpDtls.SchemaID = S.SchemaID
        AND #SpDtls.SpModifiedDate = S.SpModifiedDate
    JOIN #V1_DATE V1 
        ON V1.ObjectID = #SpDtls.ObjectID
        AND V1.SchemaID = #SpDtls.SchemaID
        AND V1.SpModifiedDate = #SpDtls.SpModifiedDate;

    SELECT S.* 
    INTO #ModifiedSp 
    FROM [dbo].[SpDtls] S
    JOIN #SpDtls 
        ON #SpDtls.ObjectID = S.ObjectID
        AND #SpDtls.SchemaID = S.SchemaID
        AND #SpDtls.SpModifiedDate = S.SpModifiedDate
    JOIN #V2_DATE V2 
        ON V2.ObjectID = #SpDtls.ObjectID
        AND V2.SchemaID = #SpDtls.SchemaID
        AND V2.SpModifiedDate = #SpDtls.SpModifiedDate;

    -- Insert into SpComparisonDtls
    INSERT INTO [dbo].[SpComparisonDtls]
    (
        ObjectID,
        SchemaID,
        SpName,
        SpCreatedBy,
        SpCreatedDate,
        SpCode_v1,
        SpLineNo_v1,
        SpModifiedDate_v1,
        SpModifiedBy_v1,
        SpCode_v2,
        SpLineNo_v2,
        SpModifiedDate_v2,
        SpModifiedBy_v2,
        ProcessDate
    )
    SELECT 
        CASE WHEN N.ObjectID IS NULL THEN M.ObjectID ELSE N.ObjectID END,
        CASE WHEN N.SchemaID IS NULL THEN M.SchemaID ELSE N.SchemaID END,
        CASE WHEN N.Spname IS NULL THEN M.Spname ELSE N.Spname END,
        CASE WHEN N.CreatedBy IS NULL THEN M.CreatedBy ELSE N.CreatedBy END,
        CASE WHEN N.SpCreatedDate IS NULL THEN M.SpCreatedDate ELSE N.SpCreatedDate END,
        N.Spcode AS SpCode_v1,
        N.LineNumber AS SpLineNo_v1,
        N.SpModifiedDate AS SpModifiedDate_v1,
        N.ModifiedBy,
        M.Spcode AS SpCode_v2,
        M.LineNumber AS SpLineNo_v2,
        M.SpModifiedDate AS SpModifiedDate_v2,
        M.ModifiedBy AS SpModifiedBy_v2,
        GETDATE()
    FROM #NewSp N
    FULL JOIN #ModifiedSp M 
        ON N.LineNumber = M.LineNumber
        AND N.ObjectID = M.ObjectID
        AND N.SchemaID = M.SchemaID;

    -- Create log table
    DROP TABLE IF EXISTS #LogTable;
    SELECT 
        V1_Date,
        ObjectID,
        SchemaID,
        Spname,
        V2_Date 
    INTO #LogTable 
    FROM (
        SELECT 
            LAG(SpModifiedDate) OVER (PARTITION BY ObjectID, SchemaID, SpName ORDER BY RN) AS V1_Date,
            ObjectID,
            SchemaID,
            Spname,
            SpModifiedDate AS V2_Date 
        FROM #SpDtls
    ) A 
    WHERE V1_Date IS NOT NULL;

    -- Insert into SpLogDtls
    INSERT INTO [dbo].[SpLogDtls]
    (
        ObjectID,
        SchemaID,
        SpName,
        SpDateModified_V1,
        SpDateModified_V2,
        ScriptStatus,
        ProcessDate
    )
    SELECT DISTINCT 
        ObjectID,
        SchemaID,
        Spname,
        V1_Date,
        V2_Date,
        'Comparison done',
        GETDATE()
    FROM #LogTable;

    -- Drop temporary tables
    DROP TABLE IF EXISTS #SpDtls;
    DROP TABLE IF EXISTS #NewSp;
    DROP TABLE IF EXISTS #ModifiedSp;
    DROP TABLE IF EXISTS #V1_DATE;
    DROP TABLE IF EXISTS #V2_DATE;
    DROP TABLE IF EXISTS #LogTable;
    DROP TABLE IF EXISTS #DeleteSp;
    DROP TABLE IF EXISTS #DeleteSingleRn;
END
GO