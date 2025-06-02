CREATE TABLE [dbo].[NPA_impacted_pboscol] (
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerACID] [varchar](20) NULL,
  [Co_borrower_impacted] [varchar](1) NULL,
  [PBos_Culprit_Impact] [varchar](1) NULL,
  [EffectiveFromTimeKey] [int] NOT NULL,
  [EffectiveToTimeKey] [int] NOT NULL
)
ON [PRIMARY]
GO