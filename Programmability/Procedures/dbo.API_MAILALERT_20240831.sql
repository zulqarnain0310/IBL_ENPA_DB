SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


Create PROCEDURE [dbo].[API_MAILALERT_20240831]--'IBL_ENPA_EXTRACTION STEP : Ganaseva_Provision_Stg_Daily' ,'Dear Ganaseva','Ganaseva ETL Staging Extraction was completed Successfully','Ganaseva ETL Staging Extraction was Failed',80,'RF'
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
DECLARE @FEEDTYPE VARCHAR(5)

SET @FEEDTYPE=@FEED

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
</Msg>
</Row>'
/*commented as requested by the bank "Dharmendra"20230715*/
--<Attachment>file.txt</Attachment> when attachment is required add this and below line inside this quotations and remove </Row> from above line
--</Row>
B2 into #temp_email from [DimSourceSystemMail] a WHERE SourceAlt_Key= @SOURCEALT_KEY 



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