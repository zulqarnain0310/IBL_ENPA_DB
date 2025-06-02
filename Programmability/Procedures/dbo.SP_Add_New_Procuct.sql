SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SP_Add_New_Procuct]
AS
DECLARE @Timekey int
DECLARE @Product_Key INT=(SELECT MAX(Product_Key) FROM DimProduct)
SELECT @Timekey= TimeKey FROM SysDataMatrix WHERE CurrentStatus='C'

INSERT INTO [dbo].[DimProduct]
           ([Product_Key]
           ,[ProductAlt_Key]
           ,[ProductCode]
		   ,ProductName
           ,[EffectiveFromTimeKey]
           ,[EffectiveToTimeKey])
SELECT (ROW_NUMBER() OVER (ORDER BY A.ProductCode)+@Product_Key) Product_Key,
       (ROW_NUMBER() OVER (ORDER BY A.ProductCode)+@Product_Key)*10 Product_Key,
	   A.ProductCode,
	   A.ProductName,
	   @Timekey,
	   49999
FROM 
(SELECT ProductCode,ProductName FROM IBL_ENPA_STGDB.dbo.Finacle_Stg_Incremental 
UNION 
SELECT ProductCode,ProductName FROM IBL_ENPA_STGDB.dbo.Prolendz_Stg_Incremental
UNION 
SELECT ProductCode,ProductName FROM IBL_ENPA_STGDB.dbo.Calypso_Stg_Incremental
UNION 
SELECT ProductCode,ProductName FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental
UNION 
SELECT ProductCode,ProductName FROM IBL_ENPA_STGDB.dbo.Ecbf_Stg_Incremental
UNION 
SELECT ProductCode,ProductName FROM IBL_ENPA_STGDB.dbo.Ganaseva_Stg_Incremental
UNION 
SELECT ProductCode,ProductName FROM IBL_ENPA_STGDB.dbo.VisionPlus_Stg_Incremental) A
LEFT JOIN DimProduct DP ON A.ProductCode=DP.ProductCode
WHERE ISNULL(A.ProductCode,'NA')<>'NA'
AND DP.ProductCode IS NULL



   
GO