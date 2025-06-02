CREATE TABLE [dbo].[NPA_IntegrationDetails_ForRestr] (
  [NCIF_ID] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerACID] [varchar](20) NULL,
  [AccountEntityID] [int] NOT NULL,
  [EffectiveFromTimeKey] [int] NOT NULL,
  [EffectiveToTimeKey] [int] NOT NULL
)
ON [PRIMARY]
GO