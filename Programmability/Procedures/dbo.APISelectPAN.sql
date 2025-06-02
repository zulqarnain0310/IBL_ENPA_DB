SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
  
CREATE PROCEDURE [dbo].[APISelectPAN]-- '1234567890,2234567890,3234567890,4234567890,5234567890,6234567890,7234567890,8234567890,9234567890,1023456789'
      @PANNo_input            VARCHAR(max) ,
		--@NCIF_Id              VARCHAR(10) ,        
      @TimeKey                INT        = 0

  
AS  
--DECLARE  
--    @PANNo            VARCHAR(10) = N'',--CCKPR3153B  
--    @NCIF_Id     VARCHAR(10) = N'',--10001967  
--    @TimeKey    INT               = 26084  
  
BEGIN  
declare @NCIF_Id              VARCHAR(10) =''
      SET @TimeKey=(Select TimeKey From SysDataMatrix WHERE CurrentStatus='C')  
      PRINT @TimeKey  
  
      SET DATEFORMAT DMY;  
  
IF OBJECT_ID('Tempdb..#input_pan_table') IS NOT NULL
        DROP TABLE #input_pan_table
select items as panno into #input_pan_table
from Split(@PANNo_input,',')
--select * from #input_pan_table
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
  
  
if (select count(panno) from #input_pan_table where panno is not null)>0 and len(isnull(@NCIF_Id,''))<>0
      begin  
            select 'Please Provide Only One Value...Either PanNo or NCIF_Id' As Remark  
                        INSERT INTO Log_APIAudit  
                  (  
                          PAN  
                         --,NCIF_Id  
                        ,RecordCount  
                        ,Date  
                        ,Time  
                        ,Remark  
                  )  
                  SELECT  
                        @PANNo_input AS PANNO,
                        --@NCIF_Id as NCIF_Id,  
                        0 AS RecordCount,  
                        CAST(GETDATE() AS DATE) AS DATECUR,  
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                        --CAST(GETDATE() AS TIME) AS TIMECUR,  
                        'Wrong Value Entered' AS Remark  
      end  
        
      else  
  
      begin  
      DECLARE @CountPack INT=(SELECT COUNT(*) FROM IBL_ENPA_STGDB.dbo.Package_Audit(nolock) WHERE CAST(ExecutionStartTime AS DATE)=CAST(GETDATE() AS DATE))  
      IF (@CountPack=0 OR @CountPack=21)  
      BEGIN  
  print'Shakti'  
             
  
   	if (select count(panno) from #input_pan_table where panno is not null)>0
            begin  
   Drop Table if exists #NPA_IntegrationDetails_Curnt_pan  
            SELECT NCIF_Id,CustomerId,CustomerACID,CustomerName,  
   IsARC_Sale,IsRestructured,IsOTS,IsFraud,IsTWO,ARC_SaleDate,WriteOffDate,PrincipleOutstanding,Balance,Segment,ProductCode,  
   FacilityType,AC_NPA_Date,NCIF_NPA_Date,NCIF_AssetClassAlt_Key,MaxDPD,IsSuitFiled,PAN,SrcSysAlt_Key,EffectiveFromTimeKey,EffectiveToTimeKey  
   INTO #NPA_IntegrationDetails_Curnt_pan FROM NPA_IntegrationDetails(nolock) WHERE PAN IN (SELECT PANNO FROM #input_pan_table)
   --and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey  
  
  
   --CREATE CLUSTERED INDEX IDX_NPA_IntegrationDetails_Curnt_pan ON #NPA_IntegrationDetails_Curnt_pan(NCIF_ID,CustomerACID)  
   DROP TABLE IF EXISTS #AdvAcRestructureDetail_Pan  
  
   Select RestructureDt,RefSystemAcId,EffectiveFromTimeKey,EffectiveToTimeKey into #AdvAcRestructureDetail_Pan    
   from CURDAT.AdvAcRestructureDetail(nolock)  
   where RefSystemAcId in (Select CustomerACID from #NPA_IntegrationDetails_Curnt_pan )  
   --and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey  
  
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
            --AND (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)  
            LEFT JOIN DimSourceSystem D  
            ON A.SrcSysAlt_Key=D.SourceAlt_Key          
            --AND (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)  
             
   end  
   /*else  
     
  
   if len(isnull(@NCIF_Id,''))>0  
        begin  
  
            Drop Table if exists #NPA_IntegrationDetails_Curnt_NCIF  
            SELECT NCIF_Id,CustomerId,CustomerACID,CustomerName,  
   IsARC_Sale,IsRestructured,IsOTS,IsFraud,IsTWO,ARC_SaleDate,WriteOffDate,PrincipleOutstanding,Balance,Segment,ProductCode,  
   FacilityType,AC_NPA_Date,NCIF_NPA_Date,NCIF_AssetClassAlt_Key,MaxDPD,IsSuitFiled,PAN,SrcSysAlt_Key,EffectiveFromTimeKey,EffectiveToTimeKey  
   INTO #NPA_IntegrationDetails_Curnt_NCIF FROM NPA_IntegrationDetails(nolock) WHERE NCIF_Id=@NCIF_Id  
   --and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey  
  
   --CREATE CLUSTERED INDEX IDX_NPA_IntegrationDetails_Curnt_NCIF ON #NPA_IntegrationDetails_Curnt_NCIF(NCIF_ID,CustomerACID)  
   DROP TABLE IF EXISTS #AdvAcRestructureDetail_nCIF  
  
   Select RestructureDt,RefSystemAcId,EffectiveFromTimeKey,EffectiveToTimeKey into #AdvAcRestructureDetail_NCIF  from CURDAT.AdvAcRestructureDetail(nolock)  
   where RefSystemAcId in (Select CustomerACID from #NPA_IntegrationDetails_Curnt_NCIF )  
   --and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey  
  
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
             
           end  
            */--SELECT * FROM #TempAuditPAN  
            DECLARE @CountPAN INT=(SELECT COUNT(*) FROM #TempAuditPAN)  
  
            IF (@CountPAN>0)  
            BEGIN  
                  SELECT * FROM #TempAuditPAN  
                  INSERT INTO Log_APIAudit  
                  (  
                         PAN  
  --                      ,NCIF_Id  
                        ,RecordCount  
                        ,Date  
                        ,Time  
                        ,Remark  
                  )  
                  SELECT  
                        @PANNo_input  AS PANNO,  
    --                    @NCIF_Id as NCIF_Id,  
                        @CountPAN AS RecordCount,  
                        CAST(GETDATE() AS DATE) AS DATECUR,  
                        --CAST(GETDATE() AS TIME) AS TIMECUR  
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR  
                        ,'Successful' as Remark  
            END  
  
            IF (@CountPAN=0)  
            BEGIN  
                  SELECT 'Number of Record Available for PAN ' + cast(@CountPAN as varchar(10)) AS Remark
                  INSERT INTO Log_APIAudit  
                  (  
                         PAN  
                      --  ,NCIF_Id  
                        ,RecordCount  
                        ,Date  
                        ,Time  
                        ,Remark  
                  )  
                  SELECT  
                        @PANNo_input AS PANNO,  
                                    @NCIF_Id as NCIF_Id,  
                        --@CountPAN AS RecordCount,  
                        CAST(GETDATE() AS DATE) AS DATECUR,  
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                        --CAST(GETDATE() AS TIME) AS TIMECUR,  
                        'No Record Available for PAN ' AS Remark  
            END  
      END  
      ELSE  
      BEGIN  
            SELECT 'Execution Process is Running Yet. Please Try After SomeTime' AS Remark  
            INSERT INTO Log_APIAudit  
                  (  
                         PAN  
                       -- ,NCIF_Id  
                        ,RecordCount  
                        ,Date  
                        ,Time  
                        ,Remark  
                  )  
                  SELECT  
                        @PANNo_input AS PANNO,  
                                    @NCIF_Id as NCIF_Id,  
                        --@CountPAN AS RecordCount,  
                        CAST(GETDATE() AS DATE) AS DATECUR,  
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                        --CAST(GETDATE() AS TIME) AS TIMECUR,  
                        'Execution Process is Running Yet. Please Try After SomeTime' AS Remark  
      END  
  
      end  
--select *from #TempAuditPAN
END  
GO