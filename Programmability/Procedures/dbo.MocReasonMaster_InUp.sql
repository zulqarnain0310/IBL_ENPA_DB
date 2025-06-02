SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MocReasonMaster_InUp]	--17,'140','ABC','Customer Reason','Shubham',27056,49999
@OperationFlag	INT
,@MocReasonCode INT
,@MocReasonName VARCHAR(250)
, @MocReasonCategory varchar(250)
,@UserLoginID	VARCHAR(30)
, @EFFECTIVEFROMTIMEKEY INT
, @EFFECTIVETOTIMEKEY INT
, @Result	INT=0 OUTPUT
AS
BEGIN

DECLARE @TIMEKEY INT=@EFFECTIVEFROMTIMEKEY

SET @MocReasonCode= (SELECT CAST( @MocReasonCode AS INT) )
--DECLARE 
--@OperationFlag	INT = 1
--,@MocReasonName VARCHAR(250) = 'Dummy2'
--, @MocReasonCategory varchar(250)= 'Account Reason'
--,@UserLoginID	VARCHAR(30)='Shubham001'
--,@EFFECTIVEFROMTIMEKEY INT=26922
--,@EFFECTIVETOTIMEKEY INT=49999
----,@Result	INT=0 OUTPUT
--,@TIMEKEY INT=26922
--,@MocReasonCode INT


SET DATEFORMAT DMY
	SET NOCOUNT ON;
/*TO INSERT NEW RECORDS IN MOD TABLE*/
IF (@OperationFlag=1)
	BEGIN
			
			SET @MocReasonCode =(select max(MocReasonAlt_Key)+10 from 
																			(select MocReasonAlt_Key from DimMocReason --where EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY 
																			union																	
																			select MocReasonAlt_Key from DimMocReason_Mod)A) --where EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY)A)


			IF EXISTS (SELECT 1 FROM (SELECT MocReasonName FROM DimMocReason where --MocReasonAlt_Key=@MocReasonCode OR
								(MocReasonName=@MocReasonName AND MocReasonCategory=@MocReasonCategory) AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
								UNION 
								SELECT MocReasonName FROM DimMocReason_Mod where --MocReasonAlt_Key=@MocReasonCode OR
								(MocReasonName=@MocReasonName AND MocReasonCategory=@MocReasonCategory) AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
								)A)
									
									BEGIN
										PRINT'RECORD EXISTS'
										--Rollback tran
										SET @Result=-6
										RETURN @Result
									END

		
			ELSE
					BEGIN
					SET @Result=1

							BEGIN
								PRINT 'INSERTING INTO MOD TABLE'
								INSERT INTO DimMocReason_Mod(
																	MocReasonAlt_Key
																	,MocReasonName
																	,MocReasonCategory
																	,AuthorisationStatus
																	,EffectiveFromTimeKey
																	,EffectiveToTimeKey
																	,CreatedBy
																	,DateCreated
																	
															)
														VALUES(		@MocReasonCode
																	,@MocReasonName
																	,@MocReasonCategory																												
																	,'NP'
																	,@TIMEKEY
																	,49999
																	,@UserLoginID
																	,GETDATE()

																)
							END
					END
	END


/*TO MODIFY EXISTING RECORDS IN MOD TABLE*/
 IF (@OperationFlag=2)
	BEGIN					
		SET @Result=1

				/*If NP record modified at the time of adding new record in mod table*/			
						DECLARE @MocReasonCode_1 INT =(select max(MocReasonAlt_Key)
												       from DimMocReason_Mod where EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)


				/*If NP record modified at the time of adding new record in mod table*/			
			IF('NP' = (SELECT AuthorisationStatus FROM DimMocReason_Mod WHERE MocReasonAlt_Key=@MocReasonCode_1 AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY))								
				BEGIN
						           
							IF EXISTS (SELECT 1 FROM (SELECT MocReasonName FROM DimMocReason where --MocReasonAlt_Key=@MocReasonCode OR
									(MocReasonName=@MocReasonName AND MocReasonCategory=@MocReasonCategory) AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
									UNION 
									SELECT MocReasonName FROM DimMocReason_Mod where --MocReasonAlt_Key=@MocReasonCode OR
									(MocReasonName=@MocReasonName AND MocReasonCategory=@MocReasonCategory) AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
									)A)
										
										BEGIN
											PRINT'RECORD EXISTS'
											--Rollback tran
											SET @Result=-6
											RETURN @Result
										END
							ELSE
								BEGIN
									   UPDATE DimMocReason_Mod SET AuthorisationStatus='FM'
																   ,EffectiveToTimeKey=EffectiveFromTimeKey - 1 
																   WHERE MocReasonAlt_Key=@MocReasonCode_1
																	AND EffectiveToTimeKey=49999
																	AND AuthorisationStatus in ('NP')

									
									  INSERT INTO DimMocReason_Mod(
																		MocReasonAlt_Key
																		,MocReasonName
																		,MocReasonCategory
																		,AuthorisationStatus
																		,EffectiveFromTimeKey
																		,EffectiveToTimeKey
																		,CreatedBy
																		,DateCreated
																		,ModifiedBy
																		,DateModified
																		
																	)
															VALUES(		@MocReasonCode_1
																		,@MocReasonName
																		,@MocReasonCategory																												
																		,'NP'
																		,@TIMEKEY
																		,49999
																		,@UserLoginID
																		,GETDATE()
																		,@UserLoginID
																		,GETDATE()

																	)									
								END
				END							
				
			/* If Authorized record is modified*/
				ELSE
					BEGIN	

							UPDATE DimMocReason SET AuthorisationStatus='MP'
												WHERE MocReasonAlt_Key=@MocReasonCode																						
											AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY

							UPDATE DimMocReason_Mod SET EffectiveToTimeKey = @TIMEKEY - 1
													WHERE MocReasonAlt_Key=@MocReasonCode
													AND ISNULL(AuthorisationStatus,'A')='A'

																											
							INSERT INTO DimMocReason_Mod(
																 MocReasonAlt_Key
																,MocReasonName
																,MocReasonCategory
																,AuthorisationStatus
																,EffectiveFromTimeKey
																,EffectiveToTimeKey
																,CreatedBy
																,DateCreated
																,ModifiedBy
																,DateModified
															)
													 SELECT     
																MocReasonAlt_Key
																,@MocReasonName
																,@MocReasonCategory
																,'MP'
																,@TIMEKEY
																,49999
																,CreatedBy
																,DateCreated
																,@UserLoginID
																,GETDATE()

													FROM DimMocReason
													WHERE MocReasonAlt_Key=@MocReasonCode
													AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
						END
	END



--/*TO DELETE EXISTING RECORDS IN MAIN TABLE AND EXPIRING IN MOD TABLE*/	
IF (@OperationFlag=3)
	BEGIN
		SET @Result=1
			IF @MocReasonCode IN (SELECT MocReasonAlt_Key FROM DimMocReason where EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
						BEGIN
							
								UPDATE DimMocReason_MOD SET			 EffectiveToTimeKey=@TimeKey -1																	
																	,ModifiedBy=@UserLoginID
																	,DateModified=GETDATE()
																--	,AuthorisationStatus='DP'
														WHERE MocReasonAlt_Key=@MocReasonCode
														AND AuthorisationStatus='A'
							
									INSERT INTO DimMocReason_Mod(
																	MocReasonAlt_Key
																	,MocReasonName
																	,MocReasonCategory
																	,AuthorisationStatus
																	,EffectiveFromTimeKey
																	,EffectiveToTimeKey
																	,CreatedBy
																	,DateCreated
																	,ModifiedBy
																	,DateModified
																)
														 SELECT     
																MocReasonAlt_Key
																,MocReasonName
																,MocReasonCategory
																,'DP'
																,@TIMEKEY
																,49999
																,@UserLoginID
																,GETDATE()
																,@UserLoginID
																,GETDATE()

													FROM DimMocReason
													WHERE MocReasonAlt_Key=@MocReasonCode
													AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY		
						END				

	END

/*TO AUTHORISE FIRSTLEVEL IN MOD TABLE*/

  IF (@OperationFlag=16)				
		BEGIN		
		SET @Result=1
						
						UPDATE DimMocReason_Mod SET ApprovedByFirstLevel=@UserLoginID 
															,DateApprovedFirstLevel=GETDATE()
															,AuthorisationStatus='1A'
								WHERE		MocReasonAlt_Key=@MocReasonCode 
										AND AuthorisationStatus IN ('NP','MP')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND CreatedBy<>@USERLOGINID

					    UPDATE DimMocReason_Mod SET ApprovedByFirstLevel=@UserLoginID 
															,DateApprovedFirstLevel=GETDATE()
															,AuthorisationStatus='1D'
								WHERE		MocReasonAlt_Key=@MocReasonCode 
										AND AuthorisationStatus IN ('DP')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND ModifiedBy<>@USERLOGINID
		END


/*TO REJECT FIRSTLEVEL IN MOD TABLE*/
IF (@OperationFlag=17)
		BEGIN
		SET @Result=1

						UPDATE DimMocReason_Mod SET ApprovedByFirstLevel=@UserLoginID 
																	,DateApprovedFirstLevel=GETDATE()
																	,AuthorisationStatus='R'
																	,EffectiveToTimeKey=EffectiveFromTimeKey-1
										WHERE		MocReasonAlt_Key=@MocReasonCode
												AND AuthorisationStatus IN ('NP','MP','DP')
												AND EffectiveFromTimeKey<=@TIMEKEY
												AND EffectiveToTimeKey>=@TIMEKEY
												AND CreatedBy<>@USERLOGINID

						UPDATE DimMocReason_Mod SET ApprovedBy=@UserLoginID 
													,DateApproved=GETDATE()
													,AuthorisationStatus='R'
													,EffectiveToTimeKey=EffectiveFromTimeKey-1
										WHERE		MocReasonAlt_Key=@MocReasonCode
												AND	MocReasonName=@MocReasonName 
												AND MocReasonCategory=@MocReasonCategory
												AND AuthorisationStatus IN ('1A','1D')
												AND CreatedBy<>@USERLOGINID
												AND ApprovedByFirstLevel<>@USERLOGINID
-----------------------------------------------------------------------------------------------------
						--UPDATE DimMocReason SET AuthorisationStatus='A'
						--				WHERE		MocReasonAlt_Key=@MocReasonCode
						--						AND AuthorisationStatus IN ('MP')
						--						AND EffectiveFromTimeKey<=@TIMEKEY
						--						AND EffectiveToTimeKey>=@TIMEKEY
						--						AND CreatedBy<>@USERLOGINID												
						
		END

/*TO AUTHORISE SECONDLEVEL IN MOD TABLE*/
IF (@OperationFlag=20)		
		BEGIN		
			SET @Result=1

						UPDATE DimMocReason_Mod SET ApprovedBy=@UserLoginID 
															,DateApproved=GETDATE()
															,AuthorisationStatus='A'
								WHERE		MocReasonAlt_Key=@MocReasonCode 
										AND AuthorisationStatus IN ('1A')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND CreatedBy<>@USERLOGINID
										AND ApprovedByFirstLevel<>@USERLOGINID
						
						UPDATE DimMocReason_Mod SET ApprovedBy=@UserLoginID 
															,DateApproved=GETDATE()
															,EffectiveToTimeKey=EffectiveFromTimeKey-1
															,AuthorisationStatus='D'
								WHERE	MocReasonAlt_Key=@MocReasonCode
										AND AuthorisationStatus IN ('1D')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND ModifiedBy<>@UserLoginID
										AND ApprovedByFirstLevel<>@USERLOGINID
					
		/*INSERT INTO MAIN TABLE WHERE AuthorisationStatus='A'*/
					IF @MocReasonName NOT IN (SELECT MocReasonName FROM DimMocReason WHERE MocReasonAlt_Key=@MocReasonCode AND MocReasonCategory=@MocReasonCategory AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
							BEGIN
									INSERT INTO DimMocReason(
																
																MocReasonAlt_Key
																,MocReasonName
																,MocReasonCategory
																,AuthorisationStatus
																,EffectiveFromTimeKey
																,EffectiveToTimeKey
																,CreatedBy
																,DateCreated
																,ApprovedBy
																,DateApproved
																,ApprovedByFirstLevel
																,DateApprovedFirstLevel
																)
																
														SELECT 
																MocReasonAlt_Key
																,MocReasonName
																,MocReasonCategory
																,AuthorisationStatus
																,EffectiveFromTimeKey
																,EffectiveToTimeKey
																,CreatedBy
																,DateCreated
																,ApprovedBy
																,DateApproved
																,ApprovedByFirstLevel
																,DateApprovedFirstLevel
																FROM DimMocReason_Mod
																WHERE AuthorisationStatus='A'
																AND MocReasonAlt_Key=@MocReasonCode
																AND EffectiveFromTimeKey<=@TIMEKEY 
																AND EffectiveToTimeKey>=@TIMEKEY
																		
							END

				/*UPDATE MAIN TABLE WHERE AuthorisationStatus='MP'*/

				ELSE IF @MocReasonName IN (SELECT MocReasonName FROM DimMocReason WHERE  MocReasonAlt_Key=@MocReasonCode AND MocReasonCategory=@MocReasonCategory and  EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
							BEGIN
								UPDATE DimMocReason SET				ApprovedBy=@UserLoginID 
										 							,DateApproved=GETDATE()
																	,AuthorisationStatus='A'
																	,MocReasonName=@MocReasonName
										WHERE		MocReasonAlt_Key=@MocReasonCode 
												AND AuthorisationStatus IN ('MP')
												AND EffectiveFromTimeKey<=@TIMEKEY
												AND EffectiveToTimeKey>=@TIMEKEY
												AND CreatedBy<>@USERLOGINID
												AND ApprovedByFirstLevel<>@USERLOGINID
								
						/*2nd levvel approval for Deleted recoerds*/		
							UPDATE A SET		   A.ApprovedBy=@UserLoginID 
										 							,A.DateApproved=GETDATE()
																	,A.EffectiveToTimeKey=@TIMEKEY - 1
																	,A.AuthorisationStatus='D'
									from DimMocReason A Inner join DimMocReason_Mod B
										on A.MocReasonAlt_Key=B.MocReasonAlt_Key
										WHERE  A.MocReasonAlt_Key=@MocReasonCode
												AND B.AuthorisationStatus IN ('D')
												AND A.EffectiveFromTimeKey<=@TIMEKEY
												AND A.EffectiveToTimeKey>=@TIMEKEY
										--		AND B.EffectiveFromTimeKey<=@TIMEKEY
										--		AND B.EffectiveToTimeKey>=@TIMEKEY

							END
				

		END
--/*TO REJECT IN MOD TABLE*/
--IF (@OperationFlag=21)
--	BEGIN

--	SET @Result=1
--	UPDATE DimMocReason_Mod SET ApprovedBy=@UserLoginID 
--												,DateApproved=GETDATE()
--												,AuthorisationStatus='R'
--					WHERE		MocReasonAlt_Key=@MocReasonCode
--							AND	MocReasonName=@MocReasonName 
--							AND MocReasonCategory=@MocReasonCategory
--							AND AuthorisationStatus IN ('1A')
--							AND CreatedBy<>@USERLOGINID
--							AND ApprovedByFirstLevel<>@USERLOGINID

--	UPDATE DimMocReason SET AuthorisationStatus='A'
--					WHERE		MocReasonAlt_Key=@MocReasonCode
--							AND	MocReasonName=@MocReasonName 
--							AND MocReasonCategory=@MocReasonCategory
--							AND AuthorisationStatus IN ('MP')
--							AND EffectiveFromTimeKey<=@TIMEKEY
--							AND EffectiveToTimeKey>=@TIMEKEY
	

--	RETURN @Result 			
--	END
END		



GO