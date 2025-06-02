SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[Prolendz_Duplicate] 
as
Begin
insert into Duplicate_Records(
Row_num,
AccountNumber,
Sourcename)
select * from (
select row_number()over(partition by Deal_No order by Customer_Code )as row_num,Deal_No,SYSTEM from Induslnd_Stg.dbo.Prolendz_Stg)a
where row_num > 1
End
GO