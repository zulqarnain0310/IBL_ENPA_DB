SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Single_Reverse_Feed_PostMOC_20241126](@TimeKey INT,@IS_MOC CHAR(1)='N') 

AS
BEGIN
DECLARE @DATE DATE
select @DATE=Date from dbo.SysDataMatrix  where  TimeKey=@TimeKey 

DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Single_Reverse_Feed_PostMOC' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @DATE,@TimeKey,'Single_Reverse_Feed_PostMOC',GETDATE()

Drop Table if exists ##Moc
Select * into ##Moc from ReverseFeedDetails_MOC   

Drop Table if exists ##Current
Select * into ##Current from ReverseFeedDetails

Drop Table if exists #ReverseFeedDetails
Select Top 0 * into #ReverseFeedDetails from ReverseFeedDetails

Insert into #ReverseFeedDetails
select * from ##Moc where UCIF_ID in (
										select UCIF_ID from ##Moc
										except
										select UCIF_ID from ##Current) 

Insert into #ReverseFeedDetails
select * from ##Current where UCIF_ID in (
											select UCIF_ID from ##Current
											except
											select UCIF_ID from ##Moc)

Insert into #ReverseFeedDetails
select * from ##Moc where UCIF_ID in (
										select UCIF_ID from ##Current
										intersect
										select UCIF_ID from ##Moc) 

 Declare @cnt int=(select isnull(COUNT(1),0) cnt from (select isnull(COUNT(1),0) cnt
					 from #ReverseFeedDetails group by AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo
					 having COUNT(1)>1) a)
  
 IF @cnt=0
		begin 

			Declare @dt varchar(20)=(Select isnull(format(MAX(AsOnDate),'ddMMyyy'),format(CAST(getdate() as date),'ddMMyyy'))
										from  ReverseFeedDetails)
			Declare @FinSqlQuery  Varchar(1000) ='select * into ReverseFeedDetails_BKP_'+@dt+' from ReverseFeedDetails'

			EXEC (@FinSqlQuery)

			 Select 'No Duplicate value Found in temp ReverseFeedDetails'

					Truncate table ReverseFeedDetails
						Insert into ReverseFeedDetails
						select * from #ReverseFeedDetails
 
		end
   ELSE 
		 begin
		 ;with cte
		 as
		 ( select ROW_NUMBER() over (Partition by AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo order by UCIF_ID) RN,
		 AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo
		 from #ReverseFeedDetails )

		 Delete from cte where RN=2

		 Declare @dt1 varchar(20)=(Select isnull(format(MAX(AsOnDate),'ddMMyyy'),format(CAST(getdate() as date),'ddMMyyy')) 
										from  ReverseFeedDetails)

		 Declare @FinSqlQuery1  Varchar(1000) ='select * into ReverseFeedDetails_BKP_'+@dt1+' from ReverseFeedDetails'

		 EXEC (@FinSqlQuery1)

		Select 'Duplicate value Found in temp ReverseFeedDetails'

				Truncate table ReverseFeedDetails
					Insert into ReverseFeedDetails
					select * from #ReverseFeedDetails
		  
		end

		/**** MOC table backup ****/
			Declare @MOCdt varchar(20)=(Select isnull(format(MAX(AsOnDate),'ddMMyyy'),format(CAST(getdate() as date),'ddMMyyy'))
										from  ReverseFeedDetails)
			Declare @MOCSqlQuery  Varchar(1000) ='select * into ReverseFeedDetails_MOCBKP_'+@MOCdt+' from ReverseFeedDetails_MOC'

			EXEC (@MOCSqlQuery)

			Truncate Table ReverseFeedDetails_MOC

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Single_Reverse_Feed_PostMOC' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

END
GO