SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create Proc [dbo].[RestructureDataOutput_BKP_22122023]
as
Declare @Timekey int=(Select Timekey from SysDataMatrix where CurrentStatus='c')
select A.NCIF_Id,A.CustomerId,A.CustomerName
		,A.SrcSysAlt_Key
		,A.CustomerACID
		,ProductCode	
		,ProductDesc
		,ISNULL(A.FlgUpg,'N')FlgUpg
		,A.UpgDate
		,A.NCIF_AssetClassAlt_Key
		,A.NCIF_NPA_Date
		,A.AC_AssetClassAlt_Key
		,A.AC_NPA_Date
		,A.SanctionedLimit	
		,A.DrawingPower	
		,A.PrincipleOutstanding	
		,A.Balance	
		,A.Overdue
		,A.DPD_Overdue_Loans
		,A.DPD_Renewals
		,A.DPD_IntService
		,A.DPD_Overdrawn
		,A.DPD_Interest_Not_Serviced
		,A.DPD_StockStmt
		,A.MaxDPD
		,A.WriteOffFlag
		,A.WriteOffDate
		,A.IntOverdue	
		,A.IntAccrued	
		,A.OtherOverdue	
		,A.PrincOverdue	
		,A.IsRestructured	
		,A.IsOTS	
		,A.IsTWO	
		,A.IsARC_Sale	
		,A.IsFraud	
		,A.IsWiful	
		,A.IsNonCooperative	
		,A.IsSuitFiled	
		,A.IsRFA	
		,A.IsFITL	
		,A.IsCentral_GovGty	
		,A.Is_Oth_GovGty
		,D.ParameterName RestructureType
		,C.RestructureTypeAlt_Key
		,B.RestructureDt
		,C.CurrentPOS	
		,C.CurrentTOS
		,C.Res_POS_to_CurrentPOS_Per
		,B.RepaymentStartDate
		,B.IntRepayStartDate
		,A.DCCO_Date
		,C.SP_ExpiryDate
		,C.SP_ExpiryExtendedDate
		,C.TEN_PC_DATE
		,C.DPD_30_90_Breach_Date
		,C.ZeroDPD_Date
		,C.SecondRestrDate
		,C.AggregateExposure
		,C.CreditRating1
		,C.CreditRating2
	--	SELECT * FROM NPA_IntegrationDetails
FROM NPA_IntegrationDetails A
	LEFT JOIN CURDAT.AdvAcRestructureDetail B
		ON A.CustomerACID=B.REFSYSTEMACID
	
		AND B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey
	LEFT JOIN AdvAcRestructureCal C
		ON A.CustomerACID=C.CustomerACID
		AND C.EffectiveFromTimeKey<=@Timekey AND C.EffectiveToTimeKey>=@Timekey
	LEFT JOIN DimParameter d
		on d.DimParameterName like '%typeofrestr%'
		and b.RestructureTypeAlt_Key=d.ParameterAlt_Key
		and d.EffectiveToTimeKey=49999
--where A.NCIF_Id in()
where 	 A.EffectiveFromTimeKey=@Timekey AND A.EffectiveToTimeKey=@Timekey
ORDER BY A.NCIF_Id,CustomerAcid
GO