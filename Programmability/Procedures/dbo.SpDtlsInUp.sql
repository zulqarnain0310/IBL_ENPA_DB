SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/* CREATED BY DF627 on 05-07-24 FOR STORING THE STORED PROC CODE ALONG WITH LINE NO, CREATED BY, MODIFIED BY, CREATION DATE AND MODIFICATION DATE */

CREATE PROC [dbo].[SpDtlsInUp]
AS
BEGIN
    -- Drop temporary table if it exists
    DROP TABLE IF EXISTS #storeproc;

    -- Create temporary table with stored procedure details
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS SrNo,
        object_id,
        schema_id,
        SCHEMA_NAME(schema_id) + '.' + name AS Spname,
        create_date,
        modify_date 
    INTO #storeproc 
    FROM sys.objects s
    LEFT JOIN [dbo].[SpDtls] Sp 
        ON Sp.ObjectID = s.object_id
        AND Sp.SchemaID = s.schema_id
        AND Sp.SpModifiedDate = s.modify_date
    WHERE 
        type = 'P' 
        AND Sp.SpModifiedDate IS NULL;

    -- Initialize loop variables
    DECLARE @Cnt INT = 1;
    DECLARE @MaxCnt INT = (SELECT COUNT(*) FROM #storeproc);

    -- Loop through each row in the temporary table
    WHILE (@Cnt <= @MaxCnt)
    BEGIN
        DECLARE @Spname VARCHAR(MAX) = (SELECT Spname FROM #storeproc WHERE SrNo = @Cnt);
        DECLARE @SpCreatedDate DATETIME = (SELECT create_date FROM #storeproc WHERE SrNo = @Cnt);
        DECLARE @SpModifiedDate DATETIME = (SELECT modify_date FROM #storeproc WHERE SrNo = @Cnt);
        DECLARE @ObjectID INT = (SELECT object_id FROM #storeproc WHERE SrNo = @Cnt);
        DECLARE @SchemaID INT = (SELECT schema_id FROM #storeproc WHERE SrNo = @Cnt);

        -- Insert stored procedure details into [dbo].[SpDtls]
        INSERT INTO [dbo].[SpDtls] (
            ObjectID,
            SchemaID,
            Spcode,
            Spname,
            LineNumber,
            SpCreatedDate,
            SpModifiedDate,
            ProcessDate
        )
        SELECT 
            @ObjectID,
            @SchemaID,
            value AS LineText,
            @Spname,
            ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS LineNumber,
            @SpCreatedDate,
            @SpModifiedDate,
            GETDATE()
        FROM 
            sys.sql_modules AS m
            CROSS APPLY STRING_SPLIT(m.definition, CHAR(10)) AS s
        WHERE 
            m.object_id = OBJECT_ID(@Spname);

        -- Increment counter
        SET @Cnt = @Cnt + 1;
    END

    -- Update CreatedBy based on change log
    UPDATE S
    SET CreatedBy = CASE WHEN EventType = 'CREATE_PROCEDURE' THEN LoginName END 
    FROM [dbo].[SpDtls] S
    JOIN dbo.DbObjChangeLog D 
        ON D.ObjectID = S.ObjectID
        AND D.SchemaID = S.SchemaID
        AND CONVERT(DATETIME, CONVERT(VARCHAR(20), PostTime, 120)) = CONVERT(DATETIME, CONVERT(VARCHAR(20), SpCreatedDate, 120));

    -- Update ModifiedBy based on change log
    UPDATE S
    SET ModifiedBy = CASE WHEN EventType = 'ALTER_PROCEDURE' THEN LoginName END 
    FROM [dbo].[SpDtls] S
    JOIN dbo.DbObjChangeLog D 
        ON D.ObjectID = S.ObjectID
        AND D.SchemaID = S.SchemaID
        AND CONVERT(DATETIME, CONVERT(VARCHAR(20), PostTime, 120)) = CONVERT(DATETIME, CONVERT(VARCHAR(20), SpModifiedDate, 120));

    -- Drop temporary table
    DROP TABLE IF EXISTS #storeproc;
END
GO