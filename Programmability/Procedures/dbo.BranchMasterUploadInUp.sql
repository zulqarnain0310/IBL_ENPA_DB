SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[BranchMasterUploadInUp]
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
		
IF (@MenuId=2010)--1003
BEGIN


	IF (@OperationFlag=1)

	BEGIN

		IF NOT (EXISTS (SELECT 1 FROM BranchMasterUpload_Stg  where FileName=@FilePathUpload))

							BEGIN
								SET @Result=-8

								RETURN @Result
							END
							else 
							begin

								select * into #BranchMasterUpload_Stg_NP from BranchMasterUpload_Stg where [Action]='A'
								select * into #BranchMasterUpload_Stg_MP from BranchMasterUpload_Stg where [Action]='U'
								select * into #BranchMasterUpload_Stg_DP from BranchMasterUpload_Stg where [Action]='D'

							end
			
	
		---use of sequence
		DECLARE @ExcelUploadId int
		select @ExcelUploadId=next value for [dbo].[Seq_UploadId]  
		select @ExcelUploadId

		--DECLARE @ExcelUploadId INT
		--SET @ExcelUploadId=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
		
		Insert into UploadStatus (FileNames,UploadedBy,UploadDateTime,UploadType)
		Values(@filepath,@UserLoginID ,GETDATE(),'Branch_Master_Upload')

		SET DATEFORMAT DMY
		IF EXISTS(SELECT 1 FROM BranchMasterUpload_Stg WHERE FileName=@FilePathUpload)
		BEGIN
			SET DATEFORMAT DMY

			IF EXISTS(SELECT 1 FROM #BranchMasterUpload_Stg_NP WHERE FileName=@FilePathUpload)
			BEGIN
					INSERT INTO DimBranch_Mod
					(
						BranchCode
					   ,BranchName
					   ,Add_1
					   ,Add_2
					   ,Add_3
					   ,Place
					   ,PinCode
					   ,BranchOpenDt
					   ,BranchAreaCategoryAlt_Key
					   ,BranchAreaCategory
					   ,BranchDistrictAlt_Key
					   ,BranchDistrictName
					   ,BranchStateAlt_Key
					   ,BranchStateName
					   ,Action
					   ,UploadId
					   ,AuthorisationStatus
					   ,EffectiveFromTimeKey
					   ,EffectiveToTimeKey
					   ,CreatedBy
					   ,DateCreated
					)
					SELECT
						 A.BranchCode
						,A.BranchName
						,A.AddLine1
						,A.AddLine2
						,A.AddLine3
						,A.Place
						,A.PinCode
						,CONVERT(DATE,A.BranchOpenDt,103) AS BranchOpenDt
						,B.AreaAlt_Key
						,A.BranchAreaCategory
						,C.DistrictAlt_Key
						,A.BranchDistrictName
						,D.StateAlt_Key
						,A.BranchStateName
						,A.Action
						,@ExcelUploadId
						--,'NP'	
						,case when A.Action='A' then 'NP' END AS AuthorisationStatus
						,@Timekey
						,49999	
						,@UserLoginID	
						,GETDATE()
				
					FROM #BranchMasterUpload_Stg_NP  A
					LEFT JOIN DimArea B
					ON A.BranchAreaCategory=B.AreaName
					AND (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
					LEFT JOIN DimGeography C
					ON A.BranchDistrictName=C.DistrictName
					AND (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
					LEFT JOIN DimState D
					ON A.BranchStateName=D.StateName
					AND (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
					where A.FileName=@FilePathUpload
			END

			IF EXISTS (SELECT 1 FROM #BranchMasterUpload_Stg_MP WHERE FileName=@FilePathUpload)
			BEGIN

				UPDATE DimBranch SET AuthorisationStatus=	'MP'
				WHERE BranchCode IN (SELECT BranchCode FROM #BranchMasterUpload_Stg_MP)
				AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
				AND ISNULL(AuthorisationStatus,'A') IN ('A')

				UPDATE DimBranch_MOD SET EffectiveToTimeKey=EffectiveFromTimeKey-1
				WHERE BranchCode IN (SELECT BranchCode FROM #BranchMasterUpload_Stg_MP)
				AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
				AND ISNULL(AuthorisationStatus,'A') IN ('A')

				INSERT INTO DimBranch_Mod
					(
						BranchCode
					   ,BranchName
					   ,Add_1
					   ,Add_2
					   ,Add_3
					   ,Place
					   ,PinCode
					   ,BranchOpenDt
					   ,BranchAreaCategoryAlt_Key
					   ,BranchAreaCategory
					   ,BranchDistrictAlt_Key
					   ,BranchDistrictName
					   ,BranchStateAlt_Key
					   ,BranchStateName
					   ,Action
					   ,UploadId
					   ,AuthorisationStatus
					   ,EffectiveFromTimeKey
					   ,EffectiveToTimeKey
					   ,CreatedBy
					   ,DateCreated
					)
					SELECT
						 A.BranchCode
						,A.BranchName
						,A.AddLine1
						,A.AddLine2
						,A.AddLine3
						,A.Place
						,A.PinCode
						,CONVERT(DATE,A.BranchOpenDt,103) AS BranchOpenDt
						,B.AreaAlt_Key
						,A.BranchAreaCategory
						,C.DistrictAlt_Key
						,A.BranchDistrictName
						,D.StateAlt_Key
						,A.BranchStateName
						,A.Action
						,@ExcelUploadId
						--,'NP'	
						,case when A.Action='U' then 'MP' END AS AuthorisationStatus
						,@Timekey
						,49999	
						,@UserLoginID	
						,GETDATE()
				
					FROM #BranchMasterUpload_Stg_MP  A
					LEFT JOIN DimArea B
					ON A.BranchAreaCategory=B.AreaName
					AND (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
					LEFT JOIN DimGeography C
					ON A.BranchDistrictName=C.DistrictName
					AND (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
					LEFT JOIN DimState D
					ON A.BranchStateName=D.StateName
					AND (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
					where A.FileName=@FilePathUpload

			END

			IF EXISTS (SELECT 1 FROM #BranchMasterUpload_Stg_DP WHERE FileName=@FilePathUpload)
			BEGIN

				UPDATE DimBranch SET AuthorisationStatus=	'DP'
				WHERE BranchCode IN (SELECT BranchCode FROM #BranchMasterUpload_Stg_DP)
				AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
				AND ISNULL(AuthorisationStatus,'A') IN ('A')
			
			INSERT INTO DimBranch_Mod
					(
						BranchCode
					   ,BranchName
					   ,Add_1
					   ,Add_2
					   ,Add_3
					   ,Place
					   ,PinCode
					   ,BranchOpenDt
					   ,BranchAreaCategoryAlt_Key
					   ,BranchAreaCategory
					   ,BranchDistrictAlt_Key
					   ,BranchDistrictName
					   ,BranchStateAlt_Key
					   ,BranchStateName
					   ,Action
					   ,UploadId
					   ,AuthorisationStatus
					   ,EffectiveFromTimeKey
					   ,EffectiveToTimeKey
					   ,CreatedBy
					   ,DateCreated
					)
					SELECT
						 A.BranchCode
						,A.BranchName
						,A.AddLine1
						,A.AddLine2
						,A.AddLine3
						,A.Place
						,A.PinCode
						,CONVERT(DATE,A.BranchOpenDt,103) AS BranchOpenDt
						,B.AreaAlt_Key
						,A.BranchAreaCategory
						,C.DistrictAlt_Key
						,A.BranchDistrictName
						,D.StateAlt_Key
						,A.BranchStateName
						,A.Action
						,@ExcelUploadId
						--,'NP'	
						,case when A.Action='D' then 'DP' END AS AuthorisationStatus
						,@Timekey
						,49999	
						,@UserLoginID	
						,GETDATE()
				
					FROM #BranchMasterUpload_Stg_DP  A
					LEFT JOIN DimArea B
					ON A.BranchAreaCategory=B.AreaName
					AND (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
					LEFT JOIN DimGeography C
					ON A.BranchDistrictName=C.DistrictName
					AND (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
					LEFT JOIN DimState D
					ON A.BranchStateName=D.StateName
					AND (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
					where A.FileName=@FilePathUpload

			END

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
				--,AsOnDate
			)

			SELECT 
				 @ExcelUploadId
				,@UserLoginID
				,GETDATE()
				,'NP'
				--,'NP'
				,'Branch_Master_Upload'
				,@EffectiveFromTimeKey
				,@EffectiveToTimeKey
				,@UserLoginID
				,GETDATE()
				--,CONVERT(Date,@AsOnDate,103)

				PRINT @@ROWCOUNT

			--Declare @SummaryId int
			--Set @SummaryId=IsNull((Select Max(SummaryId) from WriteOffSummary_Mod),0)

			PRINT @@ROWCOUNT
			
			--DELETE FROM STAGING DATA
			--Select * from BranchMasterUpload_Stg
			PRINT 'ShAKTI'
			 DELETE FROM BranchMasterUpload_Stg
			 WHERE FileName=@FilePathUpload

			 DELETE FROM #BranchMasterUpload_Stg_NP
			 WHERE FileName=@FilePathUpload
			 DELETE FROM #BranchMasterUpload_Stg_MP
			 WHERE FileName=@FilePathUpload
			 DELETE FROM #BranchMasterUpload_Stg_DP
			 WHERE FileName=@FilePathUpload

		END

	END


	IF (@OperationFlag=16)----AUTHORIZE

	BEGIN

	--Update  A
	--		Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
	--		from DimBranch_Mod A
	--		INNER join DimBranch B
	--		ON A.BranchCode=B.BranchCode
	--		AND B.EffectiveFromTimeKey <=@Timekey
	--		AND B.EffectiveToTimeKey >=@Timekey
	--		WherE A.EffectiveToTimeKey =49999
	--		AND  ISNULL(B.AuthorisationStatus,'A') IN ('MP')
		
		UPDATE 
			DimBranch_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			
			WHERE UploadId=@UniqueUploadID
			AND EffectiveFromTimeKey <=@Timekey
			AND EffectiveToTimeKey >=@Timekey
			AND ISNULL(AuthorisationStatus,'A') IN ('NP','MP')

			UPDATE 
			DimBranch_Mod 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			,EffectiveToTimeKey=EffectiveFromTimeKey-1
			WHERE UploadId=@UniqueUploadID
			AND EffectiveFromTimeKey <=@Timekey
			AND EffectiveToTimeKey >=@Timekey
			AND ISNULL(AuthorisationStatus,'A') IN ('DP')

			UPDATE 
			DimBranch 
			SET 
			AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			,EffectiveToTimeKey=EffectiveFromTimeKey-1
			WHERE  EffectiveFromTimeKey <=@Timekey
			AND EffectiveToTimeKey >=@Timekey
			AND ISNULL(AuthorisationStatus,'A') IN ('DP')

			DELETE FROM DimBranch WHERE ISNULL(AuthorisationStatus,'A') IN ('MP')

			Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from DimBranch A
			INNER join DimBranch_Mod B
			ON A.BranchCode=B.BranchCode
			AND B.EffectiveFromTimeKey <=@Timekey
			AND B.EffectiveToTimeKey >=@Timekey
			Where B.UploadId=@UniqueUploadID
			AND A.EffectiveToTimeKey >=49999

			------ MAINTAIN HISTORY
			INSERT INTO DimBranch
			(
			    BranchCode
			   ,BranchName
			   ,Add_1
			   ,Add_2
			   ,Add_3
			   ,Place
			   ,PinCode
			   ,BranchOpenDt
			   ,BranchAreaCategoryAlt_Key
			   ,BranchAreaCategory
			   ,BranchDistrictAlt_Key
			   ,BranchDistrictName
			   ,BranchStateAlt_Key
			   ,BranchStateName
			   ,Action
			   ,UploadId
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
				 BranchCode
				,BranchName
				,Add_1
				,Add_2
				,Add_3
				,Place
				,PinCode
				,CONVERT(DATE,BranchOpenDt,103) AS BranchOpenDt
				,BranchAreaCategoryAlt_Key
				,BranchAreaCategory
				,BranchDistrictAlt_Key
				,BranchDistrictName
				,BranchStateAlt_Key
				,BranchStateName
				,Action
				,UploadId                      ----- Replace Upload at the place of @ExcelUploadId to show the Upload Id in Main Table By Satwaji as on 06/08/2022 
				,AuthorisationStatus
				,@Timekey AS EffectiveFromTimeKey
				,49999 AS EffectiveToTimeKey
				,CreatedBy
				,DateCreated
				,ModifyBy
				,DateModified
				,@UserLoginID
				,Getdate()

			FROM DimBranch_Mod
			WHERE  UploadId=@UniqueUploadID AND EffectiveToTimeKey=49999


			-->=@Timekey
				
			UPDATE ExcelUploadHistory SET 
				AuthorisationStatus='A'
				,ApprovedBy=@UserLoginID
				,DateApproved=GETDATE()
			WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey)
			AND UniqueUploadID=@UniqueUploadID
			AND UploadType='Branch_Master_Upload'

				


	END

	IF (@OperationFlag=17)
	BEGIN
		UPDATE DimBranch_Mod SET 
			 AuthorisationStatus	= 'R'
			,ApprovedBy	= @UserLoginID
			,DateApproved = GETDATE()
			,EffectiveToTimeKey =@EffectiveFromTimeKey-1
		WHERE UploadId=@UniqueUploadID AND AuthorisationStatus in ('NP','MP','DP')

		UPDATE ExcelUploadHistory
		SET 
			 AuthorisationStatus	= 'R'
			,ApprovedBy	= @UserLoginID
			,DateApproved = GETDATE()
		WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey)
		AND UniqueUploadID=@UniqueUploadID
		AND UploadType='Branch_Master_Upload'

	END

END


	--COMMIT TRAN
		---SET @Result=CASE WHEN  @OperationFlag=1 THEN @UniqueUploadID ELSE 1 END
		SET @Result=CASE WHEN  @OperationFlag=1 AND @MenuId=2010 
		THEN @ExcelUploadId 
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
	RETURN -1
	END CATCH

END





GO