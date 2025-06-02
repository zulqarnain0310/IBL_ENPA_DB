SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

 CREATE PROC [dbo].[USP_READXMLString]
-- ' <Root>

--<ChnlId>D2KUAT</ChnlId>

--<Key>D2KUAT#20230622</Key>

--<Row>

--<RefId>RefId1111</RefId>

--<Txncode>EA0182</Txncode>

--<Emailid>mohd.salim@indusind.com</Emailid>            

--<Subject>Test Subject</Subject>

--<Msg>
--<![CDATA[<bodY>Dear Ganaseva</body>]]>
--<![CDATA[<body>Ganaseva ETL Staging Extraction was completed Successfully</body>]]>
--</Msg>

--<Attachment>file.txt</Attachment>

--</Row>

--</Root>','Dear Ganaseva','Ganaseva ETL Staging Extraction was completed Successfully'
(
   @XMLDOC2    XML,
   @MSG1 	varchar(max),
   @MSG2	varchar(max)
)
AS
   BEGIN
         SET NOCOUNT ON

         DECLARE @HANDLE INT
         EXEC SP_XML_PREPAREDOCUMENT  @HANDLE OUTPUT,@XMLDOC2
		 PRINT @HANDLE

		 
		/*TO GET THE CREDENTAILS USED BY THE SESSION*/		 
		  SELECT * into #credentails FROM OPENXML(@HANDLE, '/Root', 2)
         WITH (ChnlId VARCHAR(50),[Key] varchar(50))
		
		/*INSERTING INTO MAIN CREDENTAILS TABLE FROM TEMPORARY TABLE*/
		insert into credentails_api select * from #credentails 


		/*TO GET DATA FROM THE XML */
         SELECT * into #xml_table FROM OPENXML(@HANDLE, '/Root/Row', 2)
         WITH (RefId VARCHAR(50),Txncode VARCHAR(50),Emailid VARCHAR(50),Subject VARCHAR(50),Msg VARCHAR(MAX))
		 
		 /*INSERTING XML DATA AS WELL AS THE CREDENTAILS IN MAIN TABLE*/
		 INSERT INTO API_MAIL_XML_TABLE (RefId,Txncode,Emailid,Subject,Msg,ASONDATE,EFFECTIVEFROMTIMEKEY,EFFECTIVETOTIMEKEY,ChnlId,[Key],DATE,msg1,msg2)
		 SELECT RefId,Txncode,Emailid,Subject,Msg,
		 GETDATE(),
		 (SELECT TIMEKEY FROM SysDataMatrix WHERE CurrentStatus='C'),
		 (SELECT TIMEKEY FROM SysDataMatrix WHERE CurrentStatus='C'),
		 (SELECT ChnlId FROM #credentails),
		 (SELECT [KEY] FROM #credentails),
		 GETDATE(),
		 @msg1,
		 @msg2
		 FROM #xml_table
		 --SELECT * FROM  API_MAIL_XML_TABLE  
		 

END
GO