SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[REVERSEFEEDCLUB] --'REVERSE1','REVERSE2','REVERSE2','Y','ReverseFeedDetails_CLUBBED_2DAYS','1','MOC_REVERSEFEED_BATCH1','','','',''
	@DAY1 VARCHAR(MAX)
	,@DAY2 VARCHAR(MAX)
	,@DAY3 VARCHAR(MAX)='REVERSEFEEDDETAILS'
	,@MOC VARCHAR(5)='N'
	,@FINAL_CLUBBED_RF VARCHAR(MAX)='FINAL_RF'--FINAL CLUBBED RF TABLE NAME
	,@NO_BATCH VARCHAR(5)=''--TOTAL NUMBER OF BATCHES
	,@BATCH1 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH1'--BATCH 1 MOC TABLE NAME
	,@BATCH2 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH2'--BATCH 2 MOC TABLE NAME
	,@BATCH3 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH3'--BATCH 3 MOC TABLE NAME
	,@BATCH4 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH4'--BATCH 4 MOC TABLE NAME
	,@BATCH5 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH5'--BATCH 5 MOC TABLE NAME
	AS
		BEGIN

		TRUNCATE TABLE ReverseFeedDetails

		DECLARE @BKP_RF VARCHAR(MAX)
		DECLARE @DATE VARCHAR(MAX)= Convert(varchar(10),GETDATE(),112)
		PRINT @DATE 

		SET @BKP_RF = 'SELECT * INTO ReverseFeedDetails_BKP_'+@DATE+' FROM ReverseFeedDetails'
		PRINT @BKP_RF
		EXEC (@BKP_RF)
			DROP TABLE IF EXISTS ReverseFeedDetails_CLUBBED_2DAYS
			DECLARE @UNIQUE_DAY1 VARCHAR(MAX)
			DECLARE @UNIQUE_DAY2 VARCHAR(MAX)
			
			drop table if exists #ReverseFeedDetails_2days
			
			Select Top 0 * into #ReverseFeedDetails_2days from ReverseFeedDetails
			
				SET @UNIQUE_DAY1=
				'insert into #ReverseFeedDetails_2days
				select * from '+@DAY1+--ReverseFeedDetails_BKP_21012025 
				' where AccountNo in (
				select AccountNo from '+@DAY1 +--ReverseFeedDetails_BKP_21012025   ---- 78
				' except
				select AccountNo from ' + @DAY2--ReverseFeedDetails_BKP_22012025
				+' )'
				PRINT ' '
				PRINT '@UNIQUE_DAY1'
				PRINT ' '
				PRINT @UNIQUE_DAY1
				EXEC (@UNIQUE_DAY1)
			
				SET @UNIQUE_DAY2 = 
				'insert into #ReverseFeedDetails_2days
				select * from '+ @DAY2 +--ReverseFeedDetails_BKP_22012025 
				' where AccountNo in (
				select AccountNo from ' +@DAY2+-- ReverseFeedDetails_BKP_22012025
				' except
				select AccountNo from '+ @DAY1-- ReverseFeedDetails_BKP_21012025
				+ ' )'   
				
				PRINT ' '
				PRINT '@UNIQUE_DAY2'
				PRINT ' '
				PRINT @UNIQUE_DAY2	
				EXEC (@UNIQUE_DAY2)
			
			DECLARE @COMMON_DAY1_GREATER_DAY2 VARCHAR(MAX)=
				'insert into #ReverseFeedDetails_2days
				select B.*
				from '+ @DAY1+  --ReverseFeedDetails_BKP_21012025 a
				' A inner join '+ @DAY2 --ReverseFeedDetails_BKP_22012025
				+' b on a.AccountNo=b.AccountNo
				WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = ' + '''DBT''' +' then 003
				WHEN isnull(a.HomogenizedAssetClass,0) = '+ '''SUB'''+ ' THEN 002
				WHEN isnull(a.HomogenizedAssetClass,0) = '+'''STD'''+' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) > 
				(CASE WHEN isnull(b.HomogenizedAssetClass,0) = '+'''DBT'''+' then 003
				WHEN isnull(b.HomogenizedAssetClass,0) = '+'''SUB'''+' THEN 002
				WHEN isnull(b.HomogenizedAssetClass,0) = '+'''STD'''+' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)
				'
				PRINT ' '
				PRINT '@COMMON_DAY1_GREATER_DAY2'
				PRINT ' '
				PRINT @COMMON_DAY1_GREATER_DAY2
				EXEC (@COMMON_DAY1_GREATER_DAY2)

			DECLARE @COMMON_DAY1_LESS_DAY2 VARCHAR(MAX)=
				'insert into #ReverseFeedDetails_2days
				select B.*
				from '+ @DAY1+  --ReverseFeedDetails_BKP_21012025 a
				' A inner join '+ @DAY2 --ReverseFeedDetails_BKP_22012025
				+' b on a.AccountNo=b.AccountNo
				WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = ' + '''DBT''' +' then 003
				WHEN isnull(a.HomogenizedAssetClass,0) = '+ '''SUB'''+ ' THEN 002
				WHEN isnull(a.HomogenizedAssetClass,0) = '+'''STD'''+' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) < 
				(CASE WHEN isnull(b.HomogenizedAssetClass,0) = '+'''DBT'''+' then 003
				WHEN isnull(b.HomogenizedAssetClass,0) = '+'''SUB'''+' THEN 002
				WHEN isnull(b.HomogenizedAssetClass,0) = '+'''STD'''+' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)
				'
				PRINT ' '
				PRINT '@COMMON_DAY1_LESS_DAY2'
				PRINT ' '
				PRINT @COMMON_DAY1_LESS_DAY2
				EXEC (@COMMON_DAY1_LESS_DAY2)
			
			DECLARE @COMMON_DAY1_EQUALS_DAY2 VARCHAR(MAX)=
				'insert into #ReverseFeedDetails_2days
				select A.*
				from '+ @DAY1+  --ReverseFeedDetails_BKP_21012025 a
				' A inner join '+ @DAY2 --ReverseFeedDetails_BKP_22012025
				+' b on a.AccountNo=b.AccountNo
				WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = ' + '''DBT''' +' then 003
				WHEN isnull(a.HomogenizedAssetClass,0) = '+ '''SUB'''+ ' THEN 002
				WHEN isnull(a.HomogenizedAssetClass,0) = '+'''STD'''+' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) = 
				(CASE WHEN isnull(b.HomogenizedAssetClass,0) = '+'''DBT'''+' then 003
				WHEN isnull(b.HomogenizedAssetClass,0) = '+'''SUB'''+' THEN 002
				WHEN isnull(b.HomogenizedAssetClass,0) = '+'''STD'''+' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)
				'
				PRINT ' '
				PRINT '@COMMON_DAY1_EQUALS_DAY2'
				PRINT ' '
				PRINT @COMMON_DAY1_EQUALS_DAY2
				EXEC (@COMMON_DAY1_EQUALS_DAY2)
				
			SELECT * INTO ReverseFeedDetails_CLUBBED_2DAYS FROM #ReverseFeedDetails_2days


			IF @DAY3='' AND @MOC='Y'
			BEGIN
				SET @FINAL_CLUBBED_RF='ReverseFeedDetails_CLUBBED_2DAYS'
				/*ADDING MOC IN CLUBBED RF TABLE*/
				PRINT ''
				PRINT 'MOC CLUBBIBG AFTER DAY TWO CLUBBING SINCE THERE IS NO DAY 3'
				EXEC MOC_CLUBBING @FINAL_CLUBBED_RF,@NO_BATCH,@BATCH1,@BATCH2,@BATCH3,@BATCH4,@BATCH5
				PRINT ''
				PRINT 'MOC CLUBBIBG AFTER DAY TWO CLUBBING SINCE THERE IS NO DAY 3 END'
								/*ADDING MOC IN CLUBBED RF TABLE END*/
			END
			IF @DAY3<>'' AND @MOC='N'
			BEGIN
				PRINT 'CLUBBING DAY 3 WITH NO MOC SINCE MOC FLAG IS N '
				EXEC REVERSEFEEDCLUB_FINAL_DAY2_DAY3 @DAY3
				PRINT 'CLUBBING DAY 3 WITH NO MOC SINCE MOC FLAG IS N END'

				INSERT INTO ReverseFeedDetails
					select * from ReverseFeedDetails_CLUBBED_3DAYS
			END

			IF @DAY3<>'' AND @MOC='Y'
			BEGIN
				SET @FINAL_CLUBBED_RF='ReverseFeedDetails_CLUBBED_3DAYS'
				PRINT 'CLUBBING DAY 3'
				EXEC REVERSEFEEDCLUB_FINAL_DAY2_DAY3 @DAY3
				PRINT 'END OF CLUBBING DAY 3'

				/*ADDING MOC IN CLUBBED RF TABLE*/
				PRINT 'MOC CLUBBING AFTER DAY THREE CLUBBING'
				EXEC MOC_CLUBBING @FINAL_CLUBBED_RF,@NO_BATCH,@BATCH1,@BATCH2,@BATCH3,@BATCH4,@BATCH5
				PRINT 'MOC CLUBBING AFTER DAY THREE CLUBBING END'
				/*ADDING MOC IN CLUBBED RF TABLE END*/

			END


		END
GO