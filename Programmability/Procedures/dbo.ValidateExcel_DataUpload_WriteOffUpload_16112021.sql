SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ValidateExcel_DataUpload_WriteOffUpload_16112021] 
@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='FNASUPERADMIN',  
@Timekey INT=49999
,@filepath VARCHAR(MAX) ='SaletoARC.xlsx'  
WITH RECOMPILE  
AS  
  --@MenuID=N'96',@UserLoginId=N'12checker',@Timekey=N'24927',@filepath=N'Writeoff_Incremental_Upload.xlsx'
  

--DECLARE  
--@MenuID INT=96,  
--@UserLoginId varchar(20)='22checker',  
--@Timekey int=24927
--,@filepath varchar(500)='Writeoff_Incremental_Upload.xlsx'  
  
BEGIN

BEGIN TRY  
----BEGIN TRAN  
  
--Declare @TimeKey int  
    --Update UploadStatus Set ValidationOfData='N' where FileNames=@filepath  
     
	 SET DATEFORMAT DMY

 --Select @Timekey=Max(Timekey) from dbo.SysProcessingCycle  
 -- where  ProcessType='Quarterly' ----and PreMOC_CycleFrozenDate IS NULL

 Select   @Timekey=Max(Timekey) from sysDayMatrix where Cast(date as Date)=cast(getdate() as Date)

  PRINT @Timekey  
  
 --  DECLARE @DepartmentId SMALLINT ,@DepartmentCode varchar(100)  
 --SELECT  @DepartmentId= DepartmentId FROM dbo.DimUserInfo   
 --WHERE EffectiveFromTimeKey <= @Timekey AND EffectiveToTimeKey >= @Timekey  
 --AND UserLoginID = @UserLoginId  
 --PRINT @DepartmentId  
 --PRINT @DepartmentCode  
  
    
  
 --SELECT @DepartmentCode=DepartmentCode FROM AxisIntReversalDB.DimDepartment   
 --    WHERE EffectiveFromTimeKey <= @Timekey AND EffectiveToTimeKey >= @Timekey   
 --    --AND DepartmentCode IN ('BBOG','FNA')  
 --    AND DepartmentAlt_Key = @DepartmentId  
  
 --    print @DepartmentCode  
     --Select @DepartmentCode=REPLACE('',@DepartmentCode,'_')  
     
       
  
   
  
  DECLARE @FilePathUpload	VARCHAR(100)

			SET @FilePathUpload=@UserLoginId+'_'+@filepath
	PRINT '@FilePathUpload'
	PRINT @FilePathUpload

	IF EXISTS(SELECT 1 FROM dbo.MasterUploadData    where FileNames=@filepath )
	BEGIN
		Delete from dbo.MasterUploadData    where FileNames=@filepath  
		print @@rowcount
	END


IF (@MenuID=96)	
BEGIN


	  -- IF OBJECT_ID('tempdb..UploadWriteOff') IS NOT NULL  
	  --BEGIN  
	  -- DROP TABLE UploadWriteOff  
	
	  --END
	  --drop table if exists  UploadWriteOff 
	   IF OBJECT_ID('UploadWriteOff') IS NOT NULL  
		  BEGIN
	    
			DROP TABLE  UploadWriteOff

		  END

		  print @FilePathUpload

	   
  IF NOT (EXISTS (SELECT * FROM WriteOffUpload_Stg where filname=@FilePathUpload))

BEGIN
print 'NO DATA1'
			Insert into dbo.MasterUploadData
			(SR_No,ColumnName,ErrorData,ErrorType,FileNames,Flag) 
			SELECT 0 SRNO , '' ColumnName,'No Record found' ErrorData,'No Record found' ErrorType,@filepath,'SUCCESS' 
			--SELECT 0 SRNO , '' ColumnName,'' ErrorData,'' ErrorType,@filepath,'SUCCESS' 

			goto errordata
    
END



ELSE
BEGIN
PRINT 'DATA PRESENT'
	   Select *,CAST('' AS varchar(MAX)) ErrorMessage,CAST('' AS varchar(MAX)) ErrorinColumn,CAST('' AS varchar(MAX)) Srnooferroneousrows
 	   into UploadWriteOff 
	   from WriteOffUpload_Stg 
	   WHERE filname=@FilePathUpload

	   UPDATE DateOfWriteOff SET UploadID=1 FROM DateOfWriteOff WHERE UploadID IS NULL
END


PRINT 'START'
  ------------------------------------------------------------------------------  
    ----SELECT * FROM UploadWriteOff
	--SrNo	Territory	ACID	InterestReversalAmount	filname
	UPDATE UploadWriteOff
	SET  
        ErrorMessage='There is no data in excel. Kindly check and upload again' 
		,ErrorinColumn='SrNo,AsOnDate,SourceSystem,NCIF_Id,CustomerID,CustomerAcID,WriteOffDate,WriteOffType,WriteOffAmtPrincipal,WriteOffAmtInterest,Action'
		,Srnooferroneousrows=''
 FROM UploadWriteOff V  
 WHERE ISNULL(SrNo,'')=''
 AND ISNULL(AsOnDate,'')=''
 AND ISNULL(SourceSystem,'')=''
AND ISNULL(NCIF_Id,'')=''
AND ISNULL(CustomerID,'')=''
AND ISNULL(CustomerAcID,'')=''
AND ISNULL(WriteOffDate,'')=''
AND ISNULL(WriteOffType,'')=''
AND ISNULL(WriteOffAmtPrincipal,'')=''
AND ISNULL(WriteOffAmtInterest,'')=''
AND ISNULL(Action,'')=''



  --PRINT 'START VALIDATION'
  --SELECT * FROM UploadWriteOff
  IF EXISTS(SELECT 1 FROM UploadWriteOff WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  END
 
  
 -----validations on Srno
 PRINT 'SRNO'
	 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'Sr. No. cannot be blank.  Please check the values and upload again' 
								ELSE ErrorMessage+','+SPACE(1)+ 'Sr. No. cannot be blank.  Please check the values and upload again'	END
	,ErrorinColumn='SRNO'    
	,Srnooferroneousrows=''
	FROM UploadWriteOff V  
	WHERE ISNULL(SrNo,'')=''-- or ISNULL(SrNo,'0')='0'

UPDATE UploadWriteOff
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
 FROM UploadWriteOff V  
 WHERE ISNULL(SrNo,'')  LIKE '%[,!@#$%^&*()_-+=/]%'

 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SRNO  
  
  FROM UploadWriteOff v
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

  update UploadWriteOff
  set SrNo=NULL
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

  -------- CHECKING for DUPLICATE SRNO's
  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SRNO ORDER BY SRNO)ROW
   FROM UploadWriteOff
   )A
   WHERE ROW>1

 PRINT 'DUB'  


  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Following sr. no. are repeated' 
					ELSE ErrorMessage+','+SPACE(1)+     'Following sr. no. are repeated' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END
		,Srnooferroneousrows=SRNO
--		--STUFF((SELECT DISTINCT ','+SRNO 
--		--						FROM UploadWriteOff
--		--						FOR XML PATH ('')
--		--						),1,1,'')
         
		
 FROM UploadWriteOff V  
	WHERE  V.Srno IN(SELECT SRNO FROM #R )
PRINT 'DUB1'  
----------- /* Validations on AsOnDate Date
UPDATE UploadWriteOff
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

 FROM UploadWriteOff V  
 WHERE ISNULL(AsOnDate,'')='' 
 PRINT 'DUB2'

 SET DATEFORMAT DMY
UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										  WHERE ISNULL(NPADate,'')<>'' AND (CAST(ISNULL(NPADate ,'')AS Varchar(10))<>FORMAT(cast(NPADate as date),'dd-MM-yyyy'))

		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   
 FROM UploadWriteOff V  
 WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0
PRINT 'DUB3'
 --UPDATE UploadWriteOff
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'As On Date. Please check the values and upload again'     
	--							  ELSE ErrorMessage+','+SPACE(1)+ 'As On Date. Please check the values and upload again'      END
	--	,ErrorinColumn='As On Date'    
	--	,Srnooferroneousrows=SRNO  
  
 -- FROM UploadWriteOff v
 -- WHERE ISNUMERIC(v.AsOnDate)=0
 
----- Future Date Comparison
 UPDATE UploadWriteOff
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

 FROM UploadWriteOff V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND  CONVERT(date,AsOnDate,103) > CONVERT(date,GETDATE(),103)
 WHERE  (CASE WHEN ISNULL(AsOnDate,'')<>'' AND  ISDATE(AsOnDate)=1 
               THEN CASE WHEN CONVERT(date,AsOnDate) > CONVERT(date,GETDATE()) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

UPDATE UploadWriteOff
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
 FROM UploadWriteOff V  
 WHERE ISNULL(AsOnDate,'')  LIKE '%[,!@#$%^&*()_+=\]%'

 PRINT 'DUB4'
 UPDATE  UploadWriteOff 
	SET AsOnDate=NULL 
 WHERE ISDATE(AsOnDate)=0

 PRINT 'DUB41'
 IF Exists (Select 1 from UploadWriteOff where Isnumeric(SrNo)=1)
 Begin

 PRINT 'DUB42'
 Declare @count int
 select  @count = max(SrNo)  from UploadWriteOff GROUP BY AsOnDate 
 IF EXISTS (SELECT 1 FROM UploadWriteOff GROUP BY AsOnDate HAVING COUNT(*)<@count)
 BEGIN
UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'As on date should be same '     
						ELSE ErrorMessage+','+SPACE(1)+ 'As on date should be same '      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		--,Srnooferroneousrows=V.SrNo
	 
-- FROM UploadWriteOff V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0
 END
 END
 
 
 PRINT 'DUB5'
 /*validations on Source System Name*/
  
  UPDATE UploadWriteOff
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
   
   FROM UploadWriteOff V  
 WHERE ISNULL(SourceSystem,'')=''
 PRINT 'DUB6'
 UPDATE UploadWriteOff
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

 FROM UploadWriteOff V  
 WHERE ISNULL(SourceSystem,'') LIKE'%[,!@#$%^&*()+=/\]%'
 PRINT 'DUB8'
 UPDATE UploadWriteOff
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
   
 --  FROM UploadWriteOff V  
 --WHERE ISNULL(SourceSystem,'')<>''
 FROM UploadWriteOff V  
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
  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(NCIF_ID,'')='' 

-- ----SELECT * FROM UploadWriteOff
  

  -----COMMENTED ON 17/06/2021 NOT REQUIRED AS PER DOCUMENT 
--  UPDATE UploadWriteOff
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadWriteOff A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadWriteOff V  
-- WHERE ISNULL(V.NCIF_ID,'')<>''
-- AND V.NCIF_ID NOT IN(SELECT NCIF_ID FROM NPA_IntegrationDetails 
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

-- ----SELECT * FROM NPA_IntegrationDetails
   
  print 'NCIF_ID'
--  -------combination
--------	PRINT 'TerritoryAlt_Key'

UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'NCIF_Id Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'NCIF_Id Special characters are  not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(NCIF_Id,'')  LIKE'%[,!@#$%^&*()+=-_/\]%'
   
  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
--								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(NCIF_ID,'') <>'' and LEN(NCIF_ID)>16

-- -------------------------FOR DUPLICATE ACIDS
 IF OBJECT_ID('TEMPDB..#NCIF_ID_DUP') IS NOT NULL
 DROP TABLE #NCIF_ID_DUP

 SELECT * INTO #NCIF_ID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY NCIF_ID ORDER BY  NCIF_ID)AS ROW FROM UploadWriteOff
 )A
 WHERE ROW>1

-- UPDATE UploadWriteOff
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Dedupe_ID-UCIC-Enterprise_CIF ID are repeated.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Dedupe_ID-UCIC-Enterprise_CIF ID are repeated.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadWriteOff A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadWriteOff V  
-- WHERE ISNULL(NCIF_ID,'') <>'' and NCIF_ID IN(SELECT NCIF_ID FROM #NCIF_ID_DUP)

 --  ---------VALIDATIONS ON CustomerID
  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Customer ID cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Customer ID cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(CustomerID,'')='' 

-- UPDATE UploadWriteOff
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Customer ID found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid Customer ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadWriteOff A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadWriteOff V  
-- WHERE ISNULL(V.CustomerID,'')<>''
-- AND V.CustomerID NOT IN(SELECT CustomerID FROM NPA_IntegrationDetails
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

UPDATE UploadWriteOff
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

 FROM UploadWriteOff V  
 WHERE ISNULL(CustomerID,'') LIKE'%[,!@#$%^&*()+=-_/\]%'

  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Customer ID found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Customer ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
--								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(CustomerID,'') <>'' and LEN(CustomerID)>16

-- -------------------------FOR DUPLICATE CustomerId's
 --IF OBJECT_ID('TEMPDB..#CUSTID_DUP') IS NOT NULL
 --DROP TABLE #CUSTID_DUP

 --SELECT * INTO #CUSTID_DUP FROM(
 --SELECT *,ROW_NUMBER() OVER(PARTITION BY CustomerId ORDER BY  CustomerId)AS ROW FROM UploadWriteOff
 --)A
 --WHERE ROW>1

-- UPDATE UploadWriteOff
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Customer ID are repeated.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Customer ID are repeated.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadWriteOff A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadWriteOff V  
-- WHERE ISNULL(CustomerId,'') <>'' and CustomerId IN(SELECT CustomerId FROM #CUSTID_DUP)

--SELECT * FROM UploadWriteOff
  
--  UPDATE UploadWriteOff
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Customer ID found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid Customer ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadWriteOff A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadWriteOff V  
-- WHERE ISNULL(V.CustomerID,'')<>''
--  AND V.CustomerID NOT IN(SELECT CustomerId FROM NPA_IntegrationDetails A
--                                         Inner Join UploadWriteOff V on A.CustomerACID=V.CustomerACID
--								WHERE A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
--						 )
 --AND V.CustomerID NOT IN(SELECT CustomerID FROM [CurDat].[CustomerBasicDetail]
	--							WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
 --)

 print 'Customerid'

--  ---------VALIDATIONS ON ACID
  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Account ID cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Account ID cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(CustomerAcID,'')='' 

 UPDATE UploadWriteOff
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

 FROM UploadWriteOff V  
 WHERE ISNULL(CustomerAcID,'') LIKE'%[,!@#$%^&*()+=-/\]%'

-- ----SELECT * FROM UploadWriteOff
  
--  UPDATE UploadWriteOff
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Account ID found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid Account ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadWriteOff A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadWriteOff V  
-- WHERE ISNULL(V.CustomerAcID,'')<>''
-- AND V.CustomerAcID NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

-- ----SELECT * FROM UploadWriteOff
   
  print 'acid'
--  -------combination
--------	PRINT 'TerritoryAlt_Key'
   
  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Account ID found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Account ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
--								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(CustomerAcID,'') <>'' and LEN(CustomerAcID)>16

 -- Checking for Standard Accounts or Not
-- UPDATE UploadWriteOff
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Only Standard Accounts are allowed. Kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Only Standard Accounts are allowed. Kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadWriteOff A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadWriteOff V  
-- WHERE ISNULL(V.CustomerAcID,'')<>''
-- AND V.CustomerAcID NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
--								WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND AC_AssetClassAlt_Key=1)

-- -------------------------FOR DUPLICATE ACIDS
 IF OBJECT_ID('TEMPDB..#ACID_DUP') IS NOT NULL
 DROP TABLE #ACID_DUP

 SELECT * INTO #ACID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY CustomerAcID ORDER BY  CustomerAcID)AS ROW FROM UploadWriteOff
 )A
 WHERE ROW>1

 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Account ID are repeated.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Account ID are repeated.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
--								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(CustomerAcID,'') <>'' and CustomerAcID IN(SELECT CustomerAcID FROM #ACID_DUP)

 ----------- /*validations on Write-Off Date 
UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'WriteOffDate Can not be Blank . Please enter the WriteOffDate and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'WriteOffDate Can not be Blank. Please enter the DateOfApproval and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'WriteOffDate' ELSE   ErrorinColumn +','+SPACE(1)+'WriteOffDate' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffDate,'')='' 

 SET DATEFORMAT DMY
UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format ‘DD/MM/YY’'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format ‘DD/MM/YY’'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'WriteOffDate' ELSE   ErrorinColumn +','+SPACE(1)+'WriteOffDate' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										  WHERE ISNULL(NPADate,'')<>'' AND (CAST(ISNULL(NPADate ,'')AS Varchar(10))<>FORMAT(cast(NPADate as date),'dd-MM-yyyy'))

		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffDate,'')<>'' AND ISDATE(WriteOffDate)=0

-----Comparison of WriteOffDate with AsOnDate
 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Write-Off Date Should be Less than or Equal to AsOnDate. Please enter the Write-Off Date and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Write-Off Date Should be Less than or Equal to AsOnDate. Please enter the Write-Off Date and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Write-Off Date' ELSE   ErrorinColumn +','+SPACE(1)+'Write-Off Date' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadWriteOff V  
 --WHERE ISNULL(WriteOffDate,'')<>'' AND  CONVERT(date,WriteOffDate,103) > CONVERT(date,AsOnDate,103)
 WHERE  (CASE WHEN ISNULL(WriteOffDate,'')<>'' AND  ISDATE(WriteOffDate)=1 
               THEN CASE WHEN CONVERT(date,WriteOffDate) > CONVERT(date,AsOnDate) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Write Off Date' ELSE ErrorinColumn +','+SPACE(1)+  'Write Off Date' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   
--select *
 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffDate,'')  LIKE '%[,!@#$%^&*()_+=\]%'
 
 --UPDATE  UploadWriteOff 
	--SET WriteOffDate=NULL 
 --WHERE ISDATE(WriteOffDate)=0

 ---------------------------------
 
 -------------------@WriteOffDateCnt--------------------------Satwaji 08-06-2021
 DECLARE @WriteOffDateCnt int=0
 --DROP TABLE IF EXISTS WriteOffDateData
 IF OBJECT_ID('WriteOffDateData') IS NOT NULL  
	  BEGIN
	    
		DROP TABLE  WriteOffDateData
	
	  END

 SELECT * into WriteOffDateData  FROM(
 SELECT ROW_NUMBER() OVER(PARTITION BY UploadID  ORDER BY  UploadID ) 
 ROW ,UploadID,WriteOffDate FROM UploadWriteOff
 )X
 WHERE ROW=1



 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid value in Write-Off Type. Kindly enter value AWO or TWO and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid value in Write-Off Type. Kindly enter value AWO or TWO and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'WriteOffType' ELSE   ErrorinColumn +','+SPACE(1)+'WriteOffType' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadWriteOff V  
 WHERE  ISNULL(WriteOffType,'') <> '' AND WriteOffType NOT IN('AWO','TWO')

 SELECT @WriteOffDateCnt=COUNT(*) 
 FROM WriteOffDateData a
 INNER JOIN UploadWriteOff b
 ON a.UploadID=b.UploadID 
 WHERE a.WriteOffDate<>b.WriteOffDate


 --IF @WriteOffDateCnt>0
 BEGIN
  PRINT 'WriteOffDate ERROR'
  /*WriteOffDate Validation*/ --Satwaji 08-06-2021
  UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'UploadID found different Dates of WriteOffDate. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'UploadID found different Dates of WriteOffDate. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'WriteOffDate' ELSE   ErrorinColumn +','+SPACE(1)+'WriteOffDate' END     
		,Srnooferroneousrows=V.SrNo
	--	STUFF((SELECT ','+SRNO 
	--							FROM #UploadNewAccount A
	--							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
 --WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
 ----AND SRNO IN(SELECT Srno FROM #DUB2))
 --AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

	--							FOR XML PATH ('')
	--							),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(UploadID,'')<>''
 AND  CustomerAcID IN(
				 SELECT DISTINCT B.CustomerAcID from WriteOffDateData a
				 INNER JOIN UploadWriteOff b
				 on a.UploadID=b.UploadID 
				 where a.WriteOffDate<>b.WriteOffDate
				 )

-------- Validations On Write-Off Type
UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'WriteOffType Can not be Blank . Please enter the WriteOffType and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'WriteOffType Can not be Blank. Please enter the WriteOffType and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'WriteOffType' ELSE   ErrorinColumn +','+SPACE(1)+'WriteOffType' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffType,'')='' 





------ -------validations on Write-Off Amount - Interest
  UPDATE UploadWriteOff
	SET   

       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Interest Write-Off Amount cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Write-Off Amount cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadWriteOff A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
								----WHERE ISNULL(InterestReversalAmount,'')='')
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE (ISNULL(WriteOffAmtInterest,'')='' OR WriteOffAmtInterest IS NULL)

 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Write-Off Amount Interest. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Write-Off Amount Interest. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Write-Off Amount Interest' ELSE ErrorinColumn +','+SPACE(1)+  'Write-Off Amount Interest' END  
		,Srnooferroneousrows=V.SrNo
								--STUFF((SELECT ','+SRNO 
								--FROM UploadWriteOff A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadWriteOff V  
 WHERE(ISNUMERIC(WriteOffAmtInterest)=0 AND ISNULL(WriteOffAmtInterest,'')<>'') OR 
 ISNUMERIC(WriteOffAmtInterest) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Interest Write-Off Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Interest Write-Off Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadWriteOff A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffAmtInterest,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadWriteOff
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Interest Write-Off Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Interest Write-Off Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadWriteOff A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadWriteOff WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffAmtInterest,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(WriteOffAmtInterest,0)) <0

    UPDATE UploadWriteOff
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Interest Write-Off Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Interest Write-Off Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE  (CASE WHEN ISNULL(WriteOffAmtInterest,'')<>'' AND  ISNUMERIC(WriteOffAmtInterest)=1 
               THEN CASE WHEN CHARINDEX('.',WriteOffAmtInterest) <> 0 AND CHARINDEX('.',WriteOffAmtInterest)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',WriteOffAmtInterest) = 0 AND LEN(WriteOffAmtInterest)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

------ -------validations on Write off amount - Principal
  UPDATE UploadWriteOff
	SET   

       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Principal Write-Off Amount cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Principal Write-Off Amount cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadWriteOff A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
								----WHERE ISNULL(InterestReversalAmount,'')='')
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE (ISNULL(WriteOffAmtPrincipal,'')='' OR WriteOffAmtPrincipal IS NULL)

 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Principal Write-Off Amount. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Principal Write-Off Amount. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadWriteOff A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadWriteOff V  
 WHERE (ISNUMERIC(WriteOffAmtPrincipal)=0 AND ISNULL(WriteOffAmtPrincipal,'')<>'') OR 
 ISNUMERIC(WriteOffAmtPrincipal) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Principal Write-Off Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Principal Write-Off Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadWriteOff A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffAmtPrincipal,'') LIKE'%[,!@#$%^&*()_-+=/]%'

  UPDATE UploadWriteOff
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Principal Write-Off Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Principal Write-Off Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadWriteOff A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadWriteOff WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(WriteOffAmtPrincipal,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(WriteOffAmtPrincipal,0)) <0

   UPDATE UploadWriteOff
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Principal Write-Off Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Principal Write-Off Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Write-Off Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Write-Off Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE  (CASE WHEN ISNULL(WriteOffAmtPrincipal,'')<>'' AND  ISNUMERIC(WriteOffAmtPrincipal)=1 
               THEN CASE WHEN CHARINDEX('.',WriteOffAmtPrincipal) <> 0 AND CHARINDEX('.',WriteOffAmtPrincipal)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',WriteOffAmtPrincipal) = 0 AND LEN(WriteOffAmtPrincipal)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ---------- Validations for Action
 UPDATE UploadWriteOff
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Action cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Action cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								----WHERE ISNULL(InterestReversalAmount,'')='')
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(Action,'')=''

 UPDATE UploadWriteOff
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Action. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Action. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
--								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
--								---- )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadWriteOff V  
 WHERE ISNULL(Action,'')<>'' AND Action NOT IN ('A','D')
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0


 END



 
 goto valid

  END
	
   ErrorData:  
   print 'no'  

		SELECT *,'Data'TableName
		FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		return

   valid:
		IF NOT EXISTS(Select 1 from  WriteOffUpload_Stg WHERE filname=@FilePathUpload)
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
			FROM UploadWriteOff 


			
		--	----SELECT * FROM UploadWriteOff 

		--	--ORDER BY ErrorMessage,UploadWriteOff.ErrorinColumn DESC
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

		 IF EXISTS(SELECT 1 FROM WriteOffUpload_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM WriteOffUpload_Stg
		 WHERE filname=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.WriteOffUpload_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
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

	----SELECT * FROM UploadWriteOff

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

	IF EXISTS(SELECT 1 FROM WriteOffUpload_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM WriteOffUpload_Stg
		 WHERE filname=@FilePathUpload

		 

		 PRINT 'ROWS DELETED FROM DBO.WriteOffUpload_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

END CATCH

END
  
GO