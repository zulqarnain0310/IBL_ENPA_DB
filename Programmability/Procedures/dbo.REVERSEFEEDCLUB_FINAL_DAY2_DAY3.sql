SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[REVERSEFEEDCLUB_FINAL_DAY2_DAY3]--'REVERSE2'
@DAY3 VARCHAR(MAX)
AS
BEGIN
	DROP TABLE IF EXISTS ReverseFeedDetails_CLUBBED_3DAYS
				Drop table if exists  #ReverseFeedDetails_3days
					Select Top 0 * into #ReverseFeedDetails_3days from ReverseFeedDetails
					
					DECLARE @UNIQUE_DAY3 VARCHAR(MAX)
					
					DECLARE @UNIQUE_DAY2_F VARCHAR(MAX)
					
					SET @UNIQUE_DAY2_F  ='
					insert into #ReverseFeedDetails_3days
					select * from ReverseFeedDetails_CLUBBED_2DAYS where AccountNo in (
					select AccountNo from ReverseFeedDetails_CLUBBED_2DAYS 
					except
					select AccountNo from '+@DAY3 --ReverseFeedDetails_BKP_23012025
					+')'
					PRINT ' '
					PRINT @UNIQUE_DAY2_F
					EXEC (@UNIQUE_DAY2_F)
					
					
					SET @UNIQUE_DAY3 ='
					insert into #ReverseFeedDetails_3days
					select * from ' + @DAY3+--ReverseFeedDetails_BKP_23012025 
					' where AccountNo in (
					select AccountNo from ' +@DAY3--ReverseFeedDetails_BKP_23012025
					+' except
					select AccountNo from ReverseFeedDetails_CLUBBED_2DAYS)'
					
					PRINT ' '
					PRINT @UNIQUE_DAY3
					EXEC (@UNIQUE_DAY3)
					
					
					DECLARE @COMMON_DAY2_F_GREATER_DAY3 VARCHAR(MAX)=
					
					'insert into #ReverseFeedDetails_3days
					select b.*
					
					from ReverseFeedDetails_CLUBBED_2DAYS a
					inner join '+ @DAY3--ReverseFeedDetails_BKP_23012025 
					+' b on a.AccountNo=b.AccountNo
					 WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''DBT''' + ' then 003
					WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''SUB''' +' THEN 002
					WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''STD'''+' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) >
					(CASE WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''DBT'''+' then 003
					WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''SUB'''+' THEN 002
					WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''STD'''+' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)
					'
					PRINT ' '
					PRINT @COMMON_DAY2_F_GREATER_DAY3
					EXEC (@COMMON_DAY2_F_GREATER_DAY3)
					
					DECLARE @COMMON_DAY2_F_LESS_DAY3 VARCHAR(MAX)=
					
					'insert into #ReverseFeedDetails_3days
					select b.*
					
					from ReverseFeedDetails_CLUBBED_2DAYS a
					inner join '+ @DAY3--ReverseFeedDetails_BKP_23012025 
					+' b on a.AccountNo=b.AccountNo
					WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''DBT''' + ' then 003
					WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''SUB''' +' THEN 002
					WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''STD'''+' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) <
					(CASE WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''DBT'''+' then 003
					WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''SUB'''+' THEN 002
					WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''STD'''+' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)
					'
					PRINT ' '
					PRINT @COMMON_DAY2_F_LESS_DAY3
					EXEC (@COMMON_DAY2_F_LESS_DAY3)
					
					DECLARE @COMMON_DAY2_F_EQUALS_DAY3 VARCHAR(MAX)=
					
					'insert into #ReverseFeedDetails_3days
					select A.*
					
					from ReverseFeedDetails_CLUBBED_2DAYS a
					inner join '+ @DAY3--ReverseFeedDetails_BKP_23012025 
					+' b on a.AccountNo=b.AccountNo
					WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''DBT''' + ' then 003
					WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''SUB''' +' THEN 002
					WHEN isnull(a.HomogenizedAssetClass,0) ='+ '''STD'''+' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) =
					(CASE WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''DBT'''+' then 003
					WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''SUB'''+' THEN 002
					WHEN isnull(b.HomogenizedAssetClass,0) ='+ '''STD'''+' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)
					'
					PRINT ' '
					PRINT @COMMON_DAY2_F_EQUALS_DAY3
					EXEC (@COMMON_DAY2_F_EQUALS_DAY3)

					SELECT * INTO ReverseFeedDetails_CLUBBED_3DAYS FROM #ReverseFeedDetails_3days
END
GO