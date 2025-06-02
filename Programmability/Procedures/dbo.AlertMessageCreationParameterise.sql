SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AlertMessageCreationParameterise]
     @TimeKey INT,
	 --@screenFlag varchar(10),
	 @UserId varchar(50)

AS
BEGIN
		print 1

--SET @UserId ='D2kchecker'

			DECLARE @UserLocationCode varchar(10),@UserLocation varchar(10),@TireValue varchar(5)

				SET @TireValue=( SELECT ParameterValue FROM SysSolutionParameter WHERE ParameterName='TierValue')

				set @UserLocationCode=( select UserLocationCode 
				FROM DimUserInfo WHERE UserLoginID = @UserId AND (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)) 
				set  @UserLocation=( select UserLocation 
				FROM DimUserInfo WHERE UserLoginID = @UserId AND (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey))

		print 2
	SELECT  UserLocationAlt_Key as Code,LocationShortName AS [Description] from DimUserLocation 
			WHERE EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
			AND (CASE WHEN  @UserLocation = 'HO' AND LocationShortName IN ('HO','ZO','RO','BO') THEN 1 
					  WHEN  @UserLocation = 'ZO' AND LocationShortName IN ('ZO','RO','BO') THEN 1 
					  WHEN  @UserLocation = 'RO' AND LocationShortName IN ('RO','BO') THEN 1 
					  WHEN  @UserLocation = 'BO' AND LocationShortName IN ('BO') THEN 1 END ) =1


		print 3
		--select @UserLocationCode
		--select @UserLocation
	SELECT BranchCode AS Code,BranchName AS [Description] FROM DimBranch  WHERE (EffectiveFromTimeKey<=@TimeKey and 
        EffectiveToTimeKey>=@TimeKey) AND 
		 (CASE WHEN  @UserLocation = 'HO' AND BranchCode <>'' THEN 1 
			  WHEN  @UserLocation = 'ZO' AND BranchZoneAlt_Key = @UserLocationCode   THEN 1 
			  WHEN  @UserLocation = 'RO' AND BranchRegionAlt_Key = @UserLocationCode THEN 1 
			  WHEN  @UserLocation = 'BO' AND BranchCode = @UserLocationCode THEN 1 END ) =1


	print 4
	SELECT ZoneAlt_Key AS Code,ZoneName AS [Description] FROM DimZone  
	WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
	AND  (CASE WHEN  @UserLocation = 'HO' AND ZoneAlt_Key <>0 THEN 1 
			  WHEN  @UserLocation = 'ZO' AND ZoneAlt_Key = @UserLocationCode   THEN 1 
			   END ) =1



	SELECT RegionAlt_Key AS Code,RegionName AS [Description] FROM DimRegion  
	WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey AND RegionName  not in ('HEAD OFFICE'))

	AND	 (CASE WHEN  @UserLocation = 'HO' AND RegionAlt_Key <>0 THEN 1 
			  WHEN  @UserLocation = 'ZO' AND ZoneAlt_Key = @UserLocationCode   THEN 1 
			  WHEN  @UserLocation = 'RO' AND RegionAlt_Key = @UserLocationCode THEN 1 
			  END ) =1

END



GO