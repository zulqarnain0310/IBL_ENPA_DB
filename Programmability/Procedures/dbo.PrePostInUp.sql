SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[PrePostInUp]

@MonthEndDate	VARCHAR(10)
,@PrePostFreeze CHAR(1)='P'
,@UserID varchar(10)
,@TimeKey	INT=0
,@Result     SMALLINT=1   OUTPUT

AS

----P for freeze PreProcessing Flag

DECLARE
 @MonthLastDate DATE=(SELECT CONVERT(DATE,@MonthEndDate,103))
,@Date    DATE=(SELECT CONVERT(DATE,GETDATE()))

--SELECT @MonthEndDate_Org,@Date


BEGIN TRY
	BEGIN TRANSACTION


IF @PrePostFreeze='P'    
	BEGIN

				IF NOT EXISTS (SELECT  1 FROM SysDatamatrix WHERE MonthLastDate=@MonthLastDate AND PreProcessingFreeze='Y')
		
					 BEGIN
					 					 		
						UPDATE SysDatamatrix
						SET  PreProcessingFreeze='Y'
							,PreProcessingFreezeDate=@Date
							,PreProcessingFreezeBy=@UserID
						WHERE ExtDate=@MonthLastDate	

						/* CALL  NICF_LevelAssetCLassInUp SP */

						EXEC [dbo].[NCIF_LevelAssetCLassScreenInUp]
						@TIMEKEY=@TimeKey

					END	
					
				ELSE
						BEGIN
								SET @Result=-2
						END				
	END
ELSE
	  BEGIN
				IF EXISTS(SELECT 1 FROM SysDatamatrix WHERE ExtDate=@MonthLastDate AND PreProcessingFreeze='Y')
					BEGIN

							IF NOT EXISTS (SELECT 1 FROM SysDataMatrix WHERE ExtDate=@MonthLastDate AND MOC_Freeze='Y' )
								BEGIN
										 PRINT 'MOC'

										UPDATE SysDatamatrix
										SET  MOC_Freeze='Y'
											,MOC_FreezeDate=@Date
											,MOC_FreezeBy=@UserID
										WHERE ExtDate=@MonthLastDate	

										-----CALL PNPA PROCESS SP
										--EXEC PNPA_ProcessingInUp    --as per mail documented by shishir sir
										--@TimeKey=@TimeKey


										----UPDATE MOC ASSET CLASS AND NPA DATE IN CASA TABLE

										UPDATE A
										SET    A.MOC_AssetClassAlt_Key=B.MOC_AssetClassAlt_Key
											  ,A.MOC_NPA_Date=B.MOC_NPA_Date
											  ,A.MOC_Status=B.MOC_Status
											  ,A.MOC_Date=B.MOC_Date
											  ,A.MOC_ReasonAlt_Key=B.MOC_ReasonAlt_Key
										FROM CASA_NPA_IntegrationDetails A
										INNER JOIN NPA_IntegrationDetails B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																				 AND (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
																				 AND ISNULL(A.AuthorisationStatus,'A')='A'
																				 AND B.MOC_Status='Y'
																				 AND A.NCIF_Id=B.NCIF_Id

									 --  UPDATE SysDatamatrix
										--SET  CurrentStatus='U'	
										--WHERE CurrentStatus='C'	

										

										--update SysDataMatrix set CurrentStatus='C'   where   MonthFirstDate=DATEADD(MONTH, DATEDIFF(MONTH, '19000201', GETDATE()), '19000101')

									--	SELECT * FROM SysDatamatrix WHERE TimeKey>=24868 --CurrentStatus='c'
										PRINT 'Update'											



								END	
								
							ELSE
								  BEGIN
											SET @Result=-3
								  END									
					END

				ELSE
						BEGIN
								SET @Result=-4
						END		
	  
					
	  
	  END

COMMIT TRANSACTION

		--SELECT @MonthLastDate
		SET @Result=1
		RETURN @Result 

END TRY	 
BEGIN CATCH
		ROLLBACK TRAN

			 INSERT INTO ErrorLog (ErrorNumber,ErrorMsg,ErrorProc,ErrorCrDt)
				SELECT ERROR_NUMBER() [ERROR_NUMBER] ,ERROR_MESSAGE()[ERROR_MESSAGE],ERROR_PROCEDURE()[ERROR_PROCEDURE],GETDATE()[ErrorDt]	

					SELECT * FROM ErrorLog  WHERE ErrorCrDt=
					(
						SELECT MAX(ErrorCrDt)ErrorCrDt FROM ErrorLog  WHERE ErrorNumber=(SELECT ERROR_NUMBER())

					)

		SELECT ERROR_MESSAGE()
		SET @Result=-1
		RETURN @Result 

END CATCH
GO