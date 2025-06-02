SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*************************************************************
CREATED BY  : LIYAQAT
CREATED DATE: 2024-08-31
DESCRIPTION : REVERSE FEED CRISMAC Checksum Create
**************************************************************/

CREATE Proc [dbo].[RF_CRISMACChecksumCreate]
@SourceName varchar (50)
As

DECLARE @TimeKey Int= (select TimeKey from IBL_ENPA_DB.dbo.SysDataMatrix where  CurrentStatus='C')
DECLARE @Ext_Date DATE=(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=@TIMEKEY)
--Declare @SourceName varchar (50)='Finacle-2'
Declare @SourceAlt_Key varchar (50)=(select SourceAlt_Key from IBL_ENPA_DB.dbo.Dimsourcesystem 
										where SourceName=@SourceName AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey )
DECLARE @MOCDate DATE=(SELECT DISTINCT CAST(DATEADD(MONTH, DATEDIFF(MONTH, -1, 
								(SELECT DATE FROM SYSDATAMATRIX WHERE Timekey=@Timekey))-1, -1) AS date) FROM SysDataMatrix  )
DECLARE @MOCTimekey INT = (SELECT MAX(TIMEKEY) FROM SysDataMatrix WHERE MonthLastDate=@MOCDate)--26267

--Select @TimeKey,@Ext_Date,@MOCDate,@MOCTimekey

Begin

	Delete from [dbo].[CheckSumData_RF] where Timekey=@TimeKey and SourceName=@SourceName

			Drop table If exists #CheckSumData_RF 

			CREATE TABLE  #CheckSumData_RF ( 
				[AS_ON_DATE] [date] NULL,
				[Timekey] [int] NULL,
				[SourceName] [nvarchar](50) NULL,
				[SourceAlt_Key] [int] NULL,
				[RecordCount] [varchar](5) NULL,
				[RF_Type] [varchar](10) NULL,
				[CRISMAC_CheckSum] [varchar](100) NULL 
			)  
			 
			Insert into #CheckSumData_RF
				Values( @Ext_Date ,@TimeKey ,@SourceName ,case when @SourceName='Finacle-2' then 100 
						 else @SourceAlt_Key  end
						,NULL ,'DAILY' ,NULL) 

		Drop table if exists #RFCount
			select AsOnDate,SourceName,HomogenizedAssetClass ,COUNT(1) Count 
				into #RFCount from ReverseFeedDetails  
				where SourceName=@SourceName and AsOnDate=@Ext_Date
				group by  AsOnDate,SourceName,HomogenizedAssetClass 

				--select * from #RFCount

		Declare @STD Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
			where  HomogenizedAssetClass like '%1%' OR HomogenizedAssetClass like '%STD%')
		Declare @SUB Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
			where  HomogenizedAssetClass like '%2%' OR HomogenizedAssetClass like '%SUB%')
		Declare @DB1 Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
			where  HomogenizedAssetClass like '%3%' OR HomogenizedAssetClass like '%DBT%')
		Declare @DB2 Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
			where  HomogenizedAssetClass like '%4%')
		Declare @DB3 Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
			where  HomogenizedAssetClass like '%5%')
		Declare @LOS Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
			where  HomogenizedAssetClass like '%6%')
		Declare @Wrt Varchar(10) 
		Set @Wrt=Case when @SourceAlt_Key='80' Then (select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
														where HomogenizedAssetClass like '%9%') 
							Else (select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount 
									where HomogenizedAssetClass like '%7%')  End
				
    --select  @STD,@SUB,@DB1,@DB2,@DB3,@LOS,@Wrt 
	
	Declare @TotalCount Varchar(10)=(select cast(ISNULL(SUM(Count),0) as Varchar(20)) from #RFCount)
	Declare @Count Varchar(80)=
	(select ISNULL(@STD,'0')+'_'+ISNULL(@SUB,'0')+'_'+ISNULL(@DB1,'0')+'_'+ISNULL(@DB2,'0')+'_'+ISNULL(@DB3,'0')+'_'+ISNULL(@LOS,'0')+'_'+ISNULL(@Wrt,'0') )

	--select @TotalCount,@Count
	Declare @Srcname Varchar (20) =(select  Case when @SourceName='Calypso'	Then 'Calypso'
												 when @SourceName='ECBF'	Then 'ECBF'
												 when @SourceName='Finacle'	Then 'Finacle'
												 when @SourceName='Ganaseva'	Then 'Ganaseva'
												 when @SourceName='M2P'			Then 'M2P'
												 when @SourceName='Prolendz'	Then 'Prolendz'
												 when @SourceName='PT SMART'	Then 'PTSMART'
												 when @SourceName='Securitize'	Then 'Securitize'
												 when @SourceName='Tradepro'	Then 'Tradepro'
												 when @SourceName='Veefin'		Then 'Veefin'
												 when @SourceName='Finacle-2'	Then 'Finacle-2'
												 when @SourceName='Vision Plus'	Then 'Vision Plus' End 
												)											 
			--Declare @Src Varchar(8)=(select UPPER(SUBSTRING(@Srcname,0,4)))
			Declare @Src Varchar(8)=(select Case When @Srcname='Finacle-2' Then 'FI2' Else UPPER(SUBSTRING(@Srcname,0,4))End )  -- Added by Liyaqat on 20241108
			Declare @date Varchar(8)=(select Replace((convert(Varchar,@Ext_Date,103)),'/','')) 
			
 
				Update #CheckSumData_RF 
							Set CRISMAC_CheckSum=(Select @date+@TotalCount+@Src+@Count)
							    ,RecordCount=@TotalCount
								Where RF_Type='DAILY'

Print @MOCDate
Print @MOCTimekey

IF Exists (Select top 1 1 from ReverseFeedDetails where AsOnDate=@MOCDate And SourceName=@SourceName)
		Begin

			Insert into #CheckSumData_RF
				Values ( @MOCDate ,@MOCTimekey ,@SourceName 
						,case when @SourceName='Finacle-2' then 100 
								else @SourceAlt_Key  end
						,NULL ,'MOC' ,NULL)

				Drop table if exists #RFCount_MOC
					select AsOnDate,SourceName,HomogenizedAssetClass ,COUNT(1) Count 
						into #RFCount_MOC from ReverseFeedDetails  
						where SourceName=@SourceName and AsOnDate=@MOCDate
						group by  AsOnDate,SourceName,HomogenizedAssetClass 

						--select * from #RFCount

				Declare @STD_MOC Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
					where  HomogenizedAssetClass like '%1%' OR HomogenizedAssetClass like '%STD%')
				Declare @SUB_MOC Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
					where  HomogenizedAssetClass like '%2%' OR HomogenizedAssetClass like '%SUB%')
				Declare @DB1_MOC Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
					where  HomogenizedAssetClass like '%3%' OR HomogenizedAssetClass like '%DBT%')
				Declare @DB2_MOC Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
					where  HomogenizedAssetClass like '%4%')
				Declare @DB3_MOC Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
					where  HomogenizedAssetClass like '%5%')
				Declare @LOS_MOC Varchar(10)=(select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
					where  HomogenizedAssetClass like '%6%')
				Declare @Wrt_MOC Varchar(10) 
				Set @Wrt_MOC=Case when @SourceAlt_Key='80' Then (select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
																where HomogenizedAssetClass like '%9%') 
									Else (select cast(ISNULL(Count,0) as Varchar(20)) from #RFCount_MOC 
											where HomogenizedAssetClass like '%7%')  End
				
			--select  @STD,@SUB,@DB1,@DB2,@DB3,@LOS,@Wrt 
	
			Declare @TotalCount_MOC Varchar(10)=(select cast(ISNULL(SUM(Count),0) as Varchar(20)) from #RFCount_MOC)
			Declare @Count_MOC Varchar(80)=
			(select ISNULL(@STD_MOC,'0')+'_'+ISNULL(@SUB_MOC,'0')+'_'+ISNULL(@DB1_MOC,'0')+'_'+ISNULL(@DB2_MOC,'0')+'_'+ISNULL(@DB3_MOC,'0')+'_'+ISNULL(@LOS_MOC,'0')+'_'+ISNULL(@Wrt_MOC,'0') )

			--select @TotalCount,@Count
			Declare @Srcname_MOC Varchar (20) =(select  Case when @SourceName='Calypso'	Then 'Calypso'
															when @SourceName='ECBF'	Then 'ECBF'
															when @SourceName='Finacle'	Then 'Finacle'
															when @SourceName='Ganaseva'	Then 'Ganaseva'
															when @SourceName='M2P'			Then 'M2P'
															when @SourceName='Prolendz'	Then 'Prolendz'
															when @SourceName='PT SMART'	Then 'PTSMART'
															when @SourceName='Securitize'	Then 'Securitize'
															when @SourceName='Tradepro'	Then 'Tradepro'
															when @SourceName='Veefin'		Then 'Veefin'
															when @SourceName='Finacle-2'	Then 'Finacle-2'
															when @SourceName='Vision Plus'	Then 'Vision Plus' End 
														)											 
					--Declare @Src_MOC Varchar(8)=(select UPPER(SUBSTRING(@Srcname_MOC,0,4)))  
			Declare @Src_MOC Varchar(8)=(select Case When @Srcname_MOC='Finacle-2' Then 'FI2' Else UPPER(SUBSTRING(@Srcname_MOC,0,4))End ) -- Added by Liyaqat on 20241108
					Declare @date_MOC Varchar(8)=(select Replace((convert(Varchar,@MOCDate,103)),'/','')) 
			
 
						Update #CheckSumData_RF 
									Set CRISMAC_CheckSum=(Select @date_MOC+@TotalCount_MOC+@Src_MOC+@Count_MOC)
										,RecordCount=@TotalCount_MOC
										Where RF_Type='MOC'

		End


	 --select * from #CheckSumData_RF

				Update #CheckSumData_RF 
				SET CRISMAC_CheckSum='NOT APPLICABLE' 
				where CRISMAC_CheckSum is null OR CRISMAC_CheckSum='0'

				Update #CheckSumData_RF 
				SET CRISMAC_CheckSum=0 
				where SUBSTRING(CRISMAC_CheckSum,9,1)=0 and CRISMAC_CheckSum<>'NOT APPLICABLE'

				Delete from #CheckSumData_RF where CRISMAC_CheckSum='NOT APPLICABLE' 
				 
		--select * from #CheckSumData_FF
				 
							INSERT INTO [dbo].[CheckSumData_RF]
									   (AS_ON_DATE
										,Timekey
										,SourceName
										,SourceAlt_Key
										,RecordCount
										,RF_Type
										,CRISMAC_CheckSum
										,Datecreated)

								 select AS_ON_DATE
										,@TimeKey
										,SourceName
										,SourceAlt_Key
										,RecordCount
										,RF_Type
										,CRISMAC_CheckSum 
									   ,Getdate() from #CheckSumData_RF
 
				--select * from [dbo].[CheckSumData_RF]

End
GO