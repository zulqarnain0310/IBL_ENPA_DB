SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SP_MOCProcessing_16112021]
		@UserLoginId VARCHAR(20),
		@TimeKey Int, 
		@IS_MOC CHAR(1)='Y',
		@Result		INT=0 OUTPUT
AS
BEGIN
	BEGIN TRY
	DECLARE @STD INT=(SELECT AssetClassAlt_Key FROm DimAssetClass WHERE AssetClassShortNameEnum='STD' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey )
	     
		 /*STD account provission is getting zero*/
		 UPDATE NPA_IntegrationDetails 
		 SET TotalProvision=0,
		     Provsecured=0,
			 ProvUnsecured=0,
			 AddlProvision=0,
			 AddlProvisionPer=0
		 WHERE EffectiveFromTimeKey<=@TimeKey
		 AND EffectiveToTimeKey>=@TimeKey
		 AND FlgProcessing='Y'
		 AND NCIF_AssetClassAlt_Key=@STD

		  /*If AddlProvisionPer having value then initelizing AddlProvision*/
		 UPDATE NPA_IntegrationDetails 
		 SET AddlProvision=0
		 WHERE EffectiveFromTimeKey<=@TimeKey
		 AND EffectiveToTimeKey>=@TimeKey
		 AND FlgProcessing='Y'
		 AND ISNULL(AddlProvisionPer,0)>0

		 /*updating secured and unsecured amout if user change security amount*/
		 update NPA_IntegrationDetails SET SecurityValue=ApprRV,
		            SecuredAmt=CASE WHEN ISNULL(ApprRV,0)>0
					                     THEN (CASE WHEN ISNULL(ApprRV,0)>ISNULL(PrincipleOutstanding,0) 
					                     THEN ISNULL(PrincipleOutstanding,0) 
								    ELSE ISNULL(ApprRV,0) 
							   END)
							   ELSE 0
							   END,
                    UnSecuredAmt=(CASE WHEN ISNULL(ApprRV,0)>0
					                       THEN (CASE WHEN ISNULL(ApprRV,0)>ISNULL(PrincipleOutstanding,0) 
					                                       THEN 0 
								                      ELSE ISNULL(PrincipleOutstanding,0)-ISNULL(ApprRV,0) 
							                       END)
                                       ELSE PrincipleOutstanding
								  END)	    
         WHERE EffectiveFromTimeKey<=@TimeKey
		 AND EffectiveToTimeKey>=@TimeKey
		 AND FlgProcessing='Y'

		EXEC [dbo].[ProvisionComputation] @TimeKey,@IS_MOC
		update SysDataMatrix 
              set MOC_ProcessStatus	='Y'
                 ,MOC_ProcessingDate=MonthLastDate
				 ,MOC_ProcessBy	= @UserLoginId
                          where TimeKey = @TimeKey
		SET @Result=1
		RETURN @Result
		
	END TRY

	BEGIN CATCH
		IF ERROR_MESSAGE() IS NOT NULL
		SELECT -1
		SET @Result=-1
		RETURN @Result
	END CATCH
END



GO