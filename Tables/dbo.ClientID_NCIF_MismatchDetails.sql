CREATE TABLE [dbo].[ClientID_NCIF_MismatchDetails] (
  [EntityKey] [int] IDENTITY,
  [SrcSysAlt_Key] [tinyint] NULL,
  [CustomerID] [varchar](20) NULL,
  [NCIF] [varchar](20) NULL,
  [CustomerName] [varchar](80) NULL,
  [PAN] [varchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
  [Reconciled] [char](1) NULL DEFAULT ('N'),
  [TimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp] NULL
)
ON [PRIMARY]
GO