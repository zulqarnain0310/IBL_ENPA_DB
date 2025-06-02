SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CategoryProvisionInUp_BKP25042024]  -- 2,'dayanand',27056,27056,'Y','qwerty',50,''
@OperationFlag			INT
,@UserLoginID				VARCHAR(30)
, @EFFECTIVEFROMTIMEKEY INT
, @EFFECTIVETOTIMEKEY INT
,@STD_ASSET_CATValidCode VARCHAR(3)
,@STD_ASSET_CATName VARCHAR(50)
,@STD_ASSET_PER decimal(18,9)
,@Remark varchar(250) 
, @Result		INT=0 OUTPUT
AS


BEGIN


DECLARE @TIMEKEY INT=@EFFECTIVEFROMTIMEKEY
DECLARE @STD_ASSET_PER_1 DECIMAL(18,9)
set @STD_ASSET_PER_1=(select cast(@STD_ASSET_PER/100 as decimal(18,9)))
 
SET DATEFORMAT DMY
	SET NOCOUNT ON;
/*TO INSERT NEW RECORDS IN MOD TABLE*/
	IF (@OperationFlag=1)
		BEGIN
			
			DECLARE @STD_ASSET_CAT_Key INT=(select max(STD_ASSET_CAT_Key)+10 from (select STD_ASSET_CAT_Key from DIM_STD_ASSET_CAT    
			union select STD_ASSET_CAT_Key from DIM_STD_ASSET_CAT_MOD)A)

			IF (EXISTS (SELECT 1 FROM (SELECT STD_ASSET_CATShortName FROM DIM_STD_ASSET_CAT where 
								STD_ASSET_CATShortName=@STD_ASSET_CATName  AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
								UNION 
								SELECT STD_ASSET_CATShortName FROM DIM_STD_ASSET_CAT_MOD where 
								STD_ASSET_CATShortName=@STD_ASSET_CATName  AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
								)A))
									
									BEGIN
										 --Rollback tran
										SET @Result=-6
										PRINT  'SAME VALUES ALREADY EXISTS 1'
										RETURN @Result
									END

			ELSE
				BEGIN
				SET @Result=1
						BEGIN
							PRINT 'INSERTING NEW RECORD...'	
							INSERT INTO DIM_STD_ASSET_CAT_MOD(
																STD_ASSET_CAT_Key
																,STD_ASSET_CATAlt_key
																,STD_ASSET_CATName
																,STD_ASSET_CATShortName
																,STD_ASSET_CATShortNameEnum
																,STD_ASSET_CAT_Prov
																,STD_ASSET_CAT_Prov_Unsecured
																,STD_ASSET_CATValidCode
																,EffectiveFromTimeKey
																,EffectiveToTimeKey
																,CREATEDBY
																,DateCreated
																,AuthorisationStatus
															)VALUES(
																@STD_ASSET_CAT_Key
																,@STD_ASSET_CAT_Key
																,@STD_ASSET_CATName
																,@STD_ASSET_CATName
																,@STD_ASSET_CATName
																,cast(@STD_ASSET_PER_1 as decimal(18,9)) --ADDED ON 20231229 ON LOCAL
																,cast(@STD_ASSET_PER_1 as decimal(18,9))--ADDED ON 20231229 ON LOCAL
																,@STD_ASSET_CATValidCode
																,@TimeKey
																,49999
																,@UserLoginID
																,GETDATE()
																,'NP'
												)
						END
				END
	END
/*TO MODIFY EXISTING RECORDS IN MOD TABLE*/
ELSE IF (@OperationFlag=2)
	BEGIN				
		SET @Result=1	

						DECLARE @STD_ASSET_CATAlt_key_1 INT =(select max(STD_ASSET_CATAlt_key)
												       from DIM_STD_ASSET_CAT_MOD where EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)

					
					if('NP' = (SELECT AuthorisationStatus FROM DIM_STD_ASSET_CAT_MOD WHERE STD_ASSET_CATAlt_key=@STD_ASSET_CATAlt_key_1 
													AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY))
					 BEGIN
					
								UPDATE DIM_STD_ASSET_CAT_MOD SET AuthorisationStatus='FM'
															   ,EffectiveToTimeKey=EffectiveFromTimeKey - 1 
															   WHERE STD_ASSET_CATAlt_key=@STD_ASSET_CATAlt_key_1
																AND EffectiveToTimeKey=49999
																AND AuthorisationStatus in ('NP')
							
								INSERT INTO DIM_STD_ASSET_CAT_MOD(
																		STD_ASSET_CAT_Key
																		,STD_ASSET_CATAlt_key
																		,STD_ASSET_CATName
																		,STD_ASSET_CATShortName
																		,STD_ASSET_CATShortNameEnum
																		,STD_ASSET_CAT_Prov
																		,STD_ASSET_CAT_Prov_Unsecured
																		,STD_ASSET_CATValidCode
																		,EffectiveFromTimeKey
																		,EffectiveToTimeKey
																		,AuthorisationStatus
																		,CreatedBy
																		,DateCreated
																		,MODIFYBY
																		,DATEMODIFIED
																	)
															 values(
																		 @STD_ASSET_CATAlt_key_1
																		,@STD_ASSET_CATAlt_key_1
																		,@STD_ASSET_CATName
																		,@STD_ASSET_CATName
																		,@STD_ASSET_CATName
																		,@STD_ASSET_PER_1
																		,@STD_ASSET_PER_1
																		,'Y'
																		,@TIMEKEY
																		,49999
																		,'NP'
																		,@UserLoginID
																		,GETDATE()
																		,@UserLoginID
																		,GETDATE()
																	)
					 END




				ELSE
					BEGIN
							PRINT'MODIFYING RECORDS STD_ASSET_PER OF CATEGORY:'
																																		
									UPDATE DIM_STD_ASSET_CAT_MOD SET EffectiveToTimeKey = EffectiveFromTimeKey - 1
	      															,ModifyBy=@UserLoginID
																	,DateModified=GETDATE()
													WHERE STD_ASSET_CATName=@STD_ASSET_CATName AND ISNULL(AuthorisationStatus,'A')='A'
									
									INSERT INTO DIM_STD_ASSET_CAT_MOD(
																		STD_ASSET_CAT_Key
																		,STD_ASSET_CATAlt_key
																		,STD_ASSET_CATName
																		,STD_ASSET_CATShortName
																		,STD_ASSET_CATShortNameEnum
																		,STD_ASSET_CAT_Prov
																		,STD_ASSET_CAT_Prov_Unsecured
																		,STD_ASSET_CATValidCode
																		,EffectiveFromTimeKey
																		,EffectiveToTimeKey
																		,AuthorisationStatus
																		,CreatedBy
																		,DateCreated
																		,MODIFYBY
																		,DATEMODIFIED
																	)
															 SELECT
																		STD_ASSET_CAT_Key
																		,STD_ASSET_CATAlt_key
																		,STD_ASSET_CATName
																		,STD_ASSET_CATShortName
																		,STD_ASSET_CATShortNameEnum
																		,@STD_ASSET_PER_1
																		,@STD_ASSET_PER_1
																		,STD_ASSET_CATValidCode
																		,@TIMEKEY
																		,49999
																		,'MP'
																		,CreatedBy
																		,DateCreated
																		,@UserLoginID
																		,GETDATE()
															FROM DIM_STD_ASSET_CAT
															WHERE STD_ASSET_CATName=@STD_ASSET_CATName
															AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
					 END
	END

/*TO DELETE EXISTING RECORDS IN MAIN TABLE AND EXPIRING IN MOD TABLE*/	
ELSE IF (@OperationFlag=3)
	BEGIN	
		SET @Result=1
			IF @STD_ASSET_CATName IN (SELECT STD_ASSET_CATName FROM DIM_STD_ASSET_CAT where EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
							BEGIN
							
								UPDATE DIM_STD_ASSET_CAT_MOD SET    EffectiveToTimeKey=@TimeKey -1
																	,STD_ASSET_CATValidCode='N'
																	,MODIFYBY=@UserLoginID
																	,DATEMODIFIED=GETDATE()																
															WHERE STD_ASSET_CATName=@STD_ASSET_CATName
															AND AuthorisationStatus='A'															

								INSERT INTO DIM_STD_ASSET_CAT_MOD(
																		STD_ASSET_CAT_Key
																		,STD_ASSET_CATAlt_key
																		,STD_ASSET_CATName
																		,STD_ASSET_CATShortName
																		,STD_ASSET_CATShortNameEnum
																		,STD_ASSET_CAT_Prov
																		,STD_ASSET_CAT_Prov_Unsecured
																		,STD_ASSET_CATValidCode
																		,EffectiveFromTimeKey
																		,EffectiveToTimeKey
																		,AuthorisationStatus
																		,CreatedBy
																		,DateCreated
																		,MODIFYBY
																		,DATEMODIFIED
																	)
															 SELECT
																		STD_ASSET_CAT_Key
																		,STD_ASSET_CATAlt_key
																		,STD_ASSET_CATName
																		,STD_ASSET_CATShortName
																		,STD_ASSET_CATShortNameEnum
																		,STD_ASSET_CAT_Prov
																		,STD_ASSET_CAT_Prov_Unsecured
																		,STD_ASSET_CATValidCode
																		,@TIMEKEY
																		,49999
																		,'DP'
																		,@UserLoginID
																		,GETDATE()
																		,@UserLoginID
																		,GETDATE()
															FROM DIM_STD_ASSET_CAT
															WHERE STD_ASSET_CATName=@STD_ASSET_CATName
															AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
							END
	END


/*TO AUTHORISE FIRSTLEVEL IN MOD TABLE*/
  IF (@OperationFlag=16)
		BEGIN
		SET @Result=1

						UPDATE DIM_STD_ASSET_CAT_MOD SET ApprovedByFirstLevel=@UserLoginID 
															,DateApprovedFirstLevel=GETDATE()
															,AuthorisationStatus='1A'
								WHERE STD_ASSET_CATName=@STD_ASSET_CATName
										AND AuthorisationStatus IN ('NP','MP')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND CreatedBy<>@USERLOGINID

					UPDATE DIM_STD_ASSET_CAT_MOD SET ApprovedByFirstLevel=@UserLoginID 
															,DateApprovedFirstLevel=GETDATE()
															,AuthorisationStatus='1D'
								WHERE STD_ASSET_CATName=@STD_ASSET_CATName
										AND AuthorisationStatus IN ('DP')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND ModifyBy<>@USERLOGINID



		END


/*TO REJECT FIRSTLEVEL IN MOD TABLE*/
IF (@OperationFlag=17)
		BEGIN
		SET @Result=1

						UPDATE DIM_STD_ASSET_CAT_MOD SET ApprovedByFirstLevel=@UserLoginID 
																	,DateApprovedFirstLevel=GETDATE()
																	,AuthorisationStatus='R'
																	,EffectiveToTimeKey = EffectiveFromTimeKey - 1
										WHERE STD_ASSET_CATName=@STD_ASSET_CATName
												AND AuthorisationStatus IN ('NP','MP','DP')
												AND EffectiveFromTimeKey<=@TIMEKEY
												AND EffectiveToTimeKey>=@TIMEKEY
												AND CreatedBy<>@USERLOGINID

						UPDATE DIM_STD_ASSET_CAT_MOD SET ApprovedBy=@UserLoginID
														,DateApproved=GETDATE()
														,AuthorisationStatus='R'
														,EffectiveToTimeKey=EffectiveFromTimeKey - 1																									
										WHERE		STD_ASSET_CATName=@STD_ASSET_CATName
												AND AuthorisationStatus IN ('1A','1D')
												AND CreatedBy<>@USERLOGINID
												AND ApprovedByFirstLevel<>@UserLoginID




		END
/*TO AUTHORISE SECONDLEVEL IN MOD TABLE*/
IF (@OperationFlag=20)
		IF (@OperationFlag=20)
			BEGIN
			SET @Result=1


			UPDATE DIM_STD_ASSET_CAT_MOD SET ApprovedBy=@UserLoginID 
												,DateApproved=GETDATE()
												,AuthorisationStatus='A'
					WHERE STD_ASSET_CATName=@STD_ASSET_CATName
							AND AuthorisationStatus IN ('1A')
							AND EffectiveFromTimeKey<=@TIMEKEY
							AND EffectiveToTimeKey>=@TIMEKEY


			UPDATE DIM_STD_ASSET_CAT_MOD SET ApprovedBy=@UserLoginID 
												,DateApproved=GETDATE()
												,EffectiveToTimeKey=EffectiveFromTimeKey-1
												,AuthorisationStatus='D'
					WHERE STD_ASSET_CATName=@STD_ASSET_CATName
							AND AuthorisationStatus IN ('1D')
							AND EffectiveFromTimeKey<=@TIMEKEY
							AND EffectiveToTimeKey>=@TIMEKEY
							AND ModifyBy<>@UserLoginID
							AND ApprovedByFirstLevel<>@UserLoginID


		/*INSERT INTO MAIN TABLE WHERE AuthorisationStatus='A'*/
					IF @STD_ASSET_CATName NOT IN (SELECT STD_ASSET_CATName FROM DIM_STD_ASSET_CAT WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
							BEGIN
									INSERT INTO DIM_STD_ASSET_CAT(
																	STD_ASSET_CAT_Key
																	,STD_ASSET_CATAlt_key
																	,STD_ASSET_CATName
																	,STD_ASSET_CATShortName
																	,STD_ASSET_CATShortNameEnum
																	,STD_ASSET_CAT_Prov
																	,STD_ASSET_CAT_Prov_Unsecured
																	,STD_ASSET_CATValidCode
																	,EffectiveFromTimeKey
																	,EffectiveToTimeKey
																	,CREATEDBY
																	,DateCreated
																	,ApprovedBy
																	,DateApproved
																	,AuthorisationStatus
																)SELECT 
																	STD_ASSET_CAT_Key
																	,STD_ASSET_CAT_Key
																	,STD_ASSET_CATName
																	,STD_ASSET_CATName
																	,STD_ASSET_CATName
																	,STD_ASSET_CAT_Prov
																	,STD_ASSET_CAT_Prov_Unsecured
																	,STD_ASSET_CATValidCode
																	,EffectiveFromTimeKey
																	,EffectiveToTimeKey
																	,CREATEDBY
																	,DateCreated
																	,ApprovedBy
																	,DateApproved
																	,AuthorisationStatus																					
																	FROM DIM_STD_ASSET_CAT_MOD
																	WHERE AuthorisationStatus='A'
																	AND STD_ASSET_CATName=@STD_ASSET_CATName
																		
							END
		

				/*UPDATE MAIN TABLE WHERE AuthorisationStatus='MP'*/

					ELSE IF @STD_ASSET_CATName IN (SELECT STD_ASSET_CATName FROM DIM_STD_ASSET_CAT WHERE  EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
							BEGIN
								
							UPDATE DIM_STD_ASSET_CAT SET STD_ASSET_CAT_Prov=@STD_ASSET_PER_1
														,STD_ASSET_CAT_Prov_Unsecured=@STD_ASSET_PER_1
														,ApprovedBy=@UserLoginID 
										 				,DateApproved=GETDATE()											
										from DIM_STD_ASSET_CAT  										
										WHERE  STD_ASSET_CATName=@STD_ASSET_CATName
												AND AuthorisationStatus IN ('A')												
												AND EffectiveFromTimeKey<=@TIMEKEY
												AND EffectiveToTimeKey>=@TIMEKEY


							UPDATE A SET		   A.ApprovedBy=@UserLoginID 
										 							,A.DateApproved=GETDATE()
																	,A.EffectiveToTimeKey=@TIMEKEY - 1
																	,A.AuthorisationStatus='D'
									from DIM_STD_ASSET_CAT A Inner join DIM_STD_ASSET_CAT_MOD B
										on A.STD_ASSET_CATName=B.STD_ASSET_CATName
										WHERE  A.STD_ASSET_CATName=@STD_ASSET_CATName
												AND B.AuthorisationStatus IN ('D')
												AND A.EffectiveFromTimeKey<=@TIMEKEY
												AND A.EffectiveToTimeKey>=@TIMEKEY

																	
							END

			END
/*TO REJECT IN MOD TABLE*/
IF (@OperationFlag=21)
	BEGIN

	SET @Result=1
	UPDATE DIM_STD_ASSET_CAT_MOD SET ApprovedBy=@UserLoginID 
												,DateApproved=GETDATE()
												,AuthorisationStatus='R'
												,EffectiveToTimeKey = @TIMEKEY - 1
					WHERE STD_ASSET_CATName=@STD_ASSET_CATName 
							AND AuthorisationStatus IN ('1A')
							AND CreatedBy<>@USERLOGINID

	UPDATE DIM_STD_ASSET_CAT SET AuthorisationStatus='A'
					WHERE STD_ASSET_CATName=@STD_ASSET_CATName
						AND AuthorisationStatus IN ('MP')
						AND EffectiveFromTimeKey<=@TIMEKEY
						AND EffectiveToTimeKey>=@TIMEKEY
	

	RETURN @Result 			
	END
END		






GO