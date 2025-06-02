SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ValidateExcel_DataUpload_BuyOutUpload_12082021] 
@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='fnachecker',  
@Timekey INT=49999
,@filepath VARCHAR(MAX) ='BuyoutUPLOAD.xlsx'  
WITH RECOMPILE  
AS  



--DECLARE  
  
--@MenuID INT=1466,  
--@UserLoginId varchar(20)=N'2ndlvlchecker',  
--@Timekey int=N'25999'
--,@filepath varchar(500)=N'BuyoutUpload (3).xlsx'  
  
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


IF (@MenuID=99)	
BEGIN


	  -- IF OBJECT_ID('tempdb..#UploadBuyout') IS NOT NULL  
	  --BEGIN  
	  -- DROP TABLE #UploadBuyout  
	
	  --END
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
		,UnrealizedInterest,PrincipalOutstanding,AssetClassification,NPADate,DPD,SecurityAmount,Action'    
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
--	print 'Validation Error Message for SRNO'
--	 UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 	'SrNo is mandatory. Kindly check and upload again' 
--		                  ELSE ErrorMessage+','+SPACE(1)+ 'SrNo is mandatory. Kindly check and upload again'
--		  END
--		,ErrorinColumn='SRNO'    
--		,Srnooferroneousrows=''
--	FROM UploadBuyout V  
--	WHERE ISNULL(v.SrNo,'')=''  
--	 Print '1'

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid SrNo, kindly check and upload again'     
--								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid SrNo, kindly check and upload again'      END
--		,ErrorinColumn='SRNO'    
--		,Srnooferroneousrows=SrNo
		
-- FROM UploadBuyout V  
-- WHERE ISNULL(v.SrNo,'')='0'  OR ISNUMERIC(v.SrNo)=0
--  Print '2'
  
--  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
--  DROP TABLE #R

--  SELECT * INTO #R FROM(
--  SELECT *,ROW_NUMBER() OVER(PARTITION BY SrNo ORDER BY SrNo)ROW
--   FROM UploadBuyout
--   )A
--   WHERE ROW>1

-- PRINT 'Duplicate SRNO'  


--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate SrNo, kindly check and upload again' 
--					ELSE ErrorMessage+','+SPACE(1)+     'Duplicate SrNo, kindly check and upload again' END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SrNo' ELSE ErrorinColumn +','+SPACE(1)+  'SrNo' END
--		,Srnooferroneousrows=SrNo
--		--STUFF((SELECT DISTINCT ','+SrNo 
--		--						FROM UploadBuyout
--		--						FOR XML PATH ('')
--		--						),1,1,'')
         
		
-- FROM UploadBuyout V  
--	WHERE  V.SrNo IN(SELECT SrNo FROM #R )
--	Print '3'

------------- /* Validations on AsOnDate Date
--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Can not be Blank . Please enter the AsOnDate and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Can not be Blank. Please enter the AsOnDate and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
--		,Srnooferroneousrows=V.SrNo
--		--STUFF((SELECT ','+SRNO 
--		--						FROM #UploadNewAccount A
--		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
--		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
--		--										)
--		--						FOR XML PATH ('')
--		--						),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(AsOnDate,'')='' 


--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
--		,Srnooferroneousrows=V.SrNo
--		--STUFF((SELECT ','+SRNO 
--		--						FROM #UploadNewAccount A
--		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
--		--										  WHERE ISNULL(NPADate,'')<>'' AND (CAST(ISNULL(NPADate ,'')AS Varchar(10))<>FORMAT(cast(NPADate as date),'dd-MM-yyyy'))

--		--										)
--		--						FOR XML PATH ('')
--		--						),1,1,'')   
-- FROM UploadBuyout V  
-- WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0


-- ----- Future Date Comparison
-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Should not be Future Date . Please enter the AsOnDate and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Should not be Future Date. Please enter the AsOnDate and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
--		,Srnooferroneousrows=V.SrNo
--		--STUFF((SELECT ','+SRNO 
--		--						FROM #UploadNewAccount A
--		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
--		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
--		--										)
--		--						FOR XML PATH ('')
--		--						),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(AsOnDate,'')<>'' AND  CONVERT(date,AsOnDate,103) > CONVERT(date,GETDATE(),103)


-- ---------------------------------
 
-- ---------------------@AsOnDateCnt--------------------------Satwaji 08-06-2021
-- --DECLARE @AsOnDateCnt int=0
-- ----DROP TABLE IF EXISTS WriteOffDateData
-- --IF OBJECT_ID('AsOnDateData') IS NOT NULL  
--	--  BEGIN
	    
--	--	DROP TABLE  AsOnDateData
	
--	--  END

-- --SELECT * into AsOnDateData  FROM(
-- --SELECT ROW_NUMBER() OVER(PARTITION BY UploadID  ORDER BY  UploadID ) 
-- --ROW ,UploadID,AsOnDate FROM UploadBuyout
-- --)X
-- --WHERE ROW=1


-- --SELECT @AsOnDateCnt=COUNT(*) 
-- --FROM AsOnDateData a
-- --INNER JOIN UploadBuyout b
-- --ON a.UploadID=b.UploadID 
-- --WHERE a.AsOnDate<>b.AsOnDate

-- --IF @AsOnDateCnt>0
-- --BEGIN
-- -- PRINT 'AsOnDate ERROR'
-- -- /*AsOnDate Validation*/ --Satwaji 12-06-2021
-- -- UPDATE UploadBuyout
--	--SET  
-- --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'UploadID found different Dates of AsOnDate. Please check the values and upload again'     
--	--					ELSE ErrorMessage+','+SPACE(1)+ 'UploadID found different Dates of AsOnDate. Please check the values and upload again'     END
--	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END     
--	--	,Srnooferroneousrows=V.SrNo
--	----	STUFF((SELECT ','+SRNO 
--	----							FROM #UploadNewAccount A
--	----							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
-- ----WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
-- ------AND SRNO IN(SELECT Srno FROM #DUB2))
-- ----AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

--	----							FOR XML PATH ('')
--	----							),1,1,'')   

-- --FROM UploadBuyout V  
-- --WHERE ISNULL(UploadID,'')<>''
-- --AND  AccountNo IN(
--	--			 SELECT DISTINCT B.AccountNo from AsOnDateData a
--	--			 INNER JOIN UploadBuyout b
--	--			 on a.UploadID=b.UploadID 
--	--			 where a.AsOnDate<>b.AsOnDate
--	--			 )

--/*------------------- Validations on PAN -------------------- Satwaji 12-06-2021 */

----UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'The column ‘PAN’ is mandatory. Kindly check and upload again' 
----					ELSE ErrorMessage+','+SPACE(1)+ 'PAN is mandatory. Kindly check and upload again'	END
----		,ErrorinColumn='PAN'    
----		,Srnooferroneousrows=''
----	FROM UploadBuyout V  
----	WHERE V.PAN IN(SELECT PAN FROM NPA_IntegrationDetails
----								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
----						 )

--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'PAN can not be blank. Kindly check and upload again' 
--					ELSE ErrorMessage+','+SPACE(1)+ 'PAN can not be blank. Kindly check and upload again'	END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PAN' ELSE ErrorinColumn +','+SPACE(1)+  'PAN' END  
--		--,ErrorinColumn='PAN'    
--		,Srnooferroneousrows=''
--	FROM UploadBuyout V  
--	WHERE ISNULL(V.PAN,'')=''


----UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'Invalid PAN. PAN length must be 10 characters, first 5 characters must be an alphabet,next 4 character must be numeric 0-9, & last(10th) character must be an alphabet'
----		ELSE ErrorMessage+','+SPACE(1)+ 'Invalid PAN. PAN length must be 10 characters, first 5 characters must be an alphabet,next 4 character must be numeric 0-9, & last(10th) character must be an alphabet'
----		END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PAN' ELSE ErrorinColumn +','+SPACE(1)+  'PAN' END  
----		--,ErrorinColumn='PAN'    
----		,Srnooferroneousrows=''
----	FROM UploadBuyout V  
----	WHERE ISNULL(V.PAN,'')<>''
----	AND 	V.PAN  not LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]' OR Len(PAN)<>10

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

	

----  ---------VALIDATIONS ON Dedupe_ID-UCIC-Enterprise_CIF(NCIF_ID)
--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadWriteOff A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
----								----				WHERE ISNULL(ACID,'')='' )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(NCIF_Id,'')='' 

---- ----SELECT * FROM UploadBuyout
  
----  UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
----						ELSE ErrorMessage+','+SPACE(1)+'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
----		,Srnooferroneousrows=V.SRNO
------								--STUFF((SELECT ','+SRNO 
------								--FROM UploadWriteOff A
------								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
------								-- WHERE ISNULL(V.ACID,'')<>''
------								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
------								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
------								--										Timekey=@Timekey
------								--		))
------								--FOR XML PATH ('')
------								--),1,1,'')   
----		FROM UploadBuyout V  
---- WHERE ISNULL(V.NCIF_Id,'')<>''
---- AND V.NCIF_Id NOT IN(SELECT NCIF_ID FROM NPA_IntegrationDetails 
----								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
---- )

---- ----SELECT * FROM NPA_IntegrationDetails
   
--  print 'NCIF_Id(NCIF_ID)'
----  -------combination
----------	PRINT 'TerritoryAlt_Key'

--UPDATE UploadSaletoARC
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not not are allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadSaletoARC V  
-- WHERE ISNULL(NCIF_Id,'') LIKE'%[,!@#$%^&*()+=-_/\]%'
   
--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadWriteOff A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(NCIF_Id,'') <>'' and LEN(NCIF_Id)>16

---- -------------------------FOR DUPLICATE NCIF_ID
-- IF OBJECT_ID('TEMPDB..#NCIF_ID_DUP') IS NOT NULL
-- DROP TABLE #NCIF_ID_DUP

-- SELECT * INTO #NCIF_ID_DUP FROM(
-- SELECT *,ROW_NUMBER() OVER(PARTITION BY NCIF_Id ORDER BY  NCIF_Id)AS ROW FROM UploadBuyout
-- )A
-- WHERE ROW>1

---- UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Dedupe_ID-UCIC-Enterprise_CIF ID are repeated.  Please check the values and upload again'     
----					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Dedupe_ID-UCIC-Enterprise_CIF ID are repeated.  Please check the values and upload again'     END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
----		,Srnooferroneousrows=V.SRNO
------								----STUFF((SELECT ','+SRNO 
------								----FROM UploadWriteOff A
------								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
------								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
------								----FOR XML PATH ('')
------								----),1,1,'')   

---- FROM UploadBuyout V  
---- WHERE ISNULL(NCIF_Id,'') <>'' and NCIF_Id IN(SELECT NCIF_Id FROM #NCIF_ID_DUP)

---- --  ---------VALIDATIONS ON Dedupe ID - UCIC - Enterprise CIF(NCIF_ID)

------------------------------------------------
-- /*validations on CustomerName*/
  
--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CustomerName cannot be blank . Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'CustomerName cannot be blank . Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CustomerName' ELSE   ErrorinColumn +','+SPACE(1)+'CustomerName' END   
--		,Srnooferroneousrows=V.SrNo
--								--STUFF((SELECT ','+SrNo 
--								--FROM UploadBuyout A
--								--WHERE A.SrNo IN(SELECT V.SrNo  FROM UploadBuyout V  
--								--WHERE ISNULL(SOLID,'')='')
--								--FOR XML PATH ('')
--								--),1,1,'')
   
--   FROM UploadBuyout V  
-- WHERE ISNULL(CustomerName,'')=''


  


 
-- -- UPDATE UploadBuyout
--	--SET  
-- --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid CustomerName.  Please check the values and upload again'     
--	--					ELSE ErrorMessage+','+SPACE(1)+'Invalid CustomerName.  Please check the values and upload again'     END
--	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CustomerName' ELSE   ErrorinColumn +','+SPACE(1)+'CustomerName' END       
--	--	,Srnooferroneousrows=V.SrNo
--	----	STUFF((SELECT ','+SrNo 
--	----							FROM UploadBuyout A
--	----							WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
-- ----WHERE ISNULL(SOLID,'')<>''
-- ----AND  LEN(SOLID)>10)
--	----							FOR XML PATH ('')
--	----							),1,1,'')
   
-- --  FROM UploadBuyout V  
-- --WHERE ISNULL(CustomerName,'')<>''
-- --AND LEN(CustomerName)>20

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer Name' ELSE ErrorinColumn +','+SPACE(1)+  'Customer Name' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(CustomerName,'') LIKE'%[,!@#$%^&*-_/\()+=]%'

---------------------------------------------------

---------------- VALIDATIONS ON Customer Account No
--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Account ID cannot be blank.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'Account ID cannot be blank.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadWriteOff A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V  
----								----				WHERE ISNULL(ACID,'')='' )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(AccountNo,'')='' 

---- ----SELECT * FROM UploadBuyout
  
----  UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Account ID found. Please check the values and upload again'     
----						ELSE ErrorMessage+','+SPACE(1)+'Invalid Account ID found. Please check the values and upload again'     END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
----		,Srnooferroneousrows=V.SRNO
------								--STUFF((SELECT ','+SRNO 
------								--FROM UploadWriteOff A
------								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
------								-- WHERE ISNULL(V.ACID,'')<>''
------								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
------								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
------								--										Timekey=@Timekey
------								--		))
------								--FOR XML PATH ('')
------								--),1,1,'')   
----		FROM UploadBuyout V  
---- WHERE ISNULL(V.AccountNo,'')<>''
---- AND V.AccountNo NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
----								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
---- )

---- ----SELECT * FROM UploadBuyout
   
--  print 'Customer Account No'
----  -------combination
----------	PRINT 'TerritoryAlt_Key'
   
--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Account ID found. Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Account ID found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadWriteOff A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								----WHERE ISNULL(ACID,'') <>'' and LEN(ACID)>25 )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(AccountNo,'') <>'' and LEN(AccountNo)>16

-- -- Checking for Standard Accounts or Not
---- UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Only Standard Accounts are allowed. Kindly remove and upload again'     
----						ELSE ErrorMessage+','+SPACE(1)+'Only Standard Accounts are allowed. Kindly remove and upload again'     END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
----		,Srnooferroneousrows=V.SRNO
------								--STUFF((SELECT ','+SRNO 
------								--FROM UploadWriteOff A
------								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
------								-- WHERE ISNULL(V.ACID,'')<>''
------								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
------								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
------								--										Timekey=@Timekey
------								--		))
------								--FOR XML PATH ('')
------								--),1,1,'')   
----		FROM UploadBuyout V  
---- WHERE ISNULL(V.AccountNo,'')<>''
---- AND V.AccountNo NOT IN(SELECT CustomerACID FROM NPA_IntegrationDetails
----								WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND AC_AssetClassAlt_Key=1)

---- -------------------------FOR DUPLICATE AccountNo
-- IF OBJECT_ID('TEMPDB..#ACID_DUP') IS NOT NULL
-- DROP TABLE #ACID_DUP

-- SELECT * INTO #ACID_DUP FROM(
-- SELECT *,ROW_NUMBER() OVER(PARTITION BY AccountNo ORDER BY  AccountNo)AS ROW FROM UploadBuyout
-- )A
-- WHERE ROW>1

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Account ID are repeated.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Account ID are repeated.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Account ID' ELSE ErrorinColumn +','+SPACE(1)+  'Account ID' END  
--		,Srnooferroneousrows=V.SRNO
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadWriteOff A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
----								----WHERE ISNULL(ACID,'') <>'' and ACID IN(SELECT ACID FROM #ACID_DUP))
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(AccountNo,'') <>'' and AccountNo IN(SELECT AccountNo FROM #ACID_DUP)

---- --  ---------VALIDATIONS ON AccountNo

----  ---------VALIDATIONS ON Loan Agreement No

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'LoanAgreementNo cannot be blank.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'LoanAgreementNo cannot be blank.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'LoanAgreementNo' ELSE ErrorinColumn +','+SPACE(1)+  'LoanAgreementNo' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SrNo 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
----								----				WHERE ISNULL(ACID,'')='' )
----								----FOR XML PATH ('')
----								----),1,1,'')   

--FROM UploadBuyout V  
-- WHERE ISNULL(LoanAgreementNo,'')='' 
 

---- ----SELECT * FROM UploadBuyout
  
--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid LoanAgreementNo found. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid LoanAgreementNo found. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'LoanAgreementNo' ELSE ErrorinColumn +','+SPACE(1)+  'LoanAgreementNo' END  
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
-- WHERE ISNULL(V.LoanAgreementNo,'')<>'' and LEN(LoanAgreementNo)>25
-- --AND V.BuyoutPartyLoanNo NOT IN(SELECT CustomerACID FROM [CurDat].[AdvAcBasicDetail] 
--	--							WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
--	--					 )


-- IF OBJECT_ID('TEMPDB..#DUBLoan') IS NOT NULL
-- DROP TABLE #DUBLoan

-- SELECT * INTO #DUBLoan FROM(
-- SELECT *,ROW_NUMBER() OVER(PARTITION BY LoanAgreementNo ORDER BY LoanAgreementNo ) ROW FROM UploadBuyout
-- )X
-- WHERE ROW>1
   
-- --  UPDATE UploadBuyout
--	--SET  
-- --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found.LoanAgreementNo are repeated.  Please check the values and upload again'     
--	--					ELSE ErrorMessage+','+SPACE(1)+ 'Duplicate records found. LoanAgreementNo are repeated.  Please check the values and upload again'     END
--	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'LoanAgreementNo' ELSE   ErrorinColumn +','+SPACE(1)+'LoanAgreementNo' END     
--	--	,Srnooferroneousrows=V.SrNo
--	----	STUFF((SELECT ','+SRNO 
--	----							FROM #UploadNewAccount A
--	----							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
-- ----WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
-- ------AND SRNO IN(SELECT Srno FROM #DUB2))
-- ----AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

--	----							FOR XML PATH ('')
--	----							),1,1,'')   

-- --FROM UploadBuyout V  
-- --WHERE ISNULL(LoanAgreementNo,'')<>''
-- --AND LoanAgreementNo IN(SELECT LoanAgreementNo FROM #DUBLoan GROUP BY LoanAgreementNo)

---- --  ---------VALIDATIONS ON Loan Agreement No

--/*VALIDATIONS ON Indusind Loan Account No */

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'IndusindLoanAccountNo cannot be blank.  Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'IndusindLoanAccountNo cannot be blank.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'IndusindLoanAccountNo' ELSE ErrorinColumn +','+SPACE(1)+  'IndusindLoanAccountNo' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SrNo 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
----								----				WHERE ISNULL(ACID,'')='' )
----								----FOR XML PATH ('')
----								----),1,1,'')   

--FROM UploadBuyout V  
-- WHERE ISNULL(IndusindLoanAccountNo,'')='' 
 

---- ----SELECT * FROM UploadBuyout
  
----  UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid IndusindLoanAccountNo found. Please check the values and upload again'     
----						ELSE ErrorMessage+','+SPACE(1)+'Invalid IndusindLoanAccountNo found. Please check the values and upload again'     END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'IndusindLoanAccountNo' ELSE ErrorinColumn +','+SPACE(1)+  'IndusindLoanAccountNo' END  
----		,Srnooferroneousrows=V.SrNo
------								--STUFF((SELECT ','+SrNo 
------								--FROM UploadBuyout A
------								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
------								-- WHERE ISNULL(V.ACID,'')<>''
------								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
------								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
------								--										Timekey=@Timekey
------								--		))
------								--FOR XML PATH ('')
------								--),1,1,'')   
----		FROM UploadBuyout V  
---- WHERE ISNULL(V.IndusindLoanAccountNo,'')<>''
---- AND V.IndusindLoanAccountNo NOT IN(SELECT CustomerACID FROM [CurDat].[AdvAcBasicDetail] 
----								WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
--						 --)


-- IF OBJECT_ID('TEMPDB..#DUB2') IS NOT NULL
-- DROP TABLE #DUB2

-- SELECT * INTO #DUB2 FROM(
-- SELECT *,ROW_NUMBER() OVER(PARTITION BY IndusindLoanAccountNo ORDER BY IndusindLoanAccountNo ) ROW FROM UploadBuyout
-- )X
-- WHERE ROW>1
   
-- --  UPDATE UploadBuyout
--	--SET  
-- --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found.IndusindLoanAccountNo are repeated.  Please check the values and upload again'     
--	--					ELSE ErrorMessage+','+SPACE(1)+ 'Duplicate records found. IndusindLoanAccountNo are repeated.  Please check the values and upload again'     END
--	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'IndusindLoanAccountNo' ELSE   ErrorinColumn +','+SPACE(1)+'IndusindLoanAccountNo' END     
--	--	,Srnooferroneousrows=V.SrNo
--	----	STUFF((SELECT ','+SRNO 
--	----							FROM #UploadNewAccount A
--	----							WHERE A.SrNo IN(SELECT V.SrNo FROM #UploadNewAccount V  
-- ----WHERE ISNULL(ACID,'')<>'' AND ISNULL(TERRITORY,'')<>''
-- ------AND SRNO IN(SELECT Srno FROM #DUB2))
-- ----AND ACID IN(SELECT ACID FROM #DUB2 GROUP BY ACID))

--	----							FOR XML PATH ('')
--	----							),1,1,'')   

-- --FROM UploadBuyout V  
-- --WHERE ISNULL(IndusindLoanAccountNo,'')<>''
-- --AND IndusindLoanAccountNo IN(SELECT IndusindLoanAccountNo FROM #DUB2 GROUP BY IndusindLoanAccountNo)

-- /*validations on TotalOutstanding */

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'TotalOutstanding cannot be blank. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'TotalOutstanding cannot be blank. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'TotalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'TotalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								----WHERE ISNULL(InterestReversalAmount,'')='')
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(TotalOutstanding,'')=''

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid TotalOutstanding. Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'Invalid TotalOutstanding. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'TotalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'TotalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadBuyout A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
----								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
----								--)
----								--FOR XML PATH ('')
----								--),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE (ISNUMERIC(TotalOutstanding)=0 AND ISNULL(TotalOutstanding,'')<>'') OR 
-- ISNUMERIC(TotalOutstanding) LIKE '%^[0-9]%'
-- PRINT 'INVALID TotalOutstanding' 

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'TotalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'TotalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(TotalOutstanding,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid TotalOutstanding. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid TotalOutstanding. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'TotalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'TotalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
----								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
----								---- )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(TotalOutstanding,'')<>''
-- --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
-- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(TotalOutstanding,0)) <0

-- -----------------------------------------------------------------

-- /*validations on PrincipalOutstanding */

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'PrincipalOutstanding cannot be blank. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'PrincipalOutstanding cannot be blank. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								----WHERE ISNULL(InterestReversalAmount,'')='')
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(PrincipalOutstanding,'')=''

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid PrincipalOutstanding. Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'Invalid PrincipalOutstanding. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadBuyout A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
----								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
----								--)
----								--FOR XML PATH ('')
----								--),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE (ISNUMERIC(PrincipalOutstanding)=0 AND ISNULL(PrincipalOutstanding,'')<>'') OR 
-- ISNUMERIC(PrincipalOutstanding) LIKE '%^[0-9]%'
-- PRINT 'INVALID' 

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(PrincipalOutstanding,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid PrincipalOutstanding. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid PrincipalOutstanding. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PrincipalOutstanding' ELSE ErrorinColumn +','+SPACE(1)+  'PrincipalOutstanding' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
----								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
----								---- )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(PrincipalOutstanding,'')<>''
-- --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
-- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(PrincipalOutstanding,0)) <0

-- -----------------------------------------------------------------
 

--/*validations on UnrealizedInterest */

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'UnrealizedInterest cannot be blank. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'UnrealizedInterest cannot be blank. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								----WHERE ISNULL(InterestReversalAmount,'')='')
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(UnrealizedInterest,'')=''

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid UnrealizedInterest. Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'Invalid UnrealizedInterest. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
--		,Srnooferroneousrows=V.SrNo
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadBuyout A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
----								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
----								--)
----								--FOR XML PATH ('')
----								--),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE (ISNUMERIC(UnrealizedInterest)=0 AND ISNULL(UnrealizedInterest,'')<>'') OR 
-- ISNUMERIC(UnrealizedInterest) LIKE '%^[0-9]%'
-- PRINT 'INVALID UnrealizedInterest' 

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(UnrealizedInterest,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid UnrealizedInterest. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid UnrealizedInterest. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'UnrealizedInterest' ELSE ErrorinColumn +','+SPACE(1)+  'UnrealizedInterest' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
----								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
----								---- )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(UnrealizedInterest,'')<>''
-- --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
-- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(UnrealizedInterest,0)) <0

-- -----------------------------------------------------------------

--  ----------------------------------------------------
--/*validations on Asset Classification */

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'AssetClassification is mandatory. Kindly check and upload again' 
--						ELSE ErrorMessage+','+SPACE(1)+ 'AssetClassification is mandatory. Kindly check and upload again'	END
--		,ErrorinColumn='AssetClass'    
--		,Srnooferroneousrows=''
--	FROM UploadBuyout V  
--	WHERE ISNULL(v.AssetClassification,'')=''  

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid AssetClassification.  Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+'Invalid AssetClassification.  Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AssetClassification' ELSE   ErrorinColumn +','+SPACE(1)+'AssetClassification' END       
--		,Srnooferroneousrows=V.SrNo
--	--	STUFF((SELECT ','+SrNo 
--	--							FROM UploadBuyout A
--	--							WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V  
-- --WHERE ISNULL(SOLID,'')<>''
-- --AND  LEN(SOLID)>10)
--	--							FOR XML PATH ('')
--	--							),1,1,'')
   
--   FROM UploadBuyout V  
--   LEFT JOIN DimAssetClass B
--   ON V.AssetClassification=B.AssetClassName
--   AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
-- WHERE ISNULL(V.AssetClassification,'')<>''
-- AND B.AssetClassName IS NULL
-- --WHERE ISNULL(AssetClassification,'')<>''
-- --AND LEN(CustomerName)>20

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AssetClassification' ELSE ErrorinColumn +','+SPACE(1)+  'AssetClassification' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(AssetClassification,'') LIKE'%[,!@#$%^&*-_/\()+=]%'

-- ----------- /*validations on NPA_Date */

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA_Date Can not be Blank . Please enter the DateOfSaletoARC and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'NPA_Date Can not be Blank. Please enter the DateOfSaletoARC and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA_Date' ELSE   ErrorinColumn +','+SPACE(1)+'NPA_Date' END      
--		,Srnooferroneousrows=V.SrNo
--		--STUFF((SELECT ','+SRNO 
--		--						FROM #UploadNewAccount A
--		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
--		--										WHERE ISNULL(AssetClass,'')<>'' AND ISNULL(AssetClass,'')<>'STD' and  ISNULL(NPADate,'')=''
--		--										)
--		--						FOR XML PATH ('')
--		--						),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(NPADate,'')='' 


--UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format ‘dd-mm-yyyy’'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA_Date' ELSE   ErrorinColumn +','+SPACE(1)+'NPA_Date' END      
--		,Srnooferroneousrows=V.SrNo
--		--STUFF((SELECT ','+SRNO 
--		--						FROM #UploadNewAccount A
--		--						WHERE A.SrNo IN(SELECT V.SrNo  FROM #UploadNewAccount V  
--		--										  WHERE ISNULL(NPADate,'')<>'' AND (CAST(ISNULL(NPADate ,'')AS Varchar(10))<>FORMAT(cast(NPADate as date),'dd-MM-yyyy'))

--		--										)
--		--						FOR XML PATH ('')
--		--						),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(NPADate,'')<>'' AND ISDATE(NPADate)=0

-- -- Checking for NPA Date is Mandatory When Asset Classification is either of SUB / DB1 / DB2 / DB3 / LOS.
---- UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'The column NPA_Date is mandatory. Kindly check and upload again'     
----						ELSE ErrorMessage+','+SPACE(1)+'The column NPA_Date’ is mandatory. Kindly check and upload again'     END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA_Date' ELSE ErrorinColumn +','+SPACE(1)+  'NPA_Date' END  
----		,Srnooferroneousrows=V.SRNO
------								--STUFF((SELECT ','+SRNO 
------								--FROM UploadWriteOff A
------								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
------								-- WHERE ISNULL(V.ACID,'')<>''
------								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
------								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
------								--										Timekey=@Timekey
------								--		))
------								--FOR XML PATH ('')
------								--),1,1,'')   
----		FROM UploadBuyout V  
---- WHERE ISNULL(V.NPADate,'')<>''
---- AND V.NPADate NOT IN(SELECT NPADate FROM NPA_IntegrationDetails
----								WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND ISNULL(AC_NPA_Date,'') <> '' AND AC_AssetClassAlt_Key IN (2,3,4,5,6))

---- Checking for NPA Date should not be present if Asset classification is STD
---- UPDATE UploadBuyout
----	SET  
----        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Only Standard Accounts are not allowed NPA_Date. Kindly remove and upload again'     
----						ELSE ErrorMessage+','+SPACE(1)+'Only Standard Accounts are not allowed NPA_Date. Kindly remove and upload again'     END
----		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPA_Date' ELSE ErrorinColumn +','+SPACE(1)+  'NPA_Date' END  
----		,Srnooferroneousrows=V.SRNO
------								--STUFF((SELECT ','+SRNO 
------								--FROM UploadWriteOff A
------								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadWriteOff V
------								-- WHERE ISNULL(V.ACID,'')<>''
------								--		AND V.ACID NOT IN(SELECT SystemAcid FROM AxisIntReversalDB.IntReversalDataDetails 
------								--										WHERE -----EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
------								--										Timekey=@Timekey
------								--		))
------								--FOR XML PATH ('')
------								--),1,1,'')   
----		FROM UploadBuyout V  
---- WHERE ISNULL(V.NPADate,'')=''
---- AND V.NPADate IN(SELECT NPADate FROM NPA_IntegrationDetails WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND AC_AssetClassAlt_Key=1)

----------------------------------------------------------------------------
-- /*validations on DPD */

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'DPD cannot be blank. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'DPD cannot be blank. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								----WHERE ISNULL(InterestReversalAmount,'')='')
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(DPD,'')=''

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid DPD. Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'Invalid DPD. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
--		,Srnooferroneousrows=V.SrNo
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadBuyout A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
----								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
----								--)
----								--FOR XML PATH ('')
----								--),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE (ISNUMERIC(DPD)=0 AND ISNULL(DPD,'')<>'') OR 
-- ISNUMERIC(DPD) LIKE '%^[0-9]%'
-- PRINT 'INVALID' 

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(DPD,'') LIKE'%[,!@#$%^&*()_-+=/\]%'

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid DPD. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid DPD. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'DPD' ELSE ErrorinColumn +','+SPACE(1)+  'DPD' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
----								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
----								---- )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(DPD,'')<>''
-- --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
-- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(DPD,0)) <0
-------------------------------------------------------------
--/*validations on Security Amount */

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'SecurityAmount cannot be blank. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'SecurityAmount cannot be blank. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								----WHERE ISNULL(InterestReversalAmount,'')='')
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(SecurityAmount,'')=''

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid SecurityAmount. Please check the values and upload again'     
--					ELSE ErrorMessage+','+SPACE(1)+'Invalid SecurityAmount. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
--		,Srnooferroneousrows=V.SrNo
----								--STUFF((SELECT ','+SRNO 
----								--FROM UploadBuyout A
----								--WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								--WHERE (ISNUMERIC(InterestReversalAmount)=0 AND ISNULL(InterestReversalAmount,'')<>'') OR 
----								--ISNUMERIC(InterestReversalAmount) LIKE '%^[0-9]%'
----								--)
----								--FOR XML PATH ('')
----								--),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE (ISNUMERIC(SecurityAmount)=0 AND ISNULL(SecurityAmount,'')<>'') OR 
-- ISNUMERIC(SecurityAmount) LIKE '%^[0-9]%'
-- PRINT 'INVALID SecurityAmount' 

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								---- WHERE ISNULL(InterestReversalAmount,'') LIKE'%[,!@#$%^&*()_-+=/]%'
----								----)
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(SecurityAmount,'') LIKE'%[,!@#$%^&*()-_\-+=/]%'

--  UPDATE UploadBuyout
--	SET  
--        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid SecurityAmount. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid SecurityAmount. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SecurityAmount' ELSE ErrorinColumn +','+SPACE(1)+  'SecurityAmount' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
----								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
----								---- )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(SecurityAmount,'')<>''
-- --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
-- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(SecurityAmount,0)) <0

-- ---------- Validations for Action
-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Action cannot be blank. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Action cannot be blank. Please check the values and upload again'      END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT V.SrNo FROM UploadBuyout V
----								----WHERE ISNULL(InterestReversalAmount,'')='')
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE ISNULL(Action,'')=''

-- UPDATE UploadBuyout
--	SET  
--        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Action. Please check the values and upload again'     
--						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Action. Please check the values and upload again'     END
--		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
--		,Srnooferroneousrows=V.SrNo
----								----STUFF((SELECT ','+SRNO 
----								----FROM UploadBuyout A
----								----WHERE A.SrNo IN(SELECT SRNO FROM UploadBuyout WHERE ISNULL(InterestReversalAmount,'')<>''
----								---- AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
----								---- )
----								----FOR XML PATH ('')
----								----),1,1,'')   

-- FROM UploadBuyout V  
-- WHERE Action NOT IN('A','D')




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