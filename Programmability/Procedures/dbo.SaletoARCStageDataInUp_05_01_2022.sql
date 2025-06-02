SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROCEDURE  [dbo].[SaletoARCStageDataInUp_05_01_2022]
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

--DECLARE @Timekey INT=24928,
--	@UserLoginID VARCHAR(100)='FNAOPERATOR',
--	@OperationFlag INT=1,
--	@MenuId INT=163,
--	@AuthMode	CHAR(1)='N',
--	@filepath VARCHAR(MAX)='',
--	@EffectiveFromTimeKey INT=24928,
--	@EffectiveToTimeKey	INT=49999,
--    @Result		INT=0 ,
--	@UniqueUploadID INT=41
BEGIN
SET DATEFORMAT DMY
	SET NOCOUNT ON;

   DECLARE @AsOnDate VARCHAR(10)
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
		
IF (@MenuId=98)
BEGIN


	IF (@OperationFlag=1)

	BEGIN

		IF NOT (EXISTS (SELECT 1 FROM SaletoARC_Stg  where filname=@FilePathUpload))

							BEGIN
									 --Rollback tran
									SET @Result=-8

								RETURN @Result
							END
			
		---------- Implement Logic of AsOnDate for Enquiry Screen Grid Data Fetching --------------
		IF EXISTS(SELECT 1 FROM SaletoARC_Stg WHERE filname=@FilePathUpload)
		BEGIN
				------ Fetch the Value of AsOndate From Stage Table Brfore Inserting into ExcelUploadHistory Table
				SET @AsOnDate = (SELECT TOP 1 AsOnDate FROM SaletoARC_Stg WHERE filname=@FilePathUpload)
		END

		---use of sequence
		DECLARE @ExcelUploadId int
		select @ExcelUploadId=next value for [dbo].[Seq_UploadId]  
		select @ExcelUploadId

		 -- DECLARE @ExcelUploadId INT
		 -- SET @ExcelUploadId=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
		
		Insert into UploadStatus (FileNames,UploadedBy,UploadDateTime,UploadType)
		Values(@filepath,@UserLoginID ,GETDATE(),'Sale to ARC Upload')
		
		SET DATEFORMAT DMY
		IF EXISTS(SELECT 1 FROM SaletoARC_Stg WHERE FILNAME=@FilePathUpload)
		BEGIN
			SET DATEFORMAT DMY
			INSERT INTO SaletoARC_Mod
			(
				SrNo
				,UploadID
				,AsOnDate
				,NCIF_ID
				,SourceSystem
				,CustomerID
				,AccountID
				,BalanceOutstanding		-- Total Sale Consideration
				,POS
				,InterestReceivable
				,DtofsaletoARC
				,Action
				,AuthorisationStatus	
				,EffectiveFromTimeKey	
				,EffectiveToTimeKey	
				,CreatedBy	
				,DateCreated	
			)

			SELECT
				SrNo
				,@ExcelUploadId
				,AsOnDate
				,NCIF_ID
				,SourceSystem
				,CustomerID
				,AccountNo
				,Case When TotalSaleConsideration='' Then 0 Else CAST(TotalSaleConsideration AS DECIMAL(18,2)) END TotalSaleConsideration
				,Case When PrincipalConsideration='' Then 0 Else CAST(PrincipalConsideration AS DECIMAL(18,2)) END PrincipalConsideration
				,Case When InterestConsideration='' Then 0 Else CAST(InterestConsideration AS DECIMAL(18,2)) END InterestConsideration
				,DateOfSaletoARC
				,Action
				,'NP'	
				,@Timekey
				,49999	
				,@UserLoginID	
				,GETDATE()
			 
			FROM SaletoARC_Stg
			where FilName=@FilePathUpload

			INSERT INTO ExcelUploadHistory
			(
				UniqueUploadID
				,UploadedBy	
				,DateofUpload	
				,AuthorisationStatus	
				--,Action	
				,UploadType
				,EffectiveFromTimeKey	
				,EffectiveToTimeKey	
				,CreatedBy	
				,DateCreated	
				,AsOnDate					-------- New Column Added By Satwaji as on 02/09/2021
			)

			SELECT 
				 @ExcelUploadId
				,@UserLoginID
				,GETDATE()
				,'NP'
				--,'NP'
				,'Sale to ARC Upload'
				,@EffectiveFromTimeKey
				,@EffectiveToTimeKey
				,@UserLoginID
				,GETDATE()
				,CONVERT(Date,@AsOnDate,103)

				PRINT @@ROWCOUNT

			Declare @SummaryId int
			Set @SummaryId=IsNull((Select Max(SummaryId) from SaletoARCSummary_Mod),0)

			INSERT INTO SaletoARCSummary_stg
			(
				UploadID
				,SummaryID
				,NoofAccounts
				,TotalPOSinRs
				,TotalInttReceivableinRs
				,TotaloutstandingBalanceinRs
				--,ExposuretoARCinRs
				,DateOfSaletoARC
				--,DateOfApproval
			)

			SELECT
				@ExcelUploadId
				,@SummaryId --+Row_Number() over(Order by PoolID)
				,COUNT(CustomerID)
				,SUM(ISNULL(Case When PrincipalConsideration='' Then 0 Else CAST(PrincipalConsideration AS DECIMAL(18,2)) END,0)) PrincipalConsideration
				,SUM(ISNULL(Case When InterestConsideration='' Then 0 Else CAST(InterestConsideration AS DECIMAL(18,2)) END,0)) InterestConsideration
				,SUM(ISNULL(Case When TotalSaleConsideration='' Then 0 Else CAST(TotalSaleConsideration AS DECIMAL(18,2)) END,0)) TotalSaleConsideration
				--,Sum(IsNull(Cast(ExposuretoARCinRs as Decimal(16,2)),0))
				,DateOfSaletoARC
				--,DateOfApproval
				--,Sum(IsNull(Cast(PrincipalOutstandinginRs as decimal(16,2)),0)+IsNull(Cast(InterestReceivableinRs as Decimal(16,2)),0))
			FROM SaletoARC_Stg
			where FilName=@FilePathUpload
			Group by DateOfSaletoARC--,DateOfApproval

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
			
			---DELETE FROM STAGING DATA
			 DELETE FROM SaletoARC_Stg
			 WHERE filname=@FilePathUpload

			 ----RETURN @ExcelUploadId

		END
		----DECLARE @UniqueUploadID INT
		--SET @UniqueUploadID=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
	END


----------------------Two level Auth. Changes-------------

IF (@OperationFlag=16)----AUTHORIZE

	BEGIN
		
		UPDATE 
			SaletoARC_Mod 
			SET 
			AuthorisationStatus	='1A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			UPDATE 
			SaletoARCSummary_Mod 
			SET 
			AuthorisationStatus	='1A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			
		   UPDATE 
		   ExcelUploadHistory
		   SET AuthorisationStatus='1A'
		   ,ApprovedBy	=@UserLoginID
		   ,DateApproved	=GETDATE()
		   where UniqueUploadID=@UniqueUploadID
		   AND  UploadType='sale to ARC Upload'
	END

--------------------------------------------

	IF (@OperationFlag=20)----AUTHORIZE

	BEGIN
		
		UPDATE 
			SaletoARC_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			UPDATE 
			SaletoARCSummary_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID


			Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from SaletoARC A
			inner join SaletoARC_Mod B
			ON A.AccountID=B.AccountID
			AND B.EffectiveFromTimeKey <=@Timekey
			AND B.EffectiveToTimeKey >=@Timekey
			Where B.UploadId=@UniqueUploadID
			AND A.EffectiveToTimeKey >=49999

			-----maintain history
			INSERT INTO SaletoARC(
					SrNo
					--,UploadID
					,AsOnDate
					,NCIF_ID
					,SourceSystem
					,CustomerID
					,AccountID
					,BalanceOutstanding		-- Total Sale Consideration
					,POS
					,InterestReceivable
					,DtofsaletoARC
					,Action
					,AuthorisationStatus
					,EffectiveFromTimeKey
					,EffectiveToTimeKey
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,ApprovedBy
					,DateApproved)
			SELECT SrNo
					--,UploadID
					,AsOnDate
					,NCIF_ID
					,SourceSystem
					,CustomerID
					,AccountID
					,BalanceOutstanding		-- Total Sale Consideration
					,POS
					,InterestReceivable
					,DtofsaletoARC
					,Action
					,AuthorisationStatus
					,@Timekey
					,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
			FROM SaletoARC_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

			

			INSERT INTO SaletoARCSummary(
					SummaryID
					,NoofAccounts
					,TotalPOSinRs
					,TotalInttReceivableinRs
					,TotaloutstandingBalanceinRs
					--,ExposuretoARCinRs
					,DateOfSaletoARC
					--,DateOfApproval
					,AuthorisationStatus
					,EffectiveFromTimeKey
					,EffectiveToTimeKey
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,ApprovedBy
					,DateApproved)
			SELECT SummaryID
					,NoofAccounts
					,TotalPOSinRs
					,TotalInttReceivableinRs
					,TotaloutstandingBalanceinRs
					--,ExposuretoARCinRs
					,DateOfSaletoARC
					--,DateOfApproval
					,AuthorisationStatus
					,@Timekey
					,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
			FROM SaletoARCSummary_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

			-------------------------------------------------------------

			Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from CURDAT.SaletoARCFinalACFlagging A
			inner join SaletoARC_Mod B
			ON A.AccountID=B.AccountID
			AND B.EffectiveFromTimeKey <=@Timekey
			AND B.EffectiveToTimeKey >=@Timekey
			Where B.UploadId=@UniqueUploadID
			AND A.EffectiveToTimeKey >=49999

			--BEGIN  
          INSERT INTO CURDAT.SaletoARCFinalACFlagging  
          (    
			  SrcSysAlt_Key
			  ,NCIF_Id
             ,AccountID  
             ,CustomerID  
             ,BalanceOutstanding  
             ,POS  
             ,InterestReceivable
			 ,DtofsaletoARC
			 ,Action
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
  
       SELECT 
				B.SourceAlt_Key
				,A.NCIF_ID
				,A.AccountID
				,A.CustomerID
				,A.BalanceOutstanding
				,A.POS
				,A.InterestReceivable
				,A.DtofsaletoARC
				,A.Action
				,A.AuthorisationStatus
				,@Timekey
				,49999
				,A.CreatedBy
				,A.DateCreated
				,A.ModifyBy
				,A.DateModified
				,@UserLoginID
				,Getdate()
			FROM SaletoARC_Mod A
			INNER JOIN DimSourceSystem B
			ON A.SourceSystem=B.SourceName
			WHERE  A.UploadId=@UniqueUploadID and A.EffectiveToTimeKey>=@Timekey 
         -- END  

		 ---Summary Final -----------

			Insert into SaletoARCFinalSummary
			(
					SummaryID
					,NoofAccounts
					,TotalPOSinRs
					,TotalInttReceivableinRs
					,TotaloutstandingBalanceinRs
					--,ExposuretoARCinRs
					,DateOfSaletoARC
					--,DateOfApproval
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
			SELECT SummaryID
					,NoofAccounts
					,TotalPOSinRs
					,TotalInttReceivableinRs
					,TotaloutstandingBalanceinRs
					--,ExposuretoARCinRs
					,DateOfSaletoARC
					--,DateOfApproval
					,AuthorisationStatus
					,@Timekey
					,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
					
			FROM SaletoARCSummary_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

---------------------------------------------
/*--------------------Adding Flag To AdvAcOtherDetail------------Pranay 21-03-2021--------*/ 

 -- UPDATE A
	--SET  
 --       A.SplFlag=CASE WHEN ISNULL(A.SplFlag,'')='' THEN 'SaleArc'     
	--					ELSE A.SplFlag+','+'SaleArc'     END
		   
 --  FROM DBO.AdvAcOtherDetail A
 --  --INNER JOIN #Temp V  ON A.AccountEntityId=V.AccountEntityId
 -- INNER JOIN SaletoARC_Mod B ON A.RefSystemAcId=B.AccountID
	--		WHERE  B.UploadId=@UniqueUploadID and B.EffectiveToTimeKey>=@Timekey
	--		AND A.EffectiveToTimeKey=49999



			UPDATE A
			SET 
			A.POS=ROUND(B.POS,2)
			,a.ModifyBy=@UserLoginID
			,a.DateModified=GETDATE()
			FROM SaletoARC A
			INNER JOIN SaletoARC_Mod  B ON (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey)
																AND  (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)	
																AND A.AccountID=B.AccountID

				WHERE B.AuthorisationStatus='A'
				AND B.UploadId=@UniqueUploadID

				UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='A',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='sale to ARC Upload'

				


	END

	IF (@OperationFlag=17)----REJECT

	BEGIN
		
		UPDATE 
			SaletoARC_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus='NP'

			UPDATE 
			SaletoARCSummary_Mod 
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
				AND UploadType='Sale to ARC Upload'



	END

------------------------------Two level Auth. Changes---------------------

IF (@OperationFlag=21)----REJECT

	BEGIN
		
		UPDATE 
			SaletoARC_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in('NP','1A')

			UPDATE 
			SaletoARCSummary_Mod 
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
				AND UploadType='Sale to ARC Upload'



	END	
----------------------------------------------------------------------------
END


	--COMMIT TRAN
		---SET @Result=CASE WHEN  @OperationFlag=1 THEN @UniqueUploadID ELSE 1 END
		SET @Result=CASE WHEN  @OperationFlag=1 AND @MenuId=98 
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
	RETURN -1
	END CATCH

END
GO