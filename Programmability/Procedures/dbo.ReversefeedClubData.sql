SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ReversefeedClubData]
AS

BEGIN
drop table if exists #ReverseFeedDetails_2days

Select Top 0 * into #ReverseFeedDetails_2days from ReverseFeedDetails


insert into #ReverseFeedDetails_2days
select * from ReverseFeedDetails_BKP_21012025 where AccountNo in (
select AccountNo from ReverseFeedDetails_BKP_21012025   ---- 78
except
select AccountNo from ReverseFeedDetails_BKP_22012025)



insert into #ReverseFeedDetails_2days
select * from ReverseFeedDetails_BKP_22012025 where AccountNo in (
select AccountNo from ReverseFeedDetails_BKP_22012025
except
select AccountNo from ReverseFeedDetails_BKP_21012025)   ---- 17657



insert into #ReverseFeedDetails_2days
select B.*
--select a.ucif_id,a.AccountNo,a.HomogenizedAssetClass,b.HomogenizedAssetClass
from ReverseFeedDetails_BKP_21012025 a
inner join ReverseFeedDetails_BKP_22012025 b on a.AccountNo=b.AccountNo
--where isnull(a.HomogenizedAssetClass,0)>isnull(b.HomogenizedAssetClass,0)
WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(a.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(a.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) > 
(CASE WHEN isnull(b.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(b.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(b.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)

insert into #ReverseFeedDetails_2days
select b.*
--select a.ucif_id,a.AccountNo,a.HomogenizedAssetClass,b.HomogenizedAssetClass
from ReverseFeedDetails_BKP_21012025 a
inner join ReverseFeedDetails_BKP_22012025 b on a.AccountNo=b.AccountNo
--where isnull(a.HomogenizedAssetClass,0)<isnull(b.HomogenizedAssetClass,0)
WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(a.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(a.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) <
(CASE WHEN isnull(b.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(b.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(b.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)

insert into #ReverseFeedDetails_2days
select a.* from ReverseFeedDetails_BKP_21012025 a
inner join ReverseFeedDetails_BKP_22012025 b on a.AccountNo=b.AccountNo
--where isnull(a.HomogenizedAssetClass,0)=isnull(b.HomogenizedAssetClass,0)
WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(a.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(a.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) =
(CASE WHEN isnull(b.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(b.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(b.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)



----------------------3rd day comparison

Drop table if exists  #ReverseFeedDetails_3days
Select Top 0 * into #ReverseFeedDetails_3days from ReverseFeedDetails


insert into #ReverseFeedDetails_3days
select * from #ReverseFeedDetails_2days where AccountNo in (
select AccountNo from #ReverseFeedDetails_2days   ---- 15977
except
select AccountNo from ReverseFeedDetails_BKP_23012025)



insert into #ReverseFeedDetails_3days
select * from ReverseFeedDetails_BKP_23012025 where AccountNo in (
select AccountNo from ReverseFeedDetails_BKP_23012025
except
select AccountNo from #ReverseFeedDetails_2days)   ---- 2371

select * from #ReverseFeedDetails_3days


insert into #ReverseFeedDetails_3days
select b.*
--select a.ucif_id,a.AccountNo,a.HomogenizedAssetClass,b.HomogenizedAssetClass
from #ReverseFeedDetails_2days a
inner join ReverseFeedDetails_BKP_23012025 b on a.AccountNo=b.AccountNo
--where isnull(a.HomogenizedAssetClass,0)>isnull(b.HomogenizedAssetClass,0)  --- 13
WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(a.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(a.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) >
(CASE WHEN isnull(b.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(b.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(b.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)

insert into #ReverseFeedDetails_3days
select b.*
--select a.ucif_id,a.AccountNo,a.HomogenizedAssetClass,b.HomogenizedAssetClass
from #ReverseFeedDetails_2days a
inner join ReverseFeedDetails_BKP_23012025 b on a.AccountNo=b.AccountNo
--where isnull(a.HomogenizedAssetClass,0)<isnull(b.HomogenizedAssetClass,0)  --- 1
WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(a.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(a.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) <
(CASE WHEN isnull(b.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(b.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(b.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)


insert into #ReverseFeedDetails_3days
select a.* from #ReverseFeedDetails_2days a
inner join ReverseFeedDetails_BKP_23012025 b on a.AccountNo=b.AccountNo
--where isnull(a.HomogenizedAssetClass,0)=isnull(b.HomogenizedAssetClass,0)
WHERE (CASE WHEN isnull(a.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(a.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(a.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(a.HomogenizedAssetClass,0) END) =
(CASE WHEN isnull(b.HomogenizedAssetClass,0) = 'DBT' then 003
WHEN isnull(b.HomogenizedAssetClass,0) = 'SUB' THEN 002
WHEN isnull(b.HomogenizedAssetClass,0) = 'STD' THEN 001 ELSE isnull(b.HomogenizedAssetClass,0) END)

--------------------------Comparing with MOC table 

drop table if exists ##rev_bkp
select * into ##rev_bkp from #ReverseFeedDetails_3days


drop table if exists #ab
select * into #ab from ##rev_bkp where AccountNo in (
select AccountNo from ReverseFeedDetails_31122024_MOCbatch1  --- 
intersect
select AccountNo from ##rev_bkp)


delete from ##rev_bkp where AccountNo in (
select AccountNo from #ab)   ----only MOC Common acc left aftr deletion


insert into ##rev_bkp
select * from ReverseFeedDetails_31122024_MOCbatch1 where AccountNo in (
select AccountNo from #ab)


insert into ##rev_bkp
select * from ReverseFeedDetails_31122024_MOCbatch1
where AccountNo not in 
                       (select AccountNo from ##rev_bkp
                        intersect
                        select AccountNo from ReverseFeedDetails_31122024_MOCbatch1 )

INSERT INTO ReverseFeedDetails
 select * from ##rev_bkp

 --select * into ReverseFeedDetails_24012025postclub from ReverseFeedDetails

 END
GO