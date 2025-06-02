SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[ValidateExcel_BranchMasterUpload] 
@MenuID INT=2010,  
@UserLoginId  VARCHAR(20)='fnachecker',  
@Timekey INT=49999
,@filepath VARCHAR(MAX) =''  
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

	IF EXISTS(SELECT * FROM dbo.MasterUploadData    where FileNames=@filepath )
	BEGIN
		Delete from dbo.MasterUploadData    where FileNames=@filepath  
		print @@rowcount
	END


IF (@MenuID=2010)	
BEGIN


	
	  IF OBJECT_ID('UploadBranch_Master_Upload') IS NOT NULL  
	  BEGIN
	    
		DROP TABLE  UploadBranch_Master_Upload
	
	  END
	  
  IF NOT (EXISTS (SELECT 1 FROM BranchMasterUpload_Stg WHERE FileName=@FilePathUpload ))
  
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
	   Select *,CAST('' AS varchar(MAX)) ErrorMessage
	   ,CAST('' AS varchar(MAX)) ErrorinColumn
	   ,CAST('' AS varchar(MAX)) Srnooferroneousrows
 	   into UploadBranch_Master_Upload 
	   from BranchMasterUpload_Stg 
	  WHERE FileName=@FilePathUpload

	  
END
  ------------------------------------------------------------------------------  
  

  IF EXISTS(SELECT * FROM UploadBranch_Master_Upload WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  select 'No Value Found ,Please Upload Suitable File with Data' ErrorMessage,'Error' Tablename
 
  END


	

-----validations on SrNo
	print 'Validation Error Message for SRNO'
	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'SrNo is mandatory. Kindly check and upload again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'SrNo is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=''
	FROM UploadBranch_Master_Upload V  
	WHERE ISNULL(v.SrNo,'')=''  
	 Print '1'

UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END  
		,Srnooferroneousrows=V.SrNo

--select *
 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(SrNo,'')  LIKE '%[,!@#$%^&*()_-+=/]%'

 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SRNO  
  
  FROM UploadBranch_Master_Upload v
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

  --update UploadBranch_Master_Upload
  --set SrNo=NULL
  --WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid SrNo, kindly check and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid SrNo, kindly check and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SrNo
		
 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(v.SrNo,'')='0'  OR ISNUMERIC(v.SrNo)=0
  Print '2'
  
  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SrNo ORDER BY SrNo)ROW
   FROM UploadBranch_Master_Upload
   )A
   WHERE ROW>1

 PRINT 'Duplicate SRNO'  


  UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate SrNo, kindly check and upload again' 
					ELSE ErrorMessage+','+SPACE(1)+     'Duplicate SrNo, kindly check and upload again' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SrNo' ELSE ErrorinColumn +','+SPACE(1)+  'SrNo' END
		,Srnooferroneousrows=SrNo
		--STUFF((SELECT DISTINCT ','+SrNo 
		--						FROM UploadBuyout
		--						FOR XML PATH ('')
		--						),1,1,'')
         
		
 FROM UploadBranch_Master_Upload V  
	WHERE  V.SrNo IN(SELECT SrNo FROM #R )
	Print '3'


	-----validations on BranchCode
	print 'Validation Error Message for BranchCode'
	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'BranchCode is mandatory. Kindly check and upload again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'BranchCode is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='BranchCode'    
		,Srnooferroneousrows=V.SrNo
	FROM UploadBranch_Master_Upload V  
	WHERE ISNULL(v.BranchCode,'')=''  
	 Print 's1'

	 ---------------------------------------VALIDATION FOR EXIST RECORDS  --ADDED BY SHAKTI ON 01 SEP 22
	print 'VALIDATION FOR EXIST RECORDS'

	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'BranchCode is Already exists please Check and Upload Again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'BranchCode is Already exists please Check and Upload Again'
		  END
		,ErrorinColumn='BranchCode'    
		,Srnooferroneousrows=V.SrNo
	FROM UploadBranch_Master_Upload V  
	WHERE  ISNULL(v.BranchCode,'') in 
			(select BranchCode from DimBranch 
								where EffectiveToTimeKey=49999 AND BranchCode IN 
											(SELECT BranchCode FROM UploadBranch_Master_Upload WHERE [Action] IN ('A')))



	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'BranchCode is not exists please Check and Upload Again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'BranchCode is not exists please Check and Upload Again'
		  END
		,ErrorinColumn='BranchCode'    
		,Srnooferroneousrows=V.SrNo
	FROM UploadBranch_Master_Upload V  
	WHERE  ISNULL(v.BranchCode,'') not in (select BranchCode from DimBranch where EffectiveToTimeKey=49999)
	and v.Action in ('U','D')



UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchCode' ELSE ErrorinColumn +','+SPACE(1)+  'BranchCode' END  
		,Srnooferroneousrows=V.SrNo

--select *
 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(BranchCode,'')  LIKE '%[,!@#$%^&*()_-+=/]%'

  
  IF OBJECT_ID('TEMPDB..#rr') IS NOT NULL
  DROP TABLE #rr

  SELECT * INTO #Rr FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY BranchCode ORDER BY BranchCode)ROW
   FROM UploadBranch_Master_Upload
   )A
   WHERE ROW>1

 PRINT 'Duplicate BranchCode'  


  UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate BranchCode, kindly check and upload again' 
					ELSE ErrorMessage+','+SPACE(1)+     'Duplicate BranchCode, kindly check and upload again' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchCode' ELSE ErrorinColumn +','+SPACE(1)+  'BranchCode' END
		,Srnooferroneousrows=V.SrNo
		
 FROM UploadBranch_Master_Upload V  
	WHERE  V.BranchCode IN(SELECT BranchCode FROM #RR )
	Print 's3'

	-----validations on BranchName
	print 'Validation Error Message for BranchName'
	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'BranchName is mandatory. Kindly check and upload again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'BranchName is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='BranchName'    
		,Srnooferroneousrows=V.SrNo
	FROM UploadBranch_Master_Upload V  
	WHERE ISNULL(v.BranchName,'')=''  
	 Print 's11'

	 	-----validations on AddLine1
	print 'Validation Error Message for AddLine1'
	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'AddLine1 is mandatory. Kindly check and upload again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'AddLine1 is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='AddLine1'    
		,Srnooferroneousrows=V.SrNo
	FROM UploadBranch_Master_Upload V  
	WHERE ISNULL(v.AddLine1,'')=''  
	 Print 's11'
  
	-- 	-----validations on AddLine2
	--print 'Validation Error Message for AddLine2'
	-- UPDATE UploadBranch_Master_Upload
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
	--	THEN 	'AddLine2 is mandatory. Kindly check and upload again' 
	--	ELSE ErrorMessage+','+SPACE(1)+ 'AddLine2 is mandatory. Kindly check and upload again'
	--	  END
	--	,ErrorinColumn='AddLine2'    
	--	,Srnooferroneousrows=V.SrNo
	--FROM UploadBranch_Master_Upload V  
	--WHERE ISNULL(v.AddLine2,'')=''  
	-- Print 's121'

	-- 	-----validations on AddLine3
	--print 'Validation Error Message for AddLine2'
	-- UPDATE UploadBranch_Master_Upload
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
	--	THEN 	'AddLine3 is mandatory. Kindly check and upload again' 
	--	ELSE ErrorMessage+','+SPACE(1)+ 'AddLine3 is mandatory. Kindly check and upload again'
	--	  END
	--	,ErrorinColumn='AddLine3'    
	--	,Srnooferroneousrows=V.SrNo
	--FROM UploadBranch_Master_Upload V  
	--WHERE ISNULL(v.AddLine3,'')=''  
	-- Print 's1212'

	 	-----validations on Place
	print 'Validation Error Message for Place'
	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'Place is mandatory. Kindly check and upload again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'Place is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='Place'    
		,Srnooferroneousrows=V.SrNo
	FROM UploadBranch_Master_Upload V  
	WHERE ISNULL(v.Place,'')=''  
	 Print 's1212'

	 	 	-----validations on PinCode
	print 'Validation Error Message for PinCode'
	 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' 
		THEN 	'PinCode is mandatory. Kindly check and upload again' 
		ELSE ErrorMessage+','+SPACE(1)+ 'PinCode is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='PinCode'    
		,Srnooferroneousrows=V.SrNo

	FROM UploadBranch_Master_Upload V  
	WHERE ISNULL(v.PinCode,'')=''  
	 Print 's12121'

   UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'PinCode' ELSE ErrorinColumn +','+SPACE(1)+  'PinCode' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(PinCode,'')  LIKE '%[,!@#$%^&*()_-+=/]%'


 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid PinCode, kindly check and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid PinCode, kindly check and upload again'      END
		,ErrorinColumn='PinCode'    
		,Srnooferroneousrows=V.SrNo
		
 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(v.PinCode,'')='0'  OR ISNUMERIC(v.PinCode)=0

  UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid PinCode, kindly check the Length and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid PinCode, kindly check the Length and upload again'      END
		,ErrorinColumn='PinCode'    
		,Srnooferroneousrows=V.SrNo
		
 FROM UploadBranch_Master_Upload V  
 WHERE LEN(ISNULL(PinCode,'')) <> 6


----------- /* Validations on BranchOpenDt
UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchOpenDt Can not be Blank . Please enter the BranchOpenDt and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchOpenDt Can not be Blank. Please enter the BranchOpenDt and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchOpenDt' ELSE   ErrorinColumn +','+SPACE(1)+'BranchOpenDt' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(BranchOpenDt,'')='' 


SET DATEFORMAT DMY
UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchOpenDt date format. Please enter the date in format DD/MM/YYYY'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid BranchOpenDt format. Please enter the date in format DD/MM/YYYY'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchOpenDt' ELSE   ErrorinColumn +','+SPACE(1)+'BranchOpenDt' END      
		,Srnooferroneousrows=V.SrNo
		   
 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(BranchOpenDt,'')<>'' AND ISDATE(BranchOpenDt)=0


 ----- Future Date Comparison
 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchOpenDt Should not be Future Date . Please enter the BranchOpenDt and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchOpenDt Should not be Future Date. Please enter the BranchOpenDt and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchOpenDt' ELSE   ErrorinColumn +','+SPACE(1)+'BranchOpenDt' END      
		,Srnooferroneousrows=V.SrNo

 FROM UploadBranch_Master_Upload V  
 WHERE  (CASE WHEN ISNULL(BranchOpenDt,'')<>'' AND  ISDATE(BranchOpenDt)=1 
               THEN CASE WHEN CONVERT(date,BranchOpenDt) > CONVERT(date,GETDATE()) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

PRINT 'DUB4'

UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchOpenDt' ELSE ErrorinColumn +','+SPACE(1)+  'BranchOpenDt' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(BranchOpenDt,'')  LIKE '%[,!@#$%^&*()_+=\]%'

 UPDATE  UploadBranch_Master_Upload 
	SET BranchOpenDt=NULL 
 WHERE ISDATE(BranchOpenDt)=0

 ----------- /* Validations on BranchAreaCategory
UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchAreaCategory Can not be Blank . Please enter the BranchAreaCategory and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchAreaCategory Can not be Blank. Please enter the BranchAreaCategory and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchAreaCategory' ELSE   ErrorinColumn +','+SPACE(1)+'BranchAreaCategory' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(BranchAreaCategory,'')='' 

 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchAreaCategory Values will be as per “Master'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchAreaCategory Values will be as per “Master'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchAreaCategory' ELSE   ErrorinColumn +','+SPACE(1)+'BranchAreaCategory' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE BranchAreaCategory not in (SELECT DISTINCT AreaName FROM DIMAREA WHERE EffectiveToTimeKey=49999)

  ----------- /* Validations on BranchStateName
UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchStateName Can not be Blank . Please enter the BranchStateName and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchStateName Can not be Blank. Please enter the BranchStateName and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchStateName' ELSE   ErrorinColumn +','+SPACE(1)+'BranchStateName' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(BranchStateName,'')='' 

 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchStateName Values will be as per “Master'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchStateName Values will be as per “Master'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchStateName' ELSE   ErrorinColumn +','+SPACE(1)+'BranchStateName' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE BranchStateName not in (select distinct StateName from DimState where EffectiveToTimeKey=49999)
   ----------- /* Validations on BranchDistrictName
UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchDistrictName Can not be Blank . Please enter the BranchDistrictName and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchDistrictName Can not be Blank. Please enter the BranchDistrictName and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchDistrictName' ELSE   ErrorinColumn +','+SPACE(1)+'BranchDistrictName' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(BranchDistrictName,'')='' 

 
 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'BranchDistrictName Values will be as per “Master'     
						ELSE ErrorMessage+','+SPACE(1)+ 'BranchDistrictName Values will be as per “Master'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'BranchDistrictName' ELSE   ErrorinColumn +','+SPACE(1)+'BranchDistrictName' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE BranchDistrictName not in (select distinct DistrictName from DimGeography  where EffectiveToTimeKey=49999)

    ----------- /* Validations on Action
UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Action Can not be Blank . Please enter the Action and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Action Can not be Blank. Please enter the Action and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE   ErrorinColumn +','+SPACE(1)+'Action' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE ISNULL(Action,'')='' 


 UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Action Can not be more than 1 character'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Action Can not be more than 1 character'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE   ErrorinColumn +','+SPACE(1)+'Action' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE  LEN(ISNULL(Action,'')) <> 1

  UPDATE UploadBranch_Master_Upload
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Action Values with in A, D, U'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Action Values with in A, D, U'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE   ErrorinColumn +','+SPACE(1)+'Action' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadBranch_Master_Upload V  
 WHERE  Action not in ('A', 'D', 'U')


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
		IF NOT EXISTS(Select 1 from  BranchMasterUpload_Stg WHERE filename=@FilePathUpload)
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
			FROM UploadBranch_Master_Upload 

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

		 IF EXISTS(SELECT 1 FROM BranchMasterUpload_Stg WHERE filename=@FilePathUpload)
		 BEGIN
		 DELETE FROM BranchMasterUpload_Stg
		 WHERE filename=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.BranchMasterUpload_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

	END
	ELSE
	BEGIN
	PRINT ' DATA NOT PRESENT'
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


	print 'p'

   
END  TRY
  
  BEGIN CATCH
	

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()

	IF EXISTS(SELECT 1 FROM BranchMasterUpload_Stg WHERE FileName=@FilePathUpload)
		 BEGIN
		 DELETE FROM BuyoutDetails_stg
		 WHERE filname=@FilePathUpload

		 PRINT 'ROWS DELETED FROM DBO.BranchMasterUpload_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

END CATCH

END

GO