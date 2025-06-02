SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


/*
Created By		:- Baijayanti
Created Date	:- 07/06/2021
Report Name		:- Facility Wise Npa Status
*/

CREATE PROC [dbo].[Rpt-FacilityWiseNpaStatus]
@TimeKey AS INT
,@Cost AS FLOAT
AS


--DECLARE	
--@TimeKey AS INT=24927,
--@Cost AS FLOAT=1000


SELECT 

----------------Cash Credit/OD/Demand Loans-------------------
--------------------------Balance---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------
SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS SUB_CC_OD_DL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB1_CC_OD_DL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB2_CC_OD_DL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB3_CC_OD_DL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS LOS_CC_OD_DL_Outstanding,

--------------------------UnrealisedInterest---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS SUB_CC_OD_DL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB1_CC_OD_DL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB2_CC_OD_DL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB3_CC_OD_DL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS LOS_CC_OD_DL_UnrealisedInterest,

--------------------------GrossNPA---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS SUB_CC_OD_DL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB1_CC_OD_DL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB2_CC_OD_DL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB3_CC_OD_DL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS LOS_CC_OD_DL_GrossNPA,

--------------------------Provision---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS SUB_CC_OD_DL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB1_CC_OD_DL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB2_CC_OD_DL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB3_CC_OD_DL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('CC','OD','DL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS LOS_CC_OD_DL_Provision,


--------------------------NetNPA---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS SUB_CC_OD_DL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB1_CC_OD_DL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB2_CC_OD_DL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB3_CC_OD_DL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('CC','OD','DL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS LOS_CC_OD_DL_NetNPA,

---------------------Term Loans-----------------
--------------------------Balance---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------
SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('TL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS SUB_TL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('TL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB1_TL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('TL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB2_TL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('TL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB3_TL_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('TL')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS LOS_TL_Outstanding,

--------------------------UnrealisedInterest---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('TL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS SUB_TL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('TL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB1_TL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('TL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB2_TL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('TL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB3_TL_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('TL')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS LOS_TL_UnrealisedInterest,

--------------------------GrossNPA---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS SUB_TL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB1_TL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB2_TL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB3_TL_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS LOS_TL_GrossNPA,

--------------------------Provision---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('TL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS SUB_TL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('TL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB1_TL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('TL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB2_TL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('TL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB3_TL_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('TL')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS LOS_TL_Provision,


--------------------------NetNPA---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS SUB_TL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB1_TL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB2_TL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB3_TL_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('TL')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS LOS_TL_NetNPA,

---------------------Bills-----------------
--------------------------Balance---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------
SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('BP')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS SUB_Bills_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('BP')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB1_Bills_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('BP')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB2_Bills_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('BP')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS DB3_Bills_Outstanding,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('BP')
         THEN ISNULL(Balance,0)
		 ELSE 0
		 END)/@Cost                     AS LOS_Bills_Outstanding,

--------------------------UnrealisedInterest---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('BP')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS SUB_Bills_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('BP')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB1_Bills_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('BP')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB2_Bills_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('BP')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS DB3_Bills_UnrealisedInterest,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('BP')
         THEN ISNULL(UNSERVED_INTEREST,0)
		 ELSE 0
		 END)/@Cost                      AS LOS_Bills_UnrealisedInterest,

--------------------------GrossNPA---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS SUB_Bills_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB1_Bills_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB2_Bills_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS DB3_Bills_GrossNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0))
		 ELSE 0
		 END)/@Cost                      AS LOS_Bills_GrossNPA,

--------------------------Provision---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('BP')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS SUB_Bills_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('BP')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB1_Bills_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('BP')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB2_Bills_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('BP')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS DB3_Bills_Provision,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('BP')
         THEN ISNULL(TotalProvision,0)
		 ELSE 0
		 END)/@Cost                      AS LOS_Bills_Provision,


--------------------------NetNPA---------------------		
-----------------------SUB,DB1,DB2,DB3,LOS-------------------

SUM(CASE WHEN DAC.AssetClassShortNameEnum='SUB' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS SUB_Bills_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB1' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB1_Bills_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB2' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB2_Bills_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='DB3' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS DB3_Bills_NetNPA,

SUM(CASE WHEN DAC.AssetClassShortNameEnum='LOS' AND FacilityType IN('BP')
         THEN (ISNULL(Balance,0)-ISNULL(UNSERVED_INTEREST,0)-ISNULL(TotalProvision,0))
		 ELSE 0
		 END)/@Cost                      AS LOS_Bills_NetNPA

FROM  NPA_IntegrationDetails	NPAID	
						

INNER JOIN DimAssetClass DAC					ON  DAC.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key 
												    AND DAC.EffectiveFromTimeKey<=@TimeKey 
													AND DAC.EffectiveToTimeKey>=@TimeKey 
												    AND NPAID.EffectiveFromTimeKey<=@TimeKey 
													AND NPAID.EffectiveToTimeKey>=@TimeKey
												



WHERE DAC.AssetClassSubGroup IN('SUB STANDARD','DOUBTFUL','LOSS')



OPTION(RECOMPILE)
GO