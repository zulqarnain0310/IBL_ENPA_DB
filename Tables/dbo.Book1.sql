CREATE TABLE [dbo].[Book1] (
  [Retain Remove] [varchar](50) NULL,
  [EntityKey] [varchar](50) NULL,
  [NCIF_Id] [varchar](50) NULL,
  [NCIF_Changed] [varchar](50) NULL,
  [SrcSysAlt_Key] [varchar](50) NULL,
  [NCIF_EntityID] [varchar](50) NULL,
  [CustomerId] [varchar](50) NULL,
  [CustomerName] [varchar](50) NULL,
  [PAN] [varchar](50) MASKED WITH (FUNCTION = 'default()') NULL,
  [NCIF_AssetClassAlt_Key] [varchar](50) NULL,
  [NCIF_NPA_Date] [varchar](50) NULL,
  [AccountEntityID] [varchar](50) NULL,
  [CustomerACID] [varchar](50) NULL,
  [Column 13] [varchar](50) NULL
)
ON [PRIMARY]
GO