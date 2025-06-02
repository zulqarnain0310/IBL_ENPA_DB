SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



Create PROCEDURE [dbo].[API_MAILALERT_20241104]--'IBL_ENPA_EXTRACTION STEP : Ganaseva_Provision_Stg_Daily' ,'Dear Ganaseva','Ganaseva ETL Staging Extraction was completed Successfully','Ganaseva ETL Staging Extraction was Failed',80,'RF'
@PROCESSNAME AS VARCHAR(250),--subject of email
@MSG1 VARCHAR(250) ,--Dear Ganaseva,
@MSG2 VARCHAR(250) ,--Mail Body on success
@MSG3 VARCHAR(250) ,--Mail Body on failure
@SOURCEALT_KEY INT,
@FEED VARCHAR(5)
AS

/* INSERTING INTO TEMP TABLE TO GET VALUES CONVERTED TO STRING*/

DECLARE @Object AS INT;
DECLARE @ResponseText AS VARCHAR(8000);
DECLARE @TIMEKEY INT=(SELECT TIMEKEY FROM SysDataMatrix WHERE CurrentStatus='C')
DECLARE @ExtDate Date=(SELECT Date FROM SysDataMatrix WHERE TIMEKEY=@TIMEKEY)
DECLARE @FEEDTYPE VARCHAR(5)
DECLARE @SourceName Varchar(20) =(select case when @SOURCEALT_KEY=100 then 'Finacle-2' Else SourceName End from DIMSOURCESYSTEM where SourceAlt_Key=@SOURCEALT_KEY
									and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)


SET @FEEDTYPE=@FEED
 
	IF @FEEDTYPE='FF'
			Begin 
				
				Drop table If exists #Count_FF

				CREATE TABLE  #Count_FF (  
					[SourceAlt_Key] [int] NULL,
					[DataSet] [varchar](5) NULL,
					[Count] [int] NULL 
				)  
 
							Declare @DS1 Varchar(100)=(select Dataset1 From [dbo].[DIMSOURCEDATASETDETAIL] 
											where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
							Declare @DS2 Varchar(100)=(select Dataset2 From [dbo].[DIMSOURCEDATASETDETAIL] 
											where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
							Declare @DS3 Varchar(100)=(select Dataset3 From [dbo].[DIMSOURCEDATASETDETAIL] 
											where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
							Declare @DS4 Varchar(100)=(select Dataset4 From [dbo].[DIMSOURCEDATASETDETAIL] 
											where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
							Declare @DS5 Varchar(100)=(select Dataset5 From [dbo].[DIMSOURCEDATASETDETAIL] 
											where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
							Declare @DS6 Varchar(100)=(select Dataset6 From [dbo].[DIMSOURCEDATASETDETAIL] 
											where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 

												--select @DS1,@DS2,@DS3,@DS4,@DS5,@DS6

						Insert into #Count_FF ( [SourceAlt_Key],[DataSet])   
									  Values (@SourceAlt_Key,'DS1'), (@SourceAlt_Key,'DS2'), (@SourceAlt_Key,'DS3')
									  , (@SourceAlt_Key,'DS4'), (@SourceAlt_Key,'DS5'), (@SourceAlt_Key,'DS6')

											 --select * from #CheckSumData_FF 
				--Print 1
						If @DS1 is not null
							Begin
								Drop Table if exists DS1
									Exec ('select Count(1) as count into DS1 from '+@DS1) 
								Update #Count_FF  
									Set Count=(Select ISNULL(Count,0) from DS1)
									where DataSet='DS1'
							End

				 --Print 2
						If @DS2 is not null
							Begin
								Drop Table if exists DS2
									Exec ('select Count(1) as count into DS2 from '+@DS2) 
								Update #Count_FF  
								Set Count=(Select ISNULL(Count,0) from DS2)
								where DataSet='DS2'
							End
				--Print 3
						If @DS3 is not null
							Begin
								Drop Table if exists DS3
									Exec ('select Count(1) as count into DS3 from '+@DS3) 
								Update #Count_FF  
								Set Count=(Select ISNULL(Count,0) from DS3)
								where DataSet='DS3'
							End
				--Print 4
						If @DS4 is not null
							Begin
								Drop Table if exists DS4
									Exec ('select Count(1) as count into DS4 from '+@DS4) 
								Update #Count_FF  
								Set Count=(Select ISNULL(Count,0) from DS4)
								where DataSet='DS4'
							End
				--Print 5
						If @DS5 is not null
							Begin
								Drop Table if exists DS5
									Exec ('select Count(1) as count into DS5 from '+@DS5) 
								Update #Count_FF  
								Set Count=(Select ISNULL(Count,0) from DS5)
								where DataSet='DS5'
							End
				--Print 6
						If @DS6 is not null
							Begin
								Drop Table if exists DS6
									Exec ('select Count(1) as count into DS6 from '+@DS6) 
								Update #Count_FF  
								Set Count=(Select ISNULL(Count,0) from DS6)
								where DataSet='DS6'
							End
 
				 --select * from #Count_FF
  
				Declare @DS_1 Varchar(30)='DS1='+(select cast(ISNULL(Count,0) as Varchar(20)) from #Count_FF where DataSet='DS1')
				Declare @DS_2 Varchar(30)='DS2='+(select cast(ISNULL(Count,0) as Varchar(20)) from #Count_FF where DataSet='DS2')
				Declare @DS_3 Varchar(30)='DS3='+(select cast(ISNULL(Count,0) as Varchar(20)) from #Count_FF where DataSet='DS3')
				Declare @DS_4 Varchar(30)='DS4='+(select cast(ISNULL(Count,0) as Varchar(20)) from #Count_FF where DataSet='DS4')
				Declare @DS_5 Varchar(30)='DS5='+(select cast(ISNULL(Count,0) as Varchar(20)) from #Count_FF where DataSet='DS5')
				Declare @DS_6 Varchar(30)='DS6='+(select cast(ISNULL(Count,0) as Varchar(20)) from #Count_FF where DataSet='DS6')

	/****  Checksum CR changes ****/
				
		Drop table If Exists 	#CheckSumData_FF
			select ProcessDate,SourceName,DataSet,CRISMAC_CheckSum,Source_CheckSum,Start_BAU,Processing_Type,Reason,ApprovedByFirstLevel,ApprovedBy into #CheckSumData_FF
			from Dbo.CheckSumData_FF where SourceAlt_Key=@SourceAlt_Key AND EffectiveFromTimeKey=@Timekey And EffectiveToTimeKey=@Timekey

			--Select * from #CheckSumData_FF

		Drop table If Exists #FFChecksum
			select
				DataSet,'|Date of Data:'+ Convert(Varchar(10),ProcessDate,103)+
				', Source Name:'+SourceName+ 
				', Data Set:'+DataSet+  
				', CRISMAC_CheckSum:'+CRISMAC_CheckSum+  
				', Source_CheckSum:'+Source_CheckSum+  
				', Start_BAU:'+Start_BAU+  
				', Processing Type (Auto/Manual):'+Processing_Type+(Case When   Processing_Type='AUTO' Then '' ELSE
															', Reason (Mandatory if process is running manually):'+ISNULL(Reason,'')+  
															', 1st level Approver user ID:'+ISNULL(ApprovedByFirstLevel,'')+  
															', 2nd level Approver user ID:'+ISNULL(ApprovedBy,'') END)+' |' as ChecksumData into #FFChecksum
			from #CheckSumData_FF

			----Select ChecksumData from #FFChecksum where DataSet='DS1' 

			Declare @DS1_CS Varchar(MAX)=(Select ChecksumData from #FFChecksum where DataSet='DS1') 
			Declare @DS2_CS Varchar(MAX)=(Select ChecksumData from #FFChecksum where DataSet='DS2') 
			Declare @DS3_CS Varchar(MAX)=(Select ChecksumData from #FFChecksum where DataSet='DS3') 
			Declare @DS4_CS Varchar(MAX)=(Select ChecksumData from #FFChecksum where DataSet='DS4') 
			Declare @DS5_CS Varchar(MAX)=(Select ChecksumData from #FFChecksum where DataSet='DS5') 
			Declare @DS6_CS Varchar(MAX)=(Select ChecksumData from #FFChecksum where DataSet='DS6') 


				Declare @CountString Varchar(MAX)= 
				'Record Count for '+@SourceName+' is '+ ISNULL(@DS_1,'')+', '+ISNULL(@DS_2,'')+', '+ISNULL(@DS_3,'')+', '+ISNULL(@DS_4,'')+', '+ISNULL(@DS_5,'')+', '+ISNULL(@DS_6,'')
				+' Please find the forward feed details as process in the CRisMac on Today '+ ISNULL(@DS1_CS,'')+ISNULL(@DS2_CS,'')+ISNULL(@DS3_CS,'')+ISNULL(@DS4_CS,'')+ISNULL(@DS5_CS,'')+ISNULL(@DS6_CS,'')

				--select @CountString
			End


	IF @FEEDTYPE='RF'
			Begin 
				Drop table if exists #RFCount
				select AsOnDate,SourceName,COUNT(1) Count into #RFCount from ReverseFeedDetails  
				where SourceName=@SourceName and AsOnDate=@ExtDate
				group by  AsOnDate,SourceName 
				
				Declare @Count Varchar(20)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount )

	/****  Checksum CR changes ****/
				
		Declare @RF_CS Varchar(MAX)=(
									Select
									' |Dateofdata:'+Convert(Varchar(10),AS_ON_DATE,103) +
									',SourceName:'+SourceName+
									',Count:'+Convert(Varchar(20),RecordCount)+
									',CRISMACRFChecksum:'+CRISMAC_CheckSum+
									',DateTimestamp:'+ Convert(Varchar(10),Datecreated,103)+' '+ Convert(Varchar(8),Datecreated,14)+'|' 
									from Dbo.CheckSumData_RF where SourceAlt_Key=@SourceAlt_Key AND TimeKey=@Timekey )

		--select @RF_CS 
				Declare @CountString_RF Varchar(MAX)='Record Count for '+@SourceName+' is '+ISNULL(@Count,'')+' '+@RF_CS

			End

DROP TABLE IF EXISTS #temp_email ;
select 
'<Row>
<RefId>RefId1111</RefId>
<Txncode>EA0182</Txncode>
' B1,
(select 
cast((a.SourceSystemMailID) as varchar(max)) for xml path('Emailid'),type,elements absent)Emailid
,'
<Subject>'+@PROCESSNAME+'</Subject>
<Msg>
<![CDATA[<body>'+@MSG1+'</body>]]>

<![CDATA[<body>'+@MSG2+'</body>]]>

<![CDATA[<body>'+(Case when @FEEDTYPE='FF' then @CountString
					   when @FEEDTYPE='RF' then @CountString_RF
						Else '' 
						End) +'</body>]]> 

</Msg>
</Row>
'B2 into #temp_email from [DimSourceSystemMail] a WHERE SourceAlt_Key= @SOURCEALT_KEY 
AND SourceSystemMailValidCode='Y'--ADDED ON 2023-07-25



/*UPDATING FORWARD FEED TXNCODE BASED ON FEED INPUT PARAMETER*/
IF @FEEDTYPE='FF'
BEGIN
UPDATE  #temp_email SET B1= REPLACE(B1,'EA0182','EA0193')
END


DECLARE @Body AS VARCHAR(MAX) 
DROP TABLE IF EXISTS #BODY ;
SELECT (B1+cast(Emailid as varchar(max))+B2) AS XML_COL INTO #BODY FROM #temp_email
SET @Body = (select  '<Root>
<ChnlId>D2K</ChnlId>
<Key>D2K#20230622</Key>'+STRING_AGG(XML_COL,',')+'</Root>' AS BODY  FROM #BODY)



EXEC sp_OACREATE 'MSXML2.ServerXMLHttp', @Object OUT; 
EXEC sp_OAMethod @Object, 'Open', NULL, 'POST', 'https://ealert.indusind.com:1443/EmailApi/api/SendEmail', 'false' 
EXEC sp_OAMethod @Object, 'SETRequestHeader', null, 'Content-Type', 'application/XML'--TOCHECK

DECLARE @len int
SET @len = len(@body)


EXEC sp_OAMethod @Object, 'SETRequestBody', null, 'Body', @body
EXEC sp_OAMethod @Object, 'Send', null, @body

select @body "XML PASSED"
EXEC sp_OAMethod @Object, 'ResponseText', @ResponseText OUTPUT
print concat('object : ',@Object)
print concat('RESPONSE : ',+@ResponseText)
select @ResponseText "RESPONSE RECEIVED"

IF @ResponseText LIKE '%Successful%' 
BEGIN 
	PRINT 'EXECUTING [dbo].[USP_READXMLString]@body '
	EXEC [dbo].[USP_READXMLString]@body,@MSG1,@MSG2 
	update A set A.ResponseText = 'Successful' 
		FROM API_MAIL_XML_TABLE A
			inner join DimSourceSystemMail B on A.Emailid=B.SourceSystemMailID
			where A.Emailid in( select replace(replace(cast(Emailid as varchar(max)),'<Emailid>',''),'</Emailid>','') from #temp_email)
								and B.SourceSystemMailValidCode='Y'
								AND A.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND A.EFFECTIVEFROMTIMEKEY>=@TIMEKEY
								AND A.ResponseText IS NULL
			
END
else
BEGIN 
	PRINT 'EXECUTING [dbo].[USP_READXMLString]@body '
	EXEC [dbo].[USP_READXMLString] @body,@MSG1,@MSG3
	update A set ResponseText = 'Failure'
			FROM API_MAIL_XML_TABLE A
			inner join DimSourceSystemMail B on A.Emailid=B.SourceSystemMailID
			where A.Emailid in( select replace(replace(cast(Emailid as varchar(max)),'<Emailid>',''),'</Emailid>','') from #temp_email)
								and B.SourceSystemMailValidCode='Y'
								AND A.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND A.EFFECTIVEFROMTIMEKEY>=@TIMEKEY
								AND A.ResponseText IS NULL
END

print @ResponseText
/*TO CHECK THE ERROR IN CASE OF FAILURE*/
EXEC sp_OAGetErrorInfo @Object


/*DATA CHECKING IN MAIL TABLE*/
--SELECT * FROM  API_MAIL_XML_TABLE
EXEC sp_OADestroy @Object


GO