SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DimSourceSystemMail_INUP] ---'IBL149917',26852,1,'Finacle','vinit.barve@indusind.com','Y',-1
@USERLOGINID VARCHAR(250),
@TIMEKEY INT,
@OPERATIONFLAG INT,
@SourceName VARCHAR(100),
@SourceSystemMailID VARCHAR(250),
@SourceSystemMailValidCode VARCHAR(3),
@Result1 INT OUTPUT
AS
BEGIN
DECLARE @EMAILIN_DimSourceSystemMail_MOD INT

IF @SourceName = 'Gan Seva' 
BEGIN
SET @SourceName='Ganaseva'
END

/*ADDED BY ZAIN ON 20250512 FOR HANDLING FINACLE-3 IN PROFILER AND PROLEDNZ IN BACK-END*/
IF @SourceName = 'Finacle-3' and @OPERATIONFLAG in (1,2,3,16,17,20,21)
BEGIN
SET @SourceName='Prolendz'
END
/*ADDED BY ZAIN ON 20250512 FOR HANDLING FINACLE-3 IN PROFILER AND PROLEDNZ IN BACK-END END*/

DECLARE @SOURCEALT_KEY INT = (SELECT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName)


/*ADDED BY MOHIT*/

	SET @EMAILIN_DimSourceSystemMail_MOD=(SELECT COUNT(1) FROM DimSourceSystemMail_MOD 
														WHERE SourceSystemMailID=@SourceSystemMailID 
														AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
														AND SourceSystemMailValidCode='Y'
														AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)--ADDED TO HANDLE 

IF @OPERATIONFLAG=1 and @EMAILIN_DimSourceSystemMail_MOD>0 
BEGIN
	SET @Result1=-6
	RAISERROR (N'This Email ID is already Available %s ', -- Message text.
           10, -- Severity,
           1, -- State,
           @SourceSystemMailID); -- Second argument.

END
		/*INSERTING NEW MAILID*/
		IF @OPERATIONFLAG=1 AND @EMAILIN_DimSourceSystemMail_MOD=0
		BEGIN
		SET @Result1=1
		Declare @SourceSystemMail_Key int 

		IF(select count(1) from DimSourceSystemMail_MOD)  = 0
			Begin 
				Set @SourceSystemMail_Key=1
				Print @SourceSystemMail_Key
			END
		else if (SELECT MAX(isnull(@SourceSystemMail_Key,0) )+1  FROM DimSourceSystemMail_MOD )>0
			Begin
				Set  @SourceSystemMail_Key=(SELECT MAX(isnull(SourceSystemMail_Key,0) )+1  FROM DimSourceSystemMail_MOD )
			END
				INSERT INTO DimSourceSystemMail_MOD 
					(SourceSystemMail_Key
					,SourceAlt_Key
					,SourceSystemMailID 
					,SourceSystemMailValidCode 
					,CreatedBy 
					,DATECREATED 
					,AUTHORISATIONSTATUS 
					,EffectiveFromTimeKey
					,EffectiveToTimeKey
					,D2Ktimestamp
					)
					SELECT 
						(@SourceSystemMail_Key )
						,(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
						,@SourceSystemMailID 
						,@SourceSystemMailValidCode
						,@USERLOGINID
						,(SELECT convert(varchar, getdate(), 121))
						,'NP'
						,@TIMEKEY
						,49999
						,(SELECT convert(varchar, getdate(), 121))
		
		END		
		/*EXPIRING OLD EMAIL ID IN SOURCE SYSTEM NAME*/
		ELSE IF @OPERATIONFLAG=2
						
					BEGIN
					/* FOR MOD TABLE*/

					SET @Result1=1
					/*ADDED BY ZAIN ON 20250512 ON LOCAL */
					INSERT INTO DimSourceSystemMail_MOD(
							SourceSystemMail_Key,
							SourceAlt_Key	,
							SourceSystemMailID	,
							SourceSystemMailGroup	,
							SourceSystemMailSubGroup	,
							SourceSystemMailSegment	,
							SourceSystemMailValidCode	,
							AuthorisationStatus	,
							EffectiveFromTimeKey	,
							EffectiveToTimeKey	,
							CreatedBy	,
							DateCreated	,
							ModifiedBy	,
							DateModified	,
							ApprovedBy	,
							DateApproved	,
							D2Ktimestamp	,
							ApprovedByFirstLevel	,
							DateApprovedFirstLevel)
					SELECT (SELECT MAX(isnull(SourceSystemMail_Key,0) )+1  FROM DimSourceSystemMail_MOD ),
							SourceAlt_Key	,
							SourceSystemMailID	,
							SourceSystemMailGroup	,
							SourceSystemMailSubGroup	,
							SourceSystemMailSegment	,
							@SourceSystemMailValidCode, ---'N'	, ---- Changed by Liyaqat on 20250514 after discussion with Vrishali
							'MP'	,
							@TIMEKEY	,
							EffectiveToTimeKey	,
							CreatedBy	,
							DateCreated	,
							@USERLOGINID	,
							(SELECT convert(varchar, getdate(), 121))	,
							NULL	,
							NULL	,
							D2Ktimestamp	,
							NULL	,
							NULL	
						FROM DimSourceSystemMail 
							WHERE SourceSystemMailID=@SourceSystemMailID
								AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
								AND SourceAlt_Key=@SourceAlt_Key
						/*ADDED BY ZAIN ON 20250512 ON LOCAL END*/

						/*COMMENTED BY ZAIN ON 20250512 ON LOCAL */
								--UPDATE DimSourceSystemMail_MOD SET SourceSystemMailValidCode=@SourceSystemMailValidCode,--CHANGED BY ZAIN ON LOCAL & UAT FROM "N" TO PARAMETERIZED VALUE ON 20250425
								--									ModifiedBy=@USERLOGINID,
								--									DateModified=(SELECT convert(varchar, getdate(), 121))
								--	WHERE SourceSystemMailID=@SourceSystemMailID
								--	AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										--AND SourceSystemMailValidCode='Y'--CHANGED BY ZAIN ON LOCAL & UAT ON 20250425
						

					/* FOR MAIN TABLE*/
							--	UPDATE DimSourceSystemMail SET SourceSystemMailValidCode='N',
							--										ModifiedBy=@USERLOGINID,
							--										DateModified=(SELECT convert(varchar, getdate(), 121))
							--		WHERE SourceSystemMailID=@SourceSystemMailID
							--		AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
							--		AND SourceSystemMailValidCode='Y'
					/*COMMENTED BY ZAIN ON 20250512 ON LOCAL END*/
					END
		
		/*SETTING AUTHORISATION STATUS D FOR DELETED RECORDS*/
		ELSE IF @OPERATIONFLAG=3
							
					BEGIN
				
					SET @Result1=1	
					/* FOR MOD TABLE*/
					INSERT INTO DimSourceSystemMail_MOD(
							SourceSystemMail_Key,
							SourceAlt_Key	,
							SourceSystemMailID	,
							SourceSystemMailGroup	,
							SourceSystemMailSubGroup	,
							SourceSystemMailSegment	,
							SourceSystemMailValidCode	,
							AuthorisationStatus	,
							EffectiveFromTimeKey	,
							EffectiveToTimeKey	,
							CreatedBy	,
							DateCreated	,
							ModifiedBy	,
							DateModified	,
							ApprovedBy	,
							DateApproved	,
							D2Ktimestamp	,
							ApprovedByFirstLevel	,
							DateApprovedFirstLevel)
					SELECT (SELECT MAX(isnull(SourceSystemMail_Key,0) )+1  FROM DimSourceSystemMail_MOD ),
							SourceAlt_Key	,
							SourceSystemMailID	,
							SourceSystemMailGroup	,
							SourceSystemMailSubGroup	,
							SourceSystemMailSegment	,
							'D'	,
							'DP',  ----'MP'	, Changed by Liyaqat on 20250514 after discussion with Vrishali
							@TIMEKEY	,
							EffectiveToTimeKey	,
							CreatedBy	,
							DateCreated	,
							@USERLOGINID	,
							(SELECT convert(varchar, getdate(), 121)), 
							NULL	,
							NULL	,
							D2Ktimestamp	,
							NULL	,
							NULL	
						FROM DimSourceSystemMail 
							WHERE SourceSystemMailID=@SourceSystemMailID
								AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY
								AND SourceAlt_Key=@SourceAlt_Key--ADDED FOR DELETE FUNCTIONALITY OBSERVATION RAISED BY VRISHALI ON LOCAL BY ZAIN ON 20250509

								--UPDATE DimSourceSystemMail_MOD SET SourceSystemMailValidCode='D',
								--									ModifiedBy=@USERLOGINID,
								--									DateModified=(SELECT convert(varchar, getdate(), 121)),
								--									AuthorisationStatus='MP'
								--	WHERE 
								--		SourceSystemMailID=@SourceSystemMailID 
								--		AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
								--		AND EffectiveFromTimeKey<=@TIMEKEY
								--		AND EffectiveToTimeKey>=@TIMEKEY
								--		--AND CreatedBy<>@USERLOGINID
					END
		/*UPDATING AUTHORISATION STATUS 1A*/
		ELSE IF @OPERATIONFLAG=16
								
					BEGIN
						PRINT '16'
						SET @Result1=1	
								UPDATE DimSourceSystemMail_MOD SET AUTHORISATIONSTATUS='1A',
																	ApprovedByFirstLevel=@USERLOGINID,
																	DateApprovedFirstLevel=(SELECT convert(varchar, getdate(), 121))
									WHERE AuthorisationStatus IN ('NP','MP','DP')
										AND SourceSystemMailID=@SourceSystemMailID 
										AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										--AND SourceSystemMailValidCode='Y' COMMENTED FOR INACTIVE AND DELETE RECORDS HAVING 'D,N' STATUS ON 20250422 BY ZAIN
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										--AND CreatedBy<>@USERLOGINID
					END

		/*UPDATING AUTHORISATION STATUS R*/
		ELSE IF @OPERATIONFLAG=17
				
					BEGIN
					PRINT '17'
						SET @Result1=1	
								UPDATE DimSourceSystemMail_MOD SET AUTHORISATIONSTATUS='R',
																	ApprovedByFirstLevel=@USERLOGINID,
																	DateApprovedFirstLevel=(SELECT convert(varchar, getdate(), 121)),
																	EffectiveToTimeKey=@TIMEKEY-1
									WHERE AuthorisationStatus IN ('NP','MP','DP')
									AND SourceSystemMailID=@SourceSystemMailID 
									AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										--AND SourceSystemMailValidCode='Y' COMMENTED FOR INACTIVE AND DELETE RECORDS HAVING 'D,N' STATUS ON 20250422 BY ZAIN
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										--AND CreatedBy<>@USERLOGINID
					END
		/*UPDATING AUTHORISATION STATUS A*/
		ELSE IF @OPERATIONFLAG=20
			
				BEGIN
					PRINT '20'
						SET @Result1=1	


								UPDATE DimSourceSystemMail_MOD SET AUTHORISATIONSTATUS='A',
																	ApprovedBy=@USERLOGINID,
																	DateApproved=(SELECT convert(varchar, getdate(), 121))
									WHERE AuthorisationStatus='1A'
									AND SourceSystemMailID=@SourceSystemMailID 
									AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										--AND SourceSystemMailValidCode='Y' COMMENTED FOR INACTIVE AND DELETE RECORDS HAVING 'D,N' STATUS ON 20250422 BY ZAIN
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										--AND CreatedBy<>@USERLOGINID
										--AND ApprovedByFirstLevel<>@USERLOGINID
					
						/*DELETE FOR MAIN TABLE ON 20250422 BY ZAIN*/
								--DELETE 
								--DELETE FROM DimSourceSystemMail WHERE SourceSystemMailID =@SourceSystemMailID AND SourceSystemMailValidCode='D'
						/*DELETE FOR MAIN TABLE ON 20250422 BY ZAIN END*/
				
							UPDATE A SET EffectiveToTimeKey=@TIMEKEY-1     ---- Update added by Liyaqat to expire Delete record on 20250514
								FROM DimSourceSystemMail A LEFT JOIN DimSourceSystemMail_MOD B ON
								A.SourceSystemMailID=B.SourceSystemMailID AND A.SourceAlt_Key=B.SourceAlt_Key
									AND  (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
									AND  (B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY)
									WHERE B.SourceSystemMailID =@SourceSystemMailID 
									AND B.SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE 
															SourceName=@SourceName AND EffectiveFromTimeKey<=@TIMEKEY AND  EffectiveToTimeKey>=@TIMEKEY) 
											AND (B.SourceSystemMailValidCode='D' OR 
																	ISNULL(A.SourceSystemMailValidCode,'Y')<>ISNULL(B.SourceSystemMailValidCode,'Y'))
											AND B.AUTHORISATIONSTATUS='A' 

				/*INSERT NEW MAIL ID IN MAIN*/
		IF @SourceSystemMailID NOT IN (SELECT SourceSystemMailID FROM DimSourceSystemMail WHERE SourceSystemMailValidCode='Y'
										AND SourceAlt_Key=@SOURCEALT_KEY--ADDED BY ZAIN ON 20250507 DUE TO THE OBSERVATION OF SAME MAIL ID IN MULTIPLE SOURCESYSTEM SHOULD GET INSERTED
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										) 
			AND @SourceSystemMailID<>'D'
			BEGIN

			/*ADDED BY ZAIN O 20250512 FOR HANDLING DUPLICATE LIVE RECORDS IN MAIN TABLE*/
				UPDATE DimSourceSystemMail SET EffectiveToTimeKey=@TIMEKEY-1
												,ModifiedBy=@USERLOGINID
												,DateModified=(SELECT convert(varchar, getdate(), 121))
				WHERE isnull(AuthorisationStatus,'A')='A'
										AND SourceSystemMailID=@SourceSystemMailID 
										AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										AND SourceSystemMailValidCode in ('Y','N')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
			/*ADDED BY ZAIN O 20250512 FOR HANDLING DUPLICATE LIVE RECORDS IN MAIN TABLE END*/

					INSERT INTO DimSourceSystemMail(
											SourceSystemMail_Key	,
											SourceAlt_Key	,
											SourceSystemMailID	,
											SourceSystemMailGroup	,
											SourceSystemMailSubGroup	,
											SourceSystemMailSegment	,
											SourceSystemMailValidCode	,
											AuthorisationStatus	,
											EffectiveFromTimeKey	,
											EffectiveToTimeKey	,
											CreatedBy	,
											DateCreated	,
											ModifiedBy	,
											DateModified	,
											ApprovedBy	,
											DateApproved	,
											D2Ktimestamp	,
											ApprovedByFirstLevel	,
											DateApprovedFirstLevel	
										)
								SELECT
											SourceSystemMail_Key	,
											SourceAlt_Key	,
											SourceSystemMailID	,
											SourceSystemMailGroup	,
											SourceSystemMailSubGroup	,
											SourceSystemMailSegment	,
											SourceSystemMailValidCode	,
											AuthorisationStatus	,
											EffectiveFromTimeKey	,
											EffectiveToTimeKey	,
											CreatedBy	,
											DateCreated	,
											ModifiedBy	,
											DateModified	,
											ApprovedBy	,
											DateApproved	,
											D2Ktimestamp	,
											ApprovedByFirstLevel	,
											DateApprovedFirstLevel	
								FROM DimSourceSystemMail_MOD
								WHERE isnull(AuthorisationStatus,'A')='A'
										AND SourceSystemMailID=@SourceSystemMailID 
										AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										AND SourceSystemMailValidCode in ('Y','N')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND CreatedBy<>@USERLOGINID
										AND ApprovedByFirstLevel<>@USERLOGINID

				/****Delete record Insert Liyaqat 20250514****/
					INSERT INTO DimSourceSystemMail(
											SourceSystemMail_Key	,
											SourceAlt_Key	,
											SourceSystemMailID	,
											SourceSystemMailGroup	,
											SourceSystemMailSubGroup	,
											SourceSystemMailSegment	,
											SourceSystemMailValidCode	,
											AuthorisationStatus	,
											EffectiveFromTimeKey	,
											EffectiveToTimeKey	,
											CreatedBy	,
											DateCreated	,
											ModifiedBy	,
											DateModified	,
											ApprovedBy	,
											DateApproved	,
											D2Ktimestamp	,
											ApprovedByFirstLevel	,
											DateApprovedFirstLevel	
										)
								SELECT
											SourceSystemMail_Key	,
											SourceAlt_Key	,
											SourceSystemMailID	,
											SourceSystemMailGroup	,
											SourceSystemMailSubGroup	,
											SourceSystemMailSegment	,
											SourceSystemMailValidCode	,
											AuthorisationStatus	,
											EffectiveFromTimeKey	,
											(@Timekey-1)	,
											CreatedBy	,
											DateCreated	,
											ModifiedBy	,
											DateModified	,
											ApprovedBy	,
											DateApproved	,
											D2Ktimestamp	,
											ApprovedByFirstLevel	,
											DateApprovedFirstLevel	
								FROM DimSourceSystemMail_MOD
								WHERE isnull(AuthorisationStatus,'A')='A'
										AND SourceSystemMailID=@SourceSystemMailID 
										AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										AND SourceSystemMailValidCode in ('D')
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										AND CreatedBy<>@USERLOGINID
										AND ApprovedByFirstLevel<>@USERLOGINID

				/****Delete record Insert end Liyaqat 20250514****/


					/*EXPIRE IN MOD ON 20250422 BY ZAIN*/

					UPDATE DimSourceSystemMail_MOD SET EffectiveToTimeKey=@TIMEKEY-1
									WHERE AuthorisationStatus='A'
									AND SourceSystemMailID=@SourceSystemMailID 
									AND SourceAlt_Key=@SOURCEALT_KEY--COMMENTED BY ZAIN ON 20250507 AS HANDLED WITH PARAMETER(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										--AND SourceSystemMailValidCode='D'-- FOR DELETE RECORDS HAVING 'D' STATUS ON 20250422 BY ZAIN
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										--AND CreatedBy<>@USERLOGINID
										--AND ApprovedByFirstLevel<>@USERLOGINID

					/*EXPIRE IN MOD ON 20250422 BY ZAIN END*/
			END
		

					/*UPDATE IN MAIN*/ ---- commented by Liyaqat for SourceSystemMailValidCode correction on 20250514 as discussed with Vrishali
				--IF @SourceSystemMailID IN (SELECT SourceSystemMailID FROM DimSourceSystemMail WHERE 
				--						EffectiveFromTimeKey<=@TIMEKEY
				--						AND EffectiveToTimeKey>=@TIMEKEY
				--						)
				--		AND @SourceSystemMailID<>'D'
				--		BEGIN
				--		UPDATE DimSourceSystemMail SET SourceSystemMailValidCode=@SourceSystemMailValidCode 
				--										ModifiedBy=@USERLOGINID,
				--										DateModified=(SELECT convert(varchar, getdate(), 121))  
				--				WHERE SourceSystemMailID=@SourceSystemMailID
				--				AND isnull(SourceSystemMailValidCode,'N')<>'D'
				--				AND SourceAlt_Key=@SOURCEALT_KEY--COMMENTED BY ZAIN ON 20250507 AS HANDLED WITH PARAMETER(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
				--					AND	EffectiveFromTimeKey<=@TIMEKEY
				--						AND EffectiveToTimeKey>=@TIMEKEY		
						--END
			END
		/*UPDATING AUTHORISATION STATUS R*/
		ELSE IF @OPERATIONFLAG=21
			
					BEGIN
						SET @Result1=1	
								UPDATE DimSourceSystemMail_MOD SET AUTHORISATIONSTATUS='R',
																	ApprovedBy=@USERLOGINID,
																	DateApproved=(SELECT convert(varchar, getdate(), 121)),
																	EffectiveToTimeKey=@TIMEKEY-1
									WHERE AuthorisationStatus='1A'
									AND SourceSystemMailID=@SourceSystemMailID 
									AND SourceAlt_Key=(SELECT DISTINCT SourceAlt_Key FROM DIMSOURCESYSTEM WHERE SourceName=@SourceName )
										--AND SourceSystemMailValidCode='Y' COMMENTED FOR INACTIVE AND DELETE RECORDS HAVING 'D,N' STATUS ON 20250422 BY ZAIN
										AND EffectiveFromTimeKey<=@TIMEKEY
										AND EffectiveToTimeKey>=@TIMEKEY
										--AND CreatedBy<>@USERLOGINID
										--AND ApprovedByFirstLevel<>@USERLOGINID
					END
		
	RETURN @Result1 		
END


GO