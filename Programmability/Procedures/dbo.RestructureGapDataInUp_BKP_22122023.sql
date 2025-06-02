SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROCEDURE  [dbo].[RestructureGapDataInUp_BKP_22122023]
	@Timekey INT,
	@UserLoginID VARCHAR(100),
	@OperationFlag INT,
	@MenuId INT,
	@AuthMode	CHAR(1),
	@filepath VARCHAR(MAX),
	@EffectiveFromTimeKey INT,
	@EffectiveToTimeKey	INT,
    @Result		INT=0 OUTPUT,
	@UniqueUploadID INT

AS


BEGIN
SET DATEFORMAT DMY
	SET NOCOUNT ON;

   DECLARE @AsOnDate VARCHAR(10)
   
  SET @Timekey =(Select TimeKey from SysDataMatrix where date=cast(getdate()as date )) 
     	PRINT @TIMEKEY

	SET @EffectiveFromTimeKey=@TimeKey
	SET @EffectiveToTimeKey=49999


	DECLARE @FilePathUpload	VARCHAR(100)
				   SET @FilePathUpload=@UserLoginId+'_'+@filepath
					PRINT '@FilePathUpload'
					PRINT @FilePathUpload

		BEGIN TRY

		---BEGIN TRAN
		
IF (@MenuId=2011)
BEGIN
	IF (@OperationFlag=1)

	BEGIN
		IF NOT (EXISTS (SELECT 1 FROM RestructureGapData_Stg where filname=@FilePathUpload))

							BEGIN
									 --Rollback tran
									SET @Result=-8

								RETURN @Result
							END
			
                   Print 'Shakti'

		---------- Implement Logic of AsOnDate for Enquiry Screen Grid Data Fetching --------------
		IF EXISTS(SELECT 1 FROM RestructureGapData_Stg where filname=@FilePathUpload)
		BEGIN
				------ Fetch the Value of AsOndate From Stage Table Brfore Inserting into ExcelUploadHistory Table
				SET @AsOnDate = (select cast(getdate() as date))
		END

		---use of sequence
		DECLARE @ExcelUploadId int
		select @ExcelUploadId=next value for [dbo].[Seq_UploadId]  
		select @ExcelUploadId

		SET DATEFORMAT DMY
		IF EXISTS(SELECT 1 FROM RestructureGapData_Stg where filname=@FilePathUpload)
		BEGIN
		
					   
		SET DATEFORMAT DMY
				
		 DECLARE @Entity_Key Int   IF (@Entity_Key IS NULL)

                        BEGIN 
						  SET    @Entity_Key=isnull(@Entity_Key,0)+1
						 END 


				DROP TABLE IF EXISTS #tmp
					Select NCIF_ID,EffectiveFromTimeKey,EffectiveToTimeKey into #tmp 
					from NPA_IntegrationDetails 
					where NCIF_ID in(Select NCIF_ID from RestructureGapData_Stg where filname=@FilePathUpload)  
					AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey


		INSERT INTO RestructureGapData_Mod
		( NCIF_Id
		,SecondRestrDate
		,AggregateExposure
		,CreditRating1
		,CreditRating2
		,AuthorisationStatus
        ,EffectiveFromTimeKey
        ,EffectiveToTimeKey
        ,CreatedBy
        ,DateCreated
		,UploadID
		,AsOnDate
		)
		 
		SELECT distinct
			  RestructureGapData_Stg.NCIF_Id
			,convert(date,[2ndRestructuringDate],103)
			--,isnull([2ndRestructuringDate],'')
			,AggregateExposure
			,CreditRating1
			,CreditRating2
			,'NP'	
			,@Timekey
			,49999	
			,@UserLoginID	
			,GETDATE()
            ,@ExcelUploadId
			,CAST(GETDATE() AS DATE)
		FROM RestructureGapData_Stg
		left JOIN #tmp N on N.NCIF_Id=RestructureGapData_Stg.NCIF_Id
		              and EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey
		where filname=@FilePathUpload

update RestructureGapData_Mod set SecondRestrDate=null where SecondRestrDate= '1900-01-01'


		print 12345
INSERT INTO ExcelUploadHistory
	(  
		UniqueUploadID
		,UploadedBy	
		,DateofUpload	
		,AuthorisationStatus
		,UploadType
		,EffectiveFromTimeKey	
		,EffectiveToTimeKey	
		,CreatedBy	
		,DateCreated
		,AsOnDate					
		
	)
	SELECT 
			@ExcelUploadId
	        ,@UserLoginID
		   ,GETDATE()
		   ,'NP'
		   ,'Restructure GapData Upload'
		   ,@EffectiveFromTimeKey
		   ,@EffectiveToTimeKey
		   ,@UserLoginID
		   ,GETDATE()
		  -- ,CONVERT(Date,@AsOnDate,103)
		   ,@AsOnDate

			   PRINT @@ROWCOUNT
		
			Insert into UploadStatus (FileNames,UploadedBy,UploadDateTime,UploadType)
		           Values(@filepath,@UserLoginID ,GETDATE(),'Restructure GapData Upload')



		PRINT @@ROWCOUNT
		
		---DELETE FROM STAGING DATA

		 DELETE FROM RestructureGapData_Stg
		 WHERE filname=@FilePathUpload

		 ----RETURN @ExcelUploadId

END
	
	END

--------------------------------------------------------//Auth Work

IF (@OperationFlag=16)	---- FIRST LEVEL AUTHORIZE
	BEGIN	
		UPDATE RestructureGapData_mod 
		SET 
			AuthorisationStatus	='1A'
			,ApprovedByFirstLevel	= @UserLoginID
			,DateApprovedFirstLevel	= GETDATE()
		WHERE UploadId=@UniqueUploadID
			
		UPDATE ExcelUploadHistory
		SET 
			AuthorisationStatus='1A'
			,ApprovedByFirstLevel	= @UserLoginID
			,DateApprovedFirstLevel	= GETDATE()
		where UniqueUploadID=@UniqueUploadID
		AND UploadType='Restructure GapData Upload'
		
	END

--------------------------------------------

	IF (@OperationFlag=20)----AUTHORIZE

	BEGIN
		
		UPDATE 
			RestructureGapData_mod 
			SET AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID		
			

				
			DROP TABLE IF EXISTS #ACCOUNT_CAL
		
						SELECT A.* INTO #ACCOUNT_CAL 
						FROM RestructureGapData A
						INNER JOIN RestructureGapData_mod B ON A.NCIF_Id=B.NCIF_Id
						WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey> =@TimeKey)
						and (b.EffectiveFromTimeKey<=@TimeKey AND b.EffectiveToTimeKey> =@TimeKey)
						AND B.UploadID=@UniqueUploadID
						AND B.AuthorisationStatus='A'
						if exists (select 1 from RestructureGapData a where (A.EffectiveFromTimeKey=@TimeKey AND A.EffectiveToTimeKey =49999))
						begin
						update RestructureGapData_mod set ModifiedBy=@UserLoginID
														,DateModified=getdate()
														where UploadID in (select max(UploadID) 
														from RestructureGapData_mod
														where UploadID=@UniqueUploadID)

						update RestructureGapData set ModifyBy=@UserLoginID
														,DateModified=getdate()
														where UploadID in (select max(UploadID) 
														from RestructureGapData
														where UploadID=@UniqueUploadID)

						end

						UPDATE A
							SET A.EffectiveToTimeKey =A.EffectiveFromTimeKey-1
							,A.AuthorisationStatus='A'
						FROM RestructureGapData A
						INNER JOIN RestructureGapData_mod B ON A.NCIF_Id=B.NCIF_Id
						where (A.EffectiveFromTimeKey=@TimeKey AND A.EffectiveToTimeKey =49999)
						AND (B.EffectiveFromTimeKey=@TimeKey AND B.EffectiveToTimeKey =49999)
						AND A.AuthorisationStatus='A'


								
						INSERT INTO dbo.RestructureGapData
								(NCIF_ID
								,SecondRestrDate
								,AggregateExposure
								,CreditRating1
								,CreditRating2
								,AuthorisationStatus
								,EffectiveFromTimeKey
								,EffectiveToTimeKey
								,ApprovedBy
								,DateApproved
								,CreatedBy
								,DateCreated
								,ApprovedByFirstLevel
								,DateApprovedFirstLevel
								,UploadID)
					               SELECT
									B.NCIF_ID
									,B.SecondRestrDate
									,B.AggregateExposure
									,B.CreditRating1
									,B.CreditRating2
									,'A'
									,B.EffectiveFromTimeKey
									,@EffectiveToTimeKey
									,B.ApprovedBy
									,B.DateApproved
									,B.CreatedBy
									,B.DateCreated
									,B.ApprovedByFirstLevel
									,B.DateApprovedFirstLevel
									,B.UploadID
                                    from dbo.RestructureGapData_mod B 
								            where (b.EffectiveFromTimeKey<=@TimeKey and b.EffectiveToTimeKey >=@TimeKey)
										AND B.UploadID=@UniqueUploadID
										AND B.AuthorisationStatus='A'
																	  

							
		Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from  RestructureGapData_Mod A
			WHERE UploadId=@UniqueUploadID

				UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='A',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Restructure GapData Upload'

				


	END


	IF (@OperationFlag=17)	---- FIRST LEVEL REJECT
	BEGIN
		UPDATE RestructureGapData_Mod 
		SET 
			AuthorisationStatus	='R'
			,ApprovedByFirstLevel	=@UserLoginID
			,DateApprovedFirstLevel	=GETDATE()
		WHERE UploadId=@UniqueUploadID
		AND AuthorisationStatus='NP'

		
		UPDATE ExcelUploadHistory
		SET AuthorisationStatus='R'
			,ApprovedByFirstLevel=@UserLoginID
			,DateApprovedFirstLevel=GETDATE()
		WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey)
		AND UniqueUploadID=@UniqueUploadID
		AND UploadType='Restructure GapData Upload'

	END

IF (@OperationFlag=21)----REJECT

	BEGIN
		
		UPDATE 
			RestructureGapData_Mod 
			SET AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in('NP','1A')

			

			UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='R',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Restructure GapData Upload'

	END

END

		SET @Result=CASE WHEN  @OperationFlag=1 AND @MenuId=2011 THEN @ExcelUploadId 
					ELSE 1 END

		
		 Update UploadStatus Set InsertionOfData='Y',InsertionCompletedOn=GETDATE() where FileNames=@filepath

		 
		RETURN @Result
		------RETURN @UniqueUploadID
	END TRY
	BEGIN CATCH 
	   --ROLLBACK TRAN
	SELECT ERROR_MESSAGE(),ERROR_LINE()
	SET @Result=-1
	 Update UploadStatus Set InsertionOfData='Y',InsertionCompletedOn=GETDATE() where FileNames=@filepath
	--RETURN -1
	END CATCH

END


GO