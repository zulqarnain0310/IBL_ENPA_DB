SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROCEDURE [dbo].[ValidateExcel_DataUpload_CustMOCUpload] 
@MenuID INT=10,  
@UserLoginId  VARCHAR(20)='fnachecker',  
@Timekey INT=49999
,@filepath VARCHAR(MAX) ='CustMOCUpload.xlsx'  
WITH RECOMPILE  
AS  

--exec [dbo].[ValidateExcel_DataUpload_CustMOCUpload] @MenuID=N'97',@UserLoginId=N'iblfm8840',@Timekey=N'26084',@filepath=N'Customer_MOC_Upload (2).xlsx'

--DECLARE  
  
--@MenuID INT=97,  
--@UserLoginId varchar(20)=N'1maker',  
--@Timekey int=N'26084'
--,@filepath varchar(500)=N'Customer_MOC_Upload (1).xlsx'  
  
BEGIN

BEGIN TRY  
--BEGIN TRAN  
  
--Declare @TimeKey int  
    --Update UploadStatus Set ValidationOfData='N' where FileNames=@filepath  
     
	 SET DATEFORMAT DMY

 --Select @Timekey=Max(Timekey) from dbo.SysProcessingCycle  
 -- where  ProcessType='Quarterly' ----and PreMOC_CycleFrozenDate IS NULL
 
 SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y') 
 --Set  @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
 --                   Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
 --                      where A.CurrentStatus='C')

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


IF (@MenuID=97)	
BEGIN


	  IF OBJECT_ID('UploadCustMOC') IS NOT NULL  
	  BEGIN
	   
		DROP TABLE  UploadCustMOC
	
	  END
	  
  IF NOT (EXISTS (SELECT 1 FROM CustMOCUpload_stg where filname=@FilePathUpload))

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
 	   into UploadCustMOC 
	   from CustMOCUpload_stg 
	   WHERE filname=@FilePathUpload
  
END

--create  nonclustered index INX_NCIF_Id ON UploadCustMOC (NCIF_Id)

  ------------------------------------------------------------------------------  
 
	UPDATE UploadCustMOC
	SET  
        ErrorMessage='There is no data in excel. Kindly check and upload again' 
		,ErrorinColumn='SrNo,AsOnDate,NCIF_Id,CustomerId,CustomerName,MOC_AssetClassification,MOC_NPADate,AdditionalProvisionPercentage
						,MOC_Reason,Remark,MOC_Type,MOC_Source'    
		,Srnooferroneousrows=''
 FROM UploadCustMOC V  
 WHERE ISNULL(SrNo,'')=''
AND ISNULL(AsOnDate,'')=''
AND ISNULL(NCIF_Id,'')=''
AND ISNULL(CustomerId,'')=''
AND ISNULL(CustomerName,'')=''
AND ISNULL(MOC_AssetClassification,'')=''
AND ISNULL(MOC_NPADate,'')=''
--AND ISNULL(MOC_SecurityValue,'')=''
AND ISNULL(AdditionalProvisionPercentage,'')=''
AND ISNULL(MOC_Reason,'')=''
AND ISNULL(Remark,'')=''
AND ISNULL(MOC_Type,'')=''
AND ISNULL(MOC_Source,'')=''



  IF EXISTS(SELECT 1 FROM UploadCustMOC WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  END


-----validations on SrNo
	 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 	'SrNo is mandatory. Kindly check and upload again' 
		                  ELSE ErrorMessage+','+SPACE(1)+ 'SrNo is mandatory. Kindly check and upload again'
		  END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=''
	FROM UploadCustMOC V  
	WHERE ISNULL(v.SrNo,'')=''
	PRINT '1'

UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadCustMOC V  
 WHERE ISNULL(SrNo,'')  LIKE '%[,!@#$%^&*()_-+=/\]%'
 Print '2'

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SRNO'    
		,Srnooferroneousrows=SRNO  
  
  FROM UploadCustMOC v
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'
  PRINT '3'
  
  update UploadCustMOC
  set SrNo=NULL
  WHERE (ISNUMERIC(SrNo)=0 AND ISNULL(SrNo,'')<>'') OR  ISNUMERIC(SrNo) LIKE '%^[0-9]%'

  ----- Checking Duplicate SrNo's
  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SrNo ORDER BY SrNo)ROW
   FROM UploadCustMOC
   )A
   WHERE ROW>1

 PRINT 'DUB'  


  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate SrNo, kindly check and upload again' 
					ELSE ErrorMessage+','+SPACE(1)+     'Duplicate SrNo, kindly check and upload again' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SrNo' ELSE ErrorinColumn +','+SPACE(1)+  'SrNo' END
		,Srnooferroneousrows=SrNo
		
         
		
 FROM UploadCustMOC V  
	WHERE  V.SrNo IN(SELECT SrNo FROM #R )
	Print 'DUB1'

-------------  Validations on AsOnDate Date
UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Can not be Blank . Please enter the AsOnDate and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Can not be Blank. Please enter the AsOnDate and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
	  

 FROM UploadCustMOC V  
 WHERE ISNULL(AsOnDate,'')='' 

 SET DATEFORMAT DMY
UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format dd/mm/yyyy'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format dd/mm/yyyy'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
		  
 FROM UploadCustMOC V  
 WHERE ISNULL(AsOnDate,'')<>'' AND ISDATE(AsOnDate)=0

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE ErrorinColumn +','+SPACE(1)+  'AsOnDate' END  
		,Srnooferroneousrows=V.SrNo
  
--select *
 FROM UploadCustMOC V  
 WHERE ISNULL(AsOnDate,'')  LIKE '%[,!@#$%^&*()_+=\]%'

 ----- Future Date Comparison
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Should not be Future Date . Please enter the AsOnDate and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Should not be Future Date. Please enter the AsOnDate and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo
		 

 FROM UploadCustMOC V  
 --WHERE ISNULL(AsOnDate,'')<>'' AND  CONVERT(date,AsOnDate,103) > CONVERT(date,GETDATE(),103)
 WHERE  (CASE WHEN ISNULL(AsOnDate,'')<>'' AND  ISDATE(AsOnDate)=1 
               THEN CASE WHEN CONVERT(date,AsOnDate) > CONVERT(date,GETDATE()) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1
PRINT 'DUB4'

SET DATEFORMAT DMY
 UPDATE  UploadCustMOC 
	SET AsOnDate=NULL 
 WHERE ISDATE(AsOnDate)=0

 PRINT 'DUB41'
 IF Exists (Select 1 from UploadCustMOC where Isnumeric(SrNo)=1)
 Begin

 PRINT 'DUB42'
 Declare @count int
 select  @count = COUNT(SrNo) from UploadCustMOC GROUP BY AsOnDate 
 IF EXISTS (SELECT 1 FROM UploadCustMOC GROUP BY AsOnDate HAVING COUNT(*)<@count)
 BEGIN
UPDATE UploadCustMOC
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
 
 ------------- VALIDATIONS ON ASONDate Should be equal to latest MOC Initiated which are not frozen
UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AsOnDate Should be equal to latest MOC Initiated which are not frozen. Please enter the Correct AsOnDate and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'AsOnDate Should be equal to latest MOC Initiated which are not frozen. Please enter the Correct AsOnDate and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AsOnDate' ELSE   ErrorinColumn +','+SPACE(1)+'AsOnDate' END      
		,Srnooferroneousrows=V.SrNo 

 FROM UploadCustMOC V 
 WHERE ISNULL(V.AsOnDate,'')<>''
 AND convert(date,V.AsOnDate,103) NOT IN(Select DATE FROm SysDataMatrix WHERE CurrentStatus_MOC='C')

 
 
----  ---------VALIDATIONS ON Dedupe_ID-UCIC-Enterprise_CIF(NCIF_ID)	[NCIF_ID = 5 Minutes]
  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Dedupe_ID-UCIC-Enterprise_CIF ID cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadCustMOC V  
 WHERE ISNULL(NCIF_Id,'')='' 

-- --------------- Logic for Invalid NCIF_ID Found --------- START ----
	
--	IF object_id('tempdb..#NCIF_ID')is not null
--		drop table #NCIF_ID

-- select NCIF_Id into #NCIF_ID from UploadCustMOC
--	except
-- select NCIF_Id from NPA_IntegrationDetails where EffectiveFromTimeKey=@Timekey and EffectiveToTimeKey=@Timekey



-- Update A
--SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' NCIF_Id is invalid. Kindly check the entered NCIF_Id'     
-- ELSE ErrorMessage+','+SPACE(1)+' NCIF_Id is invalid. Kindly check the entered NCIF_Id'      END
-- ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE   ErrorinColumn +','+SPACE(1)+'NCIF_Id' END  
-- from UploadCustMOC a
--	inner join #NCIF_ID b
--		on a.NCIF_Id=b.NCIF_Id
 


 --IF OBJECT_ID('TempDB..#NPA_IntegrationDetails') IS NOT NULL DROP TABLE #NPA_IntegrationDetails
 --select NCIF_Id,CustomerId into #NPA_IntegrationDetails from NPA_IntegrationDetails where EffectiveFromTimeKey=@TimeKey AND EffectiveToTimeKey=@TimeKey

-- Declare @CountNCIF Int,@I1 Int,@EntityKey Int
-- Declare @NCIF_Id Varchar(100)=''
--Declare @NCIF_Id_Found Int=0

--IF OBJECT_ID('TempDB..#tmpNCIF') IS NOT NULL DROP TABLE #tmpNCIF; 
  
--  Select  ROW_NUMBER() OVER(ORDER BY  CONVERT(INT,EntityKey) ) RecentRownumber,EntityKey,NCIF_Id  into #tmpNCIF from UploadCustMOC
                  
-- Select @CountNCIF=Count(*) from #tmpNCIF
  
--   SET @I1=1
--   SET @EntityKey=0

--   SET @NCIF_Id=''
--     While(@I1<=@CountNCIF)
--               BEGIN 
			   
--			      Select @NCIF_Id =NCIF_Id,@EntityKey=EntityKey  from #tmpNCIF where RecentRownumber=@I1 
--							order By EntityKey

--					  Select      @NCIF_Id_Found=Count(1)
--				from NPA_IntegrationDetails  A Where NCIF_Id=@NCIF_Id AND
--				 EffectiveFromTimeKey=@TimeKey AND EffectiveToTimeKey=@TimeKey

--				IF @NCIF_Id_Found =0
--				    Begin
--				 Update UploadCustMOC
--										   SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' NCIF_Id is invalid. Kindly check the entered NCIF_Id'     
--											 ELSE ErrorMessage+','+SPACE(1)+' NCIF_Id is invalid. Kindly check the entered NCIF_Id'      END
--											 ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE   ErrorinColumn +','+SPACE(1)+'NCIF_Id' END   
--										   Where EntityKey=@EntityKey
--					END
--					  SET @I1=@I1+1
--					  SET @NCIF_Id=''
								
								
--			   END


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
										   
										   From UploadCustMOC A
										   Where Not Exists (Select 1 from #tmpNCIF B Where A.NCIF_Id=B.NCIF_Id)



  print 'NCIF_Id(NCIF_ID)'
  
  ---------------------new add start--------- 28092021 ----------------MoC Asset Class Should be same for NCIF_ID. 

  IF OBJECT_ID('TempDB..#MOCAssetNcif') is Not Null
  Drop Table #MOCAssetNcif

  Select NCIF_Id,count(*)Cnt INto #MOCAssetNcif from UploadCustMOC 
  Group By NCIF_Id 
  Having Count(*)>1

  IF OBJECT_ID('TempDB..#MOCAssetNcif_New') is Not Null
  Drop Table #MOCAssetNcif_New

  Select A.NCIF_Id,MOC_AssetClassification,Count(*)Cnt INto #MOCAssetNcif_New  from UploadCustMOC A
  Inner Join #MOCAssetNcif B ON A.NCIF_Id=b.NCIF_Id
  Group by A.NCIF_Id,MOC_AssetClassification
 HAVING COUNT(*)<=1




  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MoC Asset Class Should be same for NCIF_ID.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'MoC Asset Class Should be same for NCIF_ID.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC_AssetClassification' ELSE ErrorinColumn +','+SPACE(1)+  'MOC_AssetClassification' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadCustMOC V 
 Where Exists(Select 1 from #MOCAssetNcif_New A where A.NCIF_Id=V.NCIF_Id)
 
 --(
 --Select NCIF_Id,MOC_AssetClassification,ROW_NUMBER() Over (Order by NCIF_Id) AS SrNo FROM UploadCustMOC V  
 --Group by NCIF_Id,MOC_AssetClassification
 --HAVING COUNT(NCIF_Id)<=1
 --)C
 --------------------------------new add end----------------------------------------------
 

UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo

 FROM UploadCustMOC V  
 WHERE ISNULL(NCIF_Id,'') LIKE'%[,!@#$%^&*()+=-_/\]%'
   
  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SRNO
 FROM UploadCustMOC V  
 WHERE ISNULL(NCIF_Id,'') <>'' and LEN(NCIF_Id)>19

 ------- Checking for Both NCIF_ID AND CustomerID Should Be Present 
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'The Column Dedupe_ID-UCIC-Enterprise_CIF ID is mandatory.  Kindly check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'The Column Dedupe_ID-UCIC-Enterprise_CIF ID is mandatory.  Kindly check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Dedupe_ID-UCIC-Enterprise_CIF ID' ELSE ErrorinColumn +','+SPACE(1)+  'Dedupe_ID-UCIC-Enterprise_CIF ID' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE (ISNULL(CustomerId,'')=''  AND ISNULL(NCIF_Id,'')='')

-- -------------------------FOR DUPLICATE NCIF_ID
 IF OBJECT_ID('TEMPDB..#NCIF_ID_DUP') IS NOT NULL
 DROP TABLE #NCIF_ID_DUP

 SELECT * INTO #NCIF_ID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY NCIF_Id ORDER BY  NCIF_Id)AS ROW FROM UploadCustMOC
 )A
 WHERE ROW>1

-- --  ---------VALIDATIONS ON Dedupe ID - UCIC - Enterprise CIF(NCIF_ID)

---------------- VALIDATIONS ON Source_System_CIF_Customer_Identifier (CustomerID)	[CustomerID = 5 Minutes 21 Seconds]

UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Source_System_CIF_Customer_Identifier cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Source_System_CIF_Customer_Identifier cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source_System_CIF_Customer_Identifier' ELSE ErrorinColumn +','+SPACE(1)+  'Source_System_CIF_Customer_Identifier' END  
		,Srnooferroneousrows=V.SrNo 
 FROM UploadCustMOC V  
 WHERE ISNULL(CustomerId,'')='' 

--  ------------- Logic for Invalid CustomerId Found --------- START ----

--  IF object_id('tempdb..#cust_ID')is not null
--		drop table #cust_ID

-- select CustomerId into #cust_ID from UploadCustMOC
--	except
-- select CustomerId from NPA_IntegrationDetails where EffectiveFromTimeKey=26176 and EffectiveToTimeKey=26176



-- Update A
--SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' CustomerId is invalid. Kindly check the entered CustomerId'     
-- ELSE ErrorMessage+','+SPACE(1)+' CustomerId is invalid. Kindly check the entered CustomerId'      END
-- ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CustomerId' ELSE   ErrorinColumn +','+SPACE(1)+'CustomerId' END  
-- from UploadCustMOC a
--	inner join #cust_ID b
--		on a.CustomerId=b.CustomerId

/*
 Declare @CountCustID Int,@I2 Int,@EntityKeyCust Int
 Declare @CustId Varchar(100)=''
Declare @CustomerId_Found Int=0

IF OBJECT_ID('TempDB..#tmpCustID') IS NOT NULL DROP TABLE #tmpCustID; 
  
  Select  ROW_NUMBER() OVER(ORDER BY  CONVERT(INT,EntityKey) ) RecentRownumber,EntityKey,CustomerId  into #tmpCustID from UploadCustMOC
                  
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
				 Update UploadCustMOC
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
										   
										   From UploadCustMOC A
										   Where Not Exists (Select 1 from #tmpNCIF B Where A.CustomerId=B.CustomerId)

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source_System_CIF_Customer_Identifier' ELSE ErrorinColumn +','+SPACE(1)+  'Source_System_CIF_Customer_Identifier' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(CustomerId,'') LIKE'%[,!@#$%^&*()+=-/\]%'--changed on 20230606 on UAT deployed on 20230712 by zain
   
  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Source_System_CIF_Customer_Identifier found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Dedupe_ID-UCIC-Enterprise_CIF ID found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source_System_CIF_Customer_Identifier' ELSE ErrorinColumn +','+SPACE(1)+  'Source_System_CIF_Customer_Identifier' END  
		,Srnooferroneousrows=V.SRNO

 FROM UploadCustMOC V  
 WHERE ISNULL(CustomerId,'') <>'' and LEN(CustomerId)>19

 ------- Checking for Both CustomerID AND NCIF_ID Should Be Present 
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Column Source_System_CIF_Customer_Identifier is mandatory. Kindly check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Column Source_System_CIF_Customer_Identifier is mandatory. Kindly check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Source_System_CIF_Customer_Identifier' ELSE ErrorinColumn +','+SPACE(1)+  'Source_System_CIF_Customer_Identifier' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE (ISNULL(NCIF_Id,'')='' AND ISNULL(CustomerId,'')='')

 -- -------------------------FOR DUPLICATE CUST_ID's
 IF OBJECT_ID('TEMPDB..#CUSTID_DUP') IS NOT NULL
 DROP TABLE #CUSTID_DUP

 SELECT * INTO #CUSTID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY CustomerId ORDER BY  CustomerId)AS ROW FROM UploadCustMOC
 )A
 WHERE ROW>1

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Duplicate records found. Customer ID are repeated.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Duplicate records found. Customer ID are repeated.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer ID' ELSE ErrorinColumn +','+SPACE(1)+  'Customer ID' END  
		,Srnooferroneousrows=V.SRNO
 FROM UploadCustMOC V  
 WHERE ISNULL(CustomerId,'') <>'' and CustomerId IN(SELECT CustomerId FROM #CUSTID_DUP)

------------------------------------------------

-- /*validations on CustomerName*/
  
 -- UPDATE UploadCustMOC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CustomerName cannot be blank . Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+'CustomerName cannot be blank . Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CustomerName' ELSE   ErrorinColumn +','+SPACE(1)+'CustomerName' END   
	--	,Srnooferroneousrows=V.SrNo
 --FROM UploadCustMOC V  
 --WHERE ISNULL(CustomerName,'')=''

 -- UPDATE UploadCustMOC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Customer Name' ELSE ErrorinColumn +','+SPACE(1)+  'Customer Name' END  
	--	,Srnooferroneousrows=V.SrNo
 --FROM UploadCustMOC V  
 --WHERE ISNULL(CustomerName,'') LIKE'%[,!@#$%^&*-_/\()+=]%'
 
 --/*validations on MOC Asset Classification */

 ---------- MOC_AssetClassification Column is not mandatory (i.e. Optional)

  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Valid Asset Classification code not provided. Kindly Remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Valid Asset Classification code not provided. Kindly Remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AssetClassification' ELSE   ErrorinColumn +','+SPACE(1)+'AssetClassification' END       
		,Srnooferroneousrows=V.SrNo
	 FROM UploadCustMOC V  
   LEFT JOIN DimAssetClass B
   ON V.MOC_AssetClassification=B.AssetClassShortName
   AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
 WHERE ISNULL(V.MOC_AssetClassification,'')<>''
 AND B.AssetClassShortName IS NULL
 

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Asset Classification found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid Asset Classification found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Asset Classification' ELSE ErrorinColumn +','+SPACE(1)+  'Asset Classification' END  
		,Srnooferroneousrows=V.SRNO
 FROM UploadCustMOC V  
 WHERE ISNULL(MOC_AssetClassification,'') <>'' and LEN(MOC_AssetClassification)>3

  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AssetClassification' ELSE ErrorinColumn +','+SPACE(1)+  'AssetClassification' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(MOC_AssetClassification,'') LIKE'%[,!@#$%^&*-_/\()+=]%'

 -- ----------- /*validations on MOC NPA Date */

 SET DATEFORMAT DMY
UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid date format. Please enter the date in format dd/mm/yyyy'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid date format. Please enter the date in format dd/mm/yyyy'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC NPA Date' ELSE   ErrorinColumn +','+SPACE(1)+'MOC NPA Date' END      
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(MOC_NPADate,'')<>'' AND ISDATE(MOC_NPADate)=0

 ---------- Checking for NPA Date is Mandatory When Asset Classification is either of SUB / DB1 / DB2 / DB3 / LOS.
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA Date is mandatory since Asset class is set as SUB/DB1/DB2/DB3/LOS/WO. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'NPA Date is mandatory since Asset class is set as SUB/DB1/DB2/DB3/LOS/WO. Kindly check and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC NPA Date' ELSE   ErrorinColumn +','+SPACE(1)+'MOC NPA Date' END      
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(V.MOC_AssetClassification,'') IN('SUB','DB1','DB2','DB3','LOS','WO') AND (ISNULL(V.MOC_NPADate,''))=''

 ----------- Checking for NPA Date should not be present if Asset classification is STD
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA Date must be blank since Asset class is STD. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'NPA Date must be blank since Asset class is STD. Kindly check and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC NPA Date' ELSE   ErrorinColumn +','+SPACE(1)+'MOC NPA Date' END      
		,Srnooferroneousrows=V.SrNo
		  

 FROM UploadCustMOC V  
 WHERE (ISNULL(V.MOC_AssetClassification,'') IN('STD') or ISNULL(V.MOC_AssetClassification,'') IS NULL) AND (V.MOC_NPADate)<>''

 ---------------------- MOC NPA Date Should be Blank If MOC Asset Classification is also Blank
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NPA Date should be Blank since Asset Class is Blank. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'NPA Date should be Blank since Asset Class is Blank. Kindly check and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NPADATE' ELSE   ErrorinColumn +','+SPACE(1)+'NPADATE' END      
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE (ISNULL(V.MOC_AssetClassification,'') = '' AND ISNULL(V.MOC_NPADate,'') <> '')

 ----- AsOnDate Comparison
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MOC NPA Date Should be Less than or Equal to AsOnDate. Please enter the MOC NPA Date and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'MOC NPA Date Should be Less than or Equal to AsOnDate. Please enter the MOC NPA Date and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC NPA Date' ELSE   ErrorinColumn +','+SPACE(1)+'MOC NPA Date' END      
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 --WHERE ISNULL(MOC_NPADate,'')<>'' AND  (CONVERT(date,MOC_NPADate,103) > CONVERT(date,AsOnDate,103))
 WHERE  (CASE WHEN ISNULL(MOC_NPADate,'')<>'' AND  ISDATE(MOC_NPADate)=1 
               THEN CASE WHEN CONVERT(date,MOC_NPADate) > CONVERT(date,AsOnDate) 
			             THEN 1 ELSE 0 END 
			   ELSE 2 END)=1

   ------ -------validations on Additional provision percentage

  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Invalid Additional Provision Percentage. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'Invalid Additional Provision Percentage. Please check the values and upload again'      END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Percentage' END  
		,Srnooferroneousrows=V.SRNO
								

 FROM UploadCustMOC V  
 WHERE (ISNUMERIC(AdditionalProvisionPercentage)=0 AND ISNULL(AdditionalProvisionPercentage,'')<>'') OR 
 ISNUMERIC(AdditionalProvisionPercentage) LIKE '%^[0-9]%'

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Percentage' END  
		,Srnooferroneousrows=V.SRNO
								  

 FROM UploadCustMOC V  
 WHERE ISNULL(Additionalprovisionpercentage,'') LIKE'%[,!@#$%^&*()_-+=/\]%'
 PRINT 'INVALID' 

  UPDATE UploadCustMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Additional Provision Percentage. Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Additional Provision Percentage. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Percentage' END  
		,Srnooferroneousrows=V.SRNO
 FROM UploadCustMOC V  
 WHERE ISNULL(Additionalprovisionpercentage,'')<>''
 --AND TRY_CONVERT(DECIMAL(25,2),ISNULL(InterestReversalAmount,0)) <0
 AND TRY_CONVERT(DECIMAL(6,2),ISNULL(Additionalprovisionpercentage,0)) <0

 UPDATE UploadCustMOC
	SET  
        ErrorMessage= CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Additional Provision Percentage Should be less than 100. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Additional Provision Percentage Should be less than 100. Kindly check and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Additional Provision Percentage' ELSE ErrorinColumn +','+SPACE(1)+  'Additional Provision Percentage' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(Additionalprovisionpercentage,'')<>''
 AND TRY_CONVERT(Decimal(6,2),ISNULL(Additionalprovisionpercentage,0))>100
 --AND TRY_CONVERT(Decimal(6,2),ISNULL(Additionalprovisionpercentage,0))>100
 --AND CAST(ISNULL(Additionalprovisionpercentage,0.00) AS decimal) > 100.00

 ----------------------------------- Additional provision Percentage  Account/Customer Validation
 Declare @Count1 Int,@I Int,@Entity_Key Int
   Declare @CustomerId Varchar(100)=''
   Declare @AdditionalProvisionPercentageSum Decimal(16,2)=0
   Declare @AdditionalProvisionPercentage Decimal(16,2)=0
   SET @Count1=0
   /*
 IF OBJECT_ID('TempDB..#tmp') IS NOT NULL DROP TABLE #tmp; 
  
  Select  ROW_NUMBER() OVER(ORDER BY  CONVERT(INT,EntityKey) ) RecentRownumber,EntityKey,CustomerId,AdditionalProvisionPercentage  into #tmp from UploadCustMOC
                
 Select @Count1=Count(*) from #tmp
  
   SET @I=1
   SET @Entity_Key=0

   --Select * from UploadCustMOC
 
   SET @CustomerId=''
     While(@I<=@Count1)
               BEGIN 
			      Select @CustomerId =CustomerId,@Entity_Key=EntityKey,
				  @AdditionalProvisionPercentage=Case when ISNULL(AdditionalProvisionPercentage,'') = '' then 0 else CAST(AdditionalProvisionPercentage AS DECIMAL(6,2)) END
				  --,@AdditionalProvisionPercentage=AdditionalProvisionPercentage  
				  from #tmp where RecentRownumber=@I 
							order By EntityKey

				IF @AdditionalProvisionPercentage<>0
				BEGIN			 
					  Select      @AdditionalProvisionPercentageSum=SUM(ISNULL(AddlProvisionPer,0))
				from NPA_IntegrationDetails  A Where CustomerId=@CustomerId

				

				IF @AdditionalProvisionPercentageSum >0
				    Begin
				 Update UploadCustMOC
						 SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' AddlProvisionPer already exist throgh Account MOC.'     
											 ELSE ErrorMessage+','+SPACE(1)+' AddlProvisionPer already exist throgh Account MOC.'      END
								,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AddlProvisionPer' ELSE   ErrorinColumn +','+SPACE(1)+'AddlProvisionPer' END   
										      Where EntityKey=@Entity_Key
					END
				END
					  SET @I=@I+1
					  SET @CustomerId=''
								
								
			   END
*/

			Update a
						 SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' AddlProvisionPer already exist through Customer MOC.'     
											 ELSE ErrorMessage+','+SPACE(1)+' AddlProvisionPer already exist through Customer MOC.'      END
								,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AddlProvisionPer' ELSE   ErrorinColumn +','+SPACE(1)+'AddlProvisionPer' END   
				From UploadCustMOC a
			Inner Join NPA_IntegrationDetails B ON  A.NCIF_Id=B.NCIF_Id And A.CustomerId=B.CustomerId
			Where (B.EffectiveFromTimeKey=@Timekey and B.EffectiveToTimeKey=@timekey)
			ANd ISNULL(cast(AddlProvisionPer as numeric(10,2)),0)>0
			and (Case when ISNULL(a.AdditionalProvisionPercentage,'') = '' 
				then 0 else CAST(a.AdditionalProvisionPercentage AS DECIMAL(6,2)) END)>0 


 /*validations on MOC Reason*/
  
  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MOC Reason cannot be blank . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'MOC Reason cannot be blank . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Reason' ELSE   ErrorinColumn +','+SPACE(1)+'MOC Reason' END   
		,Srnooferroneousrows=V.SrNo
   FROM UploadCustMOC V  
 WHERE ISNULL(V.MOC_Reason,'')=''

 PRINT 'DUB6'

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters %[,!@#$%^&*()+=/\]% are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters %[,!@#$%^&*()+=/\]% are not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Reason' ELSE ErrorinColumn +','+SPACE(1)+  'MOC Reason' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(V.MOC_Reason,'') LIKE'%[,!@#$%^&*()+=/\]%'
 PRINT 'DUB8'

 ----------------------------------validation to check if customer moc reason is exists or not -05032024 by shubham kamble-------
 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'MOC Reason Not exists in Customer category, kindly enter existing reason and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'MOC Reason Not exists in Customer category, kindly enter existing reason and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Reason' ELSE ErrorinColumn +','+SPACE(1)+  'MOC Reason' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(V.MOC_Reason,'') NOT IN (select case when MocReasonName='Other reason of Customer MOC' then 'Other' else MocReasonName end from DimMocReason 
																																	where MocReasonCategory='Customer Reason' AND EffectiveToTimeKey=49999)
 PRINT 'MOC REASON VALIDATION'

------------------------------------------------------------------------------

 --20230621
 --UPDATE UploadCustMOC
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid MOC Reason.  Please check the values and upload again'     
	--					ELSE ErrorMessage+','+SPACE(1)+'Invalid MOC Reason.  Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Reason' ELSE   ErrorinColumn +','+SPACE(1)+'MOC Reason' END       
	--	,Srnooferroneousrows=V.SrNo
 --FROM UploadCustMOC V  
 --LEFT JOIN DimMocReason B
 --ON V.MOC_Reason=B.MocReasonName
 --AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)
 --WHERE ISNULL(V.MOC_Reason,'')<>''
 --AND B.MocReasonName IS NULL
 --PRINT 'DUB9'

 /*validations on Remark*/
  
  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Remark cannot be blank . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'Remark cannot be blank . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Remark' ELSE   ErrorinColumn +','+SPACE(1)+'Remark' END   
		,Srnooferroneousrows=V.SrNo
   FROM UploadCustMOC V  
 WHERE ISNULL(V.Remark,'')=''

 PRINT 'DUB10'

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'Remark' ELSE ErrorinColumn +','+SPACE(1)+  'Remark' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(V.Remark,'') LIKE'%[,!@#$%^&*()+=/\]%'
 PRINT 'DUB11'

 ----------------- Validations On MOC Type


	  UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MOC Type is mandatory . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'MOC Type is mandatory . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Type' ELSE   ErrorinColumn +','+SPACE(1)+'MOC Type' END   
		,Srnooferroneousrows=V.SrNo
							
   
   FROM UploadCustMOC V  
 WHERE ISNULL(MOC_Type,'')=''

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC_Type' ELSE ErrorinColumn +','+SPACE(1)+  'MOC_Type' END  
		,Srnooferroneousrows=V.SrNo
 FROM UploadCustMOC V  
 WHERE ISNULL(V.MOC_Type,'') LIKE'%[,!@#$%^&*()+=/\]%'

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MOC Type column will only accept value AUTO or MANUAL. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'MOC Type column will only accept value AUTO or MANUAL. Kindly check and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Type' ELSE   ErrorinColumn +','+SPACE(1)+'MOC Type' END   
		,Srnooferroneousrows=V.SrNo
							
   
   FROM UploadCustMOC V  
 WHERE ISNULL(MOC_Type,'') NOT IN('Auto','Manual')
 
 ----------------- Validations On MOC Source

UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MOC Source is mandatory . Please check the values and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'MOC Type is mandatory . Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Source' ELSE   ErrorinColumn +','+SPACE(1)+'MOC Source' END   
		,Srnooferroneousrows=V.SrNo
							
  --select * from UploadCustMOC 
   FROM UploadCustMOC V  
 WHERE ISNULL(MOC_Source,'')=''

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'Special characters - _ \ / not are allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'Special characters - _ \ / not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC_Source' ELSE ErrorinColumn +','+SPACE(1)+  'MOC_Source' END  
		,Srnooferroneousrows=V.SrNo
 

 FROM UploadCustMOC V  
 WHERE ISNULL(V.MOC_Source,'') LIKE'%[,!@#$%^&*()+=/\]%'

 UPDATE UploadCustMOC
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'MOC Source column will only accept value BANK, STAT AUDITOR or RBI. Kindly check and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+'MOC Source column will only accept value BANK, STAT AUDITOR or RBI. Kindly check and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'MOC Source' ELSE   ErrorinColumn +','+SPACE(1)+'MOC Source' END   
		,Srnooferroneousrows=V.SrNo
							
   
   FROM UploadCustMOC V  
 WHERE ISNULL(MOC_Source,'') NOT IN('Bank','Stat Auditor','RBI')

 Print '123'
 goto valid

  END
	
   ErrorData:  
   print 'no'  

		SELECT *,'Data'TableName
		FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		return

   valid:
		IF NOT EXISTS(Select 1 from  CustMOCUpload_Stg WHERE filname=@FilePathUpload)
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
			FROM UploadCustMOC 
			
			--PRINT 'VALIDATION ERRORS'
			
		--	----SELECT * FROM UploadCustMOC 

		--	--ORDER BY ErrorMessage,UploadCustMOC.ErrorinColumn DESC
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

		 IF EXISTS(SELECT 1 FROM CustMOCUpload_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM CustMOCUpload_Stg	
		 WHERE filname=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.CustMOCUpload_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
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

	----SELECT * FROM UploadCustMOC

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

	IF EXISTS(SELECT 1 FROM CustMOCUpload_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM CustMOCUpload_Stg	
		 WHERE filname=@FilePathUpload

		 PRINT 'ROWS DELETED FROM DBO.CustMOCUpload_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 END

	END CATCH

END
  
GO