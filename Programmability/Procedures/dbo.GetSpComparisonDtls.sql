SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/* CREATED BY DF627 ON 18-07-24 FOR DISPLAYING THE CHANGES BETWEEN 2 SP'S */

CREATE PROC [dbo].[GetSpComparisonDtls]
AS
BEGIN
    -- Drop temporary table if it exists
    DROP TABLE IF EXISTS #SpComparisonDtls;

    -- Create a temporary table with the data from SpComparisonDtls
    SELECT * INTO #SpComparisonDtls FROM [dbo].[SpComparisonDtls];

    -- Update temporary table to set SpCode_v1 to NULL if it doesn't contain alphanumeric characters
    UPDATE #SpComparisonDtls
    SET SpCode_v1 = NULL
    WHERE SpCode_v1 NOT LIKE '%[A-Za-z0-9]%';

    -- Update temporary table to set SpCode_v2 to NULL if it doesn't contain alphanumeric characters
    UPDATE #SpComparisonDtls
    SET SpCode_v2 = NULL
    WHERE SpCode_v2 NOT LIKE '%[A-Za-z0-9]%';

    -- Select data from the temporary table with change descriptions
    SELECT 
        SpName,
        SpCreatedBy,
        SpCreatedDate,
        ISNULL(SpCode_v1, '') AS SpCode_v1,
        SpLineNo_v1,
        SpModifiedDate_v1,
        SpModifiedBy_v1,
        ISNULL(SpCode_v2, '') AS SpCode_v2,
        SpLineNo_v2,
        SpModifiedDate_v2,
        SpModifiedBy_v2,
        CASE 
            WHEN SpCode_v1 <> SpCode_v2 AND SpLineNo_v1 = SpLineNo_v2 THEN 'Code is modified' 
            WHEN ISNULL(SpCode_v1, '') <> '' AND ISNULL(SpCode_v2, '') = '' AND SpLineNo_v1 = SpLineNo_v2 THEN 'Code is removed' 
            WHEN ISNULL(SpCode_v1, '') = '' AND ISNULL(SpCode_v2, '') <> '' AND SpLineNo_v1 = SpLineNo_v2 THEN 'Code is added' 
            WHEN SpLineNo_v1 IS NULL AND ISNULL(SpLineNo_v2, '') <> '' THEN 'New Lines are added'
            WHEN SpLineNo_v2 IS NULL AND ISNULL(SpLineNo_v1, '') <> '' THEN 'Existing Lines were removed'
            ELSE 'Code is same' 
        END AS 'Change Description',
        ProcessDate
    FROM #SpComparisonDtls 
	WHERE CAST(ProcessDate AS DATE)=DATEADD(DD,-1,CAST(GETDATE() AS DATE))
    --WHERE SPNAME = 'dbo.customerselect' --and ProcessDate = '2024-07-08 17:59:08.483'
    ORDER BY SpName,ProcessDate DESC, CASE WHEN SpLineNo_v1 IS NULL THEN SpLineNo_v2 ELSE SpLineNo_v1 END;

    -- Drop the temporary table
    DROP TABLE IF EXISTS #SpComparisonDtls;
END
GO