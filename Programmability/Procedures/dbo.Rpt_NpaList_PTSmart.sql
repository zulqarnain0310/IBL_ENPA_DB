SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE Proc [dbo].[Rpt_NpaList_PTSmart]      
AS

DECLARE
       @TimeKey INT=(Select TimeKey from SysDataMatrix where CurrentStatus='C')
      ,@SrcAlt_key int =(Select SourceAlt_Key from DimSourceSystem where SourceName='PT Smart')
SELECT  
DSS.SourceName          SourceName
,BranchCode             SolId
,Segment                Segment
,ProductCode            ProductCode
,NCIF_Id                NCIF_Id
,CustomerId             CustomerId
,CustomerACID           CustomerACID
,IsFunded               IsFunded
,CustomerName           CustomerName
,NCIF_NPA_Date          NCIF_NPA_Date
,AssetClassName         AssetClassName
,NCIF_AssetClassAlt_Key NCIF_AssetClassAlt_Key
,Balance                Balance
,IntOverdue             IntOverdue
,PrincipleOutstanding   PrincipleOutstanding
,SecurityValue          SecurityValue
,SecuredAmt             SecuredAmt
,UnSecuredAmt           UnSecuredAmt
,TotalProvision         TotalProvision
,SecuredFlag            [Secured Flag]
,IsRestructured         [Restructured Flag]
,ARD.RestructureDt      [Restructured Date]
,WriteOffFlag           [Write Off Flag]
,WriteOffDate           [Write Off date]
,IsFraud                [Fraud Flag]
,IsOTS                  [OTS Flag]
,IsSuitFiled            [SUIT Flag]
,IsARC_Sale             [ARC Flag]
,ARC_SaleDate           [ARC SaleDate]
,IsTWO                  [Is TWO Flag]
,GtyRepudiated          [Gty Repudiated Flag]
,FlgErosion             [Security Erosion Flag]

FROM  NPA_IntegrationDetails NPAID  
Left join curdat.AdvAcRestructureDetail ARD
ON ARD.RefSystemAcId=NPAID.CustomerAcid
AND NPAID.EffectiveFromTimeKey<=@TimeKey
AND NPAID.EffectiveToTimeKey>=@TimeKey

AND ARD.EffectiveFromTimeKey<=@TimeKey
AND ARD.EffectiveToTimeKey>=@TimeKey

LEFT JOIN DimAssetClass DAC ON  DAC.AssetClassAlt_Key=NPAID.NCIF_AssetClassAlt_Key
          AND DAC.EffectiveFromTimeKey<=@TimeKey
          AND DAC.EffectiveToTimeKey>=@TimeKey
                                                                            
LEFT JOIN DimSourceSystem DSS ON  DSS.SourceAlt_Key=NPAID.SrcSysAlt_Key
          AND DSS.EffectiveFromTimeKey<=@TimeKey
          AND DSS.EffectiveToTimeKey>=@TimeKey
Where NPAID.NCIF_AssetClassAlt_Key in (2,3,4,5,6) and NPAID.SrcSysAlt_Key=@SrcAlt_key
OPTION(RECOMPILE)

GO