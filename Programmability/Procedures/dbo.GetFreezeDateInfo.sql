SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GetFreezeDateInfo]
	@FreezeDate VARCHAR(10)
   ,@UserID varchar(10)
   ,@TimeKey	INT=0

AS 
DECLARE
@ExtDate DATE=(SELECT CONVERT(DATE,@FreezeDate,103)),@MOCAuthPending BIT,@MOCAuthPendingCount INT,@AssetClsAuthPending BIT,@AssetClsAuthPendingCount INT
  SELECT @MOCAuthPendingCount = Count(NCIF_Id) FROM MOC_NPA_IntegrationDetails_MOD WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND AuthorisationStatus  IN ('MP','NP') 
  IF @MOCAuthPendingCount > 0
	  BEGIN
		 SET @MOCAuthPending = 1
	  END
ELSE
	BEGIN
		SET @MOCAuthPending = 0
	  END

	   SELECT @AssetClsAuthPendingCount = Count(NCIF_Id) FROM NPA_IntegrationDetails_MOD WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND AuthorisationStatus  IN ('MP','NP') 
  IF @AssetClsAuthPendingCount > 0
	  BEGIN
		 SET @AssetClsAuthPending = 1
	  END
ELSE
	BEGIN
		SET @AssetClsAuthPending = 0
	  END
 BEGIN
 Declare @NextDate DATE,@NextMonthEndDate DATE --Date = DATEADD(MONTH, DATEDIFF(MONTH, '19000201', GETDATE()), '19000101')
 Declare @CurrentMOCDate DATE , @CurrentMOCTimeKey INT,@MOC_InitialisedFlag Char(1)
 --select @NextDate=DATEADD(MONTH,1,MonthFirstDate) FROM SysDatamatrix where CurrentStatus='C'

 select @NextDate=(select top 1 ExtDate from SysDatamatrix where CurrentStatus='N' and ExtDate is not null ORDER BY ExtDate)

 --select @NextMonthEndDate=MonthLastDate from SysDatamatrix where MonthFirstDate=@NextDate
 --PRINT @NextMonthEndDate
 select @CurrentMOCDate=(select top 1 MonthLastDate from SysDatamatrix where CurrentStatus_MOC='C' )

 select @CurrentMOCTimeKey=(select top 1 TimeKey from SysDatamatrix where CurrentStatus_MOC='C' )

 select @MOC_InitialisedFlag =(select top 1 MOC_Initialised from SysDatamatrix where CurrentStatus_MOC='C' )

  SELECT CONVERT(VARCHAR(10),ExtDate,103)	AS FreezeDate,ISNULL(PreProcessingFreeze,'N') AS PreProcFreeze,ISNULL(MOC_Freeze,'N') AS MocFreeze,@AssetClsAuthPending AS IsAssetClsPending,@MOCAuthPending AS IsMOCAuthPending,
  ISNULL(Finacle_Reverse,'N') as Finacle_Reverse,ISNULL(ECS_Reverse,'N') as ECS_Reverse,ISNULL(Prolendz_Reverse,'N') as Prolendz_Reverse, ISNULL(Ganseca_Reverse,'N') as Ganseva_Reverse ,ISNULL(Calypso_Reverse,'N') as Calypso_Reverse,ISNULL(ETL_Completed,'N') as ETL_Completed,CONVERT(VARCHAR(10), @NextDate,103) as NextDate, @CurrentMOCTimeKey as CurrentMOCTimeKey,@MOC_InitialisedFlag as  MOC_InitialisedFlag,CONVERT(VARCHAR(10), @CurrentMOCDate,103) as CurrentMOCDate,isnull(PNPA_Status,'N') as PNPA_Status,'TblFreezeDate' AS TableName FROM SysDatamatrix 
  WHERE  ISNULL(ExtDate,'')=ISNULL(@ExtDate,'') and CurrentStatus='C'
END

select SourceAlt_Key as Code,SourceName as Description, 'TblSourceMaster' AS TableName from DimSourceSystem
 where EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey and SourceAlt_Key in(10,20,40,60,70)

GO