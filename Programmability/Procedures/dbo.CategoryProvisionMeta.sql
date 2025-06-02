SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE proc [dbo].[CategoryProvisionMeta] --26922,'dm749'
@Timekey int,
@UserLoginId varchar(50)
as
BEGIN

SELECT * FROM 

		(Select 'CategoryMeta' AS TableName,
		STD_ASSET_CAT_Key,
		STD_ASSET_CATAlt_key as STDAsssetCode,
		STD_ASSET_CATShortNameEnum as STDAssetShortName
		from DIM_STD_ASSET_CAT_MOD	
		where EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey

	

		UNION

		Select 'CategoryMeta' AS TableName,
		STD_ASSET_CAT_Key,
		STD_ASSET_CATAlt_key as STDAsssetCode,
		STD_ASSET_CATShortNameEnum as STDAssetShortName
		from DIM_STD_ASSET_CAT
		where EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		
		)A
	 ORDER BY STD_ASSET_CAT_Key
END

--select * from DIM_STD_ASSET_CAT_MOD_Search
GO