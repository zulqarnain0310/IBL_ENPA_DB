SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
Create PROCEDURE [dbo].[SaletoARCGetUploadStatus_12082021]
	 @FileName varchar(500)
	,@Level   varchar(500)

AS
BEGIN

	IF EXISTS(SELECT 1 FROM dbo.UploadStatus where FileNames=@FileName 
					AND @Level = 'Upload')
	BEGIN
		DELETE FROM UploadStatus
		WHERE FileNames = @FileName 

	END
	ELSE if not exists( Select 1 from dbo.UploadStatus where FileNames=@FileName ) AND @Level='Upload'
	BEGIN
	   Select 'OK' as StatusOfUpload
		,@FileName as FileNames
		,'' as Error
		,'UploadStatus' as TableName

	END
	else if exists(
	              Select 1 from dbo.UploadStatus where FileNames=@FileName 
				  AND ISNULL(ValidationOfSheetNames,'N')  ='Y'
				  AND ISNULL(ValidationOfData		,'N') ='Y'
				  AND ISNULL(InsertionOfData       ,'N')  ='Y'
	         ) AND @Level='Upload'

    BEGIN
	    Select 'OK' as StatusOfUpload
		,@FileName as FileNames
		,'' as Error
		,'UploadStatus' as TableName           

	END
	else if @Level='Upload'
	BEGIN
	    Select 'NOT OK' as StatusOfUpload
		,@FileName as FileNames
		,'File Upload is In Progress By Other User' as ErrorMsg
		,'UploadStatus' as TableName             
	END
	else 
	BEGIN
	    

		 IF @Level='VOS'--- Validation of SheetName
		 BEGIN
		   
			IF EXISTS(Select 1 from dbo.ErrorMessageVOS where FileNames=@FileName)
			BEGIN
			  Select ErrorMsg,Flag,TableName,FileNames from dbo.ErrorMessageVOS
			  where FileNames=@FileName



			END
			ELSE
			BEGIN
				IF  EXISTS(SELECT 1 FROM dbo.UploadStatus WHERE FileNames = @FileName)
				BEGIN
					Select 'Validating Header and Sheet Name' ErrorMsg,'In Progress' Flag,'ErrorInUpload' TableName,@FileName FileNames,'' Srnooferroneousrows
				END
				ELSE 
				BEGIN	
					SELECT NULL ErrorMsg, NULL Flag,'ErrorInUpload' AS TableName,  NULL FileNames ,NULL Srnooferroneousrows
				END
			END

		 END

		 IF @Level='VOD'--- Validation of Data In excels
		 BEGIN
		  
			IF EXISTS(Select 1 from dbo.MasterUploadData where FileNames=@FileName)
			BEGIN
				PRINT 1111111111	
			  --Select SR_No,ColumnName,ErrorData,ErrorType,FileNames,Flag,Srnooferroneousrows

			  --from dbo.MasterUploadData
			  --where FileNames=@FileName
			  --AND ISNULL(ERRORDATA,'')<>''
			  --ORDER BY ErrorData DESC
			 

			 IF EXISTS(Select 1 from dbo.MasterUploadData where FileNames=@FileName AND ISNULL(ErrorData,'')<>'')
			BEGIN
			 	SELECT SR_No
				,ColumnName
				,ErrorData
				,ErrorType
				,FileNames
				,Flag
				,Srnooferroneousrows,'Validation'TableName
		FROM dbo.MasterUploadData  
		--(SELECT *,ROW_NUMBER() OVER(PARTITION BY ColumnName,ErrorData,ErrorType,FileNames ORDER BY ColumnName,ErrorData,ErrorType,FileNames )AS ROW 
		--FROM  dbo.MasterUploadData    )a 
		--WHERE A.ROW=1
		WHERE FileNames=@FileName
		AND ISNULL(ERRORDATA,'')<>''
	
		ORDER BY SR_No 
		END
		ELSE 
		BEGIN 
			SELECT SR_No
				,ColumnName
				,ErrorData
				,ErrorType
				,FileNames
				,Flag
				,Srnooferroneousrows,'Validation'TableName
		FROM 
		(SELECT *,ROW_NUMBER() OVER(PARTITION BY ColumnName,ErrorData,ErrorType,FileNames ORDER BY ColumnName,ErrorData,ErrorType,FileNames )AS ROW 
		FROM  dbo.MasterUploadData    )a 
		WHERE A.ROW=1
		AND FileNames=@FileName
	
		--ORDER BY ErrorData DESC

		END
		END
			ELSE
			BEGIN
			    Select '' SR_No,'' ColumnName,'Validating Excel Data' ErrorData,'' ErrorType,@FileName FileNames,'In Progress' Flag,'' Srnooferroneousrows
							

			END

		 END

		 IF @Level='TOT'--- Truncate of Table
		 BEGIN
		      Select
			  ISNULL(TruncateTable,'N')
			  
			  as StatusOfUpload
			   ,@FileName as FileNames
		   ,case when ISNULL(TruncateTable,'N')='N' then
		   'Truncating Table' 
		   else 'Truncation Complete' 
		   
		    end as ErrorMsg
		  ,case when ISNULL(TruncateTable,'N')='N' then
		   'In Progress' 
		   when ISNULL(TruncateTable,'N')='E' then 'Error'
		   else 'SUCCESS' 
		   
		    end as Flag
		   ,'ErrorInUpload' as TableName
			  
			  from UploadStatus
			  where FileNames=@FileName

			  delete from UploadStatus where FileNames=@FileName
		 END

		 IF @Level='IOD'--- Insertion Of Data
		 BEGIN
		      Select
			  ISNULL(InsertionOfData,'N')
			  
			  as StatusOfUpload
			   ,@FileName as FileNames
		   ,case when ISNULL(InsertionOfData,'N')='N' then
		   'Inserting Data' 
		   else 'Data Insertion Complete' 
		   
		    end as ErrorMsg
		  ,case when ISNULL(InsertionOfData,'N')='N' then
		   'In Progress' 
		   when ISNULL(InsertionOfData,'N')='E' then 'Error'
		   else 'SUCCESS' 
		   
		    end as Flag
		  -- ,'ErrorInUpload' as TableName
			  
			  from UploadStatus
			  where FileNames=@FileName
		 END

	END

END

GO