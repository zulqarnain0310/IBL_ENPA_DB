SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[MOC_CLUBBING]--'ReverseFeedDetails_CLUBBED_2DAYS','1','MOC_REVERSEFEED_BATCH1','','','',''
@FINAL_CLUBBED_RF VARCHAR(MAX)--FINAL CLUBBED RF TABLE NAME
,@NO_BATCH VARCHAR(5)--TOTAL NUMBER OF BATCHES
,@BATCH1 VARCHAR(MAX)--BATCH 1 MOC TABLE NAME
,@BATCH2 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH2'--BATCH 2 MOC TABLE NAME
,@BATCH3 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH3'--BATCH 3 MOC TABLE NAME
,@BATCH4 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH4'--BATCH 4 MOC TABLE NAME
,@BATCH5 VARCHAR(MAX)='MOC_REVERSEFEED_BATCH5'--BATCH 5 MOC TABLE NAME
AS
BEGIN

DECLARE @SQL VARCHAR(MAX)

		DROP TABLE IF EXISTS #REV_BKP

		SELECT * INTO #REV_BKP FROM REVERSEFEEDDETAILS WHERE 1=2

		DROP TABLE IF EXISTS #AB

		SELECT * INTO #AB FROM #REV_BKP WHERE 1=2

/*BATCH1 MOC TABLE*/
IF @NO_BATCH='1'
	BEGIN
		SET @SQL ='INSERT into #rev_bkp SELECT * from '+ @FINAL_CLUBBED_RF
		PRINT @SQL
		EXEC (@SQL)
		PRINT '@SQL SETTING AS NULL'

		SET @SQL=NULL


			SET @SQL='INSERT into #ab SELECT * from #rev_bkp where AccountNo in (
			select AccountNo from '+ @BATCH1 + 
			' intersect
			select AccountNo from #rev_bkp)'

		PRINT @SQL
		EXEC (@SQL)
		PRINT 'MAKING TEMP TABLE'

	END
/*BATCH1 MOC TABLE END*/

/*BATCH2 MOC TABLE*/
IF @NO_BATCH='2'
	BEGIN

		PRINT '@SQL SETTING AS NULL'

		SET @SQL=NULL
			drop table if exists #ab
			SET @SQL='select * into #ab from #rev_bkp where AccountNo in (
			select AccountNo from '+ @BATCH1 + 
			'select AccountNo from '+ @BATCH2 + 
			' intersect
			select AccountNo from #rev_bkp)'
		PRINT @SQL
		EXEC (@SQL)
		PRINT 'MAKING TEMP TABLE'

	END
/*BATCH2 MOC TABLE END*/

/*BATCH3 MOC TABLE*/

IF @NO_BATCH='3'
	BEGIN

		PRINT '@SQL SETTING AS NULL'

		SET @SQL=NULL
			drop table if exists #ab
			SET @SQL='INSERT into #ab SELECT from #rev_bkp where AccountNo in (
			(select AccountNo from '+ @BATCH1 + 
			'select AccountNo from '+ @BATCH2 + 
			'select AccountNo from '+ @BATCH3 + 
			' intersect
			select AccountNo from #rev_bkp)'
		
		PRINT @SQL
		EXEC (@SQL)
		PRINT 'MAKING TEMP TABLE'

	END
/*BATCH3 MOC TABLE END*/

/*BATCH4 MOC TABLE*/

IF @NO_BATCH='4'
	BEGIN

		PRINT '@SQL SETTING AS NULL'

		SET @SQL=NULL
			drop table if exists #ab
			SET @SQL='INSERT into #ab SELECT * from #rev_bkp where AccountNo in (
			(select AccountNo from '+ @BATCH1 + 
			'select AccountNo from '+ @BATCH2 + 
			'select AccountNo from '+ @BATCH3 + 
			'select AccountNo from '+ @BATCH4 + 
			' intersect
			select AccountNo from #rev_bkp)'

		PRINT @SQL
		EXEC (@SQL)
		PRINT 'MAKING TEMP TABLE'
	END
/*BATCH4 MOC TABLE END*/

/*BATCH5 MOC TABLE*/

IF @NO_BATCH='5'
	BEGIN

		PRINT '@SQL SETTING AS NULL'

		SET @SQL=NULL
			drop table if exists #ab
			SET @SQL='INSERT into #ab SELECT * from #rev_bkp where AccountNo in (
			(select AccountNo from '+ @BATCH1 + 
			'select AccountNo from '+ @BATCH2 + 
			'select AccountNo from '+ @BATCH3 + 
			'select AccountNo from '+ @BATCH4 + 
			'select AccountNo from '+ @BATCH5 + 
			' intersect
			select AccountNo from #rev_bkp)'

		PRINT @SQL
		EXEC (@SQL)
		PRINT 'MAKING TEMP TABLE'
	END
/*BATCH5 MOC TABLE END*/

INSERT INTO ReverseFeedDetails
 select * from #rev_bkp

END
GO