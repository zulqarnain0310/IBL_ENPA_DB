SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE Proc [dbo].[AuditTrail_BACKUP_23112022]
    @FromDate  AS VARCHAR(20),
	@ToDate  AS VARCHAR(20),
	@Cost AS FLOAT=1

	AS 
Begin
Declare @Timekey int=(Select Timekey from SysDataMatrix where CurrentStatus='C')
Select 
npamod.UploadId
,AccProvPer
,MocReasonName [MOC reason]
,Maker_Name.UserName [Name of Maker]
,First_Approver.UserName [Name of First Level Approver]
,Second_Approver.UserName [Name of Second Level Approver]
,Maker_Name.DesignationName [Designation of Maker]
,First_Approver.DesignationName [Designation of First Level Approver]
,Second_Approver.DesignationName [Designation of Second Level Approver]
,npa.* 
from NPA_IntegrationDetails(nolock) npa INNER JOIN 
NPA_IntegrationDetails_Mod(nolock) npamod on 
npa.CustomerACID = npamod.CustomerACID
LEFT JOIN [CURDAT].[AcceleratedProv](nolock) AccProv
on npa.CustomerACID=AccProv.CustomerACID
and AccProv.EffectiveFromTimeKey<=@TimeKey and AccProv.EffectiveToTimeKey>=@TimeKey
LEFT JOIN [dbo].[DimMocReason](nolock) DOR
on npa.MOC_ReasonAlt_Key=DOR.MocReasonAlt_Key
and DOR.EffectiveFromTimeKey<=@TimeKey  and DOR.EffectiveToTimeKey>=@TimeKey
LEFT JOIN IBL_ENPA_DB_LOCAL_DEV.dbo.ExcelUploadHistory(nolock) EUH
ON npamod.UploadId=EUH.UniqueUploadID
AND EUH.EffectiveFromTimeKey<=@TimeKey  and EUH.EffectiveToTimeKey>=@TimeKey
LEFT JOIN   (SELECT DISTINCT UserLoginID,UserName,DesignationName FROM DimUserInfo DUI inner join
             DimDesignation DDG on DUI.DesignationAlt_Key=DDG.DesignationAlt_Key
             WHERE DUI.EffectiveFromTimeKey<=@TimeKey AND DUI.EffectiveToTimeKey>=@TimeKey
			 and DDG.EffectiveFromTimeKey<=@TimeKey AND DDG.EffectiveToTimeKey>=@TimeKey) Maker_Name
on EUH.UploadedBy=Maker_Name.UserLoginID
LEFT JOIN (SELECT DISTINCT UserLoginID,UserName,DesignationName FROM DimUserInfo DUI inner join
             DimDesignation DDG on DUI.DesignationAlt_Key=DDG.DesignationAlt_Key
             WHERE DUI.EffectiveFromTimeKey<=@TimeKey AND DUI.EffectiveToTimeKey>=@TimeKey
			 and DDG.EffectiveFromTimeKey<=@TimeKey AND DDG.EffectiveToTimeKey>=@TimeKey)  First_Approver
on EUH.ApprovedByFirstLevel=First_Approver.UserLoginID
LEFT JOIN (SELECT DISTINCT UserLoginID,UserName,DesignationName FROM DimUserInfo DUI inner join
             DimDesignation DDG on DUI.DesignationAlt_Key=DDG.DesignationAlt_Key
             WHERE DUI.EffectiveFromTimeKey<=@TimeKey AND DUI.EffectiveToTimeKey>=@TimeKey
			 and DDG.EffectiveFromTimeKey<=@TimeKey AND DDG.EffectiveToTimeKey>=@TimeKey)  Second_Approver
on EUH.ApprovedBy=Second_Approver.UserLoginID
Where npa.EffectiveFromTimeKey=@TimeKey and npa.EffectiveToTimeKey=@TimeKey
and CAST (npa.MOC_Date as date) BETWEEN @FromDate AND  @ToDate
End
GO