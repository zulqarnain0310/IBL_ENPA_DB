CREATE TABLE [dbo].[accelerated_provision_cfd] (
  [ENTITY_KEY] [bigint] NOT NULL DEFAULT (NEXT VALUE FOR [ENTITY_SEQUENCE]),
  [NCIF_Id] [nvarchar](100) NULL,
  [CustomerId] [nvarchar](100) NULL,
  [CustomerACID] [nvarchar](100) NULL,
  [Accelerated Provision %] [nvarchar](100) NULL,
  [SrcSysAlt_Key] [int] NULL,
  PRIMARY KEY CLUSTERED ([ENTITY_KEY])
)
ON [PRIMARY]
GO