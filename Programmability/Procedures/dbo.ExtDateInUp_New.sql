SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ExtDateInUp_New]
	--DECLARE	
	 @XmlDocument						XML=''
	-----------D2k System Common Columns
	
	--,@Remark						VARCHAR(500)= NULL		
	,@OperationFlag					TINYINT	=16
	,@AuthMode						CHAR(1)	='Y'	
	,@EffectiveFromTimeKey			INT		=NULL
	,@EffectiveToTimeKey			INT		=NULL
	,@TimeKey						INT		=NULL
	,@CrModApBy						VARCHAR(20)	='ABC'	
	,@D2Ktimestamp					INT	OUTPUT				
	,@Result						INT OUTPUT				
	
	
AS
BEGIN

	SET NOCOUNT ON;
	SET @TimeKey=@EffectiveFromTimeKey

		DECLARE         
		         @ExEntityKey				int				= NULL
				,@AuthorisationStatus		CHAR(2)			= NULL 
				,@CreatedBy					VARCHAR(20)		= NULL
				,@DateCreated				SMALLDATETIME	= NULL
				,@ModifiedBy				VARCHAR(20)		= NULL
				,@DateModified				SMALLDATETIME	= NULL
				,@ApprovedBy				VARCHAR(20)		= NULL
				,@DateApproved				SMALLDATETIME	= NULL
				,@ErrorHandle				int				= 0
				
IF OBJECT_ID ('TEMPDB..#ExtDate')IS NOT NULL
DROP TABLE #ExtDate
SELECT
  c.value('./ExtDate[1]','varchar(10)')OrgExtDate
 ,c.value('./ExtDateTimeKey[1]','varchar(10)')ExtDateTimeKey
 ,c.value('./MonthFirstDate[1]','varchar(10)')MonthFirstDate
 ,c.value('./MonthLastDate[1]','varchar(10)')MonthLastDate
 ,c.value('./OrgExtDate[1]','DATE')ExtDate
 ,c.value('./MaxEntityKey[1]','INT')MaxEntityKey
 ,c.value('./DelStatus[1]','VARCHAR(2)')DelStatus
 ,c.value('./MinEntityKey[1]','INT')MinEntityKey
 ,c.value('./MinFromTimeKey[1]','INT')MinFromTimeKey
 ,c.value('./EntityKey[1]','INT')EntityKey
 ,c.value('./ROWNUM[1]','INT')ROWNUM
 ,ROW_NUMBER()OVER(ORDER BY (SELECT 1))R1
 INTO #ExtDate
 FROM @XmlDocument.nodes('DataSet/GridData') AS t(c)

 UPDATE A
 SET A.ExtDateTimeKey=B.TimeKey
	,A.MonthFirstDate=(SELECT DATEADD(DAY,1,EOMONTH(CONVERT(DATE,A.OrgExtDate,103),-1)))
	,A.MonthLastDate=(SELECT EOMONTH(CONVERT(DATE,A.OrgExtDate,103)))
	,A.ExtDate=(CONVERT(DATE,A.OrgExtDate,103))
 FROM #ExtDate A
 INNER JOIN SysDaymatrix B  ON CONVERT(DATE,A.OrgExtDate,103)=B.Date

UPDATE A
SET A.ROWNUM=B.ROWNUM
FROM #ExtDate A
INNER JOIN(
SELECT ROW_NUMBER()OVER(PARTITION BY MonthFirstDate ORDER BY MonthFirstDate)AS ROWNUM,MonthFirstDate,R1
FROM  #ExtDate )B  ON A.MonthFirstDate=B.MonthFirstDate
					  AND A.R1=B.R1
UPDATE A
SET A.EntityKey=B.EntityKey
FROM #ExtDate  A INNER JOIN(
 SELECT MonthFirstDate,EntityKey,ROW_NUMBER()OVER(PARTITION BY MonthFirstDate ORDER BY MonthFirstDate)AS ROWNUM 
 FROM (
 SELECT DISTINCT A.MonthFirstDate,A.EntityKey
 FROM SysDataMatrix A
 INNER JOIN #ExtDate  B  ON A.MonthFirstDate=B.MonthFirstDate
 AND ISNULL(A.CurrentStatus,'N')='N'
 AND A.ExtDate IS NULL)A)B ON A.MonthFirstDate=B.MonthFirstDate
							  AND A.ROWNUM=B.ROWNUM

	IF @OperationFlag=1  --- add
	BEGIN
	PRINT 1
		-----CHECK DUPLICATE BILL NO AT BRANCH LEVEL
		IF EXISTS(				                
					SELECT  1 FROM SysDataMatrix A
					INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate
					UNION
					SELECT  1 FROM ExtDataMatrix_Mod A
					INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate
					WHERE (EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey)
							AND  AuthorisationStatus in('NP','MP','DP','RM') 
				)	
				BEGIN
				   PRINT 2
					SET @Result=-6
					RETURN @Result --  ALEADY EXISTS
				END
	END
	
	BEGIN TRY
	BEGIN TRANSACTION	
	-----
	
	PRINT 3	
		--np- new,  mp - modified, dp - delete, fm - further modifief, A- AUTHORISED , 'RM' - REMARK 
	IF @OperationFlag =1 AND @AuthMode ='Y' -- ADD
		BEGIN
				     PRINT 'Add'
					 SET @CreatedBy =@CrModApBy 
					 SET @DateCreated = GETDATE()
					 SET @AuthorisationStatus='NP'

					 GOTO ExtSysDataMatrix_Insert
					 ExtSysDataMatrix_Insert_Add:
			END


	ELSE IF(@OperationFlag = 2 OR @OperationFlag = 3) AND @AuthMode = 'Y' --EDIT AND DELETE
			BEGIN
				Print 4
				SET @CreatedBy= @CrModApBy
				SET @DateCreated = GETDATE()
				Set @Modifiedby=@CrModApBy   
				Set @DateModified =GETDATE() 

					PRINT 5

					IF @OperationFlag = 2
						BEGIN
							PRINT 'Edit'
							SET @AuthorisationStatus ='MP'
							
						END

					ELSE
						BEGIN
							PRINT 'DELETE'
							SET @AuthorisationStatus ='DP'
							
						END

				
					PRINT 'NOT AVAILABLE IN MAIN'
					SELECT  @CreatedBy		= CreatedBy
							,@DateCreated	= DateCreated 
					FROM ExtDataMatrix_Mod A
					INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus IN('NP','MP','A','RM')
					
				
					--UPDATE NP,MP  STATUS 
					IF @OperationFlag=2
					BEGIN	

						UPDATE A
							SET AuthorisationStatus='FM'
							,ModifiedBy=@Modifiedby
							,DateModified=@DateModified
						FROM ExtDataMatrix_Mod A
						INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate		
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								AND AuthorisationStatus IN('NP','MP','RM')
					END

					GOTO ExtSysDataMatrix_Insert
					ExtSysDataMatrix_Insert_Edit_Delete:
				END

	ELSE IF @OperationFlag =3 AND @AuthMode ='N'
		BEGIN
		-- DELETE WITHOUT MAKER CHECKER
				SET @Modifiedby   = @CrModApBy 
				SET @DateModified = GETDATE() 

				UPDATE A 
				SET ExtDate=NULL
				FROM SysDataMatrix  A
				INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate	
		END
	
	
	ELSE IF @OperationFlag=17 AND @AuthMode ='Y' 
	BEGIN
				SET @ApprovedBy	   = @CrModApBy 
				SET @DateApproved  = GETDATE()

				UPDATE A
					SET AuthorisationStatus='R'
					,ApprovedBy	 =@ApprovedBy
					,DateApproved=@DateApproved
					,EffectiveToTimeKey =@EffectiveFromTimeKey-1
				FROM ExtDataMatrix_Mod A 
				INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate			
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
						AND AuthorisationStatus in('NP','MP','DP','RM')	
		END	

	ELSE IF @OperationFlag=18
	BEGIN
		PRINT 18
		SET @ApprovedBy=@CrModApBy
		SET @DateApproved=GETDATE()
		UPDATE A 
		SET AuthorisationStatus='RM'
		FROM ExtDataMatrix_Mod A
		INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate		
		WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
		AND AuthorisationStatus IN('NP','MP','DP','RM')

	END

	ELSE IF @OperationFlag=16 OR @AuthMode='N'
	BEGIN
			
			Print 'Authorise'
	-------set parameter for  maker checker disabled
			IF @AuthMode='N'
			BEGIN
				IF @OperationFlag=1
					BEGIN
						SET @CreatedBy =@CrModApBy
						SET @DateCreated =GETDATE()
					END
				ELSE
					BEGIN
						SET @ModifiedBy  =@CrModApBy
						SET @DateModified =GETDATE()
						
						SET @ApprovedBy = @CrModApBy			
						SET @DateApproved=GETDATE()
					END



			END	 
			
	---set parameters and UPDATE mod table in case maker checker enabled
			IF @AuthMode='Y'
				BEGIN
		
					
					UPDATE A
					SET A.MaxEntityKey=B.Entity_Key
					 ,A.MinEntityKey=B.MinEntity_Key
					FROM #ExtDate A
					INNER JOIN (
					SELECT MAX(Entity_Key)Entity_Key,A.ExtDate,MIN(Entity_Key)MinEntity_Key 
					FROM ExtDataMatrix_Mod A
					INNER JOIN #ExtDate B ON A.ExtDate=B.ExtDate
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
							AND AuthorisationStatus IN('NP','MP','DP','RM')
					GROUP BY A.ExtDate	)B	
							ON A.ExtDate=B.ExtDate
					
					 UPDATE B
					 SET B.DelStatus=AuthorisationStatus
					 FROM ExtDataMatrix_Mod A
					 INNER JOIN #ExtDate B ON A.Entity_Key=B.MaxEntityKey
					
					SET @ApprovedBy = @CrModApBy			
					SET @DateApproved=GETDATE()
				
					
					UPDATE B
					SET MinFromTimeKey=EffectiveFromTimeKey 
					FROM ExtDataMatrix_Mod A
					INNER JOIN #ExtDate B ON A.Entity_Key=B.MinEntityKey

					UPDATE ExtDataMatrix_Mod
					SET  EffectiveToTimeKey =B.MinFromTimeKey-1
					FROM ExtDataMatrix_Mod A
					INNER JOIN #ExtDate B  ON A.ExtDate=B.ExtDate		
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
						AND A.AuthorisationStatus='A'
			
			
		-------DELETE RECORD AUTHORISE
		
						UPDATE A
						SET AuthorisationStatus ='A'
							,ApprovedBy=@ApprovedBy
							,DateApproved=@DateApproved
							,EffectiveToTimeKey =@EffectiveFromTimeKey -1
						FROM ExtDataMatrix_Mod A
						INNER JOIN #ExtDate B  ON A.ExtDate=B.ExtDate	
												 AND ISNULL(DelStatus,'')='DP'	
						WHERE  AuthorisationStatus in('NP','MP','DP','RM')
						
						
							UPDATE A
							SET ExtDate=NULL
							FROM SysDataMatrix A
							INNER JOIN #ExtDate B  ON A.ExtDate=B.ExtDate
													AND ISNULL(DelStatus,'')='DP'
			
							UPDATE  A
								SET  AuthorisationStatus ='A'
									,ApprovedBy=@ApprovedBy
									,DateApproved=@DateApproved
							FROM ExtDataMatrix_Mod  A
							INNER JOIN #ExtDate B  ON A.ExtDate=B.ExtDate
														AND ISNULL(B.DelStatus,'')<>'DP'			
							WHERE AuthorisationStatus in('NP','MP','RM')

							DELETE FROM #ExtDate
							WHERE ISNULL(DelStatus,'')='DP'
		
				END
			
			UPDATE A
			SET A.ExtDate=B.ExtDate
			,A.TimeKey=B.ExtDateTimeKey
			FROM SysDataMatrix A
			INNER JOIN #ExtDate B  ON A.ENTITYKEY=B.EntityKey	
			WHERE ISNULL(A.CurrentStatus,'N')='N' AND A.ExtDate IS NULL		
			PRINT 'SONALI'	

				INSERT INTO SysDataMatrix
				(
					 MonthFirstDate
					,MonthLastDate
					,TimeKey
					,[MonthName]
					,[Month]
					,[Year]
					,[ExtDate]
					,[CurrentStatus]
				) 	
				SELECT
				 A.MonthFirstDate,
				 A.MonthLastDate,
				 A.ExtDateTimeKey,
				 FORMAT((CAST(A.MonthFirstDate AS DATE)),'MMMM'),
				 MONTH(A.MonthFirstDate),
				 YEAR(A.MonthFirstDate),
				 A.ExtDate
				 ,'N'
				 FROM #ExtDate A
				 WHERE A.EntityKey IS NULL
													  

		IF @AUTHMODE='N'
			BEGIN
					SET @AuthorisationStatus='A'
					GOTO ExtSysDataMatrix_Insert
					HistoryRecordInUp:
			END						
	END 


PRINT 6
SET @ErrorHandle=1

ExtSysDataMatrix_Insert:
IF @ErrorHandle=0
	BEGIN
			--SELECT @ServiceLastdate
			INSERT INTO ExtDataMatrix_Mod
												(
													ExtDate
													,AuthorisationStatus	
													,EffectiveFromTimeKey
													,EffectiveToTimeKey
													,CreatedBy
													,DateCreated
													,ModifiedBy
													,DateModified
													,ApprovedBy
													,DateApproved
													,TimeKey
													)
												
												SELECT 
										
													 ExtDate        
													,@AuthorisationStatus
													,@EffectiveFromTimeKey
													,@EffectiveToTimeKey 
													,@CreatedBy
													,@DateCreated
													,@ModifiedBy
													,@DateModified
													,@ApprovedBy 
													,@DateApproved 
													,ExtDateTimeKey
												FROM #ExtDate		

		         IF @OperationFlag =1 AND @AUTHMODE='Y'
					BEGIN
						PRINT 3
						GOTO ExtSysDataMatrix_Insert_Add
					END
				ELSE IF (@OperationFlag =2 OR @OperationFlag =3)AND @AUTHMODE='Y'
					BEGIN
						GOTO ExtSysDataMatrix_Insert_Edit_Delete
					END
				

	END

IF @OperationFlag=3 AND @AuthMode='Y'  /* If data is not aviable in main table for that scenario authorisation not happend through screen*/
	BEGIN
			IF NOT EXISTS(SELECT 1 FROM SysDataMatrix A
						  INNER JOIN  #ExtDate        B ON A.ExtDate=B.ExtDate
						 )
				BEGIN
						EXEC ExtDateInUp_New 
						 @xmlDocument=@xmlDocument,
						 @EffectiveFromTimeKey=@EffectiveFromTimeKey,
						 @EffectiveToTimeKey=@EffectiveToTimeKey,@CrModApBy=@CrModApBy,@AuthMode=N'Y',
						 @OperationFlag=16,@D2Ktimestamp=@D2Ktimestamp,@Result=@Result
				END			
	END

	-------------------
PRINT 7
		COMMIT TRANSACTION

		SELECT @D2Ktimestamp=(SELECT ISNULL(CAST(MAX(D2Ktimestamp)AS INT),0000001) FROM ExtDataMatrix_Mod
							 )
		

		IF @OperationFlag =3
			BEGIN
				SET @Result = 3
				 RETURN @Result
			END
		ELSE
			BEGIN
			PRINT 8
				 SET @Result = 1
				 RETURN @Result
				--RETURN @MgmtProfileEntityId
			END
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	SELECT ERROR_MESSAGE()
	RETURN -1

END CATCH
---------
END
GO