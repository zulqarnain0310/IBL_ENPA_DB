SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE proc [dbo].[Finacle_Duplicate] 
as
Begin

Truncate Table Duplicate_Records

insert into Duplicate_Records(
Row_num,
AccountNumber,
Sourcename)
select * from (
select row_number()over(partition by ACCOUNT_NUMBER order by CLIENT_ID )as row_num,ACCOUNT_NUMBER,SYSTEM from Induslnd_stg.dbo.Finacle_Stg)a
where row_num > 1
End


GO