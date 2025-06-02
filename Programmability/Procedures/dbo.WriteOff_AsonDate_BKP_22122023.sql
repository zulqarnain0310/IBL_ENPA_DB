SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROC [dbo].[WriteOff_AsonDate_BKP_22122023]
      @Cost AS FLOAT=1
      AS
Begin
Declare @Timekey int=(Select TimeKey from SysDatamatrix where CurrentStatus='C')
Declare @Date Date=(Select Cast(DATE as date) from SysDatamatrix where CurrentStatus='C' )

DROP TABLE IF EXISTS WriteOffdata_AsonDate

;with cte
as
(
Select distinct 
 1 as SR_No
,CONVERT(VARCHAR(20),@Date,103) AS				[As On Date]
,NCIF_Id                                        [NCIF ID]
,CustomerID                                     [Customer ID]
,CustomerName                                   [Name]
--, ''                                                [Aadhaar No]
,Pan                                            [PAN]
,WriteOffDate                                   [Write Off Date]
,IsARC_Sale										[ARC Flag]
,IsSuitFiled									[Suit Filed Flag]
,IsOTS											[OTS Flag]
,IsFraud										[Fraud Flag]
From NPA_IntegrationDetails NI
Where 
(
	ISNULL(IsTWO,'')='Y' 
	OR ISNULL(NCIF_AssetClassAlt_Key,1)=7
	OR ISNULL([IsARC_Sale],'')='Y'
	OR ISNULL([IsSuitFiled],'')='Y'
	OR ISNULL([IsOTS],'')='Y'
	OR ISNULL([IsFraud],'')='Y'
)
And NI.EffectiveFromTimeKey<=@Timekey and NI.EffectiveToTimeKey>=@Timekey

UNION

SELECT
 2 as SR_No
,CONVERT(VARCHAR(20),@Date,103) AS			[As On Date]
,NCIF_Id									[NCIF ID]
,ACWOD.CustomerID							[Customer ID]
,ACWOD.CustomerName                         [Name]
--, ''                                      [Aadhaar No]
,''                                         [PAN]
,WriteOffDt                                 [Write Off Date]
,''											[ARC Flag]
,''											[Suit Filed Flag]
,''											[OTS Flag]
,''											[Fraud Flag]

FROM [dbo].[AdvAcWODetail]    ACWOD
Where ACWOD.EffectiveToTimeKey<=@Timekey and ACWOD.EffectiveToTimeKey>=@Timekey
and  ACWOD.CustomerACID Not in
(
Select distinct CustomerACID
From NPA_IntegrationDetails NI
Where (	ISNULL(IsTWO,'')='Y' OR ISNULL(NCIF_AssetClassAlt_Key,1)=7 OR ISNULL([IsARC_Sale],'')='Y'
	OR ISNULL([IsSuitFiled],'')='Y' OR ISNULL([IsOTS],'')='Y') OR ISNULL([IsFraud],'')='Y'
And NI.EffectiveFromTimeKey<=@Timekey and NI.EffectiveToTimeKey>=@Timekey
)
Group by NCIF_Id, ACWOD.CustomerID,ACWOD.CustomerName,WriteOffDt
)

Select [As On Date],[NCIF ID],[Customer ID],[Name],[PAN],[Write Off Date],[ARC Flag], [Suit Filed Flag],[OTS Flag] , [Fraud Flag]
INTO WriteOffdata_AsonDate from cte order by SR_No,PAN desc

INSERT INTO [dbo].[hist_WriteOffdata] SELECT * FROM WriteOffdata_AsonDate


END

--exec [dbo].[WriteOff_AsonDate]

----Export 
--SELECT * FROM WriteOffdata_AsonDate

 
GO