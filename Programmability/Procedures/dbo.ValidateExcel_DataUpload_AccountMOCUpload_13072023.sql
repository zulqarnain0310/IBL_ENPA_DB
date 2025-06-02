SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROCEDURE [dbo].[ValidateExcel_DataUpload_AccountMOCUpload_13072023] 
@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='FNASUPERADMIN',  
@Timekey INT=49999
,@filepath VARCHAR(MAX) ='SaletoARC.xlsx'  
WITH RECOMPILE  
AS  

  

--DECLARE  
--@MenuID INT=101,  
--@UserLoginId varchar(20)='1maker',  
--@Timekey int=26084
--,@filepath varchar(500)='Account_MOC_Upload (3).xlsx'  
  
BEGIN

BEGIN TRY  

     
	 SET DATEFORMAT DMY
	 SET NOCOUNT ON;

	 SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y') 
	 --SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C') 

 --Select   @Timekey=Max(Timekey) from sysDayMatrix where Cast(date as Date)=cast(getdate() as Date)

  PRINT @Timekey  
   
  
   
  
  DECLARE @FilePathUpload	VARCHAR(100)

			SET @FilePathUpload=@UserLoginId+'_'+@filepath
	PRINT '@FilePathUpload'
	PRINT @FilePathUpload

	IF EXISTS(SELECT 1 FROM dbo.MasterUploadData    where FileNames=@filepath )
	BEGIN
		Delete from dbo.MasterUploadData    where FileNames=@filepath  
		print @@rowcount
	END


IF (@MenuID=101)	
BEGIN

	   IF OBJECT_ID('UploadAccountMOC') IS NOT NULL  
		  BEGIN
	    
			DROP TABLE  UploadAccountMOC

		  END

		  print @FilePathUpload

	   
  IF NOT (EXISTS (SELECT * FROM AccountLvlMOCDetails_stg where filname=@FilePathUpload))

BEGIN
print 'NO DATA1'
			Insert into dbo.MasterUploadData
			(SR_No,ColumnName,ErrorData,ErrorType,FileNames,Flag) 
			SELECT 0 SRNO , '' ColumnName,'No Record found' ErrorData,'No Record found' ErrorType,@filepath,'SUCCESS' 
			

			goto errordata
    
END



ELSE
BEGIN
PRINT 'DATA PRESENT'
	   Select *,CAST('' AS varchar(MAX)) ErrorMessage,CAST('' AS varchar(MAX)) ErrorinColumn,CAST('' AS varchar(MAX)) Srnooferroneousrows
 	   into UploadAccountMOC 
	   from AccountLvlMOCDetails_stg 
	   WHERE filname=@FilePathUpload

	   --UPDATE DateOfWriteOff SET UploadID=1 FROM DateOfWriteOff WHERE UploadID IS NULL
END

PRINT 'START'
  ------------------------------------------------------------------------------  
    ----SELECT * FROM UploadAccountMOC
	--SrNo	Territory	ACID	InterestReversalAmount	filname
	UPDATE UploadAccountMOC
	SET  
        ErrorMessage='There is no data in excel. Kindly check and upload again' 
		,ErrorinColumn='SrNo,AsOnDate,NCIF_Id,CustomerId,SourceSystem,CustomerName,AccountID,GrossBalance,PrincipalOutstanding
		          ,UnservicedInterestAmount,Additionalprovisionpercentage,AdditionalprovisionAmount,AcceleratedprovisionPercentage'
		,Srnooferroneousrows=''
 FROM UploadAccountMOC V  
 WHERE ISNULL(SrNo,'')=''
 AND ISNULL(AsOnDate,'')=''
 AND ISNULL(SourceSystem,'')=''
 AND ISNULL(NCIF_Id,'')=''
 AND ISNULL(CustomerId,'')=''
AND ISNULL(CustomerName,'') = ''
AND ISNULL(AccountID,'')=''
AND ISNULL(GrossBalance,'')=''
AND ISNULL(PrincipalOutstanding,'')=''
AND ISNULL(UnservicedInterestAmount,'')=''
AND ISNULL(Additionalprovisionpercentage,'')=''
AND ISNULL(AdditionalprovisionAmount,'')=''
AND ISNULL(AcceleratedprovisionPercentage,'')=''
AND ISNULL(MOCReason,'')=''


  --PRINT 'START VALIDATION'
  --SELECT * FROM UploadAccountMOC
  IF EXISTS(SELECT 1 FROM UploadAccountMOC WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  END
 
  ----- COMMENTED By Satwaji As On 29/06/2021 for Temporary Purpose

 -----validations on Srno
 PRINT 'SRNO'
	 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'Sr. No. cannot be blank.  Please check the values and upload again' 
								ELSE ErrorMessage+','+SPACE(1)+ 'Sr. No. cannot be blank.  Please check the values and upload again'	END
	,ErrorinColumn='SRNO'    
	,Srnooferroneousrows=''
	FROM UploadAccountMOC V  
	WHERE ISNULL(SrNo,'')=''-- or ISNULL(SrNo,'0')='0'

UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   
--select *
 FROM UploadAccountMOC V  
 WHERE ISNULL(SrNo,'')  LIKE '%[,!@#$%^&*()_-+=/]%'

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SRNO  
  
  FROM UploadAccountMOC v
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'


  update UploadAccountMOC
  set SrNo=NULL
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'


  -------- CHECKING for DUPLICATE SRNO's
  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SRNO ORDER BY SRNO)ROW
   FROM UploadAccountMOC
   )A
   WHERE ROW>1

 PRINT 'DUB'  

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Following sr. no. are repeated' 
					ELSE ErrorMessage+','+SPACE(1)+     'Following sr. no. are repeated' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END
		,Srnooferroneousrows=SRNO
--		--STUFF((SELECT DISTINCT ','+SRNO 
--		--						FROM UploadAccountMOC
--		--						FOR XML PATH ('')
--		--						),1,1,'')
         
		
 FROM UploadAccountMOC V  
	WHERE  V.Srno IN(SELECT SRNO FROM #R )
PRINT 'DUB1'  
----------- /* Validations on AsOnDate Date

UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Can not be Blank . Please enter the AsOnDate and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Can not be Blank. Please enter the AsOnDate and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(AsOnDate,'')='' 
 PRINT 'DUB2'
 SET DATEFORMAT DMY
UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format DD/MM/YYYY'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format DD/MM/YYYY'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										  WHERE ISNULL(NPADate,'')<>'' AND (CAST(ISNULL(NPADate ,'')AS Varchar(10))<>FORMAT(cast(NPADate as date),'dd-MM-yyyy'))

		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   
 FROM UploadAccountMOC V  
 WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0
PRINT 'DUB3'

UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE ErrorinColumn +','+SPACE(1)+  'AsOnDate' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   
--select *
 FROM UploadAccountMOC V  
 WHERE ISNULL(AsOnDate,'')  LIKE '%[,!@#$%^&*()_+=\]%'

 --UPDATE UploadAccountMOC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'As On Date. Please check the values and upload again'     
	--							  ELSE ErrorMessage+','+SPACE(1)+ 'As On Date. Please check the values and upload again'      END
	--	,ErrorinColumn='As On Date'    
	--	,Srnooferroneousrows=SRNO  
  
 -- FROM UploadAccountMOC v
 -- WHERE ISNUMERIC(v.AsOnDate)=0
 
----- Future Date Comparison
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Should not be Future Date . Please enter the AsOnDate and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Should not be Future Date. Please enter the AsOnDate and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadAccountMOC V  
 --WHERE  ISNULL(AsOnDate,'')<>'' AND CONVERT(date,AsOnDate) > CONVERT(date,GETDATE())
  WHERE  (Case When ISNULL(AsOnDate,'')<>'' AND  ISDATE(AsOnDate)=1 
               Then Case When CONVERT(date,AsOnDate) > CONVERT(date,GETDATE()) 
			             Then 1 Else 0 END 
			   else 2 END)=1
PRINT 'DUB4'

------ VALIDATIONS ON ASONDate Should be equal to latest MOC Initiated which are not frozen
UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Should be equal to latest MOC Initiated which are not frozen. Please enter the Correct AsOnDate and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Should be equal to latest MOC Initiated which are not frozen. Please enter the Correct AsOnDate and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadAccountMOC V 
 WHERE  (CASE WHEN ISNULL(AsOnDate,'')<>'' AND  ISDATE(AsOnDate)=1 
               THEN CASE WHEN CONVERT(date,AsOnDate) <> CONVERT(date,(Select DATE FROm SysDataMatrix WHERE CurrentStatus_MOC='C')) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 UPDATE  UploadAccountMOC 
	SET AsOnDate=NULL 
 WHERE ISDATE(AsOnDate)=0

 PRINT 'DUB41'
 IF Exists (Select 1 from UploadAccountMOC where Isnumeric(SrNo)=1)
 Begin

 PRINT 'DUB42'
 Declare @count int
 select  @count = max(SrNo)  from UploadAccountMOC GROUP BY AsOnDate 
 IF EXISTS (SELECT 1 FROM UploadAccountMOC GROUP BY AsOnDate HAVING COUNT(*)<@count)
 BEGIN
UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'As on date should be same '     
						ELSE ErrorMessage+','+SPACE(1)+ 'As on date should be same '      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		--,Srnooferroneousrows=V.SrNo
	 
-- FROM UploadAccountMOC V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0
 END
 END
PRINT 'DUB5'

 /*validations on Source System Name*/
  
  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Source System Name cannot be blank . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Source System Name cannot be blank . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source System Name' ELSE   ErrorinColumn +','+SPACE(1)+'Source System Name' END   
		,Srnooferroneousrows=V.SrNo
								--STUFF((SELECT ','+SrNo 
								--FROM UploadBuyout A
								--WHERE A.SrNo IN(SELECT V.SrNo  FROM UploadBuyout V  
								--WHERE ISNULL(SOLID,'')='')
								--FOR XML PATH ('')
								--),1,1,'')
   
   FROM UploadAccountMOC V  
 WHERE ISNULL(SourceSystem,'')=''
 PRINT 'DUB6'
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source System Name' ELSE ErrorinColumn +','+SPACE(1)+  'Source System Name' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(SourceSystem,'') LIKE'%[,!@#$%^&*()+=/\]%'
 PRINT 'DUB8'
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Source System Name.  Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Invalid Source System Name.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source System Name' ELSE   ErrorinColumn +','+SPACE(1)+'Source System Name' END       
		,Srnooferroneousrows=V.SrNo
	--	STUFF((SELECT ','+SrNo 
	--							FROM UploadBuyout A
	--							WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
 --WHERE ISNULL(SOLID,'')<>''
 --AND  LEN(SOLID)>10)
	--							FOR XML PATH ('')
	--							),1,1,'')
   
 --  FROM UploadAccountMOC V  
 --WHERE ISNULL(SourceSystem,'')<>''
 FROM UploadAccountMOC V  
 LEFT JOIN DimSourceSystem B
 ON V.SourceSystem=B.SourceName
 AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
 WHERE ISNULL(V.SourceSystem,'')<>''
 AND B.SourceName IS NULL
-- AND V.SourceSystem NOT IN(SELECT B.SourceName FROM NPA_IntegrationDetails A
-- INNER JOIN DimSourceSystem B
-- ON A.SrcSysAlt_Key=B.SourceAlt_Key
-- AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
--								WHERE A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
--)
 --AND LEN(CustomerName)>20
 PRINT 'DUB9'


--  ---------VALIDATIONS ON Dedupe_ID-UCIC-Enterprise_CIF(NCIF_ID)
  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadAccountMOC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(NCIF_Id,'')='' 

  --------------- Logic for Invalid NCIF_ID Found --------- START ----

 Declare @CountNCIF Int,@I1 Int,@EntityKey Int
 Declare @NCIF_Id Varchar(100)=''
Declare @NCIF_Id_Found Int=0
/*
IF OBJECT_ID('TempDB..#tmpNCIF') IS NOT NULL DROP TABLE #tmpNCIF; 
  
  Select  ROW_NUMBER() OVER(ORDER BY  CONVERT(INT,EntityKey) ) RecentRownumber,EntityKey,NCIF_Id  into #tmpNCIF from UploadAccountMOC
                  
 Select @CountNCIF=Count(*) from #tmpNCIF
  
   SET @I1=1
   SET @EntityKey=0

   SET @NCIF_Id=''
     While(@I1<=@CountNCIF)
               BEGIN 
			   
			      Select @NCIF_Id =NCIF_Id,@EntityKey=EntityKey  from #tmpNCIF where RecentRownumber=@I1 
							order By EntityKey

					  Select      @NCIF_Id_Found=Count(1)
				from NPA_IntegrationDetails  A Where NCIF_Id=@NCIF_Id AND
				 EffectiveFromTimeKey=@TimeKey AND EffectiveToTimeKey=@TimeKey

				IF @NCIF_Id_Found =0
				    Begin
				 Update UploadAccountMOC
										   SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' NCIF_Id is invalid. Kindly check the entered NCIF_Id'     
											 ELSE ErrorMessage+','+SPACE(1)+' NCIF_Id is invalid. Kindly check the entered NCIF_Id'      END
											 ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE   ErrorinColumn +','+SPACE(1)+'NCIF_Id' END   
										   Where EntityKey=@EntityKey
					END
					  SET @I1=@I1+1
					  SET @NCIF_Id=''
								
								
			   END
*/

IF OBJECT_ID('TempDB..#tmpNCIF') IS NOT NULL DROP TABLE #tmpNCIF; 
  
  Select  NCIF_Id,CustomerId,CustomerACID 
  into #tmpNCIF from NPA_IntegrationDetails Where EffectiveFromTimeKey=@Timekey And EffectiveToTimeKey=@Timekey

  ---------- CREATE NONCLUSTERED INDEX ON #tmpNCIF Table for NCIF_Id Column BY SATWAJI as on 21/10/2021 to Improve Performance
  CREATE NONCLUSTERED INDEX [IX_#tmpNCIF_NPA_IntegrationDetails] ON #tmpNCIF
	(
		[NCIF_Id] ASC
	)

  Update A
										   SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' NCIF_Id is invalid. Kindly check the entered NCIF_Id'     
											 ELSE ErrorMessage+','+SPACE(1)+' NCIF_Id is invalid. Kindly check the entered NCIF_Id'      END
											 ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE   ErrorinColumn +','+SPACE(1)+'NCIF_Id' END   
										   
										   From UploadAccountMOC A
										   Where Not Exists (Select 1 from #tmpNCIF B Where A.NCIF_Id=B.NCIF_Id)


--------------- Logic for Invalid NCIF_ID Found --------- END ----

 -- UPDATE UploadAccountMOC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
	--	,Srnooferroneousrows=V.SRNO
  
	--	FROM UploadAccountMOC V  
 --WHERE ISNULL(V.NCIF_Id,'')<>''
 --AND V.NCIF_Id NOT IN(SELECT NCIF_Id FROM NPA_IntegrationDetails
	--							WHERE EffectiveFromTimeKey=@Timekey AND EffectiveToTimeKey=@Timekey
 --)

-- ----SELECT * FROM UploadAccountMOC
  

  -----COMMENTED ON 17/06/2021 NOT REQUIRED AS PER DOCUMENT 
--  UPDATE UploadAccountMOC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadAccountMOC A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadAccountMOC V  
-- WHERE ISNULL(V.NCIF_ID,'')<>''
-- AND V.NCIF_ID NOT IN(SELECT NCIF_ID FROM NPA_IntegrationDetails 
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

-- ----SELECT * FROM NPA_IntegrationDetails
   
  print 'Dedupe_ID-UCIC-Enterprise_CIF ID'
--  -------combination
--------	PRINT 'TerritoryAlt_Key'

UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are  not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(NCIF_Id,'')  LIKE'%[,!@#$%^&*()+=-_/\]%'
   
  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadAccountMOC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
--								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(NCIF_Id,'') <>'' and LEN(NCIF_Id)>16

  ------- Checking for Both NCIF_ID AND CustomerID Should Be Present 
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'The Column Dedupe_ID-UCIC-Enterprise_CIF ID is mandatory.  Kindly check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'The Column Dedupe_ID-UCIC-Enterprise_CIF ID is mandatory.  Kindly check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE (ISNULL(CustomerId,'')=''  AND ISNULL(NCIF_Id,'')='')

-- -------------------------FOR DUPLICATE ACIDS
 IF OBJECT_ID('TEMPDB..#NCIF_ID_DUP') IS NOT NULL
 DROP TABLE #NCIF_ID_DUP

 SELECT * INTO #NCIF_ID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY NCIF_Id ORDER BY  NCIF_Id)AS ROW FROM UploadAccountMOC
 )A
 WHERE ROW>1

-- UPDATE UploadAccountMOC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Dedupe_ID-UCIC-Enterprise_CIF ID are repeated.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Dedupe_ID-UCIC-Enterprise_CIF ID are repeated.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadAccountMOC A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
----								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadAccountMOC V  
-- WHERE ISNULL(NCIF_ID,'') <>'' and NCIF_ID IN(SELECT NCIF_ID FROM #NCIF_ID_DUP)

 --  ---------VALIDATIONS ON CustomerID
  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Customer ID cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Customer ID cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadAccountMOC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(CustomerId,'')='' 

   --------------- Logic for Invalid CustomerId Found --------- START ----

 Declare @CountCustID Int,@I2 Int,@EntityKeyCust Int
 Declare @CustId Varchar(100)=''
Declare @CustomerId_Found Int=0
/*
IF OBJECT_ID('TempDB..#tmpCustID') IS NOT NULL DROP TABLE #tmpCustID; 
  
  Select  ROW_NUMBER() OVER(ORDER BY  CONVERT(INT,EntityKey) ) RecentRownumber,EntityKey,CustomerId  into #tmpCustID from UploadAccountMOC
                  
 Select @CountCustID=Count(*) from #tmpCustID
  
   SET @I2=1
   SET @EntityKeyCust=0

   SET @CustId=''
     While(@I2<=@CountCustID)
               BEGIN 
			   
			      Select @CustId =CustomerId,@EntityKeyCust=EntityKey  from #tmpCustID where RecentRownumber=@I2
							order By EntityKey

					  Select      @CustomerId_Found=Count(1)
				from NPA_IntegrationDetails  A Where CustomerId=@CustId AND
				 EffectiveFromTimeKey=@TimeKey AND EffectiveToTimeKey=@TimeKey

				IF @CustomerId_Found =0
				    Begin
				 Update UploadAccountMOC
										   SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' Customer ID is invalid. Kindly check the entered CustomerID'     
											 ELSE ErrorMessage+','+SPACE(1)+' Customer Id is invalid. Kindly check the entered CustomerID'      END
											 ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer Id' ELSE   ErrorinColumn +','+SPACE(1)+'Customer Id' END   
										   Where EntityKey=@EntityKeyCust
					END
					  SET @I2=@I2+1
					  SET @CustId=''
								
								
			   END
*/

---------- CREATE NONCLUSTERED INDEX ON #tmpNCIF Table for CustomerId Column BY SATWAJI as on 21/10/2021 to Improve Performance
CREATE NONCLUSTERED INDEX [IX_#tmpCUSTID_NPA_IntegrationDetails] ON #tmpNCIF
	(
		[CustomerId] ASC
	)

Update A
										   SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' Customer ID is invalid. Kindly check the entered CustomerID'     
											 ELSE ErrorMessage+','+SPACE(1)+' Customer Id is invalid. Kindly check the entered CustomerID'      END
											 ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer Id' ELSE   ErrorinColumn +','+SPACE(1)+'Customer Id' END   
										   
										   From UploadAccountMOC A
										   Where Not Exists (Select 1 from #tmpNCIF B Where A.CustomerId=B.CustomerId)



--------------- Logic for Invalid CustomerId Found --------- END ----

 --UPDATE UploadAccountMOC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Customer ID found. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+'Invalid Customer ID found. Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
	--	,Srnooferroneousrows=V.SRNO
 
	--	FROM UploadAccountMOC V  
 --WHERE ISNULL(V.CustomerId,'')<>''
 --AND V.CustomerId NOT IN(SELECT CustomerID FROM NPA_IntegrationDetails
	--							WHERE EffectiveFromTimeKey=@Timekey AND EffectiveToTimeKey=@Timekey
 --)

UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(CustomerId,'') LIKE'%[,!@#$%^&*()+=-_/\]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Customer ID found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Customer ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadAccountMOC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
--								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(CustomerId,'') <>'' and LEN(CustomerId)>19

  ------- Checking for Both CustomerID AND NCIF_ID Should Be Present 
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Column Source_System_CIF_Customer_Identifier is mandatory. Kindly check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Column Source_System_CIF_Customer_Identifier is mandatory. Kindly check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source_System_CIF_Customer_Identifier' ELSE ErrorinColumn +','+SPACE(1)+  'Source_System_CIF_Customer_Identifier' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE (ISNULL(NCIF_Id,'')='' AND ISNULL(CustomerId,'')='')

-- -------------------------FOR DUPLICATE CustomerId's
 --IF OBJECT_ID('TEMPDB..#CUSTID_DUP') IS NOT NULL
 --DROP TABLE #CUSTID_DUP

 --SELECT * INTO #CUSTID_DUP FROM(
 --SELECT *,ROW_NUMBER() OVER(PARTITION BY CustomerId ORDER BY  CustomerId)AS ROW FROM UploadAccountMOC
 --)A
 --WHERE ROW>1

-- UPDATE UploadAccountMOC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Customer ID are repeated.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Customer ID are repeated.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadAccountMOC A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
----								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadAccountMOC V  
-- WHERE ISNULL(CustomerId,'') <>'' and CustomerId IN(SELECT CustomerId FROM #CUSTID_DUP)

--SELECT * FROM UploadAccountMOC
  
--  UPDATE UploadAccountMOC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Customer ID found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid Customer ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadAccountMOC A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadAccountMOC V  
-- WHERE ISNULL(V.CustomerID,'')<>''
--  AND V.CustomerID NOT IN(SELECT CustomerId FROM NPA_IntegrationDetails A
--                                         Inner Join UploadAccountMOC V on A.CustomerACID=V.CustomerACID
--								WHERE A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
--						 )
 --AND V.CustomerID NOT IN(SELECT CustomerID FROM [CurDat].[CustomerBasicDetail]
	--							WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
 --)

 print 'Customerid'

 -- /*validations on CustomerName*/
  
--  UPDATE UploadAccountMOC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CustomerName cannot be blank . Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'CustomerName cannot be blank . Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CustomerName' ELSE   ErrorinColumn +','+SPACE(1)+'CustomerName' END   
--		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SrNo 
--								--FROM UploadCustMOC A
--								--WHERE A.SrNo IN(SELECT V.SrNo  FROM UploadCustMOC V  
--								--WHERE ISNULL(SOLID,'')='')
--								--FOR XML PATH ('')
--								--),1,1,'')
   
--   FROM UploadAccountMOC V  
-- WHERE ISNULL(CustomerName,'')=''

--  UPDATE UploadAccountMOC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer Name' ELSE ErrorinColumn +','+SPACE(1)+  'Customer Name' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadCustMOC A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadCustMOC V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadAccountMOC V  
-- WHERE ISNULL(CustomerName,'') LIKE'%[,!@#$%^&*-_/\()+=]%'

--  ---------VALIDATIONS ON ACID
  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Account ID cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Account ID cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadAccountMOC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(AccountID,'')='' 

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account No' ELSE ErrorinColumn +','+SPACE(1)+  'Account No' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(AccountID,'') LIKE'%[,!@#$%^&*()+=-/\]%'


   
  print 'acid'

   
  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Account ID found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Account ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
		,Srnooferroneousrows=V.SRNO


 FROM UploadAccountMOC V  
 WHERE ISNULL(AccountID,'') <>'' and LEN(AccountID)>16

   --------------- Logic for Invalid AccountID Found --------- START ----

 Declare @CountAccID Int,@I3 Int,@EntityKeyACC Int
 Declare @ACCId Varchar(100)=''
Declare @AccountId_Found Int=0
/*
IF OBJECT_ID('TempDB..#tmpACCId') IS NOT NULL DROP TABLE #tmpACCId; 
  
  Select  ROW_NUMBER() OVER(ORDER BY  CONVERT(INT,EntityKey) ) RecentRownumber,EntityKey,AccountID  into #tmpACCId from UploadAccountMOC
                  
 Select @CountAccID=Count(*) from #tmpACCId
  
   SET @I3=1
   SET @EntityKeyACC=0

   SET @ACCId=''
     While(@I3<=@CountAccID)
               BEGIN 
			   
			      Select @ACCId =AccountID,@EntityKeyACC=EntityKey  from #tmpACCId where RecentRownumber=@I3
							order By EntityKey

					  Select      @AccountId_Found=Count(1)
				from NPA_IntegrationDetails  A Where CustomerACID=@ACCId AND
				 EffectiveFromTimeKey=@TimeKey AND EffectiveToTimeKey=@TimeKey

				IF @AccountId_Found =0
				    Begin
				 Update UploadAccountMOC
										   SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' Account ID is invalid. Kindly check the entered AccountID'     
											 ELSE ErrorMessage+','+SPACE(1)+' Account Id is invalid. Kindly check the entered AccountID'      END
											 ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account Id' ELSE   ErrorinColumn +','+SPACE(1)+'Account Id' END   
										   Where EntityKey=@EntityKeyACC
					END
					  SET @I3=@I3+1
					  SET @ACCId=''
								
								
			   END
*/

---------- CREATE NONCLUSTERED INDEX ON #tmpNCIF Table for CustomerACID Column BY SATWAJI as on 21/10/2021 to Improve Performance
CREATE NONCLUSTERED INDEX [IX_#tmpCUSTACID_NPA_IntegrationDetails] ON #tmpNCIF
	(
		[CustomerACID] ASC
	)

	Update A
		SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' Account ID is invalid. Kindly check the entered AccountID'     
		ELSE ErrorMessage+','+SPACE(1)+' Account Id is invalid. Kindly check the entered AccountID'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account Id' ELSE   ErrorinColumn +','+SPACE(1)+'Account Id' END   
											   
	From UploadAccountMOC A
	Where Not Exists (Select 1 from #tmpNCIF B Where A.AccountID=B.CustomerACID)





--------------- Logic for Invalid AccountID Found --------- END ----

 --  UPDATE UploadAccountMOC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Account ID found. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+'Invalid Account ID found. Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
	--	,Srnooferroneousrows=V.SRNO
  
	--	FROM UploadAccountMOC V  
 --WHERE ISNULL(V.AccountID,'')<>''
 --AND V.AccountID NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
	--							WHERE EffectiveFromTimeKey=@Timekey AND EffectiveToTimeKey=@Timekey
 --)



-- -------------------------FOR DUPLICATE ACIDS
 IF OBJECT_ID('TEMPDB..#ACID_DUP') IS NOT NULL
 DROP TABLE #ACID_DUP

 SELECT * INTO #ACID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY AccountID ORDER BY  AccountID)AS ROW FROM UploadAccountMOC
 )A
 WHERE ROW>1

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Account ID are repeated.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Account ID are repeated.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadAccountMOC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
--								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(AccountID,'') <>'' and AccountID IN(SELECT AccountID FROM #ACID_DUP)

------ -------validations on GrossBalance
 -- UPDATE UploadAccountMOC
	--SET   

 --      ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Gross Balance cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Gross Balance cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Gross Balance' ELSE ErrorinColumn +','+SPACE(1)+  'Gross Balance' END  
	--	,Srnooferroneousrows=V.SRNO
	--							----STUFF((SELECT ','+SRNO 
	--							----FROM UploadAccountMOC A
	--							----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
	--							----WHERE ISNULL(InterestReversalAmount,'')='')
	--							----FOR XML PATH ('')
	--							----),1,1,'')   

 --FROM UploadAccountMOC V  
 --WHERE (ISNULL(GrossBalance,'')='' OR GrossBalance IS NULL)

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Gross Balance Interest. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Gross Balance Interest. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Gross Balance' ELSE ErrorinColumn +','+SPACE(1)+  'Gross Balance' END  
		,Srnooferroneousrows=V.SrNo
								--STUFF((SELECT ','+SRNO 
								--FROM UploadAccountMOC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE(ISNUMERIC(GrossBalance)=0 AND ISNULL(GrossBalance,'')<>'') OR 
 ISNUMERIC(GrossBalance) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

   update UploadAccountMOC
  set GrossBalance=NULL
  WHERE (ISNUMERIC(GrossBalance)=0 AND ISNULL(GrossBalance,'')<>'') OR  ISNUMERIC(GrossBalance) LIKE '%^[0-9]%'

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Gross Balance' ELSE ErrorinColumn +','+SPACE(1)+  'Gross Balance' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(GrossBalance,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Gross Balance Interest. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Gross Balance Interest. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Gross Balance' ELSE ErrorinColumn +','+SPACE(1)+  'Gross Balance' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(GrossBalance,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(GrossBalance,0)) <0

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Gross Balance Interest. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Gross Balance Interest. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Gross Balance' ELSE ErrorinColumn +','+SPACE(1)+  'Gross Balance' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE  (CASE WHEN ISNULL(GrossBalance,'')<>'' AND  ISNUMERIC(GrossBalance)=1 
               THEN CASE WHEN CHARINDEX('.',GrossBalance) <> 0 AND CHARINDEX('.',GrossBalance)-1 > 14 THEN 1
						  WHEN CHARINDEX('.',GrossBalance) = 0 AND LEN(GrossBalance)>16
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

--WHERE ISNULL(GrossBalance,'')<>''
 ----AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 --AND TRY_CONVERT(DECIMAL(18,2),ISNULL(GrossBalance,0)) <0



 ------ -------validations on PrincipalOutstanding

 -- UPDATE UploadAccountMOC
	--SET   

 --      ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Principal Outstanding cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Principal Outstanding cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Outstanding' END  
	--	,Srnooferroneousrows=V.SRNO
	--							----STUFF((SELECT ','+SRNO 
	--							----FROM UploadAccountMOC A
	--							----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
	--							----WHERE ISNULL(InterestReversalAmount,'')='')
	--							----FOR XML PATH ('')
	--							----),1,1,'')   

 --FROM UploadAccountMOC V  
 --WHERE (ISNULL(PrincipalOutstanding,'')='' OR PrincipalOutstanding IS NULL)

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Principal Outstanding. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Principal Outstanding. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Outstanding' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadAccountMOC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE (ISNUMERIC(PrincipalOutstanding)=0 AND ISNULL(PrincipalOutstanding,'')<>'') OR 
 ISNUMERIC(PrincipalOutstanding) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

    update UploadAccountMOC
  set PrincipalOutstanding=NULL
  WHERE (ISNUMERIC(PrincipalOutstanding)=0 AND ISNULL(PrincipalOutstanding,'')<>'') OR  ISNUMERIC(PrincipalOutstanding) LIKE '%^[0-9]%'

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Outstanding' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(PrincipalOutstanding,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Principal Outstanding. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Principal Outstanding. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Outstanding' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(PrincipalOutstanding,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(PrincipalOutstanding,0)) <0

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Principal Outstanding. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Principal Outstanding. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Outstanding' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE  (CASE WHEN ISNULL(PrincipalOutstanding,'')<>'' AND  ISNUMERIC(PrincipalOutstanding)=1 
               THEN CASE WHEN CHARINDEX('.',PrincipalOutstanding) <> 0 AND CHARINDEX('.',PrincipalOutstanding)-1 > 14 THEN 1
						  WHEN CHARINDEX('.',PrincipalOutstanding) = 0 AND LEN(PrincipalOutstanding)>16 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ------ -------validations on Unserviced Interest Amount

 -- UPDATE UploadAccountMOC
	--SET   

 --      ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Unserviced Interest Amount cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Unserviced Interest Amount cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Unserviced Interest Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Unserviced Interest Amount' END  
	--	,Srnooferroneousrows=V.SRNO
	--							----STUFF((SELECT ','+SRNO 
	--							----FROM UploadAccountMOC A
	--							----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
	--							----WHERE ISNULL(InterestReversalAmount,'')='')
	--							----FOR XML PATH ('')
	--							----),1,1,'')   

 --FROM UploadAccountMOC V  
 --WHERE (ISNULL(UnservicedInterestAmount,'')='' OR UnservicedInterestAmount IS NULL)

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Unserviced Interest Amount. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Unserviced Interest Amount. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Unserviced Interest Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Unserviced Interest Amount' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadAccountMOC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE (ISNUMERIC(UnservicedInterestAmount)=0 AND ISNULL(UnservicedInterestAmount,'')<>'') OR 
 ISNUMERIC(UnservicedInterestAmount) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

     update UploadAccountMOC
  set UnservicedInterestAmount=NULL
  WHERE (ISNUMERIC(UnservicedInterestAmount)=0 AND ISNULL(UnservicedInterestAmount,'')<>'') OR  ISNUMERIC(UnservicedInterestAmount) LIKE '%^[0-9]%'

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnservicedInterestAmount' ELSE ErrorinColumn +','+SPACE(1)+  'UnservicedInterestAmount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(UnservicedInterestAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Unserviced Interest Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Unserviced Interest Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Unserviced Interest Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Unserviced Interest Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(UnservicedInterestAmount,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(UnservicedInterestAmount,0)) <0

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Unserviced Interest Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Unserviced Interest Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Unserviced Interest Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Unserviced Interest Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE  (CASE WHEN ISNULL(UnservicedInterestAmount,'')<>'' AND  ISNUMERIC(UnservicedInterestAmount)=1 
               THEN CASE WHEN CHARINDEX('.',UnservicedInterestAmount) <> 0 AND CHARINDEX('.',UnservicedInterestAmount)-1 > 14 THEN 1
						  WHEN CHARINDEX('.',UnservicedInterestAmount) = 0 AND LEN(UnservicedInterestAmount)>16 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

  ------ -------validations on Additional provision percentage

 -- UPDATE UploadAccountMOC
	--SET   

 --      ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Additionalprovisionpercentage cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Additionalprovisionpercentage cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additionalprovisionpercentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additionalprovisionpercentage' END  
	--	,Srnooferroneousrows=V.SRNO
								  

 --FROM UploadAccountMOC V  
 --WHERE (ISNULL(Additionalprovisionpercentage,'')='' OR Additionalprovisionpercentage IS NULL)

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Additionalprovisionpercentage. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Additionalprovisionpercentage. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additionalprovisionpercentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additionalprovisionpercentage' END  
		,Srnooferroneousrows=V.SRNO
								

 FROM UploadAccountMOC V  
 WHERE (ISNUMERIC(Additionalprovisionpercentage)=0 AND ISNULL(Additionalprovisionpercentage,'')<>'') OR 
 ISNUMERIC(Additionalprovisionpercentage) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additionalprovisionpercentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additionalprovisionpercentage' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadAccountMOC V  
 WHERE ISNULL(Additionalprovisionpercentage,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Additionalprovisionpercentage. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Additionalprovisionpercentage. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additionalprovisionpercentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additional provisionpercentage' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadAccountMOC V  
 WHERE ISNULL(Additionalprovisionpercentage,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(Additionalprovisionpercentage,0)) <0

   UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Additional Provision should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Additional Provision should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additionalprovisionpercentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additional provisionpercentage' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadAccountMOC V  
 WHERE ISNULL(Additionalprovisionpercentage,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 --AND cast(ISNULL(Additionalprovisionpercentage,0.00) as decimal) >100
 AND TRY_CONVERT(Decimal(6,2),ISNULL(Additionalprovisionpercentage,0))>100

----------------------------------- Additional provision Percentage  Account/Customer Validation
--select * From UploadAccountMOC

Declare @Count1 Int,@I Int,@srNo Int
   Declare @AccountID Varchar(100)=''
    Declare @AdditionalProvisionPercentage Decimal(6,2)=0
   Declare @AdditionalProvisionPercentageSum Decimal(6,2)=0

    Declare @AdditionalProvisionAmountSum Decimal(16,2)=0

   SET @Count1=0
   /*
 IF OBJECT_ID('TempDB..#tmp') IS NOT NULL DROP TABLE #tmp; 
  
  Select  ROW_NUMBER() OVER(ORDER BY  CONVERT(INT,SrNo) ) RecentRownumber,SrNo,AccountID,Additionalprovisionpercentage  into #tmp from UploadAccountMOC
                  
 Select @Count1=Count(*) from #tmp
  
   SET @I=1
   SET @srNo=0
 
   SET @AccountID=''
     While(@I<=@Count1)
               BEGIN 
			     Select @AccountID =AccountID,@srNo=SrNo,
				  @AdditionalProvisionPercentage=Case when ISNULL(AdditionalProvisionPercentage,'') = '' then 0 else CAST(AdditionalProvisionPercentage AS DECIMAL(6,2)) END  from #tmp where RecentRownumber=@I 
							order By SrNo
           IF @AdditionalProvisionPercentage<>0
		     BEGIN
					  Select      @AdditionalProvisionPercentageSum=SUM(ISNULL(AddlProvisionPer,0))
					               ,@AdditionalProvisionAmountSum= SUM(ISNULL(AddlProvision,0)) 
				                           from NPA_IntegrationDetails  A Where Customeracid=@AccountID
										   and EffectiveFromTimeKey=@Timekey and EffectiveToTimeKey=@Timekey
				IF @AdditionalProvisionPercentageSum >0
				    Begin
						Update UploadAccountMOC
						 SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' AddlProvisionPer already exist through Customer MOC.'     
											 ELSE ErrorMessage+','+SPACE(1)+' AddlProvisionPer already exist through Customer MOC.'      END
								,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AddlProvisionPer' ELSE   ErrorinColumn +','+SPACE(1)+'AddlProvisionPer' END   
										      Where SrNo=@srNo
					END

					IF (@AdditionalProvisionPercentageSum >0 AND @AdditionalProvisionAmountSum>0)
				    Begin
						 Update UploadAccountMOC
								 SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' AddlProvisionPer And AdditionalProvisionAmount , both column can not have  value simaltanously . Please check and Upload again.'     
													 ELSE ErrorMessage+','+SPACE(1)+' AddlProvisionPer And AdditionalProvisionAmount , both column can not have  value simaltanously . Please check and Upload again.'      END
										,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AddlProvisionPer/Amount' ELSE   ErrorinColumn +','+SPACE(1)+'AddlProvisionPer/Amount' END   
													  Where SrNo=@srNo
					END
            END

					  SET @I=@I+1
					  SET @AccountID=''
								

								
			   END
*/

--Select * 
			Update a
						 SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' AddlProvisionPer already exist through Customer MOC.'     
											 ELSE ErrorMessage+','+SPACE(1)+' AddlProvisionPer already exist through Customer MOC.'      END
								,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AddlProvisionPer' ELSE   ErrorinColumn +','+SPACE(1)+'AddlProvisionPer' END   
				From UploadAccountMOC a
			Inner Join NPA_IntegrationDetails B ON A.AccountID=B.CustomerACID
			And A.NCIF_Id=B.NCIF_Id And A.CustomerId=B.CustomerId
			Where B.EffectiveFromTimeKey=@Timekey and B.EffectiveToTimeKey=@timekey
			AND ISNULL(B.AddlProvisionPer,0)>0
			AND (Case when ISNULL(a.Additionalprovisionpercentage,'') = '' 
				 then 0 else CAST(a.Additionalprovisionpercentage AS DECIMAL(6,2)) END) > 0

			
			--Select *
			Update a
								 SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' AddlProvisionPer And AdditionalProvisionAmount , both column can not have  value simaltanously . Please check and Upload again.'     
													 ELSE ErrorMessage+','+SPACE(1)+' AddlProvisionPer And AdditionalProvisionAmount , both column can not have  value simaltanously . Please check and Upload again.'      END
										,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AddlProvisionPer/Amount' ELSE   ErrorinColumn +','+SPACE(1)+'AddlProvisionPer/Amount' END   
						
			from UploadAccountMOC a
			Inner Join NPA_IntegrationDetails B ON A.AccountID=B.CustomerACID
			And A.NCIF_Id=B.NCIF_Id And A.CustomerId=B.CustomerId
			Where B.EffectiveFromTimeKey=@Timekey and B.EffectiveToTimeKey=@timekey
			ANd ISNULL(AddlProvision,0)>0 ANd ISNULL(AddlProvisionPer,0)>0


--------------------------------------------------------------------------------------------------------------------------



  ------ -------validations on AdditionalprovisionAmount

 -- UPDATE UploadAccountMOC
	--SET   

 --      ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AdditionalprovisionAmount cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'AdditionalprovisionAmount cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AdditionalprovisionAmount' ELSE ErrorinColumn +','+SPACE(1)+  'AdditionalprovisionAmount' END  
	--	,Srnooferroneousrows=V.SRNO
								

 --FROM UploadAccountMOC V  
 --WHERE (ISNULL(AdditionalprovisionAmount,'')='' OR AdditionalprovisionAmount IS NULL)

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid AdditionalprovisionAmount. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid AdditionalprovisionAmount. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AdditionalprovisionAmount' ELSE ErrorinColumn +','+SPACE(1)+  'AdditionalprovisionAmount' END  
		,Srnooferroneousrows=V.SRNO
								   

 FROM UploadAccountMOC V  
 WHERE (ISNUMERIC(AdditionalprovisionAmount)=0 AND ISNULL(AdditionalprovisionAmount,'')<>'') OR 
 ISNUMERIC(AdditionalprovisionAmount) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

  update UploadAccountMOC
  set AdditionalprovisionAmount=NULL
  WHERE (ISNUMERIC(AdditionalprovisionAmount)=0 AND ISNULL(AdditionalprovisionAmount,'')<>'') OR  ISNUMERIC(AdditionalprovisionAmount) LIKE '%^[0-9]%'

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AdditionalprovisionAmount' ELSE ErrorinColumn +','+SPACE(1)+  'AdditionalprovisionAmount' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadAccountMOC V  
 WHERE ISNULL(AdditionalprovisionAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid AdditionalprovisionAmount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid AdditionalprovisionAmount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AdditionalprovisionAmount' ELSE ErrorinColumn +','+SPACE(1)+  'AdditionalprovisionAmount' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadAccountMOC V  
 WHERE ISNULL(AdditionalprovisionAmount,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(AdditionalprovisionAmount,0)) <0

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid AdditionalprovisionAmount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid AdditionalprovisionAmount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AdditionalprovisionAmount' ELSE ErrorinColumn +','+SPACE(1)+  'AdditionalprovisionAmount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE  (CASE WHEN ISNULL(AdditionalprovisionAmount,'')<>'' AND  ISNUMERIC(AdditionalprovisionAmount)=1 
               THEN CASE WHEN CHARINDEX('.',AdditionalprovisionAmount) <> 0 AND CHARINDEX('.',AdditionalprovisionAmount)-1 > 14 THEN 1
						  WHEN CHARINDEX('.',AdditionalprovisionAmount) = 0 AND LEN(AdditionalprovisionAmount)>16 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ------- Checking for Both Additional Provision Percentage AND Additional Provision Amount Should not Be Present 
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'For an Account Additional Provision Percentage and Additional Provision Amount both can’t be accepted, Please provide correct data'     
					ELSE ErrorMessage+','+SPACE(1)+'For an Account Additional Provision Percentage and Additional Provision Amount both can’t be accepted, Please provide correct data'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AdditionalprovisionAmount' ELSE ErrorinColumn +','+SPACE(1)+  'AdditionalprovisionAmount' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE (ISNULL(Additionalprovisionpercentage,'') <> '' AND ISNULL(AdditionalprovisionAmount,'') <> '')

  ------ -------validations on AcceleratedprovisionPercentage

 -- UPDATE UploadAccountMOC
	--SET   

 --      ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AcceleratedprovisionPercentage cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'AcceleratedprovisionPercentage cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AcceleratedprovisionPercentage' ELSE ErrorinColumn +','+SPACE(1)+  'AcceleratedprovisionPercentage' END  
	--	,Srnooferroneousrows=V.SRNO
								
 --FROM UploadAccountMOC V  
 --WHERE (ISNULL(AcceleratedprovisionPercentage,'')='' OR AcceleratedprovisionPercentage IS NULL)

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Accelerated Provision Precentage. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Accelerated Provision Precentage. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AcceleratedprovisionPercentage' ELSE ErrorinColumn +','+SPACE(1)+  'AcceleratedprovisionPercentage' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadAccountMOC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE (ISNUMERIC(AcceleratedprovisionPercentage)=0 AND ISNULL(AcceleratedprovisionPercentage,'')<>'') OR 
 ISNUMERIC(AcceleratedprovisionPercentage) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AcceleratedprovisionPercentage' ELSE ErrorinColumn +','+SPACE(1)+  'AcceleratedprovisionPercentage' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(AcceleratedprovisionPercentage,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Accelerated Provision Precentage. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Accelerated Provision Precentage. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AcceleratedprovisionPercentage' ELSE ErrorinColumn +','+SPACE(1)+  'AcceleratedprovisionPercentage' END  
		,Srnooferroneousrows=V.SRNO
								 

 FROM UploadAccountMOC V  
 WHERE ISNULL(AcceleratedprovisionPercentage,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(16,2),ISNULL(AcceleratedprovisionPercentage,0)) <0

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Accelerated Provision Precentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Accelerated Provision Precentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AcceleratedprovisionPercentage' ELSE ErrorinColumn +','+SPACE(1)+  'AcceleratedprovisionPercentage' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadAccountMOC V  
 WHERE ISNULL(AcceleratedprovisionPercentage,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 --AND cast(ISNULL(Additionalprovisionpercentage,0.00) as decimal) >100
 AND TRY_CONVERT(Decimal(16,2),ISNULL(AcceleratedprovisionPercentage,0))>100
 
   ------ -------validations on SecurityValue

 -- UPDATE UploadAccountMOC
	--SET   

 --      ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'SecurityValue cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'SecurityValue cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityValue' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityValue' END  
	--	,Srnooferroneousrows=V.SRNO
								
 --FROM UploadAccountMOC V  
 --WHERE (ISNULL(SecurityValue,'')='' OR SecurityValue IS NULL)

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid SecurityValue. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid SecurityValue. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityValue' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityValue' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadAccountMOC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE (ISNUMERIC(SecurityValue)=0 AND ISNULL(SecurityValue,'')<>'') OR 
 ISNUMERIC(SecurityValue) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

   update UploadAccountMOC
  set SecurityValue=NULL
  WHERE (ISNUMERIC(SecurityValue)=0 AND ISNULL(SecurityValue,'')<>'') OR  ISNUMERIC(SecurityValue) LIKE '%^[0-9]%'

 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityValue' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityValue' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadAccountMOC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(SecurityValue,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid SecurityValue. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid SecurityValue. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityValue' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityValue' END  
		,Srnooferroneousrows=V.SRNO
								 

 FROM UploadAccountMOC V  
 WHERE ISNULL(SecurityValue,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(SecurityValue,0)) <0

   UPDATE UploadAccountMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Security Value. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Security Value. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Security Value' ELSE ErrorinColumn +','+SPACE(1)+  'Security Value' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE  (CASE WHEN ISNULL(SecurityValue,'')<>'' AND  ISNUMERIC(SecurityValue)=1 
               THEN CASE WHEN CHARINDEX('.',SecurityValue) <> 0 AND CHARINDEX('.',SecurityValue)-1 > 20 THEN 1
						  WHEN CHARINDEX('.',SecurityValue) = 0 AND LEN(SecurityValue)>22 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ------------------------------------------ MOCReason validation
 ----------------------------------------------
  
  UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MOCReason cannot be blank . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'MOCReason cannot be blank . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOCReason' ELSE   ErrorinColumn +','+SPACE(1)+'MOCReason' END   
		,Srnooferroneousrows=V.SrNo
								--STUFF((SELECT ','+SrNo 
								--FROM UploadBuyout A
								--WHERE A.SrNo IN(SELECT V.SrNo  FROM UploadBuyout V  
								--WHERE ISNULL(SOLID,'')='')
								--FOR XML PATH ('')
								--),1,1,'')
   
   FROM UploadAccountMOC V  
 WHERE ISNULL(MOCReason,'')=''
 PRINT 'DUB6'
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOCReason' ELSE ErrorinColumn +','+SPACE(1)+  'MOCReason' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadAccountMOC V  
 WHERE ISNULL(MOCReason,'') LIKE'%[,!@#$%^&*()+=/\]%'
 PRINT 'DUB8'
 UPDATE UploadAccountMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid MOCReason.  Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Invalid MOCReason.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOCReason' ELSE   ErrorinColumn +','+SPACE(1)+'MOCReason' END       
		,Srnooferroneousrows=V.SrNo
	--	STUFF((SELECT ','+SrNo 
	--							FROM UploadBuyout A
	--							WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
 --WHERE ISNULL(SOLID,'')<>''
 --AND  LEN(SOLID)>10)
	--							FOR XML PATH ('')
	--							),1,1,'')
   
 --  select * FROM UploadAccountMOC V  
 --WHERE ISNULL(SourceSystem,'')<>''
 --select * from DimMocReason
 FROM UploadAccountMOC V  
 LEFT JOIN DimMocReason B
 ON V.MOCReason=B.MocReasonName
 AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
 WHERE ISNULL(V.MOCReason,'')<>''
 AND B.MocReasonName IS NULL
-- AND V.SourceSystem NOT IN(SELECT B.SourceName FROM NPA_IntegrationDetails A
-- INNER JOIN DimSourceSystem B
-- ON A.SrcSysAlt_Key=B.SourceAlt_Key
-- AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
--								WHERE A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
--)
 --AND LEN(CustomerName)>20


 --END



 
 goto valid

  END
	
   ErrorData:  
   print 'no'  

		SELECT *,'Data'TableName
		FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		return

   valid:
		IF NOT EXISTS(Select 1 from  AccountLvlMOCDetails_stg WHERE filname=@FilePathUpload)
		BEGIN
		PRINT 'NO ERRORS'
			
			Insert into dbo.MasterUploadData
			(SR_No,ColumnName,ErrorData,ErrorType,FileNames,Flag) 
			SELECT '' SRNO , '' ColumnName,'' ErrorData,'' ErrorType,@filepath,'SUCCESS' 
			
		END
		ELSE
		BEGIN
			PRINT 'VALIDATION ERRORS'
			Insert into dbo.MasterUploadData
			(SR_No,ColumnName,ErrorData,ErrorType,FileNames,Srnooferroneousrows,Flag) 
			SELECT SrNo,ErrorinColumn,ErrorMessage,ErrorinColumn,@filepath,Srnooferroneousrows,'SUCCESS' 
			FROM UploadAccountMOC 


			
		--	----SELECT * FROM UploadAccountMOC 

		--	--ORDER BY ErrorMessage,UploadAccountMOC.ErrorinColumn DESC
			goto final
		END

		

  IF EXISTS (SELECT 1 FROM  dbo.MasterUploadData   WHERE FileNames=@filepath AND  ISNULL(ERRORDATA,'')<>'') 
   -- added for delete Upload status while error while uploading data.  
   BEGIN  
   --SELECT * FROM #OAOLdbo.MasterUploadData
    delete from UploadStatus where FileNames=@filepath  
   END  
  --ELSE IF EXISTS (SELECT 1 FROM  UploadStatus where ISNULL(InsertionOfData,'')='' and FileNames=@filepath and UploadedBy=@UserLoginId)  -- added validated condition successfully, delete filename from Upload status  
  --  BEGIN  
  --  print 'RC'  
  --   delete from UploadStatus where FileNames=@filepath  
  --  END    --commented in [OAProvision].[GetStatusOfUpload] SP for checkin 'InsertionOfData' Flag  
  ELSE  
   BEGIN   
  
    Update UploadStatus Set ValidationOfData='Y',ValidationOfDataCompletedOn=GetDate()   
    where FileNames=@filepath  
  
   END  


  final:
IF EXISTS(SELECT 1 FROM dbo.MasterUploadData WHERE FileNames=@filepath AND ISNULL(ERRORDATA,'')<>''
		) 
	BEGIN
	PRINT 'ERROR'
		SELECT SR_No
				,ColumnName
				,ErrorData
				,ErrorType
				,FileNames
				,Flag
				,Srnooferroneousrows,'Validation'TableName
		FROM dbo.MasterUploadData
		WHERE FileNames=@filepath
		--(SELECT *,ROW_NUMBER() OVER(PARTITION BY ColumnName,ErrorData,ErrorType,FileNames ORDER BY ColumnName,ErrorData,ErrorType,FileNames )AS ROW 
		--FROM  dbo.MasterUploadData    )a 
		--WHERE A.ROW=1
		--AND FileNames=@filepath
		--AND ISNULL(ERRORDATA,'')<>''
	
		--ORDER BY SR_No 

		 IF EXISTS(SELECT 1 FROM AccountLvlMOCDetails_stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM AccountLvlMOCDetails_stg
		 WHERE filname=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.AccountLvlMOCDetails_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

	END
	ELSE
	BEGIN
	PRINT ' DATA NOT PRESENT'
	PRINT '@filepath'
	PRINT  @filepath
		--SELECT *,'Data'TableName
		--FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		--ORDER BY ErrorData DESC
		SELECT SR_No,ColumnName,ErrorData,ErrorType,FileNames,Flag,Srnooferroneousrows,'Data'TableName 
		FROM
		(
			SELECT *,ROW_NUMBER() OVER(PARTITION BY ColumnName,ErrorData,ErrorType,FileNames,Flag,Srnooferroneousrows
			ORDER BY ColumnName,ErrorData,ErrorType,FileNames,Flag,Srnooferroneousrows)AS ROW 
			FROM  dbo.MasterUploadData    
		)a 
		WHERE A.ROW=1
		AND FileNames=@filepath

	END

	----SELECT * FROM UploadAccountMOC

	print 'p'
  ------to delete file if it has errors
		--if exists(Select  1 from dbo.MasterUploadData where FileNames=@filepath and ISNULL(ErrorData,'')<>'')
		--begin
		--print 'ppp'
		-- IF EXISTS(SELECT 1 FROM IBPCPoolDetail_stg WHERE filname=@FilePathUpload)
		-- BEGIN
		-- print '123'
		-- DELETE FROM IBPCPoolDetail_stg
		-- WHERE filname=@FilePathUpload

		-- PRINT 'ROWS DELETED FROM DBO.IBPCPoolDetail_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		-- END

		-- ELSE IF EXISTS(SELECT 1 FROM [AxisIntReversalDB].IntAccruedData_stg WHERE filname=@FilePathUpload)
		-- BEGIN
		-- DELETE FROM [AxisIntReversalDB].IntAccruedData_stg
		-- WHERE filname=@FilePathUpload

		-- PRINT 'ROWS DELETED FROM DBO.[AxisIntReversalDB].IntAccruedData_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		-- END

		-- ELSE IF EXISTS(SELECT 1 FROM [AxisIntReversalDB].AddNewAccountData_stg WHERE filname=@FilePathUpload)
		-- BEGIN
		-- DELETE FROM [AxisIntReversalDB].AddNewAccountData_stg
		-- WHERE filname=@FilePathUpload

		-- PRINT 'ROWS DELETED FROM DBO.[AxisIntReversalDB].AddNewAccountData_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		-- END
		-- end

   END  TRY
  
  BEGIN CATCH
	PRINT 'BEGIN CATCH'

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()

	--IF EXISTS(SELECT 1 FROM AccountLvlMOCDetails_stg WHERE filname=@FilePathUpload)
	--	 BEGIN
	--	 --DELETE FROM AccountLvlMOCDetails_stg
	--	 --WHERE filname=@FilePathUpload

		 

	--	 PRINT 'ROWS DELETED FROM DBO.AccountLvlMOCDetails_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
	--	 END

  END CATCH

END
 
GO