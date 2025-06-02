SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AlertMessageCreationAux]
     @TimeKey INT,
	 @screenFlag varchar(10),
	 @UserId varchar(50)

AS
BEGIN

	DECLARE @UserLocation VARCHAR(5),@UserLocationCode VARCHAR(5)
	
	SELECT @UserLocation=UserLocation, @UserLocationCode=UserLocationCode FROM DimUserInfo 
	WHERE UserLoginID = @UserId AND (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)


	SELECT [Active]
	  ,Cast(convert(date,DateCreated,103) as varchar(10)) as DateCreated
	  ,[MessageDesc]
      ,CAST([FromDate] AS varchar(10)) AS [FromDate]
      ,CAST([ToDate] AS varchar(10)) AS [ToDate]
	  ,[Location]
	  ,[AlertMessageAlt_key]
	  ,[MessageFor]
	FROM [dbo].[DimAlertMessage] 
	WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
	--AND (CASE WHEN @UserLocation = 'HO' AND UserLocationAlt_Key<> -1	THEN 1
	--		  WHEN @UserLocation = 'RO' AND UserLocationAlt_Key = @UserLocationCode	THEN 1 ) =1



	--	select BranchCode AS Code,BranchName AS [Description] from DimBranch  where EffectiveFromTimeKey<=@TimeKey and 
	--       EffectiveToTimeKey>=@TimeKey
	--	select ZoneAlt_Key AS Code,ZoneName AS [Description] from DimZone  where EffectiveFromTimeKey<=@TimeKey and 
	--       EffectiveToTimeKey>=@TimeKey
	--	select RegionAlt_Key AS Code,RegionName AS [Description] from DimRegion  where EffectiveFromTimeKey<=@TimeKey and 
	--       EffectiveToTimeKey>=@TimeKey
	--	select  UserLocationAlt_Key as Code,LocationShortName AS [Description] from DimUserLocation where EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey

END
GO