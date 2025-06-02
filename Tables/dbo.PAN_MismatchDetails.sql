CREATE TABLE [dbo].[PAN_MismatchDetails] (
  [EntityKey] [int] IDENTITY,
  [NCIF] [varchar](20) NULL,
  [SrcSysAlt_Key] [tinyint] NULL,
  [CustomerID] [varchar](20) NULL,
  [CustomerName] [varchar](80) NULL,
  [PAN] [varchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
  [NSDL_FirstName] [varchar](80) NULL,
  [NSDL_MiddleName] [varchar](80) NULL,
  [NSDL_LastName] [varchar](80) NULL,
  [Reconciled] [char](1) NULL DEFAULT ('N'),
  [TimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp] NULL,
  [PAN_Status] [char](1) MASKED WITH (FUNCTION = 'default()') NULL,
  [InsertFlag] [char](1) NULL DEFAULT ('N')
)
ON [PRIMARY]
GO