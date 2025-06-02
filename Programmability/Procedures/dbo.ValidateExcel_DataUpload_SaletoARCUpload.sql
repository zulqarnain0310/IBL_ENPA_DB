SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ValidateExcel_DataUpload_SaletoARCUpload] 
@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='FNASUPERADMIN',  
@Timekey INT=49999
,@filepath VARCHAR(MAX) ='SaletoARC.xlsx'  
WITH RECOMPILE  
AS  
--  exec [dbo].[ValidateExcel_DataUpload_SaletoARCUpload] @MenuID=N'98',@UserLoginId=N'npachecker',@Timekey=N'24927',@filepath=N'SaleToARCUpload.xlsx'
--go


--DECLARE  
  
--@MenuID INT=98,  
--@UserLoginId varchar(20)='12checker',  
--@Timekey int=24927
--,@filepath varchar(500)='SaleToARCUpload (1).xlsx'  
  
BEGIN

BEGIN TRY  
--BEGIN TRAN  
  
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

IF (@MenuID=98)	
BEGIN


	  -- IF OBJECT_ID('tempdb..UploadSaletoARC') IS NOT NULL  
	  --BEGIN  
	  -- DROP TABLE UploadSaletoARC  
	
	  --END
	  --drop table if exists  UploadSaletoARC 
	   IF OBJECT_ID('UploadSaletoARC') IS NOT NULL  
		  BEGIN
	    
			DROP TABLE  UploadSaletoARC
	
		  END
	   
  IF NOT (EXISTS (SELECT * FROM SaletoARC_Stg where filname=@FilePathUpload))

BEGIN
print 'NO DATA'
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
 	   into UploadSaletoARC 
	   from SaletoARC_Stg 
	   WHERE filname=@FilePathUpload

	   UPDATE DateOfSaletoARC SET UploadID=1 FROM DateOfSaletoARC WHERE UploadID IS NULL
END
  ------------------------------------------------------------------------------  
    ----SELECT * FROM UploadSaletoARC
	--SrNo	Territory	ACID	InterestReversalAmount	filname
	UPDATE UploadSaletoARC
	SET  
        ErrorMessage='There is no data in excel. Kindly check and upload again' 

		,ErrorinColumn='SRNO,AsOnDate,SourceSystem,NCIF_ID,CustomerID,AccountNo,DateOfSaletoARC,TotalSaleConsideration,PrincipalConsideration,InterestConsideration,Action'    
		,Srnooferroneousrows=''
 FROM UploadSaletoARC V  
 WHERE ISNULL(SrNo,'')=''
 AND ISNULL(AsOnDate,'')=''
 AND ISNULL(SourceSystem,'')=''
 AND ISNULL(NCIF_Id,'')=''
 AND ISNULL(CustomerID,'')=''
 AND ISNULL(AccountNo,'')=''
 AND ISNULL(DateOfSaletoARC,'')=''
 AND ISNULL(TotalSaleConsideration,'')=''
 AND ISNULL(PrincipalConsideration,'')=''
 AND ISNULL(InterestConsideration,'')=''
 AND ISNULL(Action,'')=''

-- WHERE ISNULL(V.SrNo,'')=''
-- ----AND ISNULL(Territory,'')=''
-- AND ISNULL(SourceSystem,'')=''
-- AND ISNULL(CustomerID,'')=''
-- AND ISNULL(CustomerName,'')=''
--AND ISNULL(AccountID,'')=''
-- AND ISNULL(TotalSaleConsideration,'')=''
-- AND ISNULL(POS,'')=''
-- AND ISNULL(InterestConsideration,'')=''
-- AND ISNULL(DateOfSaletoARC,'')=''
-- AND ISNULL(AsOnDate,'')=''
-- AND ISNULL(ExposuretoARCinRs,'')=''
--  AND ISNULL(filname,'')=''
  
  IF EXISTS(SELECT 1 FROM UploadSaletoARC WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  END

  
 -----validations on Srno
 
UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Sr. No. cannot be blank.  Please check the values and upload again' 
								ELSE ErrorMessage+','+SPACE(1)+ 'Sr. No. cannot be blank.  Please check the values and upload again'	END
	,ErrorinColumn='SRNO'    
	,Srnooferroneousrows=''
	FROM UploadSaletoARC V  
	WHERE ISNULL(v.SrNo,'')=''  

UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(SrNo,'') LIKE'%[,!@#$%^&*()+=-_/\]%'

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SRNO  
  
  FROM UploadSaletoARC v
  WHERE ISNULL(v.SrNo,'')='0'  OR ISNUMERIC(v.SrNo)=0 OR ISNULL(v.SrNo,'')<0

  update UploadSaletoARC
  set SrNo=NULL
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SRNO ORDER BY SRNO)ROW
   FROM UploadSaletoARC
   )A
   WHERE ROW>1

 PRINT 'DUB'  


  UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Following sr. no. are repeated' 
					ELSE ErrorMessage+','+SPACE(1)+     'Following sr. no. are repeated' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END
		,Srnooferroneousrows=SRNO
--		--STUFF((SELECT DISTINCT ','+SRNO 
--		--						FROM UploadWriteOff
--		--						FOR XML PATH ('')
--		--						),1,1,'')
         
		
 FROM UploadSaletoARC V  
	WHERE  V.Srno IN(SELECT SRNO FROM #R )

----------- /* Validations on AsOnDate Date
UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(AsOnDate,'')='' 

 SET DATEFORMAT DMY
UPDATE UploadSaletoARC
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
 FROM UploadSaletoARC V  
 WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0

 ----- Future Date Comparison
 UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND  CONVERT(date,AsOnDate,103) > CONVERT(date,GETDATE(),103)
 WHERE  (CASE WHEN ISNULL(AsOnDate,'')<>'' AND  ISDATE(AsOnDate)=1 
               THEN CASE WHEN CONVERT(date,AsOnDate) > CONVERT(date,GETDATE()) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

UPDATE UploadSaletoARC
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
 FROM UploadSaletoARC V  
 WHERE ISNULL(AsOnDate,'')  LIKE '%[,!@#$%^&*()_+=\]%'

 --------- Checking for As on date should be common in all Records
  UPDATE  UploadSaletoARC 
	SET AsOnDate=NULL 
 WHERE ISDATE(AsOnDate)=0

  IF Exists (Select 1 from UploadSaletoARC where Isnumeric(SrNo)=1)
 Begin

 Declare @count int
 select  @count =max(SrNo)  from UploadSaletoARC GROUP BY AsOnDate 
 IF EXISTS (SELECT 1 FROM UploadSaletoARC GROUP BY AsOnDate HAVING COUNT(*)<@count)
 BEGIN
UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'As on date should be same '     
						ELSE ErrorMessage+','+SPACE(1)+ 'As on date should be same '      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		--,Srnooferroneousrows=V.SrNo
	 
-- FROM UploadWriteOff V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0
 END
 END

 /*validations on Source System Name*/
  
  UPDATE UploadSaletoARC
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
   
   FROM UploadSaletoARC V  
 WHERE ISNULL(SourceSystem,'')=''

UPDATE UploadSaletoARC
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
 FROM UploadSaletoARC V 
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

  UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(SourceSystem,'') LIKE'%[,!@#$%^&*()+=-_/\]%'

--  ---------VALIDATIONS ON Dedupe_ID-UCIC-Enterprise_CIF(NCIF_ID)
  UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(NCIF_ID,'')='' 

-- ----SELECT * FROM UploadWriteOff
  
  -----COMMENTED ON 18/06/2021 NOT REQUIRED AS PER DOCUMENT 
--  UPDATE UploadSaletoARC
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
--		FROM UploadSaletoARC V  
-- WHERE ISNULL(V.NCIF_ID,'')<>''
-- AND V.NCIF_ID NOT IN(SELECT NCIF_ID FROM NPA_IntegrationDetails 
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

-- ----SELECT * FROM NPA_IntegrationDetails

UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(NCIF_Id,'') LIKE'%[,!@#$%^&*()+=-_/\]%'
   
  print 'NCIF_ID'
--  -------combination
--------	PRINT 'TerritoryAlt_Key'
   
  UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(NCIF_ID,'') <>'' and LEN(NCIF_ID)>16

-- -------------------------FOR DUPLICATE NCIF_ID's
 IF OBJECT_ID('TEMPDB..#NCIF_ID_DUP') IS NOT NULL
 DROP TABLE #NCIF_ID_DUP

 SELECT * INTO #NCIF_ID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY NCIF_ID ORDER BY  NCIF_ID)AS ROW FROM UploadSaletoARC
 )A
 WHERE ROW>1

-- UPDATE UploadSaletoARC
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

-- FROM UploadSaletoARC V  
-- WHERE ISNULL(NCIF_ID,'') <>'' and NCIF_ID IN(SELECT NCIF_ID FROM #NCIF_ID_DUP)

 --  ---------VALIDATIONS ON Dedupe ID - UCIC - Enterprise CIF(NCIF_ID)

 --  ---------VALIDATIONS ON CustomerID
  UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(CustomerID,'')='' 

 -----COMMENTED ON 18/06/2021 NOT REQUIRED AS PER DOCUMENT 
-- UPDATE UploadSaletoARC
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
--		FROM UploadSaletoARC V  
-- WHERE ISNULL(V.CustomerID,'')<>''
-- AND V.CustomerID NOT IN(SELECT CustomerID FROM NPA_IntegrationDetails
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(CustomerID,'') LIKE'%[,!@#$%^&*()+=-_/\]%'

  UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(CustomerID,'') <>'' and LEN(CustomerID)>16

-- -------------------------FOR DUPLICATE CustomerId's
 IF OBJECT_ID('TEMPDB..#CUSTID_DUP') IS NOT NULL
 DROP TABLE #CUSTID_DUP

 SELECT * INTO #CUSTID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY CustomerId ORDER BY  CustomerId)AS ROW FROM UploadSaletoARC
 )A
 WHERE ROW>1

-- UPDATE UploadSaletoARC
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

-- FROM UploadSaletoARC V  
-- WHERE ISNULL(CustomerId,'') <>'' and CustomerId IN(SELECT CustomerId FROM #CUSTID_DUP)

--  ---------VALIDATIONS ON ACID
  UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Account No cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Account No cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account No' ELSE ErrorinColumn +','+SPACE(1)+  'Account No' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadSaletoARC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(AccountNo,'')='' 

---- ----SELECT * FROM UploadSaletoARC
  
  -----COMMENTED ON 18/06/2021 NOT REQUIRED AS PER DOCUMENT 
--  UPDATE UploadSaletoARC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Account No found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid Account No found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account No' ELSE ErrorinColumn +','+SPACE(1)+  'Account No' END  
--		,Srnooferroneousrows=V.SRNO
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadSaletoARC A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadSaletoARC V  
-- WHERE ISNULL(V.AccountNo,'')<>''
-- AND V.AccountNo NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
--)

-- ----SELECT * FROM UploadSaletoARC
   
  PRINT 'Account NO'
--  -------combination
--------	PRINT 'TerritoryAlt_Key'
   
UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(AccountNo,'') LIKE'%[,!@#$%^&*()+=-/\]%'

  UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Account No found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Account No found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account No' ELSE ErrorinColumn +','+SPACE(1)+  'Account No' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadSaletoARC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
--								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(AccountNo,'') <>'' and LEN(AccountNo)>16

-- Checking for Standard Accounts or Not
-- UPDATE UploadSaletoARC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Only Standard Accounts are allowed. Kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Only Standard Accounts are allowed. Kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account No' ELSE ErrorinColumn +','+SPACE(1)+  'Account No' END  
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
--		FROM UploadSaletoARC V  
-- WHERE ISNULL(V.AccountNo,'')<>''
-- AND V.AccountNo NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
--								WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND AC_AssetClassAlt_Key=1)

-- -------------------------FOR DUPLICATE ACIDS
 IF OBJECT_ID('TEMPDB..#ACID_DUP') IS NOT NULL
 DROP TABLE #ACID_DUP

 SELECT * INTO #ACID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY AccountNo ORDER BY  AccountNo)AS ROW FROM UploadSaletoARC
 )A
 WHERE ROW>1

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Account No are repeated.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Account No are repeated.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account No' ELSE ErrorinColumn +','+SPACE(1)+  'Account No' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadSaletoARC A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
--								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(AccountNo,'') <>'' and AccountNo IN(SELECT AccountNo FROM #ACID_DUP)

 ----------- /*validations on ARC Sale Date */

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'ARC Sale Date Can not be Blank . Please enter The ARC Sale Date and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'ARC Sale Date Can not be Blank. Please enter the ARC Sale Date and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ARC Sale Date' ELSE   ErrorinColumn +','+SPACE(1)+'ARC Sale Date' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(DateOfSaletoARC,'')='' 

 SET DATEFORMAT DMY
UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ARC Sale Date' ELSE   ErrorinColumn +','+SPACE(1)+'ARC Sale Date' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										  WHERE ISNULL(NPADate,'')<>'' AND (CAST(ISNULL(NPADate ,'')AS Varchar(10))<>FORMAT(cast(NPADate as date),'dd-MM-yyyy'))

		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(DateOfSaletoARC,'')<>'' AND ISDATE(DateOfSaletoARC)=0

 ----- AsOnDate Comparison
 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'ARC Sale Date Should be Less than or Equal to AsOnDate. Please enter the ARC Sale Date and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'ARC Sale Date Should be Less than or Equal to AsOnDate. Please enter the ARC Sale Date and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ARC Sale Date' ELSE   ErrorinColumn +','+SPACE(1)+'ARC Sale Date' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadSaletoARC V  
 --WHERE ISNULL(DateOfSaletoARC,'')<>'' AND  (CONVERT(date,DateOfSaletoARC,103) > CONVERT(date,AsOnDate,103))
 WHERE  (CASE WHEN ISNULL(DateOfSaletoARC,'')<>'' AND  ISDATE(DateOfSaletoARC)=1 
               THEN CASE WHEN CONVERT(date,DateOfSaletoARC) > CONVERT(date,AsOnDate) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

  -------------------@ARCSaleDateCnt--------------------------Satwaji 08-06-2021
 DECLARE @ARCSaleDateCnt int=0
 --DROP TABLE IF EXISTS ARCSaleDateData
 IF OBJECT_ID('ARCSaleDateData') IS NOT NULL  
	  BEGIN
	    
		DROP TABLE  ARCSaleDateData
	
	  END

 SELECT * into ARCSaleDateData  FROM(
 SELECT ROW_NUMBER() OVER(PARTITION BY UploadID  ORDER BY  UploadID ) 
 ROW ,UploadID,DateOfSaletoARC FROM UploadSaletoARC
 )X
 WHERE ROW=1


 SELECT @ARCSaleDateCnt=COUNT(*) 
 FROM ARCSaleDateData a
 INNER JOIN UploadSaletoARC b
 ON a.UploadID=b.UploadID 
 WHERE a.DateOfSaletoARC<>b.DateOfSaletoARC

 --IF @ARCSaleDateCnt>0
 --BEGIN
 -- PRINT 'ARC Sale Date ERROR'
 -- /*ARC Sale Date Validation*/ --Satwaji 08-06-2021
 -- UPDATE UploadSaletoARC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'UploadID found different Dates of ARC Sale Date. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'UploadID found different Dates of ARC Sale Date. Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ARC Sale Date' ELSE   ErrorinColumn +','+SPACE(1)+'ARC Sale Date' END     
	--	,Srnooferroneousrows=V.SrNo
	----	STUFF((SELECT ','+SRNO 
	----							FROM #UploadNewAccount A
	----							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
 ----WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
 ------AND SRNO IN(SELECT Srno FROM #DUB2))
 ----AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

	----							FOR XML PATH ('')
	----							),1,1,'')   

 --FROM UploadSaletoARC V  
 --WHERE ISNULL(UploadID,'')<>''
 --AND  AccountNo IN(
	--			 SELECT DISTINCT B.AccountNo from ARCSaleDateData a
	--			 INNER JOIN UploadSaletoARC b
	--			 on a.UploadID=b.UploadID 
	--			 where a.DateOfSaletoARC<>b.DateOfSaletoARC
	--			 )
	-- END

------ -------validations on Total Sale Consideration
  UPDATE UploadSaletoARC
	SET   

       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Total Sale Consideration cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Total Sale Consideration cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Sale Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Total Sale Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								----WHERE ISNULL(InterestReversalAmount,'')='')
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE (ISNULL(TotalSaleConsideration,'')='' OR TotalSaleConsideration IS NULL)


 

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Total Sale Consideration. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Int Total Sale Consideration. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Sale Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Total Sale Consideration' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadSaletoARC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE (ISNUMERIC(TotalSaleConsideration)=0 AND ISNULL(TotalSaleConsideration,'')<>'') OR 
 ISNUMERIC(TotalSaleConsideration) LIKE '%^[0-9]%'
PRINT 'INVALID' 

--update UploadSaletoARC
--  set TotalSaleConsideration=NULL
--  WHERE (ISNUMERIC(TotalSaleConsideration)=0 AND ISNULL(TotalSaleConsideration,'')<>'') OR  ISNUMERIC(TotalSaleConsideration) LIKE '%^[0-9]%'

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Sale Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Total Sale Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(TotalSaleConsideration,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadSaletoARC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Total Sale Consideration. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Total Sale Consideration. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Sale Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Total Sale Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadSaletoARC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(TotalSaleConsideration,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(TotalSaleConsideration,0)) <0

   ------------------ VALIDATING THE TOTALSALE=PRINCIPAL+INTEREST or Not
 UPDATE UploadSaletoARC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Total Sale Consideration Should be the SUM of Principal Consideration
												and Interest Consideration. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Total Sale Consideration Should be the SUM of Principal Consideration
												and Interest Consideration. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Sale Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Total Sale Consideration' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadSaletoARC V  
 WHERE  (CASE WHEN (TotalSaleConsideration<>'' AND  ISNUMERIC(TotalSaleConsideration)=1) AND (PrincipalConsideration<>'' AND  ISNUMERIC(PrincipalConsideration)=1)
              AND (InterestConsideration<>'' AND  ISNUMERIC(InterestConsideration)=1)
               THEN CASE WHEN CAST(ISNULL(TotalSaleConsideration,0) AS DECIMAL(18,2)) <> (CAST(ISNULL(PrincipalConsideration,0) AS DECIMAL(18,2)) 
			   + CAST(ISNULL(InterestConsideration,0) AS DECIMAL(18,2)))
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

  UPDATE UploadSaletoARC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Total Sale Consideration. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Total Sale Consideration. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Sale Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Total Sale Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE  (CASE WHEN ISNULL(TotalSaleConsideration,'')<>'' AND  ISNUMERIC(TotalSaleConsideration)=1 
               THEN CASE WHEN CHARINDEX('.',TotalSaleConsideration) <> 0 AND CHARINDEX('.',TotalSaleConsideration)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',TotalSaleConsideration) = 0 AND LEN(TotalSaleConsideration)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ---------------------- VALIDATING THE TOTALSALE=PRINCIPAL+INTEREST or Not
 ----UPDATE UploadSaletoARC
	----SET  
 ----       ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Total Consideration Should be the SUM of Principal Consideration
	----											and the Interest Consideration. Please check the values and upload again'     
	----					ELSE ErrorMessage+','+SPACE(1)+ 'Total Consideration Should be the SUM of Principal Consideration
	----											and the Interest Consideration. Please check the values and upload again'     END
	----	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Sale Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Total Sale Consideration' END  
	----	,Srnooferroneousrows=V.SRNO
								  

 ----FROM UploadSaletoARC V  
 ----WHERE  (CASE WHEN (TotalSaleConsideration<>'' AND  ISNUMERIC(TotalSaleConsideration)=1) AND (PrincipalConsideration<>'' AND  ISNUMERIC(PrincipalConsideration)=1)
 ----             AND (InterestConsideration<>'' AND  ISNUMERIC(InterestConsideration)=1)
 ----              THEN CASE WHEN CAST(ISNULL(TotalSaleConsideration,0) AS DECIMAL(18,2)) <> (CAST(ISNULL(PrincipalConsideration,0) AS DECIMAL(18,2)) 
	----		   + CAST(ISNULL(InterestConsideration,0) AS DECIMAL(18,2)))
	----		             THEN 1 ELSE 0 END 
	----		   ELSE 2 END)=1

--WHERE  (CASE WHEN ISNULL(TotalSaleConsideration,'')<>'' AND  ISNUMERIC(TotalSaleConsideration)=1 
--               THEN CASE WHEN CAST(TotalSaleConsideration AS DECIMAL(18,2)) <> (CAST(ISNULL(PrincipalConsideration,0) AS DECIMAL(18,2)) 
--			   + CAST(ISNULL(InterestConsideration,0) AS DECIMAL(18,2)))
--			             THEN 1 ELSE 0 END 
--			   ELSE 2 END)=1
-- WHERE ISNULL(TotalSaleConsideration,'')<>'' 
--AND CAST (ISNULL(V.TotalSaleConsideration,0) AS DECIMAL(18,2)) <> CAST(ISNULL(V.PrincipalConsideration,0) AS DECIMAL(18,2)) + CAST(ISNULL(V.InterestConsideration,0) AS DECIMAL(18,2))

------ -------validations on Interest Consideration
  UPDATE UploadSaletoARC
	SET   

       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Interest Consideration cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Interest Consideration cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								----WHERE ISNULL(InterestReversalAmount,'')='')
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(InterestConsideration,'')=''

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Interest Consideration. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Interest Consideration. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Consideration' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadSaletoARC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE (ISNUMERIC(InterestConsideration)=0 AND ISNULL(InterestConsideration,'')<>'') OR 
 ISNUMERIC(InterestConsideration) LIKE '%^[0-9]%'
 PRINT ' Interest Consideration INVALID' 

 --update UploadSaletoARC
 -- set InterestConsideration=NULL
 -- WHERE (ISNUMERIC(InterestConsideration)=0 AND ISNULL(InterestConsideration,'')<>'') OR  ISNUMERIC(InterestConsideration) LIKE '%^[0-9]%'

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(InterestConsideration,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadSaletoARC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Interest Consideration. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Interest Consideration. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadSaletoARC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(InterestConsideration,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(InterestConsideration,0)) <0

   UPDATE UploadSaletoARC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Interest Consideration. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Interest Consideration. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Interest Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Interest Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE  (CASE WHEN ISNULL(InterestConsideration,'')<>'' AND  ISNUMERIC(InterestConsideration)=1 
               THEN CASE WHEN CHARINDEX('.',InterestConsideration) <> 0 AND CHARINDEX('.',InterestConsideration)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',InterestConsideration) = 0 AND LEN(InterestConsideration)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ------ -------validations on Principal Consideration
 UPDATE UploadSaletoARC
	SET   

       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Principal Consideration cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Principal Consideration cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								----WHERE ISNULL(InterestReversalAmount,'')='')
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(PrincipalConsideration,'')=''

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Principal Consideration. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Principal Consideration. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Consideration' END  
		,Srnooferroneousrows=V.SRNO
								--STUFF((SELECT ','+SRNO 
								--FROM UploadSaletoARC A
								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
								--)
								--FOR XML PATH ('')
								--),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE (ISNUMERIC(PrincipalConsideration)=0 AND ISNULL(PrincipalConsideration,'')<>'') OR 
 ISNUMERIC(PrincipalConsideration) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 --update UploadSaletoARC
 -- set PrincipalConsideration=NULL
 -- WHERE (ISNUMERIC(PrincipalConsideration)=0 AND ISNULL(PrincipalConsideration,'')<>'') OR  ISNUMERIC(PrincipalConsideration) LIKE '%^[0-9]%'

 UPDATE UploadSaletoARC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadSaletoARC V
								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
								----)
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(PrincipalConsideration,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadSaletoARC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Principal Consideration. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Principal Consideration. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadSaletoARC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadSaletoARC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE ISNULL(PrincipalConsideration,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(PrincipalConsideration,0)) <0

    UPDATE UploadSaletoARC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Principal Consideration. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Principal Consideration. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Principal Consideration' ELSE ErrorinColumn +','+SPACE(1)+  'Principal Consideration' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadSaletoARC V  
 WHERE  (CASE WHEN ISNULL(PrincipalConsideration,'')<>'' AND  ISNUMERIC(PrincipalConsideration)=1 
               THEN CASE WHEN CHARINDEX('.',PrincipalConsideration) <> 0 AND CHARINDEX('.',PrincipalConsideration)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',PrincipalConsideration) = 0 AND LEN(PrincipalConsideration)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ---------- Validations for Action
 UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE ISNULL(Action,'')=''

 UPDATE UploadSaletoARC
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

 FROM UploadSaletoARC V  
 WHERE  Action NOT IN('A','D')

 
 goto valid

  END
	
   ErrorData:  
   print 'no'  

		SELECT *,'Data'TableName
		FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		return

   valid:
		IF NOT EXISTS(Select 1 from  SaletoARC_Stg WHERE filname=@FilePathUpload)
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
			FROM UploadSaletoARC 


			
		--	----SELECT * FROM UploadSaletoARC 

		--	--ORDER BY ErrorMessage,UploadSaletoARC.ErrorinColumn DESC
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
	
		ORDER BY SR_No 

		 IF EXISTS(SELECT 1 FROM SaletoARC_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM SaletoARC_Stg
		 WHERE filname=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.SaletoARC_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

	END
	ELSE
	BEGIN
	PRINT ' DATA NOT PRESENT'
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

	----SELECT * FROM UploadSaletoARC

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
	

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()

	IF EXISTS(SELECT 1 FROM SaletoARC_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM SaletoARC_Stg
		 WHERE filname=@FilePathUpload

		 PRINT 'ROWS DELETED FROM DBO.SaletoARC_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

END CATCH

END
  
GO