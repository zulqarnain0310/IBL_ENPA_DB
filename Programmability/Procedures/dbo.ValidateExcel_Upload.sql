SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
  
CREATE Procedure [dbo].[ValidateExcel_Upload]
      @TypeOfUpload VARCHAR(30)  
     ,@XmlData XML=''                      
     ,@OperationFlag  INT       
     ,@D2Ktimestamp INT=0 OUTPUT      
     ,@AuthMode char(2) = null                                          
     ,@MenuID INT=NULL  
     ,@TimeKey int   
     ,@Result int=0 output  
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET DAteformat DMY  
  
 IF OBJECT_ID('tempdb..#TempMOCErrorData') IS NOT NULL  
  BEGIN  
   DROP TABLE #TempMOCErrorData  
  END  
 CREATE TABLE #TempMOCErrorData   
  (  
   SrNo  SMALLINT  
   --,Row_No  SMALLINT  
   ,ColumnName VARCHAR(50)  
   ,ErrorData VARCHAR(100)  
   ,ErrorType VARCHAR(100)  
  )   
   
BEGIN TRY  
 print 82  
  

  IF OBJECT_ID('Tempdb..#TempMOCData') IS NOT NULL  
    BEGIN
      DROP TABLE #TempMOCData  
     END
      PRINT '765'

					SELECT 
					 C.value('./ENTCIF[1]','varchar(30)') ENTCIF
					,C.value('./CustomerID[1]','varchar(30)')ClientID
					,C.value('./SrNo[1]','int')SrNo
					,C.value('./SourceSystem[1]','varchar(50)') SourceSystem
					,C.value('./PAN[1]','varchar(20)')PAN
					,C.value('./AssetClass[1]','varchar(20)')AssetClass
					,C.value('./NPADate[1]','varchar(10)')NPADate
					,C.value('./Remark[1]','varchar(100)')Remark
					,C.value('./Reason[1]','varchar(100)')Reason			
				
				INTO #TempMOCData
				FROM @XmlData.nodes('/DataSet/GridData') AS t(c) 
				--select * from #TempMOCData
	INSERT INTO #TempMOCErrorData    
	
	--	SELECT   ROW_NUMBER() OVER(ORDER BY T.SrNo ) SrNo 
 --    -- ,RowNo 
	 
 --     ,'SrNo' ColumnName  
 --       ,T.SrNo ErrorData  
 --     ,'is Mandatory Field' ErrorType  
 --   FROM #TempMOCData T  	 
	--	where ISNULL(T.SrNo,'')='' 
	--union 

    SELECT   SrNo  
     -- ,RowNo  
      ,'CustomerID' ColumnName  
      ,NULL ErrorData  
      ,'is Mandatory Field' ErrorType  
    FROM #TempMOCData T  	 
		WHERE ISNULL(T.ClientID,'')='' 
		
		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'SourceSystem' ColumnName  
          ,NULL ErrorData    
      ,'is Mandatory Field' ErrorType  
    FROM #TempMOCData T  	 
		WHERE ISNULL(T.SourceSystem,'')='' 
		
		
		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'ENTCIF' ColumnName  
         ,NULL ErrorData  
      ,'is Mandatory Field' ErrorType  
    FROM #TempMOCData T  	 
		WHERE ISNULL(T.ENTCIF,'')='' 

		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'AssetClass' ColumnName  
         ,NULL ErrorData  
      ,'is Mandatory Field' ErrorType  
    FROM #TempMOCData T  	 
		WHERE ISNULL(T.AssetClass,'')='' 

		--UNION
		--SELECT   SrNo  
  --   -- ,RowNo  
  --    ,'PAN' ColumnName  
  --       ,NULL ErrorData  
  --    ,'is Mandatory Field' ErrorType  
  --  FROM #TempMOCData T  	 
		--WHERE ISNULL(T.PAN,'')=''    --and @MenuID=910
		

		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'NPA Date' ColumnName  
        ,NULL ErrorData  
      ,'is Mandatory Field' ErrorType  
    FROM #TempMOCData T  	 
		WHERE T.AssetClass IN('SUB','DB1','DB2','DB3','LOS') AND ISNULL(T.NPADate,'')='' 

		UNION

		SELECT   SrNo  
     -- ,RowNo  
      ,'NPA Date' ColumnName  
        ,NULL ErrorData  
      ,'For STD asset class, do not enter the NPA Date' ErrorType  
    FROM #TempMOCData T  	 
		WHERE T.AssetClass IN('STD') AND T.NPADate<>''

		
		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'Reason' ColumnName  
        ,NULL ErrorData  
      ,'is Mandatory Field' ErrorType  
    FROM #TempMOCData T  	 
		WHERE ISNULL(T.Reason,'')='' 

		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'Source System' ColumnName  
        ,T.SourceSystem ErrorData  
      ,'Source system not valid.' ErrorType  
    FROM #TempMOCData T  	 
		WHERE T.SourceSystem not IN('10','20','60','70','40') and T.SourceSystem<>''

		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'Reason' ColumnName  
        ,T.Reason ErrorData  
      ,'Reason not valid.' ErrorType  
    FROM #TempMOCData T  	 
		WHERE T.Reason not IN('10','20') and T.Reason<>''
		--WHERE T.SourceSystem not IN('10','20') and T.Reason<>''

		UNION
		SELECT   SrNo  
     -- ,RowNo  
      ,'Asset Class' ColumnName  
        ,T.AssetClass ErrorData  
      ,'Invalid Asset Class' ErrorType  
    FROM #TempMOCData T  	 
		 LEFT JOIN DimAssetClass B  
      ON  (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)  
         and T.AssetClass=B.AssetClassShortNameEnum  
    WHERE B.AssetClassShortNameEnum IS NULL  
      AND T.AssetClass <> '' 

	  UNION
	  SELECT   SrNo  
     -- ,RowNo  
      ,'ENTCIF' ColumnName  
        ,T.ENTCIF ErrorData  
      ,'Invalid ENTCIF' ErrorType  
    FROM #TempMOCData T  	 
		 LEFT JOIN NPA_IntegrationDetails B  
      ON  (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)  
         and T.ENTCIF=B.NCIF_Id  
    WHERE B.NCIF_Id IS NULL  
      AND T.ENTCIF <> '' 

	   UNION
	  SELECT   SrNo  
     -- ,RowNo  
      ,'Customer ID' ColumnName  
        ,T.ClientID ErrorData  
      ,'Invalid Customer ID' ErrorType  
    FROM #TempMOCData T  	 
		 LEFT JOIN NPA_IntegrationDetails B  
      ON  (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)  
         and T.ClientID=B.CustomerId  
    WHERE B.CustomerId IS NULL  
      AND T.ClientID <> '' 

	   UNION
	  SELECT   SrNo  
     -- ,RowNo  
      ,'PAN' ColumnName  
        ,T.PAN ErrorData  
      ,'Invalid PAN' ErrorType  
    FROM #TempMOCData T  	 
		 LEFT JOIN NPA_IntegrationDetails B  
      ON  (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)  
         and T.PAN=B.PAN  
    WHERE B.PAN IS NULL  
      AND T.PAN <> '' 
		

	 -- select * from DimAssetClass
	  INSERT INTO #TempMOCErrorData 
		SELECT   ROW_NUMBER() OVER(ORDER BY T.SrNo ) SrNo 
     -- ,RowNo 
	 
      ,'SrNo' ColumnName  
          ,T.SrNo ErrorData  
      ,'Is Duplicate' ErrorType  
    FROM #TempMOCData T  	 
		group by T.SrNo
	having COUNT(T.SrNo)>1

	INSERT INTO #TempMOCErrorData 
		SELECT   ROW_NUMBER() OVER(ORDER BY T.ClientID ) SrNo 
     -- ,RowNo 
	 
      ,'Customer ID' ColumnName  
          ,T.ClientID ErrorData  
      ,'Is Duplicate' ErrorType  
    FROM #TempMOCData T  	 
		group by T.ClientID
	having COUNT(T.ClientID)>1



		

	  
	
   SELECT * FROM #TempMOCErrorData order by SrNo
  
END TRY  
  
BEGIN CATCH  
 ROLLBACK TRAN  
 SELECT ERROR_MESSAGE() Error_Desc, ERROR_PROCEDURE() SP_Name, ERROR_LINE() Line_No  
 RETURN -1  
  
END CATCH  
 ------  
     
END
GO