SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[ValidateExcel_DataUpload_BuyOutUpload_16112021] 
@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='fnachecker',  
@Timekey INT=49999
,@filepath VARCHAR(MAX) ='BuyoutUPLOAD.xlsx'  
WITH RECOMPILE  
AS  



--DECLARE  
  
--@MenuID INT=99,  
--@UserLoginId varchar(20)=N'1maker',  
--@Timekey int=N'26084'
--,@filepath varchar(500)=N'Securitization_Set_Upload (2).xlsx'  
  
BEGIN

BEGIN TRY  
--BEGIN TRAN  
  
--Declare @TimeKey int  
    --Update UploadStatus Set ValidationOfData='N' where FileNames=@filepath  
     
	 SET DATEFORMAT DMY

 --Select @Timekey=Max(Timekey) from dbo.SysProcessingCycle  
 -- where  ProcessType='Quarterly' ----and PreMOC_CycleFrozenDate IS NULL
 
 Set  @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
                    Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
                       where A.CurrentStatus='C')

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


IF (@MenuID=99)	
BEGIN


	
	  IF OBJECT_ID('UploadBuyout') IS NOT NULL  
	  BEGIN
	    
		DROP TABLE  UploadBuyout
	
	  END
	  
  IF NOT (EXISTS (SELECT * FROM BuyoutDetails_Stg where filname=@FilePathUpload))

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
 	   into UploadBuyout 
	   from BuyoutDetails_Stg 
	   WHERE filname=@FilePathUpload

	  
END
  ------------------------------------------------------------------------------  
  --select * from BuyoutDetails_stg
    ----SELECT * FROM UploadBuyout
	--SrNo	Territory	ACID	InterestReversalAmount	FileName
	UPDATE UploadBuyout
	SET  
        ErrorMessage='There is no data in excel. Kindly check and upload again' 
		,ErrorinColumn='SrNo,AsOnDate,PAN,NCIF_Id,CustomerName,AccountNo,LoanAgreementNo,IndusindLoanAccountNo,TotalOutstanding
		,UnrealizedInterest,PrincipalOutstanding,AssetClassification,NPADate,DPD,SecurityAmount,AdditionalProvisionAmount,AcceleratedProvisionPercentage
		,SecuredStatus,Action'    
		,Srnooferroneousrows=''
 FROM UploadBuyout V  
 WHERE ISNULL(SrNo,'')=''
AND ISNULL(AsOnDate,'')=''
AND ISNULL(PAN,'')=''
AND ISNULL(NCIF_Id,'')=''
AND ISNULL(CustomerName,'')=''
AND ISNULL(AccountNo,'')=''
AND ISNULL(LoanAgreementNo,'')=''
AND ISNULL(IndusindLoanAccountNo,'')=''
AND ISNULL(TotalOutstanding,'')=''
AND ISNULL(UnrealizedInterest,'')=''
AND ISNULL(PrincipalOutstanding,'')=''
AND ISNULL(AssetClassification,'')=''
AND ISNULL(NPADate,'')=''
AND ISNULL(DPD,'')=''
AND ISNULL(SecurityAmount,'')=''
AND ISNULL(Action,'')=''
AND ISNULL(AdditionalProvisionAmount,'')=''
AND ISNULL(AcceleratedProvisionPercentage,'')=''
AND ISNULL(SecuredStatus,'')=''
--WHERE ISNULL(V.SrNo,'')=''
-- ----AND ISNULL(Territory,'')=''
-- AND ISNULL(AccountID,'')=''
-- AND ISNULL(PoolID,'')=''
-- AND ISNULL(FileName,'')=''

  IF EXISTS(SELECT 1 FROM UploadBuyout WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  END



-----validations on SrNo
	print 'Validation Error Message for SRNO'
	 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 	'SrNo is mandatory. Kindly check and upload again' 
		                  ELSE ErrorMessage+','+SPACE(1)+ 'SrNo is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=''
	FROM UploadBuyout V  
	WHERE ISNULL(v.SrNo,'')=''  
	 Print '1'

UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END  
		,Srnooferroneousrows=V.SrNo

--select *
 FROM UploadBuyout V  
 WHERE ISNULL(SrNo,'')  LIKE '%[,!@#$%^&*()_-+=/]%'

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SRNO  
  
  FROM UploadBuyout v
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

  update UploadBuyout
  set SrNo=NULL
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid SrNo, kindly check and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid SrNo, kindly check and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SrNo
		
 FROM UploadBuyout V  
 WHERE ISNULL(v.SrNo,'')='0'  OR ISNUMERIC(v.SrNo)=0
  Print '2'
  
  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SrNo ORDER BY SrNo)ROW
   FROM UploadBuyout
   )A
   WHERE ROW>1

 PRINT 'Duplicate SRNO'  


  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate SrNo, kindly check and upload again' 
					ELSE ErrorMessage+','+SPACE(1)+     'Duplicate SrNo, kindly check and upload again' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SrNo' ELSE ErrorinColumn +','+SPACE(1)+  'SrNo' END
		,Srnooferroneousrows=SrNo
		--STUFF((SELECT DISTINCT ','+SrNo 
		--						FROM UploadBuyout
		--						FOR XML PATH ('')
		--						),1,1,'')
         
		
 FROM UploadBuyout V  
	WHERE  V.SrNo IN(SELECT SrNo FROM #R )
	Print '3'

----------- /* Validations on AsOnDate Date
UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(AsOnDate,'')='' 

SET DATEFORMAT DMY
UPDATE UploadBuyout
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
 FROM UploadBuyout V  
 WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0


 ----- Future Date Comparison
 UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND  CONVERT(date,AsOnDate,103) > CONVERT(date,GETDATE(),103)
 WHERE  (CASE WHEN ISNULL(AsOnDate,'')<>'' AND  ISDATE(AsOnDate)=1 
               THEN CASE WHEN CONVERT(date,AsOnDate) > CONVERT(date,GETDATE()) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

PRINT 'DUB4'

UPDATE UploadBuyout
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
 FROM UploadBuyout V  
 WHERE ISNULL(AsOnDate,'')  LIKE '%[,!@#$%^&*()_+=\]%'

 UPDATE  UploadBuyout 
	SET AsOnDate=NULL 
 WHERE ISDATE(AsOnDate)=0

 PRINT 'DUB41'
 IF Exists (Select 1 from UploadBuyout where Isnumeric(SrNo)=1)
 Begin

 PRINT 'DUB42'
 Declare @count int
 select  @count = max(SrNo)  from UploadBuyout GROUP BY AsOnDate 
 IF EXISTS (SELECT 1 FROM UploadBuyout GROUP BY AsOnDate HAVING COUNT(*)<@count)
 BEGIN
UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'As on date should be same '     
						ELSE ErrorMessage+','+SPACE(1)+ 'As on date should be same '      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END  
		--,Srnooferroneousrows=V.SrNo
	 
-- FROM UploadCustMOC V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0
 END
 END
 
 
 PRINT 'DUB5'

 ---------------------------------
 
 ---------------------@AsOnDateCnt--------------------------Satwaji 08-06-2021
 --DECLARE @AsOnDateCnt int=0
 ----DROP TABLE IF EXISTS WriteOffDateData
 --IF OBJECT_ID('AsOnDateData') IS NOT NULL  
	--  BEGIN
	    
	--	DROP TABLE  AsOnDateData
	
	--  END

 --SELECT * into AsOnDateData  FROM(
 --SELECT ROW_NUMBER() OVER(PARTITION BY UploadID  ORDER BY  UploadID ) 
 --ROW ,UploadID,AsOnDate FROM UploadBuyout
 --)X
 --WHERE ROW=1


 --SELECT @AsOnDateCnt=COUNT(*) 
 --FROM AsOnDateData a
 --INNER JOIN UploadBuyout b
 --ON a.UploadID=b.UploadID 
 --WHERE a.AsOnDate<>b.AsOnDate

 --IF @AsOnDateCnt>0
 --BEGIN
 -- PRINT 'AsOnDate ERROR'
 -- /*AsOnDate Validation*/ --Satwaji 12-06-2021
 -- UPDATE UploadBuyout
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'UploadID found different Dates of AsOnDate. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'UploadID found different Dates of AsOnDate. Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END     
	--	,Srnooferroneousrows=V.SrNo
	----	STUFF((SELECT ','+SRNO 
	----							FROM #UploadNewAccount A
	----							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
 ----WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
 ------AND SRNO IN(SELECT Srno FROM #DUB2))
 ----AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

	----							FOR XML PATH ('')
	----							),1,1,'')   

 --FROM UploadBuyout V  
 --WHERE ISNULL(UploadID,'')<>''
 --AND  AccountNo IN(
	--			 SELECT DISTINCT B.AccountNo from AsOnDateData a
	--			 INNER JOIN UploadBuyout b
	--			 on a.UploadID=b.UploadID 
	--			 where a.AsOnDate<>b.AsOnDate
	--			 )

/*------------------- Validations on PAN -------------------- Satwaji 12-06-2021 */

--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'The column ‘PAN’ is mandatory. Kindly check and upload again' 
--					ELSE ErrorMessage+','+SPACE(1)+ 'PAN is mandatory. Kindly check and upload again'	END
--		,ErrorinColumn='PAN'    
--		,Srnooferroneousrows=''
--	FROM UploadBuyout V  
--	WHERE V.PAN IN(SELECT PAN FROM NPA_IntegrationDetails
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
--						 )

--------------- VALIDATIONS ON PAN CARD
-- Commented By SATWAJI AS Per Bank's Team Instructions as on 12/08/2021 for Mandatory to Optional change

--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'PAN can not be blank. Kindly check and upload again' 
--					ELSE ErrorMessage+','+SPACE(1)+ 'PAN can not be blank. Kindly check and upload again'	END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PAN' ELSE ErrorinColumn +','+SPACE(1)+  'PAN' END  
--		--,ErrorinColumn='PAN'    
--		,Srnooferroneousrows=''
--	FROM UploadBuyout V  
--	WHERE ISNULL(V.PAN,'')=''

--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PAN' ELSE ErrorinColumn +','+SPACE(1)+  'PAN' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   
----select *
-- FROM UploadBuyout V  
-- WHERE ISNULL(V.PAN,'')  LIKE '%[,!@#$%^&*()_-+=/\]%'


--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'Invalid PAN. PAN length must be 10 characters, first 5 characters must be an alphabet,next 4 character must be numeric 0-9, & last(10th) character must be an alphabet'
--		ELSE ErrorMessage+','+SPACE(1)+ 'Invalid PAN. PAN length must be 10 characters, first 5 characters must be an alphabet,next 4 character must be numeric 0-9, & last(10th) character must be an alphabet'
--		END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PAN' ELSE ErrorinColumn +','+SPACE(1)+  'PAN' END  
--		--,ErrorinColumn='PAN'    
--		,Srnooferroneousrows=''
--	FROM UploadBuyout V  
--	WHERE ISNULL(V.PAN,'')<>''
--	AND 	V.PAN  not LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]' OR Len(PAN)<>10

--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'Invalid PAN. PAN length must be 10 characters, first 5 characters must be an alphabet,next 4 character must be numeric 0-9, & last(10th) character must be an alphabet'
--		ELSE ErrorMessage+','+SPACE(1)+ 'Invalid PAN. PAN length must be 10 characters, first 5 characters must be an alphabet,next 4 character must be numeric 0-9, & last(10th) character must be an alphabet'
--		END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PAN' ELSE ErrorinColumn +','+SPACE(1)+  'PAN' END  
--		--,ErrorinColumn='PAN'    
--		,Srnooferroneousrows=''
--	FROM UploadBuyout V  
--	WHERE --ISNULL(V.PAN,'')<>'' AND
--	V.PAN  not LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]' OR Len(PAN)<>10

	

--  ---------VALIDATIONS ON Dedupe_ID-UCIC-Enterprise_CIF(NCIF_ID)
  UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(NCIF_Id,'')='' 

-- ----SELECT * FROM UploadBuyout
  
--  UPDATE UploadBuyout
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
--		FROM UploadBuyout V  
-- WHERE ISNULL(V.NCIF_Id,'')<>''
-- AND V.NCIF_Id NOT IN(SELECT NCIF_ID FROM NPA_IntegrationDetails 
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

-- ----SELECT * FROM NPA_IntegrationDetails
   
  print 'NCIF_Id(NCIF_ID)'
--  -------combination
--------	PRINT 'TerritoryAlt_Key'

  UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(NCIF_Id,'') <>'' and LEN(NCIF_Id)>16

 UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(V.NCIF_Id,'') LIKE '%[,!@#$%^&*()+=-_/\]%'

-- -------------------------FOR DUPLICATE NCIF_ID
 IF OBJECT_ID('TEMPDB..#NCIF_ID_DUP') IS NOT NULL
 DROP TABLE #NCIF_ID_DUP

 SELECT * INTO #NCIF_ID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY NCIF_Id ORDER BY  NCIF_Id)AS ROW FROM UploadBuyout
 )A
 WHERE ROW>1

-- UPDATE UploadBuyout
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

-- FROM UploadBuyout V  
-- WHERE ISNULL(NCIF_Id,'') <>'' and NCIF_Id IN(SELECT NCIF_Id FROM #NCIF_ID_DUP)

-- --  ---------VALIDATIONS ON Dedupe ID - UCIC - Enterprise CIF(NCIF_ID)

----------------------------------------------
 /*validations on CustomerName*/
  
  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CustomerName cannot be blank . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'CustomerName cannot be blank . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CustomerName' ELSE   ErrorinColumn +','+SPACE(1)+'CustomerName' END   
		,Srnooferroneousrows=V.SrNo
								--STUFF((SELECT ','+SrNo 
								--FROM UploadBuyout A
								--WHERE A.SrNo IN(SELECT V.SrNo  FROM UploadBuyout V  
								--WHERE ISNULL(SOLID,'')='')
								--FOR XML PATH ('')
								--),1,1,'')
   
   FROM UploadBuyout V  
 WHERE ISNULL(CustomerName,'')=''


  


 
 -- UPDATE UploadBuyout
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid CustomerName.  Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+'Invalid CustomerName.  Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CustomerName' ELSE   ErrorinColumn +','+SPACE(1)+'CustomerName' END       
	--	,Srnooferroneousrows=V.SrNo
	----	STUFF((SELECT ','+SrNo 
	----							FROM UploadBuyout A
	----							WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
 ----WHERE ISNULL(SOLID,'')<>''
 ----AND  LEN(SOLID)>10)
	----							FOR XML PATH ('')
	----							),1,1,'')
   
 --  FROM UploadBuyout V  
 --WHERE ISNULL(CustomerName,'')<>''
 --AND LEN(CustomerName)>20

  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer Name' ELSE ErrorinColumn +','+SPACE(1)+  'Customer Name' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(CustomerName,'') LIKE'%[,!@#$%^&*-_/\()+=]%'

-------------------------------------------------

-------------- VALIDATIONS ON Customer Account No
  UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(AccountNo,'')='' 

-- ----SELECT * FROM UploadBuyout
  
--  UPDATE UploadBuyout
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
--		FROM UploadBuyout V  
-- WHERE ISNULL(V.AccountNo,'')<>''
-- AND V.AccountNo NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
-- )

-- ----SELECT * FROM UploadBuyout
   
  print 'Customer Account No'
--  -------combination
--------	PRINT 'TerritoryAlt_Key'
   
  UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(AccountNo,'') <>'' and LEN(AccountNo)>16

 -- Checking for Standard Accounts or Not
-- UPDATE UploadBuyout
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
--		FROM UploadBuyout V  
-- WHERE ISNULL(V.AccountNo,'')<>''
-- AND V.AccountNo NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
--								WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND AC_AssetClassAlt_Key=1)

-- -------------------------FOR DUPLICATE AccountNo
 IF OBJECT_ID('TEMPDB..#ACID_DUP') IS NOT NULL
 DROP TABLE #ACID_DUP

 SELECT * INTO #ACID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY AccountNo ORDER BY  AccountNo)AS ROW FROM UploadBuyout
 )A
 WHERE ROW>1

 UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(AccountNo,'') <>'' and AccountNo IN(SELECT AccountNo FROM #ACID_DUP)

-- --  ---------VALIDATIONS ON AccountNo

--  ---------VALIDATIONS ON Loan Agreement No

  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'LoanAgreementNo cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'LoanAgreementNo cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'LoanAgreementNo' ELSE ErrorinColumn +','+SPACE(1)+  'LoanAgreementNo' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SrNo 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

FROM UploadBuyout V  
 WHERE ISNULL(LoanAgreementNo,'')='' 
 

-- ----SELECT * FROM UploadBuyout
  
  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid LoanAgreementNo found. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Invalid LoanAgreementNo found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'LoanAgreementNo' ELSE ErrorinColumn +','+SPACE(1)+  'LoanAgreementNo' END  
		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SrNo 
--								--FROM UploadBuyout A
--								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								-- WHERE ISNULL(V.ACID,'')<>''
--								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
--								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
--								--										Timekey=@Timekey
--								--		))
--								--FOR XML PATH ('')
--								--),1,1,'')   
		FROM UploadBuyout V  
 WHERE ISNULL(V.LoanAgreementNo,'')<>'' and LEN(LoanAgreementNo)>25
 --AND V.BuyoutPartyLoanNo NOT IN(SELECT CustomerACID FROM [CurDat].[AdvAcBasicDetail] 
	--							WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
	--					 )


 IF OBJECT_ID('TEMPDB..#DUBLoan') IS NOT NULL
 DROP TABLE #DUBLoan

 SELECT * INTO #DUBLoan FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY LoanAgreementNo ORDER BY LoanAgreementNo ) ROW FROM UploadBuyout
 )X
 WHERE ROW>1
   
 --  UPDATE UploadBuyout
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found.LoanAgreementNo are repeated.  Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Duplicate records found. LoanAgreementNo are repeated.  Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'LoanAgreementNo' ELSE   ErrorinColumn +','+SPACE(1)+'LoanAgreementNo' END     
	--	,Srnooferroneousrows=V.SrNo
	----	STUFF((SELECT ','+SRNO 
	----							FROM #UploadNewAccount A
	----							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
 ----WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
 ------AND SRNO IN(SELECT Srno FROM #DUB2))
 ----AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

	----							FOR XML PATH ('')
	----							),1,1,'')   

 --FROM UploadBuyout V  
 --WHERE ISNULL(LoanAgreementNo,'')<>''
 --AND LoanAgreementNo IN(SELECT LoanAgreementNo FROM #DUBLoan GROUP BY LoanAgreementNo)

-- --  ---------VALIDATIONS ON Loan Agreement No

/*VALIDATIONS ON Indusind Loan Account No */

  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'IndusindLoanAccountNo cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'IndusindLoanAccountNo cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'IndusindLoanAccountNo' ELSE ErrorinColumn +','+SPACE(1)+  'IndusindLoanAccountNo' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SrNo 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
--								----				WHERE ISNULL(ACID,'')='' )
--								----FOR XML PATH ('')
--								----),1,1,'')   

FROM UploadBuyout V  
 WHERE ISNULL(IndusindLoanAccountNo,'')='' 
 

-- ----SELECT * FROM UploadBuyout
  
--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid IndusindLoanAccountNo found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid IndusindLoanAccountNo found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'IndusindLoanAccountNo' ELSE ErrorinColumn +','+SPACE(1)+  'IndusindLoanAccountNo' END  
--		,Srnooferroneousrows=V.SrNo
----								--STUFF((SELECT ','+SrNo 
----								--FROM UploadBuyout A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								-- WHERE ISNULL(V.ACID,'')<>''
----								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
----								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----								--										Timekey=@Timekey
----								--		))
----								--FOR XML PATH ('')
----								--),1,1,'')   
--		FROM UploadBuyout V  
-- WHERE ISNULL(V.IndusindLoanAccountNo,'')<>''
-- AND V.IndusindLoanAccountNo NOT IN(SELECT CustomerACID FROM [CurDat].[AdvAcBasicDetail] 
--								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
						 --)


 IF OBJECT_ID('TEMPDB..#DUB2') IS NOT NULL
 DROP TABLE #DUB2

 SELECT * INTO #DUB2 FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY IndusindLoanAccountNo ORDER BY IndusindLoanAccountNo ) ROW FROM UploadBuyout
 )X
 WHERE ROW>1
   
 --  UPDATE UploadBuyout
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found.IndusindLoanAccountNo are repeated.  Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Duplicate records found. IndusindLoanAccountNo are repeated.  Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'IndusindLoanAccountNo' ELSE   ErrorinColumn +','+SPACE(1)+'IndusindLoanAccountNo' END     
	--	,Srnooferroneousrows=V.SrNo
	----	STUFF((SELECT ','+SRNO 
	----							FROM #UploadNewAccount A
	----							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
 ----WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
 ------AND SRNO IN(SELECT Srno FROM #DUB2))
 ----AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

	----							FOR XML PATH ('')
	----							),1,1,'')   

 --FROM UploadBuyout V  
 --WHERE ISNULL(IndusindLoanAccountNo,'')<>''
 --AND IndusindLoanAccountNo IN(SELECT IndusindLoanAccountNo FROM #DUB2 GROUP BY IndusindLoanAccountNo)

 /*validations on TotalOutstanding */

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'TotalOutstanding cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'TotalOutstanding cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'TotalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'TotalOutstanding' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								----WHERE ISNULL(InterestReversalAmount,'')='')
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(TotalOutstanding,'')=''

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid TotalOutstanding. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid TotalOutstanding. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'TotalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'TotalOutstanding' END  
		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SRNO 
--								--FROM UploadBuyout A
--								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
--								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
--								--)
--								--FOR XML PATH ('')
--								--),1,1,'')   

 FROM UploadBuyout V  
 WHERE (ISNUMERIC(TotalOutstanding)=0 AND ISNULL(TotalOutstanding,'')<>'') OR 
 ISNUMERIC(TotalOutstanding) LIKE '%^[0-9]%'
 PRINT 'INVALID TotalOutstanding' 

-- update UploadBuyout
--  set TotalOutstanding=NULL
--  --WHERE (ISNUMERIC(TotalOutstanding)=0 AND ISNULL(TotalOutstanding,'')<>'') OR  ISNUMERIC(TotalOutstanding) LIKE '%^[0-9]%'
--  WHERE
--  (CASE WHEN ISNULL(TotalOutstanding,'')<>'' AND  ISNUMERIC(TotalOutstanding)=1 
--               THEN CASE WHEN CHARINDEX('.',TotalOutstanding) <> 0 AND CHARINDEX('.',TotalOutstanding)-1 > 16 THEN 1
--						  WHEN CHARINDEX('.',TotalOutstanding) = 0 AND LEN(TotalOutstanding)>18 
--						  THEN 1 ELSE 0	END
--			             --THEN 1 ELSE 0 END 
--			   ELSE 2 END)=1

--update UploadBuyout
--  set PrincipalOutstanding=NULL
--  --WHERE (ISNUMERIC(PrincipalOutstanding)=0 AND ISNULL(PrincipalOutstanding,'')<>'') OR  ISNUMERIC(PrincipalOutstanding) LIKE '%^[0-9]%'
--  WHERE
--  (CASE WHEN ISNULL(PrincipalOutstanding,'')<>'' AND  ISNUMERIC(PrincipalOutstanding)=1 
--               THEN CASE WHEN CHARINDEX('.',PrincipalOutstanding) <> 0 AND CHARINDEX('.',PrincipalOutstanding)-1 > 16 THEN 1
--						  WHEN CHARINDEX('.',PrincipalOutstanding) = 0 AND LEN(PrincipalOutstanding)>18 
--						  THEN 1 ELSE 0	END
--			             --THEN 1 ELSE 0 END 
--			   ELSE 2 END)=1

--update UploadBuyout
--  set UnrealizedInterest=NULL
--  --WHERE (ISNUMERIC(UnrealizedInterest)=0 AND ISNULL(UnrealizedInterest,'')<>'') OR  ISNUMERIC(UnrealizedInterest) LIKE '%^[0-9]%'
--  WHERE
--  (CASE WHEN ISNULL(UnrealizedInterest,'')<>'' AND  ISNUMERIC(UnrealizedInterest)=1 
--               THEN CASE WHEN CHARINDEX('.',UnrealizedInterest) <> 0 AND CHARINDEX('.',UnrealizedInterest)-1 > 16 THEN 1
--						  WHEN CHARINDEX('.',UnrealizedInterest) = 0 AND LEN(UnrealizedInterest)>18 
--						  THEN 1 ELSE 0	END
--			             --THEN 1 ELSE 0 END 
--			   ELSE 2 END)=1

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'TotalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'TotalOutstanding' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(TotalOutstanding,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Total Outstanding. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid TotalOutstanding. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Total Outstanding' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
--								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
--								---- )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(TotalOutstanding,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND CONVERT(DECIMAL(18,2),ISNULL(TotalOutstanding,0)) <0

  ------------------ VALIDATING THE TOTALSALE=PRINCIPAL+INTEREST or Not
 UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Total Outstanding Should be the SUM of Principal Outstanding
												and the Unrealized Interest. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Total Outstanding Should be the SUM of Principal Outstanding
												and the Unrealized Interest. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Total Outstanding' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadBuyout V  
 WHERE  (CASE WHEN (TotalOutstanding<>'' AND  ISNUMERIC(TotalOutstanding)=1) AND (PrincipalOutstanding<>'' AND  ISNUMERIC(PrincipalOutstanding)=1)
              AND (UnrealizedInterest<>'' AND  ISNUMERIC(UnrealizedInterest)=1)
               THEN CASE WHEN CAST(ISNULL(TotalOutstanding,0) AS DECIMAL(18,2)) <> (CAST(ISNULL(PrincipalOutstanding,0) AS DECIMAL(18,2)) 
			   + CAST(ISNULL(UnrealizedInterest,0) AS DECIMAL(18,2)))
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Total Outstanding. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Total Outstanding. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Total Outstanding' ELSE ErrorinColumn +','+SPACE(1)+  'Total Outstanding' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE  (CASE WHEN ISNULL(TotalOutstanding,'')<>'' AND  ISNUMERIC(TotalOutstanding)=1 
               THEN CASE WHEN CHARINDEX('.',TotalOutstanding) <> 0 AND CHARINDEX('.',TotalOutstanding)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',TotalOutstanding) = 0 AND LEN(TotalOutstanding)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 -----------------------------------------------------------------

 /*validations on PrincipalOutstanding */

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'PrincipalOutstanding cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'PrincipalOutstanding cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								----WHERE ISNULL(InterestReversalAmount,'')='')
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(PrincipalOutstanding,'')=''

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid PrincipalOutstanding. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid PrincipalOutstanding. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SRNO 
--								--FROM UploadBuyout A
--								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
--								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
--								--)
--								--FOR XML PATH ('')
--								--),1,1,'')   

 FROM UploadBuyout V  
 WHERE (ISNUMERIC(PrincipalOutstanding)=0 AND ISNULL(PrincipalOutstanding,'')<>'') OR 
 ISNUMERIC(PrincipalOutstanding) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(PrincipalOutstanding,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid PrincipalOutstanding. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid PrincipalOutstanding. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
--								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
--								---- )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(PrincipalOutstanding,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(PrincipalOutstanding,0)) <0

  UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE  (CASE WHEN ISNULL(PrincipalOutstanding,'')<>'' AND  ISNUMERIC(PrincipalOutstanding)=1 
               THEN CASE WHEN CHARINDEX('.',PrincipalOutstanding) <> 0 AND CHARINDEX('.',PrincipalOutstanding)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',PrincipalOutstanding) = 0 AND LEN(PrincipalOutstanding)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1 

/*validations on UnrealizedInterest */

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'UnrealizedInterest cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'UnrealizedInterest cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								----WHERE ISNULL(InterestReversalAmount,'')='')
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(UnrealizedInterest,'')=''

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid UnrealizedInterest. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid UnrealizedInterest. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SRNO 
--								--FROM UploadBuyout A
--								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
--								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
--								--)
--								--FOR XML PATH ('')
--								--),1,1,'')   

 FROM UploadBuyout V  
 WHERE (ISNUMERIC(UnrealizedInterest)=0 AND ISNULL(UnrealizedInterest,'')<>'') OR 
 ISNUMERIC(UnrealizedInterest) LIKE '%^[0-9]%'
 PRINT 'INVALID UnrealizedInterest' 

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(UnrealizedInterest,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid UnrealizedInterest. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid UnrealizedInterest. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
--								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
--								---- )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(UnrealizedInterest,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(UnrealizedInterest,0)) <0

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Unrealized Interest. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Unrealized Interest. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Unrealized Interest' ELSE ErrorinColumn +','+SPACE(1)+  'Unrealized Interest' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE  (CASE WHEN ISNULL(UnrealizedInterest,'')<>'' AND  ISNUMERIC(UnrealizedInterest)=1 
               THEN CASE WHEN CHARINDEX('.',UnrealizedInterest) <> 0 AND CHARINDEX('.',UnrealizedInterest)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',UnrealizedInterest) = 0 AND LEN(UnrealizedInterest)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1 
  ----------------------------------------------------
/*validations on Asset Classification */

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'AssetClassification is mandatory. Kindly check and upload again' 
						ELSE ErrorMessage+','+SPACE(1)+ 'AssetClassification is mandatory. Kindly check and upload again'	END
		,ErrorinColumn='AssetClass'    
		,Srnooferroneousrows=''
	FROM UploadBuyout V  
	WHERE ISNULL(v.AssetClassification,'')=''  

  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid AssetClassification.  Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Invalid AssetClassification.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AssetClassification' ELSE   ErrorinColumn +','+SPACE(1)+'AssetClassification' END       
		,Srnooferroneousrows=V.SrNo
	--	STUFF((SELECT ','+SrNo 
	--							FROM UploadBuyout A
	--							WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
 --WHERE ISNULL(SOLID,'')<>''
 --AND  LEN(SOLID)>10)
	--							FOR XML PATH ('')
	--							),1,1,'')
   
   FROM UploadBuyout V  
   LEFT JOIN DimAssetClass B
   ON V.AssetClassification=B.AssetClassShortName
   AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
 WHERE ISNULL(V.AssetClassification,'')<>''
 AND B.AssetClassName IS NULL
 --WHERE ISNULL(AssetClassification,'')<>''
 --AND LEN(CustomerName)>20

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Asset Classification found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Asset Classification found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Asset Classification' ELSE ErrorinColumn +','+SPACE(1)+  'Asset Classification' END  
		,Srnooferroneousrows=V.SRNO
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadWriteOff A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
--								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(AssetClassification,'') <>'' and LEN(AssetClassification)>3

  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AssetClassification' ELSE ErrorinColumn +','+SPACE(1)+  'AssetClassification' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(AssetClassification,'') LIKE'%[,!@#$%^&*-_/\()+=]%'

 ----------- /*validations on NPA_Date */

 --UPDATE UploadBuyout
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA_Date Can not be Blank . Please enter the DateOfSaletoARC and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'NPA_Date Can not be Blank. Please enter the DateOfSaletoARC and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA_Date' ELSE   ErrorinColumn +','+SPACE(1)+'NPA_Date' END      
	--	,Srnooferroneousrows=V.SrNo
	--	--STUFF((SELECT ','+SRNO 
	--	--						FROM #UploadNewAccount A
	--	--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
	--	--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
	--	--										)
	--	--						FOR XML PATH ('')
	--	--						),1,1,'')   

 --FROM UploadBuyout V  
 --WHERE ISNULL(NPADate,'')='' 

 SET DATEFORMAT DMY
UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA_Date' ELSE   ErrorinColumn +','+SPACE(1)+'NPA_Date' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										  WHERE ISNULL(NPADate,'')<>'' AND (CAST(ISNULL(NPADate ,'')AS Varchar(10))<>FORMAT(cast(NPADate as date),'dd-MM-yyyy'))

		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(NPADate,'')<>'' AND ISDATE(NPADate)=0

 -- Checking for NPA Date is Mandatory When Asset Classification is either of SUB / DB1 / DB2 / DB3 / LOS.
UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA Date is mandatory since Asset class is set as SUB/DB1/DB2/DB3/LOS/WO. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'NPA Date is mandatory since Asset class is set as SUB/DB1/DB2/DB3/LOS/WO. Kindly check and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA Date' ELSE   ErrorinColumn +','+SPACE(1)+'NPA Date' END      
		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SRNO 
--								--FROM UploadWriteOff A
--								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
--								-- WHERE ISNULL(V.ACID,'')<>''
--								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
--								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
--								--										Timekey=@Timekey
--								--		))
--								--FOR XML PATH ('')
--								--),1,1,'') 
 FROM UploadBuyout V  
 WHERE ISNULL(V.AssetClassification,'') IN('SUB','DB1','DB2','DB3','LOS','WO') AND (V.NPADate)=''

  ----- AsOnDate Comparison
 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA Date Should be Less than or Equal to AsOnDate. Please enter the MOC NPA Date and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'NPA Date Should be Less than or Equal to AsOnDate. Please enter the MOC NPA Date and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA Date' ELSE   ErrorinColumn +','+SPACE(1)+'NPA Date' END      
		,Srnooferroneousrows=V.SrNo
		--STUFF((SELECT ','+SRNO 
		--						FROM #UploadNewAccount A
		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
		--										)
		--						FOR XML PATH ('')
		--						),1,1,'')   

 FROM UploadBuyout V  
 --WHERE ISNULL(MOC_NPADate,'')<>'' AND  (CONVERT(date,MOC_NPADate,103) > CONVERT(date,AsOnDate,103))
 WHERE  (CASE WHEN ISNULL(NPADate,'')<>'' AND  ISDATE(NPADate)=1 
               THEN CASE WHEN CONVERT(date,NPADate) > CONVERT(date,AsOnDate) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

 ---------- Checking for NPA Date should not be present if Asset classification is STD
UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA Date must be blank since Asset class is STD. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'NPA Date must be blank since Asset class is STD. Kindly check and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA Date' ELSE   ErrorinColumn +','+SPACE(1)+'NPA Date' END      
		,Srnooferroneousrows=V.SrNo
		  

 FROM UploadBuyout V  
 WHERE (ISNULL(V.AssetClassification,'') IN('STD') or ISNULL(V.AssetClassification,'') IS NULL) AND (V.NPADate)<>''

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA Date' ELSE ErrorinColumn +','+SPACE(1)+  'NPA Date' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   
--select *
 FROM UploadBuyout V  
 WHERE ISNULL(NPADate,'')  LIKE '%[,!@#$%^&*()_+=\]%'

--------------------------------------------------------------------------
 /*validations on DPD */

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'DPD cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'DPD cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								----WHERE ISNULL(InterestReversalAmount,'')='')
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(DPD,'')=''

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid DPD. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid DPD. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SRNO 
--								--FROM UploadBuyout A
--								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
--								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
--								--)
--								--FOR XML PATH ('')
--								--),1,1,'')   

 FROM UploadBuyout V  
 WHERE (ISNUMERIC(DPD)=0 AND ISNULL(DPD,'')<>'') OR 
 ISNUMERIC(DPD) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(DPD,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid DPD. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid DPD. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
--								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
--								---- )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(DPD,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(DPD,0)) <0 
 
 UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid DPD. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid DPD. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
		,Srnooferroneousrows=V.SrNo


 FROM UploadBuyout V  
 WHERE ISNULL(DPD,'')<>''

 AND   LEN(DPD) >5 
-----------------------------------------------------------
/*validations on Security Amount */

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'SecurityAmount cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'SecurityAmount cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								----WHERE ISNULL(InterestReversalAmount,'')='')
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(SecurityAmount,'')=''

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid SecurityAmount. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid SecurityAmount. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SRNO 
--								--FROM UploadBuyout A
--								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
--								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
--								--)
--								--FOR XML PATH ('')
--								--),1,1,'')   

 FROM UploadBuyout V  
 WHERE (ISNUMERIC(SecurityAmount)=0 AND ISNULL(SecurityAmount,'')<>'') OR 
 ISNUMERIC(SecurityAmount) LIKE '%^[0-9]%'
 PRINT 'INVALID SecurityAmount' 

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
--								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
--								----)
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(SecurityAmount,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid SecurityAmount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid SecurityAmount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
		,Srnooferroneousrows=V.SrNo
--								----STUFF((SELECT ','+SRNO 
--								----FROM UploadBuyout A
--								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
--								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
--								---- )
--								----FOR XML PATH ('')
--								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE ISNULL(SecurityAmount,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(SecurityAmount,0)) <0

   UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Security Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Security Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Security Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Security Amount' END  
		,Srnooferroneousrows=V.SRNO
								----STUFF((SELECT ','+SRNO 
								----FROM UploadAccountMOC A
								----WHERE A.SrNo IN(SELECT SRNO FROM UploadAccountMOC WHERE ISNULL(InterestReversalAmount,'')<>''
								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
								---- )
								----FOR XML PATH ('')
								----),1,1,'')   

 FROM UploadBuyout V  
 WHERE  (CASE WHEN ISNULL(SecurityAmount,'')<>'' AND  ISNUMERIC(SecurityAmount)=1 
               THEN CASE WHEN CHARINDEX('.',SecurityAmount) <> 0 AND CHARINDEX('.',SecurityAmount)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',SecurityAmount) = 0 AND LEN(SecurityAmount)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1 

 ---------- Validations for Action
 UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE ISNULL(Action,'')=''

 UPDATE UploadBuyout
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

 FROM UploadBuyout V  
 WHERE Action NOT IN('A','D')


 -----------------------------------------
 -----------------------------------------------------------
/*validations on Additional Provision Amount */

 --UPDATE UploadBuyout
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Additional Provision Amount cannot be blank. Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Additional Provision Amount cannot be blank. Please check the values and upload again'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AdditionalProvisionAmount' ELSE ErrorinColumn +','+SPACE(1)+  'AdditionalProvisionAmount' END  
	--	,Srnooferroneousrows=V.SrNo


 --FROM UploadBuyout V  
 --WHERE ISNULL(AdditionalProvisionAmount,'')=''

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Additional Provision Amount. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Additional Provision Amount. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Amount' END  
		,Srnooferroneousrows=V.SrNo
  

 FROM UploadBuyout V  
 WHERE (ISNUMERIC(AdditionalProvisionAmount)=0 AND ISNULL(AdditionalProvisionAmount,'')<>'') OR 
 ISNUMERIC(AdditionalProvisionAmount) LIKE '%^[0-9]%'
 PRINT 'INVALID SecurityAmount' 

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Amount' END  
		,Srnooferroneousrows=V.SrNo
  

 FROM UploadBuyout V  
 WHERE ISNULL(AdditionalProvisionAmount,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Additional Provision Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Additional Provision Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Amount' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadBuyout V  
 WHERE ISNULL(AdditionalProvisionAmount,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(AdditionalProvisionAmount,0)) <0

   UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Additional Provision Amount. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Additional Provision Amount. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Amount' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Amount' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadBuyout V  
 WHERE  (CASE WHEN ISNULL(AdditionalProvisionAmount,'')<>'' AND  ISNUMERIC(AdditionalProvisionAmount)=1 
               THEN CASE WHEN CHARINDEX('.',AdditionalProvisionAmount) <> 0 AND CHARINDEX('.',AdditionalProvisionAmount)-1 > 16 THEN 1
						  WHEN CHARINDEX('.',AdditionalProvisionAmount) = 0 AND LEN(AdditionalProvisionAmount)>18 
						  THEN 1 ELSE 0	END
			             --THEN 1 ELSE 0 END 
			   ELSE 2 END)=1 


 ---------- Validations for Secured Status===========================================================
 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Secured Status cannot be blank. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Secured Status cannot be blank. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Secured Status' ELSE ErrorinColumn +','+SPACE(1)+  'Secured Status' END  
		,Srnooferroneousrows=V.SrNo


 FROM UploadBuyout V  
 WHERE ISNULL(SecuredStatus,'')=''

 UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Secured Status. Please check the values (Y OR N) and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Action. Please check the values(Y OR N) and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Secured Status' ELSE ErrorinColumn +','+SPACE(1)+  'Secured Status' END  
		,Srnooferroneousrows=V.SrNo
 

 FROM UploadBuyout V  
 WHERE SecuredStatus NOT IN('Y','N')

 ----------------------------===================================================
 ------ -------validations on Accelerated Provision Percentage
 
  UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Accelerated Provision Percentage. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Accelerated Provision Percentage. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Accelerated Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Accelerated Provision Percentage' END  
		,Srnooferroneousrows=V.SRNO
								

 FROM UploadBuyout V  
 WHERE (ISNUMERIC(AcceleratedProvisionPercentage)=0 AND ISNULL(AcceleratedProvisionPercentage,'')<>'') OR 
 ISNUMERIC(AcceleratedProvisionPercentage) LIKE '%^[0-9]%'

 UPDATE UploadBuyout
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Accelerated Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Accelerated Provision Percentage' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadBuyout V  
 WHERE ISNULL(AcceleratedProvisionPercentage,'') LIKE'%[,!@#$%^&*()_-+=/\]%'
 PRINT 'INVALID' 

  UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Accelerated Provision Percentage. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Accelerated Provision Percentage. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Accelerated Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Accelerated Provision Percentage' END  
		,Srnooferroneousrows=V.SRNO
								 

 FROM UploadBuyout V  
 WHERE ISNULL(AcceleratedProvisionPercentage,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(6,2),ISNULL(AcceleratedProvisionPercentage,0)) <0

 UPDATE UploadBuyout
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Accelerated Provision Percentage Should be less than 100. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Accelerated Provision Percentage Should be less than 100. Kindly check and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Accelerated Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Accelerated Provision Percentage' END  
		,Srnooferroneousrows=V.SrNo
--							

 FROM UploadBuyout V  
 WHERE ISNULL(AcceleratedProvisionPercentage,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(AcceleratedProvisionPercentage,0))>100
 --AND TRY_CONVERT(Decimal(6,2),ISNULL(Additionalprovisionpercentage,0))>100
 --AND CAST(ISNULL(Additionalprovisionpercentage,0.00) AS decimal) > 100.00

 

--------------------------------------================================================-----------------------------------------------


 Print '123'
 goto valid

  END
	
   ErrorData:  
   print 'no'  

		SELECT *,'Data'TableName
		FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		return

   valid:
		IF NOT EXISTS(Select 1 from  BuyoutDetails_Stg WHERE filname=@FilePathUpload)
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
			FROM UploadBuyout 

			--PRINT 'VALIDATION ERRORS'
			
		--	----SELECT * FROM UploadBuyout 

		--	--ORDER BY ErrorMessage,UploadBuyout.ErrorinColumn DESC
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
	Print 'Validation=Y'
    Update UploadStatus Set ValidationOfData='Y',ValidationOfDataCompletedOn=GetDate()   
    where FileNames=@filepath  
  
   END  


  final:
  Print 'ERR'
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

		 IF EXISTS(SELECT 1 FROM BuyoutDetails_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM BuyoutDetails_Stg
		 WHERE filname=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.BuyoutDetails_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
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

	----SELECT * FROM UploadBuyout

	print 'p'
  ------to delete file if it has errors
		--if exists(Select  1 from dbo.MasterUploadData where FileNames=@filepath and ISNULL(ErrorData,'')<>'')
		--begin
		--print 'ppp'
		-- IF EXISTS(SELECT 1 FROM BuyoutDetails_stg WHERE FileName=@FilePathUpload)
		-- BEGIN
		-- print '123'
		-- DELETE FROM BuyoutDetails_stg
		-- WHERE FileName=@FilePathUpload

		-- PRINT 'ROWS DELETED FROM DBO.BuyoutDetails_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		-- END
		-- END

   
END  TRY
  
  BEGIN CATCH
	

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()

	IF EXISTS(SELECT 1 FROM BuyoutDetails_stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM BuyoutDetails_stg
		 WHERE filname=@FilePathUpload

		 PRINT 'ROWS DELETED FROM DBO.BuyoutDetails_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

END CATCH

END

GO