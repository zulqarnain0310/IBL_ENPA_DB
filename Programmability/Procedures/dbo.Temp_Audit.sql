SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE Proc [dbo].[Temp_Audit]
as 
begin

select sourcename,cast(TempCount as varchar(20)) as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='Finacle_Temp'
union all
select sourcename,cast(TempCount as varchar(20))  as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='CASA_Temp'
union all
select '','','','' 
union all
select 'Finacle Sub-Total',cast(sum(TempCount) as varchar(20))  as tempcount,cast(sum(DebitAmount) as varchar(20)) as Debit_amount,cast(sum(CreditAmount) as varchar(20)) as Credit_amount from TempCount where sourcename in('Finacle_Temp','CASA_Temp')
union all
select sourcename,cast(TempCount as varchar(20))  as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='ECS_Temp'
union all
select sourcename,cast(TempCount as varchar(20)) as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='Prolendz_Temp'
union all
select sourcename,cast(TempCount as varchar(20))  as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='Ganseva_Temp'
union all
select sourcename,cast(TempCount as varchar(20))  as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='Calypso_Temp'
union all
select sourcename,cast(TempCount as varchar(20))  as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='ECBF_Temp'
union all
select sourcename,cast(TempCount as varchar(20))  as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='Tradepro_Temp'
union all
select sourcename,cast(TempCount as varchar(20))  as tempcount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where sourcename='DedupSysData_Temp'
union all
select '','','','' 
union all
select '','','','' 
union all
select 'Total',cast(sum(TempCount) as varchar(60))  as tempcount,cast(sum(DebitAmount) as varchar(60)) as Debit_amount,cast(sum(CreditAmount) as varchar(60)) as Credit_amount from TempCount 
END
GO