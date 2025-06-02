CREATE TABLE [dbo].[MetaDynamicCallStaticSP] (
  [ClientSideParams] [varchar](1000) NULL,
  [Entitykey] [smallint] IDENTITY,
  [ServerSideParams] [varchar](1000) NULL,
  [ControlID] [int] NULL,
  [SPName] [varchar](200) NULL
)
ON [PRIMARY]
GO