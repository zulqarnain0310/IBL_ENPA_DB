CREATE TABLE [dbo].[NPA_IntegrationDetails_17072024_MocRetention112Cust] (
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerACID] [varchar](20) NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [ErosionDT] [date] NULL,
  [DbtDT] [date] NULL,
  [NatureofClassification] [char](1) NULL,
  [DateofImpacting] [date] NULL,
  [ImpactingAccountNo] [varchar](5000) NULL,
  [ImpactingSourceSystemName] [varchar](500) NULL,
  [Co_borrower_impacted] [varchar](1) NULL,
  [PBos_Culprit_Impact] [varchar](1) NULL
)
ON [PRIMARY]
GO