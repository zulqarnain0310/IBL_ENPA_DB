SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[WriteOffStageDataInUp_09092021]
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

--DECLARE @Timekey INT=24927,
--	@UserLoginID VARCHAR(100)='12checker',
--	@OperationFlag INT=20,
--	@MenuId INT=96,
--	@AuthMode	CHAR(1)='Y',
--	@filepath VARCHAR(MAX)='',
--	@EffectiveFromTimeKey INT=24927,
--	@EffectiveToTimeKey	INT=49999,
--    @Result		INT=0 ,
--	@UniqueUploadID INT=71
BEGIN
SET DATEFORMAT DMY
	SET NOCOUNT ON;

   
   --DECLARE @Timekey INT
   --SET @Timekey=(SELECT MAX(TIMEKEY) FROM dbo.SysProcessingCycle
			--	WHERE ProcessType='Quarterly')

			SET @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
			Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
			 where A.CurrentStatus='C')

	PRINT @TIMEKEY

	SET @EffectiveFromTimeKey=@TimeKey
	SET @EffectiveToTimeKey=49999


	DECLARE @FilePathUpload	VARCHAR(100)
				   SET @FilePathUpload=@UserLoginId+'_'+@filepath
					PRINT '@FilePathUpload'
					PRINT @FilePathUpload


		BEGIN TRY

		--BEGIN TRAN
		
IF (@MenuId=96)
BEGIN


	IF (@OperationFlag=1)

	BEGIN

		IF NOT (EXISTS (SELECT 1 FROM WriteOffUpload_Stg  where filname=@FilePathUpload))

							BEGIN
									 --Rollback tran
									SET @Result=-8

								RETURN @Result
							END
			


		IF EXISTS(SELECT 1 FROM WriteOffUpload_Stg WHERE FILNAME=@FilePathUpload)
		BEGIN
		
		INSERT INTO ExcelUploadHistory
	(
		UploadedBy	
		,DateofUpload	
		,AuthorisationStatus	
		--,Action	
		,UploadType
		,EffectiveFromTimeKey	
		,EffectiveToTimeKey	
		,CreatedBy	
		,DateCreated	
		
	)

	SELECT @UserLoginID
		   ,GETDATE()
		   ,'NP'
		   --,'NP'
		   ,'Write Off Data Upload'
		   ,@EffectiveFromTimeKey
		   ,@EffectiveToTimeKey
		   ,@UserLoginID
		   ,GETDATE()

		   PRINT @@ROWCOUNT

		   DECLARE @ExcelUploadId INT
	   SET 	@ExcelUploadId=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
		
			Insert into UploadStatus (FileNames,UploadedBy,UploadDateTime,UploadType)
		Values(@filepath,@UserLoginID ,GETDATE(),'Write Off Data Upload')

		--DECLARE @SourceAlt_Key INT
		--SET @SourceAlt_Key=(SELECT A.SourceAlt_Key FROM DimSourceSystem A
		--					INNER JOIN WriteOffUpload_Stg B
		--					ON A.SourceName=B.SourceSystem)
		SET DATEFORMAT DMY
 		INSERT INTO AdvAcWODetail_Mod
		(
			SrcSysAlt_Key
			,NCIF_Id
			,CustomerID
			,CustomerACID
			,WriteOffDt
			,WO_PWO
			,WriteOffAmt
			,IntSacrifice
			,Action
			,AuthorisationStatus
			,EffectiveFromTimeKey
			,EffectiveToTimeKey
			,CreatedBy
			,DateCreated
			,UploadId

			,SrNo
			,AsOnDate
			
		)

		SELECT
			B.SourceAlt_Key
			,A.NCIF_Id
			,A.CustomerID
			,A.CustomerAcID
			,A.WriteOffDate
			,A.WriteOffType
			,Case When A.WriteOffAmtInterest='' Then 0 Else CAST(A.WriteOffAmtInterest AS DECIMAL(18,2)) END WriteOffAmtInterest
			,Case When A.WriteOffAmtPrincipal='' Then 0 Else  CAST(A.WriteOffAmtPrincipal AS DECIMAL(18,2)) END WriteOffAmtPrincipal
			,A.Action
			,'NP'	
			,@Timekey
			,49999	
			,@UserLoginID	
			,GETDATE()
			,@ExcelUploadId

			,A.SrNo
			,A.AsOnDate
			 
		FROM WriteOffUpload_Stg  A
		INNER JOIN DimSourceSystem B
		ON A.SourceSystem=B.SourceName
		where A.filname=@FilePathUpload

		

		Declare @SummaryId int
		Set @SummaryId=IsNull((Select Max(SummaryId) from WriteOffSummary_Mod),0)

		INSERT INTO WriteOffSummary_stg
		(
			UploadID
			,SummaryID
			,NoofAccounts
			,TotalWriteOffAmtinRS
			,TotalIntSacrificeinRS
		)

		SELECT
			@ExcelUploadId
			,@SummaryId --+Row_Number() over(Order by PoolID)
			,COUNT(CustomerID)
			,SUM(ISNULL(Case When A.WriteOffAmtInterest='' Then 0 Else CAST(A.WriteOffAmtInterest AS DECIMAL(18,2)) END,0)) WriteOffAmtInterest
			,SUM(ISNULL(Case When A.WriteOffAmtPrincipal='' Then 0 Else  CAST(A.WriteOffAmtPrincipal AS DECIMAL(18,2)) END,0)) WriteOffAmtPrincipal

			FROM WriteOffUpload_Stg A
		where FilName=@FilePathUpload
		--Group by DateOfSaletoARC,DateOfApproval

		--where FilName=@FilePathUpload
		--Group by PoolID,PoolName

		--INSERT INTO IBPCPoolSummary_Mod
		--(
		--	UploadID
		--	,SummaryID
		--	,PoolID
		--	,PoolName
		--	,BalanceOutstanding
		--	,NoOfAccount
		--	,AuthorisationStatus	
		--	,EffectiveFromTimeKey	
		--	,EffectiveToTimeKey	
		--	,CreatedBy	
		--	,DateCreated	
		--)

		--SELECT
		--	@ExcelUploadId
		--	,@SummaryId+Row_Number() over(Order by PoolID)
		--	,PoolID
		--	,PoolName
		--	,Sum(IsNull(POS,0)+IsNull(InterestReceivable,0))
		--	,Count(PoolID)
		--	,'NP'	
		--	,@Timekey
		--	,49999	
		--	,@UserLoginID	
		--	,GETDATE()
		--FROM IBPCPoolDetail_stg
		--where FilName=@FilePathUpload
		--Group by PoolID,PoolName

		PRINT @@ROWCOUNT
		
		--DELETE FROM STAGING DATA
		--Select * from WriteOffUpload_Stg
		PRINT 'Sach'
		 DELETE FROM WriteOffUpload_Stg
		 WHERE filname=@FilePathUpload

		 ----RETURN @ExcelUploadId

END
		   ----DECLARE @UniqueUploadID INT
	--SET 	@UniqueUploadID=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
	END


----------------------Two level Auth. Changes-------------

IF (@OperationFlag=16)----AUTHORIZE

	BEGIN
		
		UPDATE 
			AdvAcWoDetail_Mod 
			SET 
			AuthorisationStatus	='1A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			UPDATE 
			WriteOffSummary_Mod 
			SET 
			AuthorisationStatus	='1A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			
		   UPDATE 
		   ExcelUploadHistory
		   SET AuthorisationStatus='1A'
		   ,ApprovedBy	=@UserLoginID
		   where UniqueUploadID=@UniqueUploadID
		   AND  UploadType='Write Off Data Upload'
	END

--------------------------------------------

	IF (@OperationFlag=20)----AUTHORIZE

	BEGIN
		
		UPDATE 
			AdvAcWoDetail_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID

			UPDATE 
			WriteOffSummary_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID

			Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from CURDAT.AdvAcWODetail A
			inner join AdvAcWoDetail_Mod B
			ON A.CustomerACID=B.CustomerACID
			AND B.EffectiveFromTimeKey <=@Timekey
			AND B.EffectiveToTimeKey >=@Timekey
			Where B.UploadId=@UniqueUploadID
			AND A.EffectiveToTimeKey >=49999

			-----maintain history
			INSERT INTO CURDAT.AdvAcWODetail
			(
					SrcSysAlt_Key
					,NCIF_Id
					,CustomerID
					,CustomerACID
					,WriteOffDt
					,WO_PWO
					,WriteOffAmt
					,IntSacrifice
					,Action
					,AuthorisationStatus
					,EffectiveFromTimeKey
					,EffectiveToTimeKey
					,CreatedBy
					,DateCreated
					,ModifiedBy
					,DateModified
					,ApprovedBy
					,DateApproved
					)

			
			SELECT SrcSysAlt_Key
					,NCIF_Id
					,CustomerID
					,CustomerACID
					,WriteOffDt
					,WO_PWO
					,WriteOffAmt
					,IntSacrifice
					,Action
					,AuthorisationStatus
					,@Timekey,49999
					,CreatedBy
					,DateCreated
					,ModifiedBy
					,DateModified
					,@UserLoginID
					,Getdate()
			FROM AdvAcWoDetail_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

			

			INSERT INTO WriteOffSummary(
					--Entity_Key
					UploadID
					,SummaryID
					,NoofAccounts
					,TotalWriteOffAmtinRS
					,TotalIntSacrificeinRS
					,AuthorisationStatus
					,EffectiveFromTimeKey
					,EffectiveToTimeKey
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,ApprovedBy
					,DateApproved
					)
			SELECT --Entity_Key
					UploadID
					,SummaryID
					,NoofAccounts
					,TotalWriteOffAmtinRS
					,TotalIntSacrificeinRS
					,AuthorisationStatus
					,@Timekey,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
			FROM WriteOffSummary_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

			PRINT 'INSERT INTO WriteOffSummary FROM WriteOffSummary_Mod'
			-------------------------------------------------------------
			/*
			Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from SaletoARCFinalACFlagging A
			inner join AdvAcWoDetail_Mod B
			ON A.AccountID=B.AccountID
			AND B.EffectiveFromTimeKey <=@Timekey
			AND B.EffectiveToTimeKey >=@Timekey
			Where B.UploadId=@UniqueUploadID
			AND A.EffectiveToTimeKey >=49999

			--BEGIN  
          INSERT INTO SaletoARCFinalACFlagging  
          (    --Entity_Key  
              --SourceAlt_Key,
             SourceSystem  
             ,AccountID  
             ,CustomerID  
             ,CustomerName  
             --,FlagAlt_Key  
             ,AccountBalance  
             ,POS  
             ,InterestReceivable
			 ,ExposureAmount
              --,AuthorisationStatus  
			  --,Remark
			  ,AuthorisationStatus
              ,EffectiveFromTimeKey  
              ,EffectiveToTimeKey  
              ,CreatedBy  
              ,DateCreated  
              ,ModifyBy  
              ,DateModified  
              ,ApprovedBy  
              ,DateApproved  
             -- ,D2Ktimestamp  
            )  
  
       SELECT SourceSystem
				 ,AccountID
					,CustomerID
					,CustomerName
					,BalanceOutstanding
					,POS
					,InterestReceivable
					,AmountSold
					,AuthorisationStatus
					,@Timekey
					,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
			FROM AdvAcWoDetail_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey 
         -- END  
			*/
		 ---Summary Final -----------

			Insert into WriteOffSummary
			(
					 UploadID
					,SummaryID
					,NoofAccounts
					,TotalWriteOffAmtinRS
					,TotalIntSacrificeinRS
					,AuthorisationStatus
					,EffectiveFromTimeKey
					,EffectiveToTimeKey
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,ApprovedBy
					,DateApproved
			
			)
			SELECT UploadID
					,SummaryID
					,NoofAccounts
					,TotalWriteOffAmtinRS
					,TotalIntSacrificeinRS
					,AuthorisationStatus
					,@Timekey,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
					
			FROM WriteOffSummary_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey


		

				UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='A',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Write Off Data Upload'

				


	END

	IF (@OperationFlag=17)----REJECT

	BEGIN
		
		UPDATE 
			AdvAcWoDetail_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus='NP'

			UPDATE 
			WriteOffSummary_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus='NP'
			----SELECT * FROM IBPCPoolDetail

			UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='R',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Write Off Data Upload'



	END

------------------------------Two level Auth. Changes---------------------

IF (@OperationFlag=21)----REJECT

	BEGIN
		
		UPDATE 
			AdvAcWoDetail_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in('NP','1A')

			UPDATE 
			WriteOffSummary_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in ('NP','1A')
			----SELECT * FROM IBPCPoolDetail

			UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='R',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Write Off Data Upload'



	END	
----------------------------------------------------------------------------
END


	--COMMIT TRAN
		---SET @Result=CASE WHEN  @OperationFlag=1 THEN @UniqueUploadID ELSE 1 END
		SET @Result=CASE WHEN  @OperationFlag=1 AND @MenuId=96 
		THEN @ExcelUploadId 
					ELSE 1 END

		
		 Update UploadStatus Set InsertionOfData='Y',InsertionCompletedOn=GETDATE() where FileNames=@filepath

		 ---- IF EXISTS(SELECT 1 FROM IBPCPoolDetail_stg WHERE filEname=@FilePathUpload)
		 ----BEGIN
			----	 DELETE FROM IBPCPoolDetail_stg
			----	 WHERE filEname=@FilePathUpload

			----	 PRINT 'ROWS DELETED FROM IBPCPoolDetail_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 ----END
		 

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