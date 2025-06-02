SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[MocFreezeInUp]
--DECLARE  
		@Timekey			INT		=49999
		--,@LastQtrDateKey	INT		=24927
		,@LastMonthDateKey	INT		=26084
		--,@UserLevelType		VARCHAR(2)=''
	    -- ,@XmlDocument		XML
		,@UserLoginId		VARCHAR(20) 
		,@Action			Varchar(30)=''
		,@D2Ktimestamp		INT=0 OUTPUT
		,@Result			INT=0 OUTPUT

AS
BEGIN TRY 		
			
		BEGIN TRAN 
			--DECLARE @PrevLastQtrDateKey INT , @CurrQtrDate DATE
			--SET @PrevLastQtrDateKey =(SELECT  MAX(Prev_Qtr_key)FROM SysDataMatrix WHERE Prev_Qtr_key < @LastQtrDateKey)

			DECLARE @PrevLastMonthKey INT, @CurrentMonthDate DATE
			SET @PrevLastMonthKey=(SELECT MAX(Prev_Month_Key) FROM SysDataMatrix WHERE Prev_Month_Key < @LastMonthDateKey)
	
		
		--DROP TABLE IF EXISTS #BranchData

		--SELECT 
		--c.value('./Code [1]','VARCHAR(10)')BranchCode 
		
		--INTO #BranchData
		--FROM @XmlDocument.nodes('/DataSet/MOC') AS t(c)  --/DataSet/GridData

		--DROP TABLE IF EXISTS #BranchCode
		--CREATE TABLE #BranchCode(BranchCode VARCHAR(20))



		IF @Action='FREEZ'
			BEGIN
					UPDATE sysdatamatrix
					set MOC_Freeze='Y',
					MOC_FreezeDate=GETDATE(),
					MOC_FreezeBy=@UserLoginId,
					--MOC_ProcessStatus = 'Y',
					--MOC_ProcessingDate = GETDATE(),
					CurrentStatus_Moc='Y'
				 where TimeKey=@LastMonthDateKey
				 AND CurrentStatus_MOC='C'
			END 
	--ELSE IF @Action='UNFREEZ'
	--		BEGIN
	--				UPDATE sysdatamatrix
	--				set MOC_Freeze='N',
	--				MOC_FreezeDate=GETDATE(),
	--				MOC_FreezeBy=@UserLoginId,
	--				CurrentStatus_Moc=NULL
	--			 where TimeKey=@LastMonthDateKey
	--			 AND CurrentStatus_MOC='C'
	--		END 		

		--ELSE IF @Action='Initialis'
		--	BEGIN
		--			UPDATE sysdatamatrix
		--			set MOC_Initialised='Y',
		--			MOC_FreezeDate=GETDATE(),
		--			MOC_FreezeBy=@UserLoginId,
		--			CurrentStatus_Moc=NULL
		--		 where TimeKey=@LastMonthDateKey
		--		 AND CurrentStatus_MOC='C'
		--	END 


/*
		
DECLARE @MOC_Initialised_Key int ,@MOC_Initialised_Date date


	select @MOC_Initialised_Key=max(TimeKey) from sysdatamatrix where MOC_Initialised='Y'

		
				Declare @MocFreez char(1)='N'
				select @MocFreez=MOC_Frozen from sysdatamatrix where TimeKey=@MOC_Initialised_Key

				--select @MocFreez

				IF ISNULL(@MocFreez,'N')='N'
					BEGIN
					print 'troloki'
				update 
				sysdatamatrix
					set MOC_Frozen='Y'
				 where TimeKey=@MOC_Initialised_Key


				END 
		
		
			ELSE
					BEGIN

					DECLARE @LastQtrDateKey1 INT
				SELECT @LastQtrDateKey1=TimeKey FROM SysDayMatrix WHERE DATE=(
				SELECT EOMONTH(DATEADD(MONTH,3,DATE)) FROM SysDayMatrix WHERE TimeKey=@MOC_Initialised_Key
				)

					--SELECT DATEADD(MONTH,3,)

							
				
				update 				 
				sysdatamatrix 
					set MOC_Initialised='Y'
				where TimeKey=@LastQtrDateKey1

				
				END 
			




		--FOR UPATING A MOC FROZEN FLAG IN SYSDATAMATRIX

		

		/*
		IF NOT EXISTS (SELECT 1 FROM FactBranch_Moc WHERE TimeKey =  @PrevLastQtrDateKey )
		BEGIN
				INSERT INTO FactBranch_Moc
				(
					BranchCode
					,TimeKey
					,BO_MOC_Frozen
					,RO_MOC_Frozen
					,ZO_MOC_Frozen
				)
				SELECT BankCode
						,@Timekey
						,'N'
						,'N'
						,'N'
				 FROM DimBranch
				WHERE EffectiveFromTimeKey <= @Timekey AND EffectiveToTimeKey >= @Timekey
					
		END


		IF @UserLevelType='HO'
		BEGIN
				PRINT 'HO'
			INSERT INTO #BranchCode
			SELECT BR.BranchCode
			FROM DimBranch BR
			WHERE BR.EffectiveFromTimeKey <= @Timekey AND BR.EffectiveToTimeKey >= @Timekey		
		END
		ELSE
		BEGIN
			INSERT INTO #BranchCode
			SELECT BR.BranchCode
		 FROM DimBranch BR
		INNER JOIN #BranchData DT
			ON BR.EffectiveFromTimeKey <= @Timekey AND BR.EffectiveToTimeKey >= @Timekey
			AND (CASE WHEN @UserLevelType = 'ZO' AND BranchZoneAlt_Key = DT.BranchCode THEN 1
					  WHEN @UserLevelType = 'RO' AND BranchRegionAlt_Key = DT.BranchCode THEN 1
					  WHEN @UserLevelType = 'BO' AND BR.BranchCode = DT.BranchCode THEN 1
				END)=1
		END
		
 
		IF @UserLevelType = 'HO'
		BEGIN
			print 'HO UPDATE'
			UPDATE Moc
			SET BO_MOC_Frozen  = 'Y'
				,BO_MOC_FreezingDate = CASE WHEN ISNULL(BO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE BO_MOC_FreezingDate END
				,BO_MOC_FreezingBy  =  CASE WHEN ISNULL(BO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE BO_MOC_FreezingBy END
			
				,RO_MOC_Frozen = 'Y'
				,RO_MOC_FreezingDate = CASE WHEN ISNULL(RO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE RO_MOC_FreezingDate END
				,RO_MOC_FreezingBy  =  CASE WHEN ISNULL(RO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE RO_MOC_FreezingBy END
			
				,ZO_MOC_Frozen = 'Y'
				,ZO_MOC_FreezingDate = CASE WHEN ISNULL(ZO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE ZO_MOC_FreezingDate END
				,ZO_MOC_FreezingBy  =  CASE WHEN ISNULL(ZO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE ZO_MOC_FreezingBy END
			FROM FactBranch_Moc  Moc
			INNER JOIN #BranchCode BR
				ON Moc.TimeKey = @PrevLastQtrDateKey
				AND BR.BranchCode = MOc.BranchCode
			
			IF @@ROWCOUNT>0
			BEGIN
				SET @Result =1
				--RETURN  @Result
			END
		END
		IF @UserLevelType = 'ZO'
		BEGIN
			print 'ZO'
			UPDATE Moc
			SET BO_MOC_Frozen  = 'Y'
				,BO_MOC_FreezingDate = CASE WHEN ISNULL(BO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE BO_MOC_FreezingDate END
				,BO_MOC_FreezingBy  =  CASE WHEN ISNULL(BO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE BO_MOC_FreezingBy END
			
				,RO_MOC_Frozen = 'Y'
				,RO_MOC_FreezingDate = CASE WHEN ISNULL(RO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE RO_MOC_FreezingDate END
				,RO_MOC_FreezingBy  =  CASE WHEN ISNULL(RO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE RO_MOC_FreezingBy END
			
				,ZO_MOC_Frozen = 'Y'
				,ZO_MOC_FreezingDate = CASE WHEN ISNULL(ZO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE ZO_MOC_FreezingDate END
				,ZO_MOC_FreezingBy  =  CASE WHEN ISNULL(ZO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE ZO_MOC_FreezingBy END
			FROM FactBranch_Moc  Moc
			INNER JOIN #BranchCode BR
				ON Moc.TimeKey = @PrevLastQtrDateKey
				AND BR.BranchCode = MOc.BranchCode
			
			IF @@ROWCOUNT>0
			BEGIN
				SET @Result =1
				--RETURN  @Result
			END

		END
		IF @UserLevelType = 'RO'
		BEGIN
			UPDATE Moc
			SET BO_MOC_Frozen  = 'Y'
				,BO_MOC_FreezingDate = CASE WHEN ISNULL(BO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE BO_MOC_FreezingDate END
				,BO_MOC_FreezingBy  =  CASE WHEN ISNULL(BO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE BO_MOC_FreezingBy END
			
				,RO_MOC_Frozen = 'Y'
				,RO_MOC_FreezingDate = CASE WHEN ISNULL(RO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE RO_MOC_FreezingDate END
				,RO_MOC_FreezingBy  =  CASE WHEN ISNULL(RO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE RO_MOC_FreezingBy END

				,ZO_MOC_Frozen = 'Y'
				,ZO_MOC_FreezingDate = CASE WHEN ISNULL(ZO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE ZO_MOC_FreezingDate END
				,ZO_MOC_FreezingBy  =  CASE WHEN ISNULL(ZO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE ZO_MOC_FreezingBy END
			
			FROM FactBranch_Moc  Moc
			INNER JOIN #BranchCode BR
				ON Moc.TimeKey = @PrevLastQtrDateKey
				AND BR.BranchCode = MOc.BranchCode
			
			IF @@ROWCOUNT>0
			BEGIN
				SET @Result =1
				--RETURN  @Result
			END
		END
		IF @UserLevelType = 'BO'
		BEGIN
			UPDATE Moc
			SET BO_MOC_Frozen  = 'Y'
				,BO_MOC_FreezingDate = CASE WHEN ISNULL(BO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE BO_MOC_FreezingDate END
				,BO_MOC_FreezingBy  =  CASE WHEN ISNULL(BO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE BO_MOC_FreezingBy END

				,RO_MOC_Frozen = 'Y'
				,RO_MOC_FreezingDate = CASE WHEN ISNULL(RO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE RO_MOC_FreezingDate END
				,RO_MOC_FreezingBy  =  CASE WHEN ISNULL(RO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE RO_MOC_FreezingBy END

				,ZO_MOC_Frozen = 'Y'
				,ZO_MOC_FreezingDate = CASE WHEN ISNULL(ZO_MOC_FreezingDate,'')='' THEN GETDATE() ELSE ZO_MOC_FreezingDate END
				,ZO_MOC_FreezingBy  =  CASE WHEN ISNULL(ZO_MOC_FreezingBy,'')='' THEN @UserLoginId ELSE ZO_MOC_FreezingBy END
			
			FROM FactBranch_Moc  Moc
			INNER JOIN #BranchCode BR
				ON Moc.TimeKey = @PrevLastQtrDateKey
				AND BR.BranchCode = MOc.BranchCode
			
			IF @@ROWCOUNT>0
			BEGIN
				SET @Result =1
				--RETURN  @Result
			END
		END
	
		IF NOT EXISTS (SELECT 1 FROM FactBranch_Moc WHERE TimeKey =  @PrevLastQtrDateKey AND ISNULL(ZO_MOC_Frozen,'N')='N')
		BEGIN
			print 'komal1'
			UPDATE SysDataMatrix 
			SET MOC_Frozen = 'Y'
			WHERE Prev_Qtr_key = @PrevLastQtrDateKey
			
			PRINT CAST(@@ROWCOUNT AS VARCHAR(3))+' Row Updated '
		END
		*/
*/
		commit tran
		set @Result=1
		RETURN @Result
		
END TRY
BEGIN CATCH
	    SELECT ERROR_MESSAGE() ERRORDESC
		ROLLBACK TRAN
		SET @RESULT=-1
		RETURN @RESULT
END  CATCH

		

GO