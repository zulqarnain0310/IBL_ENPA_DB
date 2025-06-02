SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

/*****************************************************
CREATED BY  : LIYAQAT
CREATED DATE: 2024-08-20
DESCRIPTION : ECS REVERSE FEED
--DESCRIPTION : FORWARD FEED CRISMAC Checksum Create
*******************************************************/

Create Proc [dbo].[FF_CRISMACChecksumCreate_20241022]
@SourceName varchar (50)
As

DECLARE @TimeKey Int=(select TimeKey from IBL_ENPA_DB.dbo.SysDataMatrix where  CurrentStatus='C')
DECLARE @Ext_Date DATE=(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=@TIMEKEY)
--Declare @SourceName varchar (50)='Veefin'
Declare @SourceAlt_Key varchar (50)=(select SourceAlt_Key from IBL_ENPA_DB.dbo.Dimsourcesystem 
										where SourceName=@SourceName AND EffectiveFromTimeKey<=@TimeKey 
										AND EffectiveToTimeKey>=@TimeKey )
----select @TimeKey,@Ext_Date,@SourceName,@SourceAlt_Key,@date
Begin
	Delete from [dbo].[CheckSumData_FF] where Timekey=@TimeKey and SourceName=@SourceName

Drop table If exists #CheckSumData_FF 

CREATE TABLE  #CheckSumData_FF ( 
	[ProcessDate] [date] NULL,
	[Timekey] [int] NULL,
	[SourceName] [nvarchar](50) NULL,
	[SourceAlt_Key] [int] NULL,
	[DataSet] [varchar](5) NULL,
	[CRISMAC_CheckSum] [varchar](200) NULL,
	[Source_CheckSum] [varchar](200) NULL,
	[Start_BAU] [CHAR] (1) 
)  

Declare @Srcname Varchar (20) =(select  Case when @SourceAlt_Key=40		Then 'Calypso'
										     when @SourceAlt_Key=50		Then 'ECBF'
										     when @SourceAlt_Key=10		Then 'Finacle'
										     when @SourceAlt_Key=70		Then 'Ganaseva'
										     when @SourceAlt_Key=120	Then 'M2P'
										     when @SourceAlt_Key=60		Then 'Prolendz'
										     when @SourceAlt_Key=80		Then 'PTSMART'
										     when @SourceAlt_Key=130	Then 'Securitize'
										     when @SourceAlt_Key=30		Then 'Tradepro'
										     when @SourceAlt_Key=90		Then 'Veefin'
										     when @SourceAlt_Key=100	Then 'Finacle2'
										     when @SourceAlt_Key=20		Then 'VisionPlus' End 
											)

			Declare @DS1 Varchar(100)=(select Dataset1 From [dbo].[DIMSOURCEDATASETDETAIL] 
							where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
			Declare @DS2 Varchar(100)=(select Dataset2 From [dbo].[DIMSOURCEDATASETDETAIL] 
							where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
			Declare @DS3 Varchar(100)=(select Dataset3 From [dbo].[DIMSOURCEDATASETDETAIL] 
							where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
			Declare @DS4 Varchar(100)=(select Dataset4 From [dbo].[DIMSOURCEDATASETDETAIL] 
							where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
			Declare @DS5 Varchar(100)=(select Dataset5 From [dbo].[DIMSOURCEDATASETDETAIL] 
							where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 
			Declare @DS6 Varchar(100)=(select Dataset6 From [dbo].[DIMSOURCEDATASETDETAIL] 
							where SourceAlt_Key=@SourceAlt_Key and EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY) 

								--select @DS1,@DS2,@DS3,@DS4,@DS5,@DS6

		Insert into #CheckSumData_FF 
							 ([ProcessDate], [Timekey],[SourceName],[SourceAlt_Key],[DataSet],[Start_BAU])   
					  Values (@Ext_Date,@TimeKey,@SourceName,@SourceAlt_Key,'DS1','N'),
							 (@Ext_Date,@TimeKey,@SourceName,@SourceAlt_Key,'DS2','N'),
							 (@Ext_Date,@TimeKey,@SourceName,@SourceAlt_Key,'DS3','N'),
							 (@Ext_Date,@TimeKey,@SourceName,@SourceAlt_Key,'DS4','N'),
							 (@Ext_Date,@TimeKey,@SourceName,@SourceAlt_Key,'DS5','N'),
							 (@Ext_Date,@TimeKey,@SourceName,@SourceAlt_Key,'DS6','N')

							 --select * from #CheckSumData_FF

			Declare @Src Varchar(8)=(select UPPER(SUBSTRING(@Srcname,0,4))) 
			Declare @date Varchar(8)=(select Replace((convert(Varchar,@Ext_Date,103)),'/',''))
Print 1
		If @DS1 is not null
			Begin
			Drop Table if exists TempDS1
					Exec ('select Count(1) as count, SUM(PrincOutStd) Total into TempDS1 from '+@DS1)
			Drop Table if exists DS1Date
					Exec ('select Distinct AsOnDate as Date into DS1Date from '+@DS1) 

				Declare @Count1 Varchar(100)=(Select ISNULL(Count,0) from TempDS1)
				Declare @Total1 Varchar(100)=(Select ISNULL(Total,0) from TempDS1)
				Declare @DS1Date Varchar(8)=(select Replace((convert(Varchar,Date,103)),'/','') from DS1Date)
	 
				Update #CheckSumData_FF 
							Set CRISMAC_CheckSum=(Select ISNULL(@DS1Date,'')+@Count1+@Src+@Total1) 
						where DataSet='DS1'
	End

Print 2
		If @DS2 is not null
			Begin
			Drop Table if exists TempDS2
					Exec ('select Count(1) as count into TempDS2 from '+@DS2)

			Drop Table if exists Count_Assetclass
					Exec ('select Count(1) as Total into Count_Assetclass from '+@DS2+' Where SrcAssetClass is Not NULL' ) 
			Drop Table if exists DS2Date
					Exec ('select Distinct AsOnDate as Date into DS2Date from '+@DS2) 
						
							Declare @Count2 Varchar(100)=(Select ISNULL(Count,0) from TempDS2)
							Declare @Total2 Varchar(100)=(Select ISNULL(Total,0) from Count_Assetclass)
				Declare @DS2Date Varchar(8)=(select Replace((convert(Varchar,Date,103)),'/','') from DS2Date)
	 
				Update #CheckSumData_FF 
							Set CRISMAC_CheckSum=(Select ISNULL(@DS2Date,'')+@Count2+@Src+@Total2) 
						where DataSet='DS2' 
			End

Print 3
		If @DS3 is not null
			Begin
			Drop Table if exists TempDS3
					Exec ('select Count(1) as count, SUM(COLL_AMT) Total into TempDS3 from '+@DS3)
			Drop Table if exists DS3Date
					Exec ('select Distinct AS_ON_DATE as Date into DS3Date from '+@DS3) 

							Declare @Count3 Varchar(100)=(Select ISNULL(Count,0) from TempDS3)
							Declare @Total3 Varchar(100)=(Select ISNULL(Total,0) from TempDS3)
				Declare @DS3Date Varchar(8)=(select Replace((convert(Varchar,Date,103)),'/','') from DS3Date)
	 
				Update #CheckSumData_FF 
							Set CRISMAC_CheckSum=(Select ISNULL(@DS3Date,'')+@Count3+@Src+@Total3) 
						where DataSet='DS3'  
			End

Print 4	
		If @DS4 is not null
			Begin
			Drop Table if exists TempDS4
					Exec ('select Count(1) as count, SUM(RESTR_AMT) Total into TempDS4 from '+@DS4)
			Drop Table if exists DS4Date
					Exec ('select Distinct AS_ON_DATE as Date into DS4Date from '+@DS4) 
							Declare @Count4 Varchar(100)=(Select ISNULL(Count,0) from TempDS4)
							Declare @Total4 Varchar(100)=(Select ISNULL(Total,0) from TempDS4)
				Declare @DS4Date Varchar(8)=(select Replace((convert(Varchar,Date,103)),'/','') from DS4Date)
	 	 
				Update #CheckSumData_FF 
					Set CRISMAC_CheckSum=(Select ISNULL(@DS4Date,'')+@Count4+@Src+@Total4) 
						where DataSet='DS4'
			End	
			
			--select * from #CheckSumData_FF
	
Print 5
		If @DS5 is not null
			Begin
			Drop Table if exists TempDS5
					Exec ('select Count(1) as count into TempDS5 from '+@DS5)
								Declare @Count5 Varchar(100)=(Select ISNULL(Count,0) from TempDS5)
			Drop Table if exists DS5Date
					Exec ('select Distinct AS_ON_DATE as Date into DS5Date from '+@DS5)  

				Declare @DS5Date Varchar(8)=(select Replace((convert(Varchar,Date,103)),'/','') from DS5Date)
	 
				Update #CheckSumData_FF 
							Set CRISMAC_CheckSum=(Select ISNULL(@DS5Date,'')+@Count5+@Src) 
						where DataSet='DS5'  
			End

Print 6
		If @DS6 is not null
			Begin
			Drop Table if exists TempDS6
					Exec ('select Count(1) as count into TempDS6 from '+@DS6)
							Declare @Count6 Varchar(100)=(Select ISNULL(Count,0) from TempDS6) 
							
					If @SourceName='PT Smart'
						Begin
								Drop Table if exists DS6Date
								Exec ('select Distinct ASONDATE as Date into DS6Date from '+@DS6)  
								Declare @DS6Date Varchar(8)=(select Replace((convert(Varchar,Date,103)),'/','') from DS6Date)

								Update #CheckSumData_FF 
									Set CRISMAC_CheckSum=(Select ISNULL(@DS6Date,'')+@Count6+@Src) 
								where DataSet='DS6' 
						 End
					If @SourceName<>'PT Smart'
						Begin
								Drop Table if exists DS6Date
								Exec ('select Distinct AS_ON_DATE as Date into DS6Date from '+@DS6)  
								Declare @DS6Date_1 Varchar(8)=(select Replace((convert(Varchar,Date,103)),'/','') from DS6Date)

								Update #CheckSumData_FF 
									Set CRISMAC_CheckSum=(Select ISNULL(@DS6Date_1,'')+@Count6+@Src) 
								where DataSet='DS6' 
						 End  
			End 
			
			 	Update #CheckSumData_FF 
				SET CRISMAC_CheckSum='NOT APPLICABLE' 
				where CRISMAC_CheckSum is null
				
			--select * from #CheckSumData_FF

				Update #CheckSumData_FF 
				SET CRISMAC_CheckSum=0 
				where SUBSTRING(CRISMAC_CheckSum,9,1)=0 and CRISMAC_CheckSum<>'NOT APPLICABLE'

				Delete from #CheckSumData_FF where CRISMAC_CheckSum='NOT APPLICABLE' 
				 
		--select * from #CheckSumData_FF

/**Source checksum insert and check/Set Start_BAU flag  **/
  
				Drop Table if exists #SourceChecksum
				 SELECT * into #SourceChecksum FROM IBL_ENPA_STGDB..HeaderTable 
				 where Source=@Srcname And	AS_ON_DATE=@Ext_Date
  
					Update A 
					SET  Source_CheckSum=b.Source_CheckSum 
					from #CheckSumData_FF a Join #SourceChecksum B 
					on a.DataSet=B.Table_Name
		
					Update A 
					SET  Start_BAU='Y'
					from #CheckSumData_FF A Where CRISMAC_CheckSum=Source_CheckSum
			

							INSERT INTO [dbo].[CheckSumData_FF]
									   ([ProcessDate]
									   ,[Timekey]
									   ,[SourceName]
									   ,[SourceAlt_Key]
									   ,[DataSet]
									   ,[CRISMAC_CheckSum]
									   ,[Source_CheckSum]
									   ,[Start_BAU]
									   ,[Processing_Type]
									   ,[CreatedBy]
									   ,[Datecreated]
									   ,AuthorisationStatus
										,EffectiveFromTimeKey
										,EffectiveToTimeKey)
								 select [ProcessDate]
									   ,[Timekey]
									   ,[SourceName]
									   ,[SourceAlt_Key]
									   ,[DataSet]
									   ,[CRISMAC_CheckSum]
									   ,[Source_CheckSum]
									   ,[Start_BAU]
									   ,'AUTO'
									   ,'D2K'
									   ,Getdate() 
									   ,'A'
									   ,@TimeKey
									   ,@TimeKey
									   from #CheckSumData_FF
 

End
GO