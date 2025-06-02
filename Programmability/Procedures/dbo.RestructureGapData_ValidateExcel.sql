SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RestructureGapData_ValidateExcel] 
@MenuID INT=2011,  
@UserLoginId  VARCHAR(20)='',  
@Timekey INT=49999,
@filepath VARCHAR(MAX) =''  
WITH RECOMPILE  
AS  

BEGIN

BEGIN TRY  

	 SET DATEFORMAT DMY
	 SET NOCOUNT ON;

	 SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus ='C')--cast(getdate()as date)) 
	
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


IF (@MenuID=2011)	
BEGIN

	   IF OBJECT_ID('Upload_RestructureGapData') IS NOT NULL  
		  BEGIN
			DROP TABLE  Upload_RestructureGapData
		  END

		  print @FilePathUpload
		IF NOT (EXISTS (SELECT * FROM RestructureGapData_Stg where filname=@FilePathUpload))

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
 	   into Upload_RestructureGapData 
	   from RestructureGapData_Stg
	   WHERE filname=@FilePathUpload

END

PRINT 'START'
  ------------------------------------------------------------------------------  
	UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage='There is no data in excel. Kindly check and upload again' 
		,ErrorinColumn='SrNo,AsOnDate,NCIF_Id,CustomerId,SourceSystem,CustomerName,AccountID,GrossBalance,PrincipalOutstanding
		          ,UnservicedInterestAmount,Additionalprovisionpercentage,AdditionalprovisionAmount,AcceleratedprovisionPercentage'
		,Srnooferroneousrows=''
	FROM Upload_RestructureGapData V  
	WHERE ISNULL(SlNo,'')=''
	AND ISNULL(NCIF_ID,'')=''
	AND ISNULL([2ndRestructuringDate],'')=''
	AND ISNULL(AggregateExposure,'')=''
	AND ISNULL([CreditRating1],'')=''
	AND ISNULL([CreditRating2],'') = ''
	AND ISNULL(filname,'')=''

  IF EXISTS(SELECT 1 FROM Upload_RestructureGapData WHERE ISNULL(ErrorMessage,'')<>'')
  BEGIN
  PRINT 'NO DATA'
  GOTO ERRORDATA;
  END
 
  -----validations on Srno
 PRINT 'SRNO'
	 UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN	'Sr. No. cannot be blank.  Please check the values and upload again' 
								ELSE ErrorMessage+','+SPACE(1)+ 'Sr. No. cannot be blank.  Please check the values and upload again'	END
	,ErrorinColumn='SlNo'    
	,Srnooferroneousrows=''
	FROM Upload_RestructureGapData V  
	WHERE ISNULL(SlNo,'')=''

UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'SlNo Special characters not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'SlNo Special characters not allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SlNo' ELSE ErrorinColumn +','+SPACE(1)+  'SlNo' END  
		,Srnooferroneousrows=V.SlNo

 FROM Upload_RestructureGapData V  
 WHERE ISNULL(SlNo,'')  LIKE '%[,!@#$%^&*()_-+=/]%'

 UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid Sr. No.  Please check the values and upload again'     
								  ELSE ErrorMessage+','+SPACE(1)+ 'Invalid Sr. No.  Please check the values and upload again'      END
		,ErrorinColumn='SlNo'    
		,Srnooferroneousrows=SlNo  
  
  FROM Upload_RestructureGapData v
  WHERE (ISNUMERIC(SlNo)=0 AND ISNULL(SlNo,'')<>'') OR  ISNUMERIC(SlNo) LIKE '%^[0-9]%'

    UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid SlNo. Please check the Length ,length must be less than 11 and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid SlNo. Please check the Length,length must be less than 11 and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SlNo' ELSE ErrorinColumn +','+SPACE(1)+  'SlNo' END  
		,Srnooferroneousrows=V.SlNo  

 FROM Upload_RestructureGapData V  
 WHERE ISNULL(SlNo,'') <>'' and LEN(SlNo)>10

  update Upload_RestructureGapData
  set SlNo=NULL
  WHERE (ISNUMERIC(SlNo)=0 AND ISNULL(SlNo,'')<>'') OR  ISNUMERIC(SlNo) LIKE '%^[0-9]%'


  -------- CHECKING for DUPLICATE SRNO's
  IF OBJECT_ID('TEMPDB..#R') IS NOT NULL
  DROP TABLE #R

  SELECT * INTO #R FROM(
  SELECT *,ROW_NUMBER() OVER(PARTITION BY SlNo ORDER BY SlNo)ROW
   FROM Upload_RestructureGapData
   )A
   WHERE ROW>1

 PRINT 'DUB'  

  UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Following sr. no. are repeated' 
					ELSE ErrorMessage+','+SPACE(1)+     'Following sr. no. are repeated' END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'SRNO' ELSE ErrorinColumn +','+SPACE(1)+  'SRNO' END
		,Srnooferroneousrows=SlNo

 FROM Upload_RestructureGapData V  
	WHERE  V.SlNo IN(SELECT SlNo FROM #R )
PRINT 'Shakti1'  
--  -------------------------------------------VALIDATIONS ON (NCIF_ID)
  UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NCIF_Id cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'NCIF_Id cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE ErrorinColumn +','+SPACE(1)+  'NCIF_Id' END  
		,Srnooferroneousrows=V.SlNo  

 FROM Upload_RestructureGapData V  
 WHERE ISNULL(NCIF_Id,'')='' 

 if exists(select 1 from RestructureGapData_Stg where len(NCIF_Id)>0)
begin

 Declare @CountNCIF Int,@I1 Int,@EntityKey Int
 Declare @NCIF_Id Varchar(100)=''
Declare @NCIF_Id_Found Int=0

IF OBJECT_ID('TempDB..#tmpNCIF') IS NOT NULL DROP TABLE #tmpNCIF; 
  
  Select  NCIF_Id,CustomerId,CustomerACID 
  into #tmpNCIF from NPA_IntegrationDetails Where EffectiveFromTimeKey<=@Timekey And EffectiveToTimeKey>=@Timekey

  CREATE NONCLUSTERED INDEX [IX_#tmpNCIF_NPA_IntegrationDetails] ON #tmpNCIF
	(
		[NCIF_Id] ASC
	)

  Update A
										   SET   ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN ' NCIF_Id is invalid. Kindly check the entered NCIF_Id'     
											 ELSE ErrorMessage+','+SPACE(1)+' NCIF_Id is invalid. Kindly check the entered NCIF_Id'      END
											 ,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE   ErrorinColumn +','+SPACE(1)+'NCIF_Id' END   
										   
										   From Upload_RestructureGapData A
										   Where Not Exists (Select 1 from #tmpNCIF B Where A.NCIF_Id=B.NCIF_Id)



  print 'shakti111'
--  -------combination

UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN  'In NCIF_Id Special characters are not allowed, kindly remove and upload again'     
						ELSE ErrorMessage+','+SPACE(1)+ 'In NCIF_Id Special characters are  not are allowed, kindly remove and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE ErrorinColumn +','+SPACE(1)+  'NCIF_Id' END  
		,Srnooferroneousrows=V.SlNo 

 FROM Upload_RestructureGapData V  
 WHERE ISNULL(NCIF_Id,'')  LIKE'%[,!@#$%^&*()+=-_/\]%'
   
  UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'Invalid NCIF_Id found. Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+  'Invalid NCIF_Id found. Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE ErrorinColumn +','+SPACE(1)+  'NCIF_Id' END  
		,Srnooferroneousrows=V.SlNo  

 FROM Upload_RestructureGapData V  
 WHERE ISNULL(NCIF_Id,'') <>'' and LEN(NCIF_Id)>30

  ------- Checking for Both NCIF_ID AND CustomerID Should Be Present 

 UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NCIF_Id is mandatory.  Kindly check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'NCIF_Id is mandatory.  Kindly check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE ErrorinColumn +','+SPACE(1)+  'NCIF_Id' END  
		,Srnooferroneousrows=V.SlNo  

 FROM Upload_RestructureGapData V  
 WHERE ISNULL(NCIF_Id,'')=''

 -- -------------------------FOR DUPLICATE ACIDS
 IF OBJECT_ID('TEMPDB..#NCIF_ID_DUP') IS NOT NULL
 DROP TABLE #NCIF_ID_DUP

 SELECT * INTO #NCIF_ID_DUP FROM(
 SELECT *,ROW_NUMBER() OVER(PARTITION BY NCIF_Id ORDER BY  NCIF_Id)AS ROW FROM Upload_RestructureGapData
 )A
 WHERE ROW>1

 IF EXISTS (SELECT 1 FROM #NCIF_ID_DUP)
 BEGIN
  UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'NCIF_Id is Duplicate.  Kindly check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'NCIF_Id is Duplicate.  Kindly check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'NCIF_Id' ELSE ErrorinColumn +','+SPACE(1)+  'NCIF_Id' END  
		,Srnooferroneousrows=V.SlNo  

 FROM Upload_RestructureGapData V  
 WHERE NCIF_Id IN (SELECT NCIF_Id FROM #NCIF_ID_DUP)
 END

 END
 -------------------------------------------------------------------------------//Shakti12092022

 --  UPDATE Upload_RestructureGapData
	--SET  
 --       ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN '2ndRestructuringDate cannot be blank.  Please check the values and upload again'     
	--				ELSE ErrorMessage+','+SPACE(1)+'2ndRestructuringDate cannot be blank.  Please check the values and upload again'     END
	--	,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '2ndRestructuringDate' ELSE ErrorinColumn +','+SPACE(1)+  '2ndRestructuringDate' END  
	--	,Srnooferroneousrows=V.SlNo  

	--FROM Upload_RestructureGapData V  
	--WHERE ISNULL([2ndRestructuringDate],'')=''
	
if exists(select 1 from RestructureGapData_Stg where len([2ndRestructuringDate])>0)
begin
	   UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN '2ndRestructuringDate should be in dd/mm/yyyy e.g 01/01/2019'     
					ELSE ErrorMessage+','+SPACE(1)+'2ndRestructuringDate should be in dd/mm/yyyy e.g 01/01/2019'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '2ndRestructuringDate' ELSE ErrorinColumn +','+SPACE(1)+  '2ndRestructuringDate' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE ISNULL([2ndRestructuringDate],'') not like '%[0-3][0-9][/][0-1][0-9][/][0-9][0-9][0-9][0-9]%'
	and len([2ndRestructuringDate])>0
	--and isdate([2ndRestructuringDate])=1


    UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN '2ndRestructuringDate should be in dd/mm/yyyy e.g 01/01/2019,Please Check and Upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'2ndRestructuringDate should be in dd/mm/yyyy e.g 01/01/2019,Please Check and Upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '2ndRestructuringDate' ELSE ErrorinColumn +','+SPACE(1)+  '2ndRestructuringDate' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE ISNULL([2ndRestructuringDate],'') not like '%[0-3][0-9][/][0-1][0-9][/][0-9][0-9][0-9][0-9]%'
	AND LEN(ISNULL([2ndRestructuringDate],'')) <> 10 
	AND ISNULL([2ndRestructuringDate],'')<>''
	and len([2ndRestructuringDate])>0

	UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN '2ndRestructuringDate should be in dd/mm/yyyy and Proper date Format'     
					ELSE ErrorMessage+','+SPACE(1)+'2ndRestructuringDate should be in dd/mm/yyyy and Proper date Format'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN '2ndRestructuringDate' ELSE ErrorinColumn +','+SPACE(1)+  '2ndRestructuringDate' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE LEN(ISNULL([2ndRestructuringDate],'')) = 10
	AND ISNULL([2ndRestructuringDate],'')  like  '%[0-3][0-9][/][0-1][0-9][/][0-9][0-9][0-9][0-9]%'
	AND
	( Case 
		   WHEN LEN(ISNULL([2ndRestructuringDate],'')) <> 10 then 1 
	       WHEN ISNULL([2ndRestructuringDate],'') NOT like  '%[0-3][0-9][/][0-1][0-9][/][0-9][0-9][0-9][0-9]%' then 1
	       WHEN  Cast(SUBSTRING(cast([2ndRestructuringDate] as varchar(10)),1,2)   as Int) <= 0 then 1
		   WHEN MONTH(Convert(date,cast([2ndRestructuringDate] as varchar(10)),103)) IN (1,3,5,7,8,10,12) AND Cast(SUBSTRING(cast([2ndRestructuringDate] as varchar(10)),1,2)   as Int) > 31 then 1
		   WHEN MONTH(Convert(date,cast([2ndRestructuringDate] as varchar(10)),103)) =2 AND Cast(SUBSTRING(cast([2ndRestructuringDate] as varchar(10)),7,10)   as Int) % 4  =0  and Cast(SUBSTRING(cast([2ndRestructuringDate] as varchar(10)),1,2)   as Int) > 29 then 1
		   WHEN MONTH(Convert(date,cast([2ndRestructuringDate] as varchar(10)),103)) =2 AND Cast(SUBSTRING(cast([2ndRestructuringDate] as varchar(10)),7,10)   as Int) % 4  <> 0  and Cast(SUBSTRING(cast([2ndRestructuringDate] as varchar(10)),1,2)   as Int) > 28 then 1
		   WHEN MONTH(Convert(date,cast([2ndRestructuringDate] as varchar(10)),103)) NOT IN (1,2,3,5,7,8,10,12) AND Cast(SUBSTRING(cast([2ndRestructuringDate] as varchar(10)),1,2)   as Int) > 30  then 1
	  else 0
	  end
	)=1
	and len([2ndRestructuringDate])>0
  end
  ---------------------------------------------------------------------//Aggregate Exposure
     UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AggregateExposure cannot be blank.  Please check the values and upload again'     
					ELSE ErrorMessage+','+SPACE(1)+'AggregateExposure cannot be blank.  Please check the values and upload again'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AggregateExposure' ELSE ErrorinColumn +','+SPACE(1)+  'AggregateExposure' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE ISNULL(AggregateExposure,'')='' 
if exists(select 1 from RestructureGapData_Stg where len(AggregateExposure)>0 
--and isnull(AggregateExposure,'') not like'% %'
)
begin

    UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AggregateExposure length should be within 50'     
					ELSE ErrorMessage+','+SPACE(1)+'AggregateExposure length should be within 50'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AggregateExposure' ELSE ErrorinColumn +','+SPACE(1)+  'AggregateExposure' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE LEN(ISNULL(AggregateExposure,'')) > 50 
	AND ISNULL(AggregateExposure,'')<>'' 

	UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AggregateExposure should be containing only Master Values'     
					ELSE ErrorMessage+','+SPACE(1)+'AggregateExposure should be containing only Master Values'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AggregateExposure' ELSE ErrorinColumn +','+SPACE(1)+  'AggregateExposure' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE AggregateExposure not in --('Less than 100 CR','100 CR to Less than 500 CR','Equal to or Greater than 500 CR')
									(select ParameterShortName 
									from  DimParameter 
									where DimParameterName='RestructureGapData' 
									and ParameterName='AggregateExposure')

	
    UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'AggregateExposure should be containing alpha-numeric values'     
					ELSE ErrorMessage+','+SPACE(1)+'AggregateExposure should be containing alpha-numeric values'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'AggregateExposure' ELSE ErrorinColumn +','+SPACE(1)+  'AggregateExposure' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE ISNULL(AggregateExposure,'') LIKE '%[!$#%&+,<=>@`|~"*\^\?\]%'
END
  ---------------------------------------------------------------------//Credit Rating 1
  if exists(select 1 from RestructureGapData_Stg where len(CreditRating1)>0 
  --and isnull(CreditRating1,'AA')='AA'
  )
begin
      UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CreditRating1 length should be within 10'     
					ELSE ErrorMessage+','+SPACE(1)+'CreditRating1 length should be within 10'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CreditRating1' ELSE ErrorinColumn +','+SPACE(1)+  'CreditRating1' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE LEN(ISNULL(CreditRating1,'')) > 10 
	AND ISNULL(CreditRating1,'')<>'' 

	  UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CreditRating1 should be containing alpha-numeric values except (+) and (-)'     
					ELSE ErrorMessage+','+SPACE(1)+'CreditRating1 should be containing alpha-numeric values except (+) and (-) '     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CreditRating1' ELSE ErrorinColumn +','+SPACE(1)+  'CreditRating1' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE [CreditRating1] LIKE '%[!$#%&,<=>@`|~"*\^\?\]%'

	UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CreditRating1 should be containing only Master Values'     
					ELSE ErrorMessage+','+SPACE(1)+'CreditRating1 should be containing only Master Values'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CreditRating1' ELSE ErrorinColumn +','+SPACE(1)+  'CreditRating1' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE [CreditRating1]  not in (select ParameterShortName 
									from  DimParameter 
									where DimParameterName='RestructureGapData' 
									and ParameterName='Credit Rating'
									union
									select (''))
end
	  ---------------------------------------------------------------------//Credit Rating 2
   if exists(select 1 from RestructureGapData_Stg where len(CreditRating2)>0 
   --and isnull(CreditRating2,'AA')='AA'
   )
begin     
	  
	  UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CreditRating2 length should be within 10'     
					ELSE ErrorMessage+','+SPACE(1)+'CreditRating2 length should be within 10'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CreditRating2' ELSE ErrorinColumn +','+SPACE(1)+  'CreditRating2' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE LEN(ISNULL(CreditRating2,'')) > 10 
	AND ISNULL(CreditRating2,'')<>'' 

	 UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CreditRating2 should be containing alpha-numeric values except (+) and (-)'     
					ELSE ErrorMessage+','+SPACE(1)+'CreditRating2 should be containing alpha-numeric values except (+) and (-) '     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CreditRating2' ELSE ErrorinColumn +','+SPACE(1)+  'CreditRating2' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE [CreditRating2] LIKE '%[!$#%&,<=>@`|~"*\^\?\]%'


	UPDATE Upload_RestructureGapData
	SET  
        ErrorMessage=CASE WHEN ISNULL(ErrorMessage,'')='' THEN 'CreditRating2 should be containing only Master Values'     
					ELSE ErrorMessage+','+SPACE(1)+'CreditRating2 should be containing only Master Values'     END
		,ErrorinColumn=CASE WHEN ISNULL(ErrorinColumn,'')='' THEN 'CreditRating2' ELSE ErrorinColumn +','+SPACE(1)+  'CreditRating2' END  
		,Srnooferroneousrows=V.SlNo  

	FROM Upload_RestructureGapData V  
	WHERE [CreditRating2] not in (select ParameterShortName 
									from  DimParameter 
									where DimParameterName='RestructureGapData' 
									and ParameterName='Credit Rating'
									union
									select (''))
end
 
 goto valid

  END
	
   ErrorData:  
   print 'no'  

		SELECT *,'Data'TableName
		FROM dbo.MasterUploadData WHERE FileNames=@filepath 
		return

   valid:
		IF NOT EXISTS(Select 1 from  RestructureGapData_Stg WHERE filname=@FilePathUpload)
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
			SELECT SlNo,ErrorinColumn,ErrorMessage,ErrorinColumn,@filepath,Srnooferroneousrows,'SUCCESS' 
			FROM Upload_RestructureGapData 

			goto final
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
		
		 IF EXISTS(SELECT 1 FROM RestructureGapData_Stg WHERE filname=@FilePathUpload)
		 BEGIN
		 DELETE FROM RestructureGapData_Stg
		 WHERE filname=@FilePathUpload

		 PRINT 1

		 PRINT 'ROWS DELETED FROM DBO.RestructureGapData_Stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
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


	print 'p'
  
   END  TRY
  
  BEGIN CATCH
	PRINT 'BEGIN CATCH'

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()

  END CATCH

END
 
GO