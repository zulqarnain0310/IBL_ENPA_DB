CREATE TABLE [dbo].[accelerated_provision_cfd_20230928] (
  [ENTITY_KEY] [bigint] NOT NULL DEFAULT (NEXT VALUE FOR [ENTITY_SEQEUNCE]),
  [NCIF_Id] [nvarchar](100) NULL,
  [CustomerId] [nvarchar](100) NULL,
  [CustomerACID] [nvarchar](100) NULL,
  [Accelerated Provision %] [nvarchar](100) NULL,
  PRIMARY KEY CLUSTERED ([ENTITY_KEY])
)
ON [PRIMARY]
GO