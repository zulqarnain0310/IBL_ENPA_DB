SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[MetaAssetClassBind]
	@MenuID INT,
	@UserID	VARCHAR(10),
	@TimeKey INT

AS
BEGIN
--------------For Asset Class Change At Client ID Level Tab------------
SELECT [ScreenName]
      ,[CtrlName]
      ,[ResourceKey]
      ,[FldDataType]
      ,[Col_lg]
      ,[Col_md]
      ,[Col_sm]
      ,[MinLength]
      ,[MaxLength]
      ,[ErrorCheck]
      ,[DataSeq]
      ,[FldGridView]
      ,[CriticalErrorType]
      ,[ScreenFieldNo]
      ,[IsEditable]
      ,[IsVisible]
      ,[IsUpper]
      ,[IsMandatory]
      ,[AllowChar]
      ,[DisAllowChar]
      ,[DefaultValue]
      ,[AllowToolTip]
      ,[ReferenceColumnName]
      ,[ReferenceTableName]
      ,[MOC_Flag]
	  ,[HigherLevelEdit]
	  ,CASE WHEN [IsEditable] = 'E' THEN 'false' else 'true' end AS IsDisabled
	  ,'TblMeta' AS TableName 
	   FROM [dbo].[MetaScreenFieldDetail] WHERE MenuId = @MenuID order by DataSeq

SELECT [SourceAlt_Key],[SourceName] AS [Description] ,'TblSource' AS TableName FROM DimSourceSystem WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey and [SourceAlt_Key]not in(30,40,50) Order By [SourceAlt_Key] 

SELECT [AssetClassAlt_Key],[AssetClassName] AS [Description],'TblAssetClass' AS TableName FROM DimAssetClass WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey Order By [AssetClassAlt_Key] 

SELECT [MocReasonAlt_Key],[MocReasonName] AS [Description],'TblMOCReason' AS TableName  FROM [dbo].[DimMocReason] WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey Order By [MocReasonAlt_Key] 

SELECT ISNULL(PreProcessingFreeze,'N') AS IsPreProcessingFreeze,ISNULL(MOC_Freeze,'N') AS IsPostProcessingFreeze,'TblProcessing' 
AS TableName FROM 
SysDataMatrix  WHERE CurrentStatus = 'C'
END



GO