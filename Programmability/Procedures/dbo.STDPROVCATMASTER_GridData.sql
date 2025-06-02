SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[STDPROVCATMASTER_GridData] --27056,'SHUBHAM','2'
	 @Timekey INT,
	 @UserLoginId VARCHAR(100),
	 @OPERATIONFLAG VARCHAR(3)
AS


BEGIN
		SET NOCOUNT ON;

		SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 

  
    PRINT @Timekey 

		
	IF @OPERATIONFLAG=2
		BEGIN 
			select * from
			(SELECT STD_ASSET_CATName,STD_ASSET_CATShortNameEnum,A.STD_ASSET_CAT_Prov*100 STD_ASSET_CAT_Prov,A.CreatedBy [CrModBy],A.ModifyBy [ModAppBy], NULL AS [FirstLevelApprovedBy]
			,ISNULL(AuthorisationStatus,'A')AS AuthorisationStatus
			 from DIM_STD_ASSET_CAT A WHERE ISNULL(AuthorisationStatus,'A')='A' AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
			 UNION
			 SELECT STD_ASSET_CATName,STD_ASSET_CATShortNameEnum,A.STD_ASSET_CAT_Prov*100 as STD_ASSET_CAT_Prov,A.CreatedBy [CrModBy],A.ModifyBy [ModAppBy], A.ApprovedByFirstLevel [FirstLevelApprovedBy]
			,ISNULL(AuthorisationStatus,'A')AS AuthorisationStatus
			 from DIM_STD_ASSET_CAT_MOD A WHERE ISNULL(AuthorisationStatus,'A')IN ('NP','MP','DP','1A','1D'))A
			 order by STD_ASSET_CATName
		 
		
		END 


	 else IF @OPERATIONFLAG=16
		BEGIN
		 SELECT STD_ASSET_CATName,STD_ASSET_CATShortNameEnum,A.STD_ASSET_CAT_Prov*100 as STD_ASSET_CAT_Prov,A.CreatedBy [CrModBy],A.ModifyBy [ModAppBy], A.ApprovedByFirstLevel [FirstLevelApprovedBy],AuthorisationStatus from DIM_STD_ASSET_CAT_MOD A		
		 where AuthorisationStatus IN ('NP','MP','DP' )
		  AND (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
				--AND 
				
		
		END 

	ELSE IF @OPERATIONFLAG=20
		BEGIN
		 SELECT STD_ASSET_CATName,STD_ASSET_CATShortNameEnum,A.STD_ASSET_CAT_Prov*100 as STD_ASSET_CAT_Prov,A.CreatedBy [CrModBy],A.ModifyBy [ModAppBy], A.ApprovedByFirstLevel [FirstLevelApprovedBy],AuthorisationStatus from DIM_STD_ASSET_CAT_MOD A		
		 where (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
				AND AuthorisationStatus IN ('1A','1D')
		
		END 


END
GO