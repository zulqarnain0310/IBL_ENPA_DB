SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE Proc [dbo].[Dimproduct_Finacle_Insert]
AS

Declare @Timekey int= (select TimeKey From  SysDataMatrix where CurrentStatus='C')

IF OBJECT_ID ('TEMPDB..#temp')IS NOT NULL
DROP TABLE 	#temp

select  distinct  A.SCHEME_CODE,B.ProductCode,Dense_Rank() over(order by A.SCHEME_CODE) newcode into #temp  from 
InduslndStg.dbo.Finacle_Stg A
LEFT JOIN DIMPRODUCT B on A.SCHEME_CODE=B.ProductCode
where B.ProductCode is null and A.SCHEME_CODE<>''

Declare @ProductAlt_Key int = (select max(ProductAlt_Key) from DIMPRODUCT)
Declare @Product_Key int=(select max(Product_Key) from DIMPRODUCT)

Declare @newcode int=(select max(newcode) from #temp)
Declare @newcodeNo int=(select max(newcode) from #temp)

declare @no int =1

while @no<=@newcodeNo
begin
insert into DIMPRODUCT  (Product_Key,ProductAlt_Key,ProductCode,EffectiveFromTimeKey,EffectiveToTimeKey)

select @Product_Key+1, @ProductAlt_Key+10 ,SCHEME_CODE,@Timekey,49999  from #temp where newcode=@no
 set @no=@no+1
 set @Product_Key=@Product_Key+1
 set @ProductAlt_Key=@ProductAlt_Key+10
 set @newcode= @newcode+10
 end
GO