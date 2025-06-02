SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO




create proc [dbo].[dimsourcenamek]
@DtEnter as varchar(20)

AS
--DECLARE	
--@DtEnter as varchar(20)='30/09/2017'


DECLARE @DtEnter1 date ,@From1 date,@to1 date 

SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
----Print @DtEnter1

DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)

SELECT 0 AS VALUE,'<ALL>' AS LABEL 
UNION ALL 

select SourceAlt_Key as value,SourceName as label from DimSourceSystem
 where EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
GO