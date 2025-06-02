SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE procedure [dbo].[null_erosion] as
begin
update a set ErosionDT=null,LossDT=null
from NPA_IntegrationDetails a where CustomerACID in (select CustomerACID from ErosionDoubtfuldatepatch27092023) 
and EffectiveFromTimeKey>=26932 and EffectiveToTimeKey>=26932 
end
GO