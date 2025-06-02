SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE  [dbo].[BuyOutStageDataInUp_16112021]
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
		
IF (@MenuId=99)
BEGIN


	IF (@OperationFlag=1)

	BEGIN

		IF NOT (EXISTS (SELECT 1 FROM BuyoutDetails_Stg  where filname=@FilePathUpload))
		BEGIN
			 --Rollback tran
			SET @Result=-8
			RETURN @Result
		END
			
		---------- Implement Logic of AsOnDate for Enquiry Screen Grid Data Fetching --------------
		IF EXISTS(SELECT 1 FROM BuyoutDetails_Stg WHERE filname=@FilePathUpload)
		BEGIN
			------ Fetch the Value of AsOndate From Stage Table Brfore Inserting into ExcelUploadHistory Table
			SET @AsOnDate = (SELECT TOP 1 AsOnDate FROM BuyoutDetails_Stg WHERE filname=@FilePathUpload)
		END

		---use of sequence
		DECLARE @ExcelUploadId int
		select @ExcelUploadId=next value for [dbo].[Seq_UploadId]  
		select @ExcelUploadId

		 -- DECLARE @ExcelUploadId INT
		 -- SET @ExcelUploadId=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
		
		Insert into UploadStatus (FileNames,UploadedBy,UploadDateTime,UploadType)
		Values(@filepath,@UserLoginID ,GETDATE(),'Buyout Upload')

		SET DATEFORMAT DMY
		IF EXISTS(SELECT 1 FROM BuyoutDetails_Stg WHERE filname=@FilePathUpload)
		BEGIN
			SET DATEFORMAT DMY
			INSERT INTO BuyoutDetails_Mod
			(
				 SrNo
				,UploadID
				--,SummaryID
				,AsOnDate
				,PAN
				,NCIF_Id
				,CustomerName
				,CustomerACID
				,LoanAgreementNo
				,BuyoutPartyLoanNo
				,InterestReceivable
				,PrincipalOutstanding
				,TotalOutstanding
				,FinalAssetClassAlt_Key
				,FinalNpaDt
				,DPD
				,SecurityValue
				,Action
				,AdditionalProvisionAmount
				,AcceleratedProvisionPercentage
				,SecuredStatus
				,AuthorisationStatus
				,EffectiveFromTimeKey
				,EffectiveToTimeKey
				,CreatedBy
				,DateCreated
			)

			SELECT
				 A.SrNo
				,@ExcelUploadId
				--,A.SummaryID
				,A.AsOnDate
				,A.PAN
				,A.NCIF_Id
				,A.CustomerName
				,A.AccountNo
				,A.LoanAgreementNo
				,A.IndusindLoanAccountNo
				,Case When A.UnrealizedInterest='' Then 0 Else CAST(A.UnrealizedInterest AS DECIMAL(18,2)) END UnrealizedInterest
				,Case When A.PrincipalOutstanding='' Then 0 Else CAST(A.PrincipalOutstanding AS DECIMAL(18,2)) END PrincipalOutstanding
				,Case When A.TotalOutstanding='' Then 0 Else CAST(A.TotalOutstanding AS DECIMAL(18,2)) END TotalOutstanding
				,B.AssetClassAlt_Key
				,A.NPADate
				,A.DPD
				,Case When A.SecurityAmount='' Then 0 Else CAST(A.SecurityAmount AS DECIMAL(18,2)) END SecurityAmount
				,A.Action
				,case when A.AdditionalProvisionAmount='' then 0 else cast(A.AdditionalProvisionAmount as decimal(16,2)) END AdditionalProvisionAmount
				,case when A.AcceleratedProvisionPercentage='' then 0 else cast(A.AcceleratedProvisionPercentage as decimal(16,2)) end AcceleratedProvisionPercentage
				,A.SecuredStatus
				,'NP'	
				,@Timekey
				,49999	
				,@UserLoginID	
				,GETDATE()
				
				 
			FROM BuyoutDetails_Stg A
			INNER JOIN DimAssetClass B
			ON A.AssetClassification=B.AssetClassShortName
			where filname=@FilePathUpload 

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
			   ,'Buyout Upload'
			   ,@EffectiveFromTimeKey
			   ,@EffectiveToTimeKey
			   ,@UserLoginID
			   ,GETDATE()
			   ,CONVERT(Date,@AsOnDate,103)

			   PRINT @@ROWCOUNT

			Declare @SummaryId int
			Set @SummaryId=IsNull((Select Max(SummaryId) from BuyoutSummary_Mod),0)

			INSERT INTO BuyoutSummary_Stg
			(
				UploadID
				,SummaryID
				,NCIF_Id
				,CustomerName
				,CustomerACID
				,TotalNoofBuyoutParty
				,TotalPrincipalOutstandinginRs
				,TotalInterestReceivableinRs
				,GrandTotalOutstanding
				,TotalSecurityValue
				,TotalAdditionalProvisionAmount
			)
			SELECT
				@ExcelUploadId
				,@SummaryId+Row_Number() over(Order by NCIF_Id)
				,NCIF_Id
				,CustomerName
				,AccountNo
				--,sum(isnull (cast(BuyoutPartyLoanNo as Decimal(16,2)),0))
				,Count(1)
				,SUM(ISNULL(Case When PrincipalOutstanding='' Then 0 Else CAST(PrincipalOutstanding AS DECIMAL(18,2)) END,0)) PrincipalOutstanding
				,SUM(ISNULL(Case When UnrealizedInterest='' Then 0 Else CAST(UnrealizedInterest AS DECIMAL(18,2)) END,0)) UnrealizedInterest
				,SUM(ISNULL(Case When TotalOutstanding='' Then 0 Else CAST(TotalOutstanding AS DECIMAL(18,2)) END,0)) TotalOutstanding
				,SUM(ISNULL(Case When SecurityAmount='' Then 0 Else CAST(SecurityAmount AS DECIMAL(18,2)) END,0)) SecurityAmount
				,SUM(ISNULL(Case When AdditionalProvisionAmount='' Then 0 Else CAST(AdditionalProvisionAmount AS DECIMAL(16,2)) END,0)) AdditionalProvisionAmount

				
			FROM BuyoutDetails_Stg
			where filname=@FilePathUpload
			Group by NCIF_Id,CustomerName,AccountNo

			
			PRINT @@ROWCOUNT
			
			---DELETE FROM STAGING DATA
			 DELETE FROM BuyoutDetails_Stg
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
			BuyoutDetails_Mod 
			SET 
			AuthorisationStatus	='1A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			UPDATE 
			BuyoutSummary_Mod 
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
		   and UploadType='Buyout Upload'
	END

--------------------------------------------

	IF (@OperationFlag=20)----AUTHORIZE

	BEGIN
		
		UPDATE 
			BuyoutDetails_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			UPDATE 
			BuyoutSummary_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID

			Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from BuyoutDetails A
			inner join BuyoutDetails_Mod B
			ON A.CustomerACID=B.CustomerACID
			AND B.EffectiveFromTimeKey <=@Timekey
			AND B.EffectiveToTimeKey >=@Timekey
			Where B.UploadId=@UniqueUploadID
			AND A.EffectiveToTimeKey >=49999

			-----maintain history
			INSERT INTO BuyoutDetails
			(
				 SrNo
				,UploadID
				,SummaryID
				,AsOnDate
				,PAN
				,NCIF_Id
				,CustomerName
				,CustomerACID
				,LoanAgreementNo
				,BuyoutPartyLoanNo
				,TotalOutstanding
				,InterestReceivable
				,PrincipalOutstanding
				,FinalAssetClassAlt_Key
				,FinalNpaDt
				,DPD
				,SecurityValue
				,Action
				,AdditionalProvisionAmount
				,AcceleratedProvisionPercentage
				,SecuredStatus
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
			SELECT 
				SrNo
				,UploadID
				,SummaryID
				,AsOnDate
				,PAN
				,NCIF_Id
				,CustomerName
				,CustomerACID
				,LoanAgreementNo
				,BuyoutPartyLoanNo
				,TotalOutstanding
				,InterestReceivable
				,PrincipalOutstanding
				,FinalAssetClassAlt_Key
				,FinalNpaDt
				,DPD
				,SecurityValue
				,Action
				,AdditionalProvisionAmount
				,AcceleratedProvisionPercentage
				,SecuredStatus
				,AuthorisationStatus
				,@Timekey
				,49999
				,CreatedBy
				,DateCreated
				,ModifyBy
				,DateModified
				,@UserLoginID
				,Getdate()
					
			FROM BuyoutDetails_Mod
			WHERE  UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

			INSERT INTO BuyoutSummary
			(
				SummaryID
				,NCIF_Id
				,PAN
				,CustomerName
				,CustomerACID
				,LoanAgreementNo
				,BuyoutPartyLoanNo
				,TotalNoofBuyoutParty
				,TotalPrincipalOutstandinginRs
				,TotalInterestReceivableinRs
				,GrandTotalOutstanding
				,TotalSecurityValue
				--,AdditionalProvisionAmount
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
			SELECT 
				SummaryID
				,NCIF_Id
				,PAN
				,CustomerName
				,CustomerACID
				,LoanAgreementNo
				,BuyoutPartyLoanNo
				,TotalNoofBuyoutParty
				,TotalPrincipalOutstandinginRs
				,TotalInterestReceivableinRs
				,GrandTotalOutstanding
				,TotalSecurityValue
				--,AdditionalProvisionAmount
				,AuthorisationStatus
				,@Timekey
				,49999
				,CreatedBy
				,DateCreated
				,ModifyBy
				,DateModified
				,@UserLoginID
				,Getdate()
			FROM BuyoutSummary_Mod
			WHERE  UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

			-----------------------------------------------------------

			Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from CURDAT.BuyoutFinalDetails A
			inner join BuyoutDetails_Mod B
			ON A.CustomerACID=B.CustomerACID
			AND B.EffectiveFromTimeKey <=@Timekey
			AND B.EffectiveToTimeKey >=@Timekey
			Where B.UploadId=@UniqueUploadID
			AND A.EffectiveToTimeKey >=49999


			-----------------Insert into Final Tables ----------

			Insert into CURDAT.BuyoutFinalDetails
			(
					 SummaryID
					,PAN
					,NCIF_Id
					,CustomerName
					,CustomerACID
					,LoanAgreementNo
					,BuyoutPartyLoanNo
					,InterestReceivable
					,PrincipalOutstanding
					,TotalOutstanding
					,FinalAssetClassAlt_Key
					,FinalNpaDt
					,DPD
					,SecurityValue
					,Action
					,AdditionalProvisionAmount
					,AcceleratedProvisionPercentage
					,SecuredStatus
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

			SELECT 
					SummaryID
					,PAN
					,NCIF_Id
					,CustomerName
					,CustomerACID
					,LoanAgreementNo
					,BuyoutPartyLoanNo
					,InterestReceivable
					,PrincipalOutstanding
					,TotalOutstanding
					,FinalAssetClassAlt_Key
					,CASE WHEN ISNULL(FinalNpaDt,'') ='' THEN NULL ELSE CONVERT(DATE,FinalNpaDt,103) END AS FinalNpaDt 
					,DPD
					,SecurityValue
					,Action
					,AdditionalProvisionAmount
					,AcceleratedProvisionPercentage
					,SecuredStatus
					,AuthorisationStatus
					,@Timekey
					,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
			FROM BuyoutDetails_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

			---Summary Final -----------

			Insert into BuyoutFinalSummary
			(
					UploadID
					,SummaryID
					,PAN
					,NCIF_Id
					,CustomerName
					,CustomerACID
					,LoanAgreementNo
					,BuyoutPartyLoanNo
					,TotalNoofBuyoutParty
					,TotalPrincipalOutstandinginRs
					,TotalInterestReceivableinRs
					,GrandTotalOutstanding
					,TotalSecurityValue
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
			SELECT 
					UploadID
					,SummaryID
					,PAN
					,NCIF_Id
					,CustomerName
					,CustomerACID
					,LoanAgreementNo
					,BuyoutPartyLoanNo
					,TotalNoofBuyoutParty
					,TotalPrincipalOutstandinginRs
					,TotalInterestReceivableinRs
					,GrandTotalOutstanding
					,TotalSecurityValue
					,AuthorisationStatus
					,@Timekey
					,49999
					,CreatedBy
					,DateCreated
					,ModifyBy
					,DateModified
					,@UserLoginID
					,Getdate()
					FROM BuyoutSummary_Mod A
			WHERE  A.UploadId=@UniqueUploadID and EffectiveToTimeKey>=@Timekey

---------------------------------------------
/*--------------------Adding Flag To AdvAcOtherDetail------------Pranay 21-03-2021--------*/ 

 -- UPDATE A
	--SET  
 --       A.SplFlag=CASE WHEN ISNULL(A.SplFlag,'')='' THEN 'Buyout'     
	--					ELSE A.SplFlag+','+'Buyout'     END
		   
 --  FROM DBO.AdvAcOtherDetail A
 --  --INNER JOIN #Temp V  ON A.AccountEntityId=V.AccountEntityId
 -- INNER JOIN BuyoutDetails_Mod B ON A.RefSystemAcId=B.BuyoutPartyLoanNo
	--		WHERE  B.UploadId=@UniqueUploadID and B.EffectiveToTimeKey>=@Timekey
	--		AND A.EffectiveToTimeKey=49999



			UPDATE A
			SET 
			A.PrincipalOutstanding=ROUND(B.PrincipalOutstanding,2)
			,a.ModifyBy=@UserLoginID
			,a.DateModified=GETDATE()
			FROM BuyoutDetails A
			INNER JOIN BuyoutDetails_Mod B ON (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey)
																AND  (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey)	
																AND A.BuyoutPartyLoanNo=B.BuyoutPartyLoanNo

				WHERE B.AuthorisationStatus='A'
				AND B.UploadId=@UniqueUploadID

				UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='A',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Buyout Upload'

				


	END

	IF (@OperationFlag=17)----REJECT

	BEGIN
		
		UPDATE 
			BuyoutDetails_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus='NP'

			UPDATE 
			BuyoutSummary_Mod 
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
				AND UploadType='Buyout Upload'



	END
--------------------Two level Auth. Changes---------------

IF (@OperationFlag=21)----REJECT

	BEGIN
		
		UPDATE 
			BuyoutDetails_Mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in ('NP','1A')

			UPDATE 
			BuyoutSummary_Mod 
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
				AND UploadType='Buyout Upload'



	END
---------------------------------------------------------------------
END


	--COMMIT TRAN
		---SET @Result=CASE WHEN  @OperationFlag=1 THEN @UniqueUploadID ELSE 1 END
		SET @Result=CASE WHEN  @OperationFlag=1 AND @MenuId=99 THEN @ExcelUploadId 
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