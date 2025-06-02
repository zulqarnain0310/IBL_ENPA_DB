SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/*  CREATED BY DF627 ON 23-05-24 FOR THE PURPOSE OF STORING TOTAL LINE OF CODE OF THE STORED PROC */

CREATE PROC [dbo].[SPLineCntInUp]
AS
BEGIN
    -- Insert data into SpTotalLineCnt table
    INSERT INTO DBO.SpTotalLineCnt
    SELECT 
        @@SERVERNAME AS ServerName,
        DB_NAME() AS DatabaseName,
        O.object_id,
        S.schema_id,
        o.type_desc AS ROUTINE_TYPE,
        QUOTENAME(s.[name]) + '.' + QUOTENAME(o.[name]) AS [OBJECT_NAME],
        (LEN(m.definition) - LEN(REPLACE(m.definition, CHAR(10), ''))) AS LINES_OF_CODE,
        o.create_date AS CreatedDate,
        o.modify_date AS ModifiedDate,
        GETDATE() AS ProcessDate
    FROM sys.sql_modules AS m
    INNER JOIN sys.objects AS o ON m.[object_id] = o.[OBJECT_ID]
    INNER JOIN sys.schemas AS s ON s.[schema_id] = o.[schema_id];

 
END;


GO