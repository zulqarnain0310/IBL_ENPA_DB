SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


Create proc [dbo].[Main_Audit]
AS
Begin

select sourcename,cast(MainCount as varchar(20)) as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='Finacle_Main'
union all
select sourcename,cast(MainCount as varchar(20))  as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='CASA_Main'
union all
select '','','','' 
union all
select 'Finacle Sub-Total',cast(sum(MainCount) as varchar(20))  as MainCount,cast(sum(DebitAmount) as varchar(20)) as Debit_amount,cast(sum(CreditAmount) as varchar(20)) as Credit_amount from MainCount where sourcename in('Finacle_Main','CASA_Main')
union all
select sourcename,cast(MainCount as varchar(20))  as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='ECS_Main'
union all
select sourcename,cast(MainCount as varchar(20)) as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='Prolendz_Main'
union all
select sourcename,cast(MainCount as varchar(20))  as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='Ganseva_Main'
union all
select sourcename,cast(MainCount as varchar(20))  as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='Calypso_Main'
union all
select sourcename,cast(MainCount as varchar(20))  as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='ECBF_Main'
union all
select sourcename,cast(MainCount as varchar(20))  as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='Tradepro_Main'
union all
select sourcename,cast(MainCount as varchar(20))  as MainCount,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from MainCount where sourcename='DedupSysData_Main'
union all
select '','','','' 
union all
select '','','','' 
union all
select 'Total',cast(sum(MainCount) as varchar(60))  as MainCount,cast(sum(DebitAmount) as varchar(60)) as Debit_amount,cast(sum(CreditAmount) as varchar(60)) as Credit_amount from MainCount 
End
GO