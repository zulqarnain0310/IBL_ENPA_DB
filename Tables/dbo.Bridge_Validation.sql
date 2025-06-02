CREATE TABLE [dbo].[Bridge_Validation] (
  [EntityKey] [int] IDENTITY,
  [OldNCIF] [varchar](20) NULL,
  [OldNEntityID] [int] NULL,
  [NewNCIF] [varchar](20) NULL,
  [NewNEntityID] [int] NULL,
  [ClientID] [varchar](20) NULL
)
ON [PRIMARY]
GO