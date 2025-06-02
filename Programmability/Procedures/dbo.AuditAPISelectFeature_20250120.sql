SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
 
Create PROCEDURE [dbo].[AuditAPISelectFeature_20250120]  
       @PANNo            VARCHAR(10) = N'',
       @NCIF_Id              VARCHAR(10) = N'',
       @Aadhar  VARCHAR(2000)=N'',
	   @VoterId VARCHAR(20)=N'',  
       @TimeKey             INT        = 0

AS
SET NOCOUNT ON 
--DECLARE
--    @PANNo   VARCHAR(10) = N'',--CCKPR3153B  ATNPS2773C
--    @NCIF_Id VARCHAR(10) = N'10000027',--10001967  
--    @Aadhar  VARCHAR(2000)=N'',
--	@VoterId VARCHAR(20)=N'', -- SVI2339884
--    @TimeKey INT  = 26084

BEGIN
      SET @TimeKey=27292 ---- (Select TimeKey From SysDataMatrix WHERE CurrentStatus='C')
      PRINT @TimeKey

      SET DATEFORMAT DMY;

 		IF OBJECT_ID('Tempdb..#TempAuditPAN') IS NOT NULL
    DROP TABLE #TempAuditPAN
	CREATE TABLE [dbo].[#TempAuditPAN](
	[CountPAN] [bigint] NULL,
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
	IsSuitFiled [varchar](1) NULL,	-- Added on 28/12/2022 , as per requirement of Bank 
	PAN VARCHAR(20) NULL,
	Voter_ID VARCHAR(2000) NULL,
    AADHAR_ID VARCHAR(2000) NULL,
    Matched_Criteria VARCHAR(1000) NULL
    ) ON [PRIMARY]


      If len(isnull(@PANNo,''))= 0 and len(isnull(@NCIF_Id,''))=0 and len(isnull(@Aadhar,''))=0 and len(isnull(@VoterId,''))=0
      begin
            select 'Please Provide Atleast One Value...Either PanNo or NCIF_Id or Aadhar or VoterId' As Remark
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
                        @Aadhar,
						@VoterId,
                        CAST(GETDATE() AS DATE) AS DATECUR,
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
                        --CAST(GETDATE() AS TIME) AS TIMECUR,
                        'Please Provide Atleast One Value...Either PanNo or NCIF_Id or Aadhar or VoterId' AS Remark
      end
      
    else

    begin
 
 
 print 'Shakti'
        
                      Declare @PANNo_final varchar(200)
                      if len(isnull(@PANNo,''))>0
	                  begin
	                  set @PANNo_final=@PANNo
	                  end
	                  else
	                  begin
	                  set @PANNo_final='XXXX'
	                  end
	                 
                      Declare @NCIF_Id_final varchar(200)
                      if len(isnull(@NCIF_Id,''))>0
	                  begin
	                  set @NCIF_Id_final=@NCIF_Id
	                  end
	                  else
	                  begin
	                  set @NCIF_Id_final='XXXX'
	                  end

	                  Declare @Aadhar_final varchar(2000)
                      if len(isnull(@Aadhar,''))>0
	                  begin
	                  set @Aadhar_final=@Aadhar
	                  end
	                  else
	                  begin
	                  set @Aadhar_final='XXXX'
	                  end
	    
	                  Declare @VoterId_final varchar(200)
                      if len(isnull(@VoterId,''))>0
	                  begin
	                  set @VoterId_final=@VoterId
	                  end
	                  else
	                  begin
	                  set @VoterId_final='XXXX'
	                  end
		
		   If(@PANNo_final<>'xxxx' or @VoterId_final<>'xxxx' or @Aadhar_final<>'XXXX' or @NCIF_Id_final<>'XXXX')
		    begin

			truncate table audit_chk 
		
		INSERT INTO audit_chk (START_TIME,STEP)
			SELECT GETDATE(),0
			UPDATE audit_chk SET END_TIME=GETDATE() where step=0 

			Drop table if exists #AadharVoterIDdata
				select * into #AadharVoterIDdata from D2K_AADHAR_VOTER_ALL_NEW1 with (nolock)
														where UCIC=@NCIF_Id_final
				UNION ALL
				select * from D2K_AADHAR_VOTER_ALL_NEW1 with (nolock) where AADHAR_NO=@Aadhar_final
				UNION ALL
				select * from D2K_AADHAR_VOTER_ALL_NEW1 with (nolock) where KYCID=@VoterId_final
				UNION ALL
				select * from D2K_AADHAR_VOTER_ALL_NEW1 with (nolock) where PAN=@PANNo_final

				--select * from #AadharVoterIDdata 
			Drop table if exists #ucic
				SELECT Distinct UCIC into #ucic FROM #AadharVoterIDdata 
				where AADHAR_NO=@Aadhar_final or KYCID=@VoterId_final or PAN=@PANNo_final
		
				IF Exists (SELECT 1 From #ucic ) And @NCIF_Id_final='xxxx'
	                  BEGIN
						SET @NCIF_Id_final=(select Top 1 UCIC from #ucic) 
	                  END

 -- select * from #ucic
 --select STRING_AGG(UCIC,',') from #ucic

			INSERT INTO audit_chk (START_TIME,STEP)
			SELECT GETDATE(),1
 
			DROP TABLE IF EXISTS #NPA_IntegrationDetails_Curnt

			SELECT NCIF_Id,CustomerId,CustomerACID,CustomerName,
			IsARC_Sale,IsRestructured,IsOTS,IsFraud,IsTWO,ARC_SaleDate,WriteOffDate,PrincipleOutstanding,Balance,Segment,ProductCode,
			FacilityType,AC_NPA_Date,NCIF_NPA_Date,NCIF_AssetClassAlt_Key,MaxDPD,IsSuitFiled,PAN,AccountEntityId,SrcSysAlt_Key,EffectiveFromTimeKey,EffectiveToTimeKey
					into #NPA_IntegrationDetails_Curnt
					FROM NPA_IntegrationDetails_Curnt with (nolock)
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND
					PAN=@PANNo_final OR NCIF_Id=@NCIF_Id_final OR NCIF_Id in (select UCIC from #ucic) 


			UPDATE audit_chk SET END_TIME=GETDATE() where step=1

			INSERT INTO audit_chk (START_TIME,STEP)
			SELECT GETDATE(),2

			Insert into #TempAuditPAN
            SELECT
                   ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS CountPAN
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
				  ,A.IsSuitFiled	-- Added on 28/12/2022 , as per requirement of Bank 
				  ,A.PAN
				  ,Av.KYCID Voter_ID 
                  ,Av.AADHAR_NO  AADHAR_ID 
                  ,'' Matched_Criteria 
            --INTO #TempAuditPAN
            FROM #NPA_IntegrationDetails_Curnt A
            LEFT JOIN CURDAT.AdvAcRestructureDetail (nolock) C
            ON A.AccountEntityId=C.AccountEntityId
            AND (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
            LEFT JOIN DimSourceSystem D
            ON A.SrcSysAlt_Key=D.SourceAlt_Key        
            AND (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
            LEFT JOIN #AadharVoterIDdata AV
			ON A.NCIF_Id=AV.UCIC
            WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
           -- AND (A.PAN=@PANNo_final OR A.NCIF_Id=@NCIF_Id_final OR AV.AADHAR_NO=@Aadhar_final OR AV.KYCID=@VoterId_final) 
			
			UPDATE #TempAuditPAN SET Matched_Criteria='NCIF_ID' WHERE NCIF_Id=@NCIF_Id_final
			UPDATE #TempAuditPAN SET Matched_Criteria=CONCAT(Matched_Criteria,' ,PAN') WHERE PAN=@PANNo_final
			UPDATE #TempAuditPAN SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Aadhar') WHERE AADHAR_ID=@Aadhar_final
			UPDATE #TempAuditPAN SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Voter_ID') WHERE Voter_ID=@VoterId_final
			  
            update #TempAuditPAN set Matched_Criteria= replace(Matched_Criteria,' ,','') where Matched_Criteria like ' ,%' 

					UPDATE audit_chk SET END_TIME=GETDATE() where step=2
           END
		        INSERT INTO audit_chk (START_TIME,STEP)
			SELECT GETDATE(),3
            --SELECT * FROM #TempAuditPAN
            DECLARE @CountPAN INT=(SELECT COUNT(*) FROM #TempAuditPAN)

            IF (@CountPAN>0)
            BEGIN
                  SELECT * FROM #TempAuditPAN
                  INSERT INTO Log_APIAudit
                  (
                         PAN
                        ,NCIF_Id
                        ,AADHAR
						,VOTERID
                        ,RecordCount
                        ,Date
                        ,Time
                        ,Remark
                  )
                  SELECT
                        @PANNO AS PANNO,
                        @NCIF_Id as NCIF_Id,
                        @Aadhar_final,
						@VoterId_final,
                        @CountPAN AS RecordCount,
                        CAST(GETDATE() AS DATE) AS DATECUR,
                        --CAST(GETDATE() AS TIME) AS TIMECUR
                        CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR
                        ,'Successful' as Remark
            END

                 UPDATE audit_chk SET END_TIME=GETDATE() where step=3
--select @CountPAN
            IF (@CountPAN=0)
            begin
				
               if  (@PANNo_final<>'xxxx' and  @VoterId_final<>'xxxx' and @Aadhar_final<>'XXXX' and @NCIF_Id_final<>'XXXX')
                begin
                SELECt 'No Record Available for all Parameters PAN / NCIF_Id / AadharID /VoterID' as Remark
			    end
				else
				begin
				if (@PANNo_final<>'xxxx') And @NCIF_Id_final='XXXX' 
				begin
				--Select 'No Record Available for Pan:-'  + @PANNo_final as Remark
				Select 'No Record Available for Pan'  as Remark
				end

				if (@Aadhar_final<>'xxxx') And @NCIF_Id_final='XXXX' 
				begin
				--Select 'No Record Available for AadharID:-' + @Aadhar_final as Remark
				Select 'No Record Available for AadharID' as Remark
				end

				if (@VoterId_final<>'xxxx') And @NCIF_Id_final='XXXX' 
				begin
				--Select 'No Record Available for VoterID:-' + @VoterId_final as Remark
				Select 'No Record Available for VoterID' as Remark
				end
            end
	--select @NCIF_Id_final
	--select @CountPAN
		If (@NCIF_Id_final<>'xxxx') and (@CountPAN=0)
				begin   
						IF EXISTS (select 1 from  CoBorrowerData_curnt with (nolock) where NCIFID_COBORROWER=@NCIF_Id_final OR  NCIFID_COBORROWER in (select UCIC from #ucic) ) 
							Begin
							Drop table if exists #Cobodata
								select distinct a.*
								into #Cobodata from CoBorrowerData_curnt (nolock) a 
									Inner Join NPA_IntegrationDetails_Curnt (nolock) c on a.NCIFID_PrimaryAccount=c.NCIF_Id
									Left Join NPA_IntegrationDetails_Curnt (nolock) b 
									on a.NCIFID_COBORROWER=b.NCIF_Id  where (a.NCIFID_COBORROWER=@NCIF_Id_final OR a.NCIFID_COBORROWER in (select UCIC from #ucic))
									 and b.NCIF_Id is null --and a.AcDegFlg='Y'
						
						--select * from  #Cobodata 

										Drop Table If exists #SACOBO1
								 				 SELECT 
                  										ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS CountPAN  
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
														,Case when @PANNo_final<>'xxxx' Then @PANNo_final else Null END  as PAN
														,Case when @VoterId_final<>'xxxx' Then @VoterId_final else Null END  as  Voter_ID 
														,Case when @Aadhar_final<>'xxxx' Then @Aadhar_final else Null END  as  AADHAR_ID 
														,'Matched_Criteria Avialable in data,PAN,Aadhar,Voter_ID,All' Matched_Criteria   
														Into #SACOBO1 
            									--FROM (select distinct * from #Cobodata where ISNULL(AcDegFlg,'N')='Y') A
            									FROM #Cobodata A
 
											UPDATE #SACOBO1 SET Matched_Criteria=''
											UPDATE #SACOBO1 SET Matched_Criteria='NCIF_ID' WHERE (NCIF_Id=@NCIF_Id_final AND  ISNULL(NCIF_Id,'')=@NCIF_Id )
											AND ( ISNULL(PAN,'')<>@PANNo_final OR ISNULL(AADHAR_ID,'')<>@Aadhar_final OR ISNULL(Voter_ID,'')<>@VoterId_final )
											UPDATE #SACOBO1 SET Matched_Criteria=CONCAT(Matched_Criteria,' ,PAN') WHERE PAN=@PANNo_final
											UPDATE #SACOBO1 SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Aadhar') WHERE AADHAR_ID=@Aadhar_final
											UPDATE #SACOBO1 SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Voter_ID') WHERE Voter_ID=@VoterId_final
			  
													Update A SET A.AADHAR_ID=B.AADHAR_NO 
													, A.Voter_ID=B.KYCID,A.PAN=B.PAN
													FROM #SACOBO1 A JOIN #AadharVoterIDdata B
													ON A.NCIF_Id=B.UCIC

											select * from #SACOBO1 


									INSERT INTO Log_APIAudit
                  							  (
                        							 PAN
                        							,NCIF_Id
													,AADHAR
													,VOTERID
                        							,RecordCount
                        							,Date
                        							,Time
                        							,Remark
                  							  )
                  							  SELECT
                        							@PANNO AS PANNO,
                        							@NCIF_Id as NCIF_Id,
													@Aadhar_final,
													@VoterId_final,
                        							@CountPAN AS RecordCount,
                        							CAST(GETDATE() AS DATE) AS DATECUR,
                        							CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
                        							--CAST(GETDATE() AS TIME) AS TIMECUR,  
                        							'Successful' AS Remark 
								end

				Else			
				begin
                  SELECt 'No Record Available for PAN / NCIF_Id ' + isnull(@PANNo,'')+isnull(@NCIF_Id,'') AS Remark  
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
            END  
      END   
      end  
END  
GO