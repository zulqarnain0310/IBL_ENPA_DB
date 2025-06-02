SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROC [dbo].[Assetclass_Reverse_Feed_MOC_BKP20250206]
    @TimeKey INT,
    @IS_MOC CHAR(1) = 'N'
AS
BEGIN
    DECLARE @DATE DATE
    SELECT @DATE = Date 
    FROM dbo.SysDataMatrix  
    WHERE TimeKey = @TimeKey

    DECLARE @CUTOVERDATE DATE = '2024-01-24' -- Changed on 20231021 by Zain for Finacle Prolendz same source -- ON PROD 20240126

    DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
    WHERE [SP_Name] = 'Assetclass_Reverse_Feed_MOC' 
    AND [EXT_DATE] = @DATE 
    AND ISNULL([Audit_Flg], 0) = 0

    INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]([EXT_DATE], [Timekey], [SP_Name], Start_Date_Time)
    SELECT @DATE, @TimeKey, 'Assetclass_Reverse_Feed_MOC', GETDATE()

    TRUNCATE TABLE ReverseFeedDetails_MOC

    INSERT INTO ReverseFeedDetails_MOC(
        AsOnDate, AccountNo, SOL_ID, Scheme_Type, Scheme_Code, CIF_ID, UCIF_ID, SourceName, SrcAssetClass, HomogenizedAssetClass, 
        HomogenizedNpaDt, IS_MOC, NatureofClassification, DateofImpacting, ImpactingAccountNo, ImpactingSourceSystemName
    )
    SELECT DISTINCT 
        @DATE As_On_Processing_Date, 
        a.CustomerACID Account_No, 
        a.BranchCode Sol_Id,
        a.ProductType SchemeType, 
        a.ProductCode Scheme_Code,
        a.CustomerId Source_System_CIF, 
        A.NCIF_Id Dedupe_ID_UCIC_Enterprise_CIF,
        CASE 
            WHEN a.SrcSysAlt_Key = 100 THEN 'Finacle-2' 
            ELSE b.SourceName 
        END SourceName,
        CASE 
            WHEN a.SrcSysAlt_Key = 10 THEN c.FinacleAssetClassCode
            WHEN a.SrcSysAlt_Key = 20 AND C.AssetClassAlt_Key = 1 THEN '1'  -- VISION PLUS
            WHEN a.SrcSysAlt_Key = 20 AND C.AssetClassAlt_Key IN (2, 3, 4, 5, 6) THEN '8'  -- VISION PLUS
            WHEN a.SrcSysAlt_Key = 20 AND C.AssetClassAlt_Key = 7 THEN '9'  -- VISION PLUS
            WHEN a.SrcSysAlt_Key = 30 THEN c.TradeProAssetClassCode -- TradePro
            WHEN a.SrcSysAlt_Key = 40 THEN c.CalypsoAssetClassCode
            WHEN a.SrcSysAlt_Key = 50 THEN c.eCBFAssetClassCode
            WHEN (@CUTOVERDATE >= @DATE AND a.SrcSysAlt_Key = 60) THEN c.ProlendzAssetClassCode  -- Changed on 20231021 by Zain for Finacle Prolendz same source -- ON PROD 20240117
            WHEN (@CUTOVERDATE < @DATE AND a.SrcSysAlt_Key = 60) THEN c.FinacleAssetClassCode  -- Changed on 20231021 by Zain for Finacle Prolendz same source -- ON PROD 20240117
            WHEN a.SrcSysAlt_Key = 70 THEN c.GanasevaAssetClassCode
            WHEN a.SrcSysAlt_Key = 80 THEN c.PTSmartAssetClassCode
            WHEN a.SrcSysAlt_Key = 90 THEN c.VeefinAssetClassCode  -- Veefin
            WHEN a.SrcSysAlt_Key = 100 THEN c.Finacle2AssetClassCode
            WHEN a.SrcSysAlt_Key = 120 AND C.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) = 0 THEN 'STD'  -- M2P
            WHEN a.SrcSysAlt_Key = 120 AND C.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) BETWEEN 1 AND 30 THEN 'SMA0'
            WHEN a.SrcSysAlt_Key = 120 AND C.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) BETWEEN 31 AND 60 THEN 'SMA1'
            WHEN a.SrcSysAlt_Key = 120 AND C.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) BETWEEN 61 AND 89 THEN 'SMA2'
            WHEN a.SrcSysAlt_Key = 120 AND C.AssetClassAlt_Key = 2 THEN 'SUB'  -- M2P
            WHEN a.SrcSysAlt_Key = 120 AND C.AssetClassAlt_Key IN (3, 4, 5) THEN 'DBT'  -- M2P
            WHEN a.SrcSysAlt_Key = 120 AND C.AssetClassAlt_Key = 6 THEN 'DBT' -- M2P  -- CURRENTLY LOSS NOT AVAILABLE
        END Source_System_Asset_Classification,
        CASE 
            WHEN a.SrcSysAlt_Key = 10 THEN d.FinacleAssetClassCode 
            WHEN a.SrcSysAlt_Key = 20 THEN d.VP_AssetClassCode -- VISION PLUS
            WHEN a.SrcSysAlt_Key = 30 THEN d.TradeProAssetClassCode -- TradePro
            WHEN a.SrcSysAlt_Key = 40 THEN d.CalypsoAssetClassCode
            WHEN a.SrcSysAlt_Key = 50 THEN d.eCBFAssetClassCode
            WHEN (@CUTOVERDATE >= @DATE AND a.SrcSysAlt_Key = 60) THEN D.ProlendzAssetClassCode  -- Changed on 20231021 by Zain for Finacle Prolendz same source -- ON PROD 20240117
            WHEN (@CUTOVERDATE < @DATE AND a.SrcSysAlt_Key = 60) THEN D.FinacleAssetClassCode  -- Changed on 20231021 by Zain for Finacle Prolendz same source -- ON PROD 20240117
            WHEN a.SrcSysAlt_Key = 70 THEN d.GanasevaAssetClassCode
            WHEN a.SrcSysAlt_Key = 80 THEN d.PTSmartAssetClassCode 
            WHEN a.SrcSysAlt_Key = 90 THEN d.VeefinAssetClassCode  -- Veefin
            WHEN a.SrcSysAlt_Key = 100 THEN d.Finacle2AssetClassCode
            WHEN a.SrcSysAlt_Key = 120 AND D.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) = 0 THEN 'STD'  -- M2P
            WHEN a.SrcSysAlt_Key = 120 AND D.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) BETWEEN 1 AND 30 THEN 'SMA0'
            WHEN a.SrcSysAlt_Key = 120 AND D.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) BETWEEN 31 AND 60 THEN 'SMA1'
            WHEN a.SrcSysAlt_Key = 120 AND D.AssetClassAlt_Key = 1 AND ISNULL(a.MaxDPD, 0) BETWEEN 61 AND 89 THEN 'SMA2'
            WHEN a.SrcSysAlt_Key = 120 AND D.AssetClassAlt_Key = 2 THEN 'SUB'  -- M2P
            WHEN a.SrcSysAlt_Key = 120 AND D.AssetClassAlt_Key IN (3, 4, 5) THEN 'DBT'  -- M2P
            WHEN a.SrcSysAlt_Key = 120 AND D.AssetClassAlt_Key = 6 THEN 'DBT' -- M2P  -- CURRENTLY LOSS NOT AVAILABLE
        END Homogenized_Asset_Classification,
        a.NCIF_NPA_Date Homogenized_NPA_Date,
        CASE WHEN @IS_MOC = 'Y' THEN 'Y' ELSE 'N' END IS_MOC,
        NatureofClassification,  -- 20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
        DateofImpacting,  -- 20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
        ImpactingAccountNo,  -- 20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
        ImpactingSourceSystemName  -- 20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
    FROM [dbo].[NPA_IntegrationDetails] a
    INNER JOIN [dbo].[DimSourceSystem] b 
        ON a.SrcSysAlt_Key = b.SourceAlt_Key
        AND b.EffectiveFromTimeKey <= @TimeKey 
        AND b.EffectiveToTimeKey >= @TimeKey
        AND a.EffectiveFromTimeKey <= @TimeKey 
        AND a.EffectiveToTimeKey >= @TimeKey
    INNER JOIN [dbo].[DimAssetClass] c 
        ON a.AC_AssetClassAlt_Key = c.AssetClassAlt_Key
        AND c.EffectiveFromTimeKey <= @TimeKey 
        AND c.EffectiveToTimeKey >= @TimeKey
    INNER JOIN [dbo].[DimAssetClass] d 
        ON a.NCIF_AssetClassAlt_Key = d.AssetClassAlt_Key
        AND d.EffectiveFromTimeKey <= @TimeKey 
        AND d.EffectiveToTimeKey >= @TimeKey
    INNER JOIN NPA_IntegrationDetails_Mod f 
        ON a.EffectiveFromTimeKey = @TimeKey
        AND a.NCIF_Id = f.NCIF_Id
        AND a.CustomerACID = f.CustomerACID
        AND a.CustomerId = f.customerid
	LEFT JOIN PREMOC.NPA_IntegrationDetails PRE 
        ON A.CustomerACID = PRE.CustomerACID
   
    WHERE (
        (ISNULL(A.AC_AssetClassAlt_Key, 0) <> ISNULL(A.NCIF_AssetClassAlt_Key, 0) 
        OR ISNULL(A.AC_NPA_Date, '1900-01-01') <> ISNULL(A.NCIF_NPA_Date, '1900-01-01'))
    )
    AND (ISNULL(A.AC_AssetClassAlt_Key, 0) <> ISNULL(PRE.AC_AssetClassAlt_Key, 0)
	    OR 
	      ISNULL(A.AC_NPA_Date,'1900-01-01') <> ISNULL(PRE.AC_NPA_Date,'1900-01-01'))
END
GO