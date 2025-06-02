SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[EnquiryRejectView]

 @TimeKey			INT
,@SelectLevel	VARCHAR(5) 
,@EnterValue	VARCHAR(20)
,@SearchLevel  VARCHAR(10) 

AS

--DECLARE
-- @TimeKey			INT
--,@SelectLevel	VARCHAR(5) 
--,@EnterValue	VARCHAR(20)

IF @SelectLevel='MOC'   ---MOC DROP DOWN
	BEGIN
	PRINT 'MOC'
							SELECT  
							ab.NCIF_Id AS ENCIF,
							cd.PAN,
							'TblReject' AS TableName
							FROM MOC_NPA_IntegrationDetails_MOD ab
							 INNER JOIN NPA_IntegrationDetails cd 
											on (CD.EffectiveFromTimeKey<=@TimeKey AND cd.EffectiveToTimeKey>=@TimeKey)
											AND (AB.EffectiveFromTimeKey<=@TimeKey AND AB.EffectiveToTimeKey>=@TimeKey)
											AND cd.NCIF_Id=ab.NCIF_Id 
							WHERE AB.NCIF_Id=CASE WHEN @EnterValue<>'' THEN @EnterValue  ELSE ab.NCIF_Id END
							AND AB.AuthorisationStatus='R'
							GROUP BY ab.NCIF_Id,cd.PAN

					END


ELSE     ---	ASSET DROP DOWN
	BEGIN
		SELECT 
									ab.CustomerId   AS ClientID,
									cd.PAN,
								    'TblReject' AS TableName
									 FROM NPA_IntegrationDetails_MOD ab
									 INNER JOIN NPA_IntegrationDetails cd 
												ON (cd.EffectiveFromTimeKey<=@TimeKey AND cd.EffectiveToTimeKey>=@TimeKey)
													AND (ab.EffectiveFromTimeKey<=@TimeKey AND ab.EffectiveToTimeKey>=@TimeKey)
													AND cd.CustomerId=ab.CustomerId 
									WHERE AB.CustomerId=CASE WHEN @EnterValue<>'' THEN @EnterValue ELSE ab.CustomerId END
									AND AB.AuthorisationStatus='R'
									GROUP BY ab.CustomerId,cd.PAN
	END	


		
		
GO