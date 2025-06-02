SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ValidateExcel_DataUpload_ProvisionPolicyUpload] 
@MenuID INT,  
@UserLoginId  VARCHAR(20),  
@Timekey INT
,@filepath VARCHAR(MAX)   
WITH RECOMPILE  
AS  

  
BEGIN
BEGIN TRY  

     
	SET DATEFORMAT DMY
	SET NOCOUNT ON;

	SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 
	PRINT @Timekey          
  Declare @processingdate Date = (Select DATE from SysDataMatrix where CurrentStatus='C')

    DECLARE @FilePathUpload	VARCHAR(100)

			SET @FilePathUpload=@UserLoginId+'_'+@filepath
	PRINT '@FilePathUpload'
	PRINT @FilePathUpload

	IF EXISTS(SELECT 1 FROM dbo.MasterUploadData    where FileNames=@filepath )
	BEGIN
		Delete from dbo.MasterUploadData    
		where FileNames=@filepath  
		PRINT @@rowcount
	END


IF (@MenuID=2026)	
BEGIN

	   IF OBJECT_ID('UploadProvisionPolicy') IS NOT NULL  
		  BEGIN	    
			DROP TABLE  UploadProvisionPolicy
		  END

		  PRINT @FilePathUpload

	   
  IF NOT (EXISTS (SELECT * FROM ProvisionPolicy_stg where filname=@FilePathUpload))

BEGIN
PRINT 'NO DATA1'
			INSERT into dbo.MasterUploadData
			(SR_No,ColumnName,ErrorData,ErrorType,FileNames,Flag) 
			SELECT 0 SrNo , '' ColumnName,'No Record found' ErrorData,'No Record found' ErrorType,@filepath,'SUCCESS' 
			
			GOTO errordata
    
END

ELSE
BEGIN
PRINT 'DATA PRESENT'
	   Select *,CAST('' AS varchar(MAX)) ErrorMessage,CAST('' AS varchar(MAX)) ErrorinColumn,CAST('' AS varchar(MAX)) Srnooferroneousrows
 	   into UploadProvisionPolicy 
	   from ProvisionPolicy_stg 
	   WHERE filname=@FilePathUpload

END

PRINT 'START'
------------------------------------------------------------------------------  
	
  UPDATE UploadProvisionPolicy
  SET  
          ErrorMessage='There is no data in excel. Kindly check and upload again' 
  		,ErrorinColumn='SrNo,SourceSystem,SchemeCode,upto3months,[3monthsupto6months],[6monthsupto9months],
  						[9monthsupto12months],Doubtful1,Doubtful2,Doubtful3,Loss'-----,ProvisionUnSecured'
  		,Srnooferroneousrows=''
  FROM UploadProvisionPolicy V  
  WHERE ISNULL(SrNo,'')=''
  AND ISNULL(SourceSystem,'')=''
  AND ISNULL(SchemeCode,'')=''
  AND ISNULL(upto3months,'')=''
  AND ISNULL([3monthsupto6months],'')=''
  AND ISNULL([6monthsupto9months],'')=''
  AND ISNULL([9monthsupto12months],'')=''
  AND ISNULL(Doubtful1,'')=''
  AND ISNULL(Doubtful2,'')=''
  AND ISNULL(Doubtful3,'')=''
  AND ISNULL(Loss,'')=''
  --AND ISNULL(ProvisionUnSecured,'')=''

PRINT 'START VALIDATION'

  IF EXISTS(SELECT 1 FROM UploadProvisionPolicy WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  END
  ---------------------- Validation for Scheme Code and Source System Combination ------------------------- addded by mohit 15/07/2024 to avoid wrong scheme code for source system

PRINT 'Scheme Code and Source System Name not matched'

UPDATE UploadProvisionPolicy
SET  
    ErrorMessage = CASE WHEN ISNULL(ErrorMessage, '') = '' THEN 'Scheme code not exist in system please check and correct the Action'   ----Change error code as suggested by Dayanand mane on 05/11/2024  
                        ELSE ErrorMessage + ', ' + 'Scheme code not exist in system please check and correct the Action' END,
    ErrorinColumn = CASE WHEN ISNULL(ErrorinColumn, '') = '' THEN 'SchemeCode, SourceSystem' ELSE ErrorinColumn + ', ' + 'SchemeCode, SourceSystem' END,   
    Srnooferroneousrows = V.SrNo
FROM UploadProvisionPolicy V  
LEFT JOIN DIMPROVISIONPOLICY DP
ON V.SchemeCode = DP.Scheme_Code
AND V.SourceSystem = DP.Source_System
WHERE DP.Scheme_Code IS NULL AND Action<>'A'
   
------------------------Validations on SrNo-------------------------------------------------------------

 PRINT 'SrNo'
	 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'Sr. No. cannot be blank.  Please check the values and upload again' 
								ELSE ErrorMessage+','+SPACE(1)+ 'Sr. No. cannot be blank.  Please check the values and upload again'	END
	,ErrorinColumn='SrNo'    
	,Srnooferroneousrows=''
	FROM UploadProvisionPolicy V  
	WHERE ISNULL(SrNo,'')=''-- or ISNULL(SrNo,'0')='0'

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SrNo' ELSE ErrorinColumn +','+SPACE(1)+  'SrNo' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadProvisionPolicy V  
 WHERE ISNULL(SrNo,'')  LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(SrNo,'') LIKE '%!%%' ESCAPE '!'  --added by Mayuresh to consider % as string on 20241105
--LIKE '%[,!@#$%^&*()_-+=/]%'

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SrNo'    
		,Srnooferroneousrows=SrNo  
  
  FROM UploadProvisionPolicy v
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'


  update UploadProvisionPolicy
  set SrNo=NULL
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'


  ---------------------------- CHECKING for DUPLICATE SrNo's-----------------------------
  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SrNo ORDER BY SrNo)ROW
   FROM UploadProvisionPolicy
   )A
   WHERE ROW>1

 PRINT 'DUB'  

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Following sr. no. are repeated' 
					ELSE ErrorMessage+','+SPACE(1)+     'Following sr. no. are repeated' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SrNo' ELSE ErrorinColumn +','+SPACE(1)+  'SrNo' END
		,Srnooferroneousrows=SrNo		
 FROM UploadProvisionPolicy V  
	WHERE  V.SrNo IN(SELECT SrNo FROM #R )
 PRINT 'DUB1'  

 ---------------------- /*validations on Source System Name*/--------------------------
  
 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Source System Name cannot be blank . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Source System Name cannot be blank . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source System Name' ELSE   ErrorinColumn +','+SPACE(1)+'Source System Name' END   
		,Srnooferroneousrows=V.SrNo
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(SourceSystem,'')=''
 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source System Name' ELSE ErrorinColumn +','+SPACE(1)+  'Source System Name' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(SourceSystem,'') LIKE '%[,!@#$%^&*()+=/\]%' ---OR  ISNULL(SourceSystem,'') LIKE '%!%%' ESCAPE '!'  --added by Mayuresh to consider % as string on 20241105
 --LIKE'%[,!@#$%^&*()+=/\]%' 


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Source System Name.  Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Invalid Source System Name.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source System Name' ELSE   ErrorinColumn +','+SPACE(1)+'Source System Name' END       
		,Srnooferroneousrows=V.SrNo
FROM UploadProvisionPolicy V  
 LEFT JOIN DimSourceSystem B
 ON V.SourceSystem=B.SourceName
 AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
 WHERE ISNULL(V.SourceSystem,'')<>''
 AND B.SourceName IS NULL
 PRINT 'DUB2'

 ------------------------ /*validations on Scheme Code*/-----------------------------
  
 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Scheme Code cannot be blank . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Scheme Code cannot be blank . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Scheme Code' ELSE   ErrorinColumn +','+SPACE(1)+'Scheme Code' END   
		,Srnooferroneousrows=V.SrNo  
   FROM UploadProvisionPolicy V  
 WHERE ISNULL(SchemeCode,'')='' AND Action='A'

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Scheme Code' ELSE ErrorinColumn +','+SPACE(1)+  'Scheme Code' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(SchemeCode,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(SchemeCode,'') LIKE '%!%%' ESCAPE '!'  --added by Mayuresh to consider % as string on 20241105
 --LIKE'%[,!@#$%^&*()+=/\]%'


  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Pending Scheme codes cannot be modified. Please check the values and upload again.'     
						ELSE ErrorMessage+','+SPACE(1)+'Pending Scheme codes cannot be modified. Please check the values and upload again.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Scheme Code' ELSE   ErrorinColumn +','+SPACE(1)+'Scheme Code' END   
		,Srnooferroneousrows=V.SrNo  
   FROM UploadProvisionPolicy V  
 WHERE ISNULL(SchemeCode,'') IN (SELECT ISNULL(Scheme_Code,'') FROM DIMPROVISIONPOLICY_MOD where AuthorisationStatus IN ('NP','MP','DP'))
 
 ---------------validations on Action---------------------

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Please check and select correct Action. Action should be A =Addition OR U =Modification OR D =Deletion.'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Action. Please check and select correct Action.'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE V.Action NOT IN ('A','U','D') 


  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again.'     
					ELSE ErrorMessage+','+SPACE(1)+'Special characters - _ \ / not are allowed, kindly remove and upload again.'       END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(V.Action,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR  ISNULL(V.Action,'') LIKE '%!%%' ESCAPE '!' --added by Mayuresh to consider % as string on 20241105
 --LIKE'%[,!@#$%^&*()+=/\]%'


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Action should not be blank. Please check and select correct Action.'     
					ELSE ErrorMessage+','+SPACE(1)+'Action should not be blank. Please check and select correct Action.'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(V.Action,'')=''
 PRINT 'DUB13'
 
 
 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Only existing Scheme Code can be modified. Please check and select correct Action in Excel sheet.'    
					ELSE ErrorMessage+','+SPACE(1)+'Only existing Scheme Code can be modified. Please check and select correct Action in Excel sheet.'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE V.SchemeCode NOT IN (SELECT CASE WHEN Scheme_Code IS NULL THEN NULL ELSE Scheme_Code END from DIMPROVISIONPOLICY )
 AND V.Action='U'
 PRINT 'DUB14'
 
  UPDATE UploadProvisionPolicy  ---ADDED BY MOHIT AS INFORMATION GIVEN BY DAYANAND MANE TO AVOID SAME SCHEME_CODE FOR DIFFERENT SOURCE 03/07/2024
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Scheme Code already exists. Please check and select correct Action in Excel sheet.'    
					ELSE ErrorMessage+','+SPACE(1)+'Scheme Code already exists. Please check and select correct Action in Excel sheet.'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo							
    FROM UploadProvisionPolicy V  
    WHERE V.SchemeCode in (Select Scheme_Code from DIMPROVISIONPOLICY_MOD where EffectiveToTimeKey=49999 
	UNION Select Scheme_Code from DIMPROVISIONPOLICY where EffectiveToTimeKey=49999)
    AND V.Action='A'
 PRINT 'DUB15'


  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Only existing Scheme Code can be Deleted. Please check and select correct Action in Excel sheet.'    
					ELSE ErrorMessage+','+SPACE(1)+'Only existing Scheme Code can be Deleted. Please check and select correct Action in Excel sheet.'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE V.SchemeCode NOT IN (SELECT CASE WHEN Scheme_Code IS NULL THEN NULL ELSE Scheme_Code END from DIMPROVISIONPOLICY  ) 
 AND V.Action='D'
 AND V.SourceSystem NOT IN ('Vision Plus','PT Smart','Ganaseva')
 PRINT 'DUB14'


---------------Added on 07052024 for same record is uploaded again with same value and duplicate record are generated-------------------------------
 -- UPDATE UploadProvisionPolicy
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Scheme Code already exists. Please check and select correct Action in Excel sheet.'    
	--				ELSE ErrorMessage+','+SPACE(1)+'Scheme Code already exists. Please check and select correct Action in Excel sheet.'      END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Action' ELSE ErrorinColumn +','+SPACE(1)+  'Action' END  
	--	,Srnooferroneousrows=V.SrNo							
 --   FROM UploadProvisionPolicy V  
 --   WHERE V.SchemeCode in (Select Scheme_Code from DIMPROVISIONPOLICY_MOD)
 --   AND V.Action='A'

-------------validations on Provision percentage upto3months-------

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in upto3months field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in upto3months field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'upto3months' ELSE ErrorinColumn +','+SPACE(1)+  'upto3months' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC(upto3months)=0 AND ISNULL(upto3months,'')<>'') OR 
 ISNUMERIC(upto3months) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'upto3months' ELSE ErrorinColumn +','+SPACE(1)+  'upto3months' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(upto3months,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(upto3months,'') LIKE '%!%%' ESCAPE '!' --added by Mayuresh to consider % as string on 20241105
 AND ISNUMERIC(upto3months) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC(upto3months) LIKE '%^[0-9]%'


  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in upto3months field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in upto3months field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'upto3months' ELSE ErrorinColumn +','+SPACE(1)+  'upto3months' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(upto3months,'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(upto3months,0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'upto3months' ELSE ErrorinColumn +','+SPACE(1)+  'upto3months' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(upto3months,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(upto3months,0))>100
 PRINT 'DUB4'

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'upto3months' ELSE ErrorinColumn +','+SPACE(1)+  'upto3months' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(upto3months,'')='' AND Action='A'


  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'upto3months' ELSE ErrorinColumn +','+SPACE(1)+  'upto3months' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(upto3months,'')<>'' AND Action='D'

-------------validations on Provision percentage [3monthsupto6months]-------


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in [3monthsupto6months] field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in [3monthsupto6months] field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[3monthsupto6months]' ELSE ErrorinColumn +','+SPACE(1)+  '[3monthsupto6months]' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC([3monthsupto6months])=0 AND ISNULL([3monthsupto6months],'')<>'') OR 
 ISNUMERIC([3monthsupto6months]) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[3monthsupto6months]' ELSE ErrorinColumn +','+SPACE(1)+  '[3monthsupto6months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([3monthsupto6months],'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL([3monthsupto6months],'') LIKE '%!%%' ESCAPE '!' --added by Mayuresh to consider % as string on 20241105
 AND ISNUMERIC([3monthsupto6months]) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC([3monthsupto6months]) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in [3monthsupto6months] field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in [3monthsupto6months] field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[3monthsupto6months]' ELSE ErrorinColumn +','+SPACE(1)+  '[3monthsupto6months]' END  
		,Srnooferroneousrows=V.SrNo
								  

 FROM UploadProvisionPolicy V  
 WHERE ISNULL([3monthsupto6months],'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL([3monthsupto6months],0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[3monthsupto6months]' ELSE ErrorinColumn +','+SPACE(1)+  '[3monthsupto6months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([3monthsupto6months],'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL([3monthsupto6months],0))>100
 PRINT 'DUB5'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[3monthsupto6months]' ELSE ErrorinColumn +','+SPACE(1)+  '[3monthsupto6months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([3monthsupto6months],'')='' AND Action='A'


   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[3monthsupto6months]' ELSE ErrorinColumn +','+SPACE(1)+  '[3monthsupto6months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([3monthsupto6months],'')<>'' AND Action='D'

 -------------validations on Provision percentage [6monthsupto9months]-------

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in [6monthsupto9months] field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in [6monthsupto9months] field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[6monthsupto9months]' ELSE ErrorinColumn +','+SPACE(1)+  '[6monthsupto9months]' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC([6monthsupto9months])=0 AND ISNULL([6monthsupto9months],'')<>'') OR 
 ISNUMERIC([6monthsupto9months]) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[6monthsupto9months]' ELSE ErrorinColumn +','+SPACE(1)+  '[6monthsupto9months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([6monthsupto9months],'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL([6monthsupto9months],'') LIKE '%!%%' ESCAPE '!' --added by Mayuresh to consider % as string on 20241105
 AND ISNUMERIC([6monthsupto9months]) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC([6monthsupto9months]) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in [6monthsupto9months] field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in [6monthsupto9months] field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[6monthsupto9months]' ELSE ErrorinColumn +','+SPACE(1)+  '[6monthsupto9months]' END  
		,Srnooferroneousrows=V.SrNo
								  

 FROM UploadProvisionPolicy V  
 WHERE ISNULL([6monthsupto9months],'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL([6monthsupto9months],0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[6monthsupto9months]' ELSE ErrorinColumn +','+SPACE(1)+  '[6monthsupto9months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([6monthsupto9months],'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL([6monthsupto9months],0))>100
 PRINT 'DUB6'


  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[6monthsupto9months]' ELSE ErrorinColumn +','+SPACE(1)+  '[6monthsupto9months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([6monthsupto9months],'')='' AND Action='A'


   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[6monthsupto9months]' ELSE ErrorinColumn +','+SPACE(1)+  '[6monthsupto9months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([6monthsupto9months],'')<>'' AND Action='D'

-------------validations on Provision percentage [9monthsupto12months]-------


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in [9monthsupto12months] field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in [9monthsupto12months] field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[9monthsupto12months]' ELSE ErrorinColumn +','+SPACE(1)+  '[9monthsupto12months]' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC([9monthsupto12months])=0 AND ISNULL([9monthsupto12months],'')<>'') OR 
 ISNUMERIC([9monthsupto12months]) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[9monthsupto12months]' ELSE ErrorinColumn +','+SPACE(1)+  '[9monthsupto12months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([9monthsupto12months],'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL([9monthsupto12months],'') LIKE '%!%%' ESCAPE '!' --added by Mayuresh to consider % as string on 20241105
  AND ISNUMERIC([9monthsupto12months]) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC([9monthsupto12months]) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in [9monthsupto12months] field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in [9monthsupto12months] field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[9monthsupto12months]' ELSE ErrorinColumn +','+SPACE(1)+  '[9monthsupto12months]' END  
		,Srnooferroneousrows=V.SrNo
								  

 FROM UploadProvisionPolicy V  
 WHERE ISNULL([9monthsupto12months],'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL([9monthsupto12months],0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[9monthsupto12months]' ELSE ErrorinColumn +','+SPACE(1)+  '[9monthsupto12months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([9monthsupto12months],'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL([9monthsupto12months],0))>100
 PRINT 'DUB7'
 
 
  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[9monthsupto12months]' ELSE ErrorinColumn +','+SPACE(1)+  '[9monthsupto12months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([9monthsupto12months],'')='' AND Action='A'

    UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '[9monthsupto12months]' ELSE ErrorinColumn +','+SPACE(1)+  '[9monthsupto12months]' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL([9monthsupto12months],'')<>'' AND Action='D'

-------------validations on Provision percentage Doubtful1-------


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in Doubtful1 field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in Doubtful1 field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful1' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful1' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC(Doubtful1)=0 AND ISNULL(Doubtful1,'')<>'') OR 
 ISNUMERIC(Doubtful1) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful1' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful1' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful1,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(Doubtful1,'') LIKE '%!%%' ESCAPE '!'--added by Mayuresh to consider % as string on 20241105
 AND ISNUMERIC(Doubtful1) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC(Doubtful1) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in Doubtful1 field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in Doubtful1 field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful1' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful1' END  
		,Srnooferroneousrows=V.SrNo
								  

 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful1,'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(Doubtful1,0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful1' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful1' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful1,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(Doubtful1,0))>100
 PRINT 'DUB8'

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful1' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful1' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful1,'')='' AND Action='A'

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful1' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful1' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful1,'')<>'' AND Action='D'

-------------validations on Provision percentage Doubtful2-------


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in Doubtful2 field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in Doubtful2 field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful2' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful2' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC(Doubtful2)=0 AND ISNULL(Doubtful2,'')<>'') OR 
 ISNUMERIC(Doubtful2) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful2' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful2' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful2,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(Doubtful2,'')LIKE '%!%%' ESCAPE '!' --added by Mayuresh to consider % as string on 20241105
 AND ISNUMERIC(Doubtful2) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC(Doubtful2) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in Doubtful2 field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in Doubtful2 field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful2' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful2' END  
		,Srnooferroneousrows=V.SrNo
								  

 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful2,'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(Doubtful2,0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful2' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful2' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful2,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(Doubtful2,0))>100
 PRINT 'DUB9'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful2' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful2' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful2,'')='' AND Action='A'

    UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful2' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful2' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful2,'')<>'' AND Action='D'

-------------validations on Provision percentage Doubtful3-------


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in Doubtful3 field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in Doubtful3 field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful3' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful3' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC(Doubtful3)=0 AND ISNULL(Doubtful3,'')<>'') OR 
 ISNUMERIC(Doubtful3) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful3' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful3' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful3,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(Doubtful3,'') LIKE '%!%%' ESCAPE '!'  --added by Mayuresh to consider % as string on 20241105
 AND ISNUMERIC(Doubtful3) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC(Doubtful3) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in Doubtful3 field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in Doubtful3 field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful3' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful3' END  
		,Srnooferroneousrows=V.SrNo
								  

 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful3,'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(Doubtful3,0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful3' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful3' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful3,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(Doubtful3,0))>100
 PRINT 'DUB10'

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful3' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful3' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful3,'')='' AND Action='A'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Doubtful3' ELSE ErrorinColumn +','+SPACE(1)+  'Doubtful3' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Doubtful3,'')<>'' AND Action='D'

-------------validations on Provision percentage Loss-------


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in Loss field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in Loss field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Loss' ELSE ErrorinColumn +','+SPACE(1)+  'Loss' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC(Loss)=0 AND ISNULL(Loss,'')<>'') OR 
 ISNUMERIC(Loss) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Loss' ELSE ErrorinColumn +','+SPACE(1)+  'Loss' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Loss,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(Loss,'')LIKE '%!%%' ESCAPE '!'   --added by Mayuresh to consider % as string on 20241105
 AND ISNUMERIC(Loss) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC(Loss) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in Loss field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in Loss field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Loss' ELSE ErrorinColumn +','+SPACE(1)+  'Loss' END  
		,Srnooferroneousrows=V.SrNo
								  

 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Loss,'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(Loss,0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Loss' ELSE ErrorinColumn +','+SPACE(1)+  'Loss' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Loss,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(Loss,0))>100
 PRINT 'DUB11'


   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Loss' ELSE ErrorinColumn +','+SPACE(1)+  'Loss' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Loss,'')='' AND Action='A'

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Loss' ELSE ErrorinColumn +','+SPACE(1)+  'Loss' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(Loss,'')<>'' AND Action='D'
 /*
-------------validations on Provision percentage ProvisionUnSecured-------


 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Provision percentage in ProvisionUnSecured field. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Provisionpercentage in ProvisionUnSecured field. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ProvisionUnSecured' ELSE ErrorinColumn +','+SPACE(1)+  'ProvisionUnSecured' END  
		,Srnooferroneousrows=V.SrNo							
 FROM UploadProvisionPolicy V  
 WHERE (ISNUMERIC(ProvisionUnSecured)=0 AND ISNULL(ProvisionUnSecured,'')<>'') OR 
 ISNUMERIC(ProvisionUnSecured) LIKE '%^[0-9]%'
 PRINT 'INVALID' 

 UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ProvisionUnSecured' ELSE ErrorinColumn +','+SPACE(1)+  'ProvisionUnSecured' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(ProvisionUnSecured,'') LIKE '%[,!@#$%^&*()+=/\]%' --OR ISNULL(ProvisionUnSecured,'')LIKE '%!%%' ESCAPE '!'   --added by Mayuresh to consider % as string on 20241105
  AND ISNUMERIC(ProvisionUnSecured) LIKE '%^[0-9]%'
 --LIKE'%[,!@#$%^&*()_-+=/]%' AND ISNUMERIC(ProvisionUnSecured) LIKE '%^[0-9]%'

  UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Provisionpercentage in ProvisionUnSecured field. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Provisionpercentage in ProvisionUnSecured field. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ProvisionUnSecured' ELSE ErrorinColumn +','+SPACE(1)+  'ProvisionUnSecured' END  
		,Srnooferroneousrows=V.SrNo
								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(ProvisionUnSecured,'')<>''
 AND TRY_CONVERT(DECIMAL(18,2),ISNULL(ProvisionUnSecured,0)) <0

   UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Provision Percentage should be less than 100. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Provision Percentage should be less than 100. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ProvisionUnSecured' ELSE ErrorinColumn +','+SPACE(1)+  'ProvisionUnSecured' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(ProvisionUnSecured,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(ProvisionUnSecured,0))>100
 PRINT 'DUB12'

 
    UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should not be blank for new scheme code'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should not be blank for new scheme code'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ProvisionUnSecured' ELSE ErrorinColumn +','+SPACE(1)+  'ProvisionUnSecured' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(ProvisionUnSecured,'')='' AND Action='A'

    UPDATE UploadProvisionPolicy
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Percentage should be blank for Scheme Code deletion.'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Percentage should be blank for Scheme Code deletion.'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'ProvisionUnSecured' ELSE ErrorinColumn +','+SPACE(1)+  'ProvisionUnSecured' END  
		,Srnooferroneousrows=V.SrNo								  
 FROM UploadProvisionPolicy V  
 WHERE ISNULL(ProvisionUnSecured,'')<>'' AND Action='D'

 */
 

  ---------------------- Validation for Effectivedate ------------------------- 

PRINT 'Scheme Code and Source System Name not matched'

UPDATE UploadProvisionPolicy
SET  
    ErrorMessage = CASE WHEN ISNULL(ErrorMessage, '') = '' THEN 'Effectivedate should be greater than processing date '  
                        ELSE ErrorMessage + ', ' + 'Effectivedate should be greater than processing date ' END,
    ErrorinColumn = CASE WHEN ISNULL(ErrorinColumn, '') = '' THEN 'Effectivedate' ELSE ErrorinColumn + ', ' + 'Effectivedate' END,   
    Srnooferroneousrows = V.SrNo
FROM UploadProvisionPolicy V  
WHERE V.Effectivedate <= @processingdate
   
    

 GOTO valid

  END
	
   ErrorData:  
   PRINT 'no'  

		SELECT *,'Data'TableName
		FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		return

   valid:
		IF NOT EXISTS(Select 1 from  ProvisionPolicy_stg WHERE filname=@FilePathUpload)
		BEGIN
		PRINT 'NO ERRORS'
			
			INSERT into dbo.MasterUploadData
			(SR_No,ColumnName,ErrorData,ErrorType,FileNames,Flag) 
			SELECT '' SrNo , '' ColumnName,'' ErrorData,'' ErrorType,@filepath,'SUCCESS' 
			
		END
		ELSE
		BEGIN
			PRINT 'VALIDATION ERRORS'
			INSERT into dbo.MasterUploadData
			(SR_No,ColumnName,ErrorData,ErrorType,FileNames,Srnooferroneousrows,Flag) 
			SELECT SrNo,ErrorinColumn,ErrorMessage,ErrorinColumn,@filepath,Srnooferroneousrows,'SUCCESS' 
			FROM UploadProvisionPolicy 


			GOTO final
		END

		

  IF EXISTS (SELECT 1 FROM  dbo.MasterUploadData   WHERE FileNames=@filepath AND  ISNULL(ERRORDATA,'')<>'') 
   -- added for delete Upload status while error while uploading data.  
   BEGIN  
    delete from UploadStatus where FileNames=@filepath  
   END  

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

		 IF EXISTS(SELECT 1 FROM ProvisionPolicy_stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM ProvisionPolicy_stg
		 WHERE filname=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.ProvisionPolicy_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

	END
	ELSE
	BEGIN
	PRINT ' DATA NOT PRESENT'
	PRINT '@filepath'
	PRINT  @filepath

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

	PRINT 'p'

   END  TRY
  

  BEGIN CATCH
	PRINT 'BEGIN CATCH'

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()

	IF EXISTS(SELECT 1 FROM ProvisionPolicy_stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM ProvisionPolicy_stg
		 WHERE filname=@FilePathUpload

		 

		 PRINT 'ROWS DELETED FROM DBO.ProvisionPolicy_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

  END CATCH

END
 
GO