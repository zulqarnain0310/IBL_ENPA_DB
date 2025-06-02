SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create PROC [dbo].[ReverseFeedValidations]

AS

BEGIN

Declare @Timekey as Int= (Select TimeKey from SysDataMatrix where CurrentStatus='C')
Declare @Date as Date= (Select Date from SysDataMatrix where CurrentStatus='C')

Delete From RFValidationDetails where AsOnDate=@Date

Insert into RFValidationDetails
Select AsOnDate,SourceName,Remark 
	from (
		Select * from (
		Select AsOnDate,SourceName,'UCIF ID Is Null' Remark from ReverseFeedDetails where UCIF_ID Is Null
		Group By AsOnDate,SourceName
		
		UNION
		
		Select AsOnDate,SourceName,'CIF ID Is Null' Remark from ReverseFeedDetails where CIF_ID Is Null
		Group By AsOnDate,SourceName
		
		UNION
		
		Select AsOnDate,SourceName,'AccountNo Is Null' Remark from ReverseFeedDetails where AccountNo Is Null
		Group By AsOnDate,SourceName
		
		UNION
		
		Select AsOnDate,SourceName,'SrcAssetClass Is Null' Remark from ReverseFeedDetails where SrcAssetClass Is Null
		Group By AsOnDate,SourceName
		
		UNION
		
		Select AsOnDate,SourceName,'HomogenizedAssetClass Is Null' Remark from ReverseFeedDetails where HomogenizedAssetClass Is Null
		Group By AsOnDate,SourceName
		)A
		
		UNION
		
		
		Select * from (
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>c.FinacleAssetClassCode
		Where B.SourceName='Finacle' And A.SrcAssetClass not in (Select isnull(FinacleAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>(case when A.SourceName='VISION PLUS' And C.AssetClassAlt_Key=1 then '1'  --VISION PLUS
		--			when A.SourceName='VISION PLUS' And C.AssetClassAlt_Key in (2,3,4,5,6) then '8'  --VISION PLUS
		--			 when A.SourceName='VISION PLUS' And C.AssetClassAlt_Key=7 then '9' End) --VISION PLUS
		Where A.SourceName='VISION PLUS' And A.SrcAssetClass not in (Select ISNULL(case When AssetClassAlt_Key=1 then '1'  
					when AssetClassAlt_Key in (2,3,4,5,6) then '8'  
					 when AssetClassAlt_Key=7 then '9' End,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>c.TradeProAssetClassCode
		Where A.SourceName='TradePro' And A.SrcAssetClass not in (Select isnull(TradeProAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>c.CalypsoAssetClassCode
		Where A.SourceName='Calypso' And A.SrcAssetClass not in (Select isnull(CalypsoAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>c.eCBFAssetClassCode
		Where A.SourceName='ECBF' And A.SrcAssetClass not in (Select isnull(eCBFAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.ProlendzAssetClassCode
		Where A.SourceName='Prolendz' And A.SrcAssetClass not in (Select isnull(ProlendzAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>c.GanasevaAssetClassCode
		Where A.SourceName='Ganaseva' And A.SrcAssetClass not in (Select isnull(GanasevaAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>c.PTSmartAssetClassCode
		Where A.SourceName='PT Smart' And A.SrcAssetClass not in (Select isnull(PTSmartAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'SrcAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.SrcAssetClass<>c.VeefinAssetClassCode
		Where A.SourceName='Veefin'  And A.SrcAssetClass not in (Select isnull(VeefinAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		)A
		
		UNION
		
		Select * from (
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.FinacleAssetClassCode
		Where A.SourceName='Finacle' And A.HomogenizedAssetClass not in (Select Isnull(FinacleAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.VP_AssetClassCode
		Where A.SourceName='VISION PLUS' And A.HomogenizedAssetClass not in (Select Isnull(VP_AssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.TradeProAssetClassCode
		Where A.SourceName='TradePro'  And A.HomogenizedAssetClass not in (Select Isnull(TradeProAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.CalypsoAssetClassCode
		Where A.SourceName='Calypso' And A.HomogenizedAssetClass not in (Select isnull(CalypsoAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.eCBFAssetClassCode
		Where A.SourceName='ECBF' And A.HomogenizedAssetClass not in (Select isnull(eCBFAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.ProlendzAssetClassCode
		Where A.SourceName='Prolendz'  And A.HomogenizedAssetClass not in (Select isnull(ProlendzAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.GanasevaAssetClassCode
		Where A.SourceName='Ganaseva' And A.HomogenizedAssetClass not in (Select isnull(GanasevaAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.PTSmartAssetClassCode
		Where A.SourceName='PT Smart'  And A.HomogenizedAssetClass not in (Select isnull(PTSmartAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedAssetClass Is MisMatch'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		--Inner Join DimAssetClass C On A.HomogenizedAssetClass<>c.VeefinAssetClassCode
		Where A.SourceName='Veefin' And A.HomogenizedAssetClass not in (Select isnull(PTSmartAssetClassCode,0) from DimAssetClass)
		Group By AsOnDate,A.SourceName
		)A
		
		
		UNION
		
		Select * from (
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.FinacleAssetClassCode
		Where A.SourceName='Finacle' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.VP_AssetClassCode
		Where A.SourceName='VISION PLUS' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.TradeProAssetClassCode
		Where A.SourceName='TradePro' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.CalypsoAssetClassCode
		Where A.SourceName='Calypso' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.eCBFAssetClassCode
		Where A.SourceName='ECBF' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.ProlendzAssetClassCode
		Where A.SourceName='Prolendz' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.GanasevaAssetClassCode
		Where A.SourceName='Ganaseva' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.PTSmartAssetClassCode
		Where A.SourceName='PT Smart' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is In Standard'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.VeefinAssetClassCode
		Where A.SourceName='Veefin' And C.AssetClassAlt_Key=1 And A.HomogenizedNpaDt Is Not Null
		Group By AsOnDate,A.SourceName
		)A
		
		
		UNION
		
		Select * from (
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.FinacleAssetClassCode
		Where A.SourceName='Finacle' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.VP_AssetClassCode
		Where A.SourceName='VISION PLUS' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.TradeProAssetClassCode
		Where A.SourceName='TradePro' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.CalypsoAssetClassCode
		Where A.SourceName='Calypso' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.eCBFAssetClassCode
		Where A.SourceName='ECBF' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.ProlendzAssetClassCode
		Where A.SourceName='Prolendz' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.GanasevaAssetClassCode
		Where A.SourceName='Ganaseva' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.PTSmartAssetClassCode
		Where A.SourceName='PT Smart' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		UNION
		Select AsOnDate,A.SourceName,'HomogenizedNPADate Is Not In NPA'Remark from ReverseFeedDetails A
		Inner Join DimSourceSystem B On A.SourceName=B.SourceName AND B.EffectiveToTimeKey=49999
		Inner Join DimAssetClass C On A.HomogenizedAssetClass=c.VeefinAssetClassCode
		Where A.SourceName='Veefin' And C.AssetClassAlt_Key<>1 And A.HomogenizedNpaDt Is Null
		Group By AsOnDate,A.SourceName
		)A

)RF


END
GO