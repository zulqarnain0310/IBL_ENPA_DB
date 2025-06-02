SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
   
CREATE PROCEDURE [dbo].[AuditAPISelect]  
      @PANNo            VARCHAR(10) = N'',  
      @NCIF_Id         VARCHAR(10) = N'',  
      @TimeKey          INT        = 0  
 AS  
SET NOCOUNT ON 
set statistics time off
--DECLARE  
--    @PANNo            VARCHAR(10) = N'',--CCKPR3153B  
--    @NCIF_Id     VARCHAR(10) = N'66339021',--10001967  
--    @TimeKey    INT               = 26084  

BEGIN  
      SET @TimeKey=27231 ----(Select TimeKey From SysDataMatrix WHERE CurrentStatus='C')  
      PRINT @TimeKey  
  
      SET DATEFORMAT DMY;  
  
   IF OBJECT_ID('Tempdb..#TempAuditPAN') IS NOT NULL  
        DROP TABLE #TempAuditPAN  
 CREATE TABLE [dbo].[#TempAuditPAN](  
 [CountPAN] [bigint] NULL,  
 PAN   [varchar](100) NULL, 
 [NCIF_Id] [varchar](100) NULL,  
 [SourceName] [varchar](50) NULL,  
 [CustomerId] [varchar](20) NULL,  
 [CustomerACID] [varchar](20) NULL,  
 [CustomerName] [varchar](500) NULL,  
 [ARCFLAG] [varchar](1) NULL,  
 [IsRestructured] [varchar](1) NULL,  
 [OTS] [varchar](1) NULL,  
 [fraud] [varchar](1) NULL,  
 [WriteOffFlag] [varchar](1) NULL,  
 [ARC_SaleDate] [varchar](10) NULL,  
 [Writeoffdate] [varchar](10) NULL,  
 [RestructureDt] [varchar](10) NULL,  
 [PrincipleOutstanding] [decimal](16, 2) NOT NULL,  
 [Balance] [decimal](16, 2) NOT NULL,  
 [Segment] [varchar](100) NULL,  
 [ProductCode] [varchar](50) NULL,  
 [FacilityType] [varchar](10) NULL,  
 [AC_NPA_Date] [varchar](10) NULL,  
 [NCIF_AssetClassAlt_Key] [smallint] NULL,  
 [NCIF_NPA_Date] [varchar](10) NULL,  
 [Status] [varchar](3) NOT NULL,  
 [MaxDPD] [int] NULL,  
 IsSuitFiled [varchar](1) NULL -- Added on 28/12/2022 , as per requirement of Bank   
 ) ON [PRIMARY]  
  
  
	If len(isnull(@PANNo,''))= 0 and len(isnull(@NCIF_Id,''))=0
      begin
            select 'Please Provide Atleast One Value...Either PanNo or NCIF_Id' As Remark
                        INSERT INTO Log_APIAudit    
                  (
                         PAN
                        ,NCIF_Id
                        ,RecordCount --- AADHAR ,VOTERID TABLE COLUMN ADDITION AND SELECT INSERTION
						,AADHAR
						,VOTERID
                        ,Date
                        ,Time
                        ,Remark
                  )
                  SELECT
                        @PANNO AS PANNO,
                        @NCIF_Id as NCIF_Id,
                        0 AS RecordCount,
                        NULL,
						NULL,
                        CAST(GETDATE() AS DATE) AS DATECUR,
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
                        --CAST(GETDATE() AS TIME) AS TIMECUR,
                        'Please Provide Atleast One Value...Either PanNo or NCIF_Id or Aadhar or VoterId' AS Remark
      end
      
 else

    begin
  
      if len(isnull(@PANNo,''))>0 and len(isnull(@NCIF_Id,''))>0  
      begin  
            select 'Please Provide Only One Value...Either PanNo or NCIF_Id' As Remark  
                        INSERT INTO Log_APIAudit  
                  (  
                          PAN  
                         ,NCIF_Id  
                        ,RecordCount  
                        ,Date  
                        ,Time  
                        ,Remark  
                  )  
                  SELECT  
                        @PANNO AS PANNO,  
                        @NCIF_Id as NCIF_Id,  
                        0 AS RecordCount,  
                        CAST(GETDATE() AS DATE) AS DATECUR,  
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                        --CAST(GETDATE() AS TIME) AS TIMECUR,  
                        'Wrong Value Entered' AS Remark  
      end  
        
      else  
  
      begin  

   if len(isnull(@PANNo,''))>0  
            begin  
   Drop Table if exists #NPA_IntegrationDetails_Curnt_pan  
            SELECT NCIF_Id,CustomerId,CustomerACID,CustomerName,  
   IsARC_Sale,IsRestructured,IsOTS,IsFraud,IsTWO,ARC_SaleDate,WriteOffDate,PrincipleOutstanding,Balance,Segment,ProductCode,  
   FacilityType,AC_NPA_Date,NCIF_NPA_Date,NCIF_AssetClassAlt_Key,MaxDPD,IsSuitFiled,PAN,SrcSysAlt_Key,EffectiveFromTimeKey,EffectiveToTimeKey  
   INTO #NPA_IntegrationDetails_Curnt_pan FROM NPA_IntegrationDetails_Curnt(nolock) WHERE PAN=@PANNo    
   --and (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey ) 
  
  
   --CREATE CLUSTERED INDEX IDX_NPA_IntegrationDetails_Curnt_pan ON #NPA_IntegrationDetails_Curnt_pan(NCIF_ID,CustomerACID)  
   DROP TABLE IF EXISTS #AdvAcRestructureDetail_Pan  
  
   Select RestructureDt,RefSystemAcId,EffectiveFromTimeKey,EffectiveToTimeKey into #AdvAcRestructureDetail_Pan    
   from CURDAT.AdvAcRestructureDetail_Curnt (nolock)  
   where --(EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey ) AND
   RefSystemAcId in (Select CustomerACID from #NPA_IntegrationDetails_Curnt_pan ) 
  
   --CREATE CLUSTERED INDEX IDX_NPA_IntegrationDetails_NCIF ON #AdvAcRestructureDetail_Pan(RefSystemAcId)  
  
   insert into #TempAuditPAN  
            SELECT  
                   ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS CountPAN  
                  ,a.PAN
                  ,A.NCIF_Id  
                  ,D.SourceName AS SourceName  
                  ,A.CustomerId  
                  ,A.CustomerACID  
                  ,A.CustomerName  
                  --,A.NCIF_AssetClassAlt_Key  
                  ,A.IsARC_Sale AS ARCFLAG  
                  ,A.IsRestructured AS IsRestructured  
                  ,A.IsOTS AS OTS  
                  ,A.IsFraud AS fraud  
                  ,A.IsTWO AS WriteOffFlag  
                  ,CONVERT(VARCHAR(10),A.ARC_SaleDate,103) AS ARC_SaleDate  
                  ,CONVERT(VARCHAR(10),A.WriteOffDate,103) AS Writeoffdate  
                  ,CONVERT(VARCHAR(10),C.RestructureDt,103) AS RestructureDt  
                  ,ISNULL(A.PrincipleOutstanding,0.00) AS PrincipleOutstanding  
                  ,ISNULL(A.Balance,0.00) AS Balance  
                  ,A.Segment  
                  ,A.ProductCode  
                  ,A.FacilityType  
                  ,CONVERT(VARCHAR(10),A.AC_NPA_Date,103) AS AC_NPA_Date  
                  ,A.NCIF_AssetClassAlt_Key  
                  ,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103) AS NCIF_NPA_Date  
                  ,CASE WHEN A.NCIF_AssetClassAlt_Key=1 THEN 'STD' ELSE 'NPA' END AS Status  
                  ,A.MaxDPD  
      ,A.IsSuitFiled -- Added on 28/12/2022 , as per requirement of Bank   
            --INTO #TempAuditPAN  
            FROM #NPA_IntegrationDetails_Curnt_pan A  
            LEFT JOIN #AdvAcRestructureDetail_Pan C  
            ON A.CustomerACID=C.RefSystemAcId     
            LEFT JOIN DimSourceSystem D  
            ON A.SrcSysAlt_Key=D.SourceAlt_Key          
            --AND (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)  
             
   end  
   else  
     
  
   if len(isnull(@NCIF_Id,''))>0  
        begin  
  
            Drop Table if exists #NPA_IntegrationDetails_Curnt_NCIF  
            SELECT NCIF_Id,CustomerId,CustomerACID,CustomerName,  
   IsARC_Sale,IsRestructured,IsOTS,IsFraud,IsTWO,ARC_SaleDate,WriteOffDate,PrincipleOutstanding,Balance,Segment,ProductCode,  
   FacilityType,AC_NPA_Date,NCIF_NPA_Date,NCIF_AssetClassAlt_Key,MaxDPD,IsSuitFiled,PAN,SrcSysAlt_Key,EffectiveFromTimeKey,EffectiveToTimeKey  
   INTO #NPA_IntegrationDetails_Curnt_NCIF FROM NPA_IntegrationDetails_Curnt(nolock) WHERE NCIF_Id=@NCIF_Id  
   --and (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey ) 
  
   --CREATE CLUSTERED INDEX IDX_NPA_IntegrationDetails_Curnt_NCIF ON #NPA_IntegrationDetails_Curnt_NCIF(NCIF_ID,CustomerACID)  
   DROP TABLE IF EXISTS #AdvAcRestructureDetail_nCIF  
  
   Select RestructureDt,RefSystemAcId,EffectiveFromTimeKey,EffectiveToTimeKey into #AdvAcRestructureDetail_NCIF  
   from CURDAT.AdvAcRestructureDetail_Curnt(nolock)  
   where RefSystemAcId in (Select CustomerACID from #NPA_IntegrationDetails_Curnt_NCIF )  
  -- and (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey )  
  
   --CREATE CLUSTERED INDEX IDX_NPA_IntegrationDetails_NCIF ON #AdvAcRestructureDetail_nCIF(RefSystemAcId)  
  
   insert into #TempAuditPAN  
            SELECT  
                   ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS CountPAN  
                  ,a.PAN
                  ,A.NCIF_Id  
                  ,D.SourceName AS SourceName  
                  ,A.CustomerId  
                  ,A.CustomerACID  
                  ,A.CustomerName  
                  --,A.NCIF_AssetClassAlt_Key  
                  ,A.IsARC_Sale AS ARCFLAG  
                  ,A.IsRestructured AS IsRestructured  
                  ,A.IsOTS AS OTS  
                  ,A.IsFraud AS fraud  
                  ,A.IsTWO AS WriteOffFlag  
                  ,CONVERT(VARCHAR(10),A.ARC_SaleDate,103) AS ARC_SaleDate  
                  ,CONVERT(VARCHAR(10),A.WriteOffDate,103) AS Writeoffdate  
                  ,CONVERT(VARCHAR(10),C.RestructureDt,103) AS RestructureDt  
                  ,ISNULL(A.PrincipleOutstanding,0.00) AS PrincipleOutstanding  
                  ,ISNULL(A.Balance,0.00) AS Balance  
                  ,A.Segment  
                  ,A.ProductCode  
                  ,A.FacilityType  
                  ,CONVERT(VARCHAR(10),A.AC_NPA_Date,103) AS AC_NPA_Date  
                  ,A.NCIF_AssetClassAlt_Key  
                  ,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103) AS NCIF_NPA_Date  
                  ,CASE WHEN A.NCIF_AssetClassAlt_Key=1 THEN 'STD' ELSE 'NPA' END AS Status  
                  ,A.MaxDPD  
      ,A.IsSuitFiled -- Added on 28/12/2022 , as per requirement of Bank   
            --INTO #TempAuditPAN  
            FROM #NPA_IntegrationDetails_Curnt_NCIF A  
            LEFT JOIN #AdvAcRestructureDetail_nCIF C  
            ON A.CustomerACID=C.RefSystemAcId  
            LEFT JOIN DimSourceSystem D  
            ON A.SrcSysAlt_Key=D.SourceAlt_Key          
            --AND (D.EffectiveFromTimeKey<=@TimeKey and D.EffectiveToTimeKey>=@TimeKey ) 
           end  
            --SELECT * FROM #TempAuditPAN  
            DECLARE @CountPAN INT=(SELECT COUNT(*) FROM #TempAuditPAN)  
  
     IF (@CountPAN>0)  
            begin  
                  SELECT * FROM #TempAuditPAN  
                  INSERT INTO Log_APIAudit  
                  (  
                         PAN  
                        ,NCIF_Id  
                        ,RecordCount  
                        ,Date  
                        ,Time  
                        ,Remark  
                  )  
                  SELECT  
                        @PANNO AS PANNO,  
                        @NCIF_Id as NCIF_Id,  
                        @CountPAN AS RecordCount,  
                        CAST(GETDATE() AS DATE) AS DATECUR,  
                        --CAST(GETDATE() AS TIME) AS TIMECUR  
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR  
                        ,'Successful' as Remark  
            END  
   
     IF (@CountPAN=0)  
            begin  
					Drop table if exists #ucicdata2
					Create Table #ucicdata2 ( UCIC VARCHAR(50) NULL)
					 CREATE INDEX Idx_UCIC on #ucicdata2(UCIC)
							 IF len(isnull(@PANNo,''))<> 0 And len(isnull(@NCIF_Id,''))=0

							 IF len(isnull(@PANNo,''))<> 0 And len(isnull(@NCIF_Id,''))=0
									  begin
												Insert into #ucicdata2 ( UCIC)
												SELECT Distinct UCIC FROM D2K_AADHAR_VOTER_ALL_NEW1 where PAN=@PANNo

											SET @NCIF_Id=(select Top 1 UCIC from #ucicdata2)
									  End  

			DROP  TABLE  IF exists #CoBo_Check
				   select NCIFID_COBORROWER,NCIFID_PrimaryAccount,AcDegDate,AcDegFlg
				   into #CoBo_Check from  dbo.CoBorrowerData_curnt (nolock) where NCIFID_COBORROWER in (@NCIF_Id) OR NCIFID_COBORROWER in  (select UCIC from #ucicdata2)

			IF len(isnull(@NCIF_Id,''))>0 AND  Exists (select 1 from  #CoBo_Check)
			 
					BEGIN

					/* 2025 liyaqat code
								Drop Table If Exists #Cobodata
									select distinct a.NCIFID_COBORROWER,a.AcDegDate,a.AcDegFlg
									into #Cobodata from dbo.CoBorrowerData_curnt_API(nolock) a 
										Inner Join NPA_IntegrationDetails_Curnt(nolock) c on a.NCIFID_PrimaryAccount=c.NCIF_Id
										Left Join NPA_IntegrationDetails_Curnt(nolock) b 
										on a.NCIFID_COBORROWER=b.NCIF_Id  where (a.NCIFID_COBORROWER=@NCIF_Id OR NCIFID_COBORROWER in (select UCIC from #ucicdata2))
										 and b.NCIF_Id is null ---and a.AcDegFlg='Y'

*/

						/* satish Added code 2025 */				 
						Drop table if exists #NCIF_NIdata
								select distinct NCIF_Id into #NCIF_NIdata from NPA_IntegrationDetails_Curnt
								where NCIF_Id in 
								(select NCIFID_PrimaryAccount from #CoBo_Check union
									select NCIFID_COBORROWER from #CoBo_Check)
								
							
								Drop Table If Exists #Cobodata
									select distinct a.*
									into #Cobodata from #CoBo_Check a 
										Inner Join #NCIF_NIdata c on a.NCIFID_PrimaryAccount=c.NCIF_Id
										Left Join #NCIF_NIdata b  on a.NCIFID_COBORROWER=b.NCIF_Id  
										 and b.NCIF_Id is null ---and a.AcDegFlg='Y'

							--select * from #Cobodata 

								 				 SELECT 
                  										ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS CountPAN  
                  										,@PANNo  as PAN
														,A.NCIFID_COBORROWER  as NCIF_Id
                  										,NULL as SourceName  
                  										,NULL as CustomerId  
                  										,NULL as CustomerACID  
                  										,NULL as CustomerName  
                  										--,A.NCIF_AssetClassAlt_Key  
                  										,NULL as ARCFLAG  
                  										,NULL as IsRestructured  
                  										,NULL as OTS  
                  										,NULL as fraud  
                  										,NULL as WriteOffFlag  
                  										,NULL as ARC_SaleDate  
                  										,NULL as Writeoffdate  
                  										,NULL as RestructureDt  
                  										,NULL as PrincipleOutstanding  
                  										,NULL as Balance  
                  										,NULL as Segment  
                  										,NULL as ProductCode  
                  										,NULL as FacilityType  
                  										,NULL as AC_NPA_Date  
                  										,NULL as NCIF_AssetClassAlt_Key  
                  										,CONVERT(VARCHAR(10),A.AcDegDate,103) AS NCIF_NPA_Date  
                  										,CASE WHEN ISNULL(A.AcDegFlg,'N')='N' THEN 'STD' ELSE 'NPA' END AS Status  
                  										,NULL as MaxDPD  
														,NULL as IsSuitFiled 
            									FROM #Cobodata A
									 
									INSERT INTO Log_APIAudit  
                  							(  
                        					 PAN  
                        					,NCIF_Id  
                        					,RecordCount  
                        					,Date  
                        					,Time  
                        					,Remark  
                  							  )  
                  							  SELECT  
                        							@PANNO AS PANNO,  
                                    							@NCIF_Id as NCIF_Id,  
                        							@CountPAN AS RecordCount,  
                        							CAST(GETDATE() AS DATE) AS DATECUR,  
                        							CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                        							--CAST(GETDATE() AS TIME) AS TIMECUR,  
                        							'Successful' AS Remark 
								end
				Else
				Begin
                  SELECt 'No Record Available for PAN / NCIF_Id ' +  isnull(@PANNo,'') + isnull(@NCIF_Id,'') AS Remark  
                  INSERT INTO Log_APIAudit  
                  (  
                         PAN  
                        ,NCIF_Id  
                        ,RecordCount  
                        ,Date  
                        ,Time  
                        ,Remark  
                  )  
                  SELECT  
                        @PANNO AS PANNO,  
                                    @NCIF_Id as NCIF_Id,  
                        @CountPAN AS RecordCount,  
                        CAST(GETDATE() AS DATE) AS DATECUR,  
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                        --CAST(GETDATE() AS TIME) AS TIMECUR,  
                        'No Record Available for PAN / NCIF_Id' AS Remark 
				 end
              end
 
	end 
 end

DROP TABLE IF EXISTS #TempAuditPAN
DROP TABLE IF EXISTS #AdvAcRestructureDetail_Pan
DROP TABLE IF EXISTS #AdvAcRestructureDetail_NCIF
DROP TABLE IF EXISTS #CoBo_Check
DROP TABLE IF EXISTS #ucicdata2
DROP TABLE IF EXISTS #NPA_IntegrationDetails_Curnt_Pan
DROP TABLE IF EXISTS #NPA_IntegrationDetails_Curnt_NCIF
DROP TABLE IF EXISTS #CoBo_Check
DROP TABLE IF EXISTS #NCIF_NIdata
DROP TABLE IF EXISTS #Cobodata 

End
GO