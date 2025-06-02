SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE Proc [dbo].[Stg_Audit]
@NPA int
as 

--declare
--@NPA int=0


begin

select SourceName,cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='Finacle_Stg'
union all
select '','','' ,''
union all
select '','','',''
union all
select 'Finacle_Subtotal',cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='Finacle_Stg'
union all
select SourceName,cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='ECS_Stg'
union all
select SourceName,cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='Prolendz_Stg'
union all
select SourceName,cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='ganseva_Stg'
union all
select SourceName,cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='Calypso_Stg'
union all
select SourceName,cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='ECBF_Stg'
UNION ALL
select SourceName,cast(StgCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from InduslndStg.dbo.StgCount where SourceName='Tradepro_Stg'
union all
select SourceName,cast(TempCount as varchar(20)) as stg_count,cast(DebitAmount as varchar(20)) as Debit_amount,cast(CreditAmount as varchar(20)) as Credit_amount from TempCount where SourceName='DedupSysData_Temp'
union all
select 'Ixsight(Other System data-Not reqd)',((select StgCount from InduslndStg.dbo.StgCount where SourceName='Ixsight_Stg')-
(select cast(TempCount as varchar(20)) from TempCount where SourceName='DedupSysData_Temp')), '' as Debit_amount,'' as Credit_amount
union all
select 'DedupSystem Sub-Total',cast(StgCount as varchar(20)) as stg_count,'' as Debit_amount,'' as Credit_amount from InduslndStg.dbo.StgCount where SourceName='Ixsight_Stg'
union all
select 'Total',cast(sum(StgCount) as varchar(50)),cast(sum(DebitAmount) as varchar(50)) as Debit_amount,cast(sum(CreditAmount) as varchar(50)) as Credit_amount   from InduslndStg.dbo.StgCount

where @NPA=0

end




GO