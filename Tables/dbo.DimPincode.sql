CREATE TABLE [dbo].[DimPincode] (
  [Pincode_Key] [int] NOT NULL,
  [Pincode] [int] NULL,
  [PincodeOfficeName] [varchar](100) NULL,
  [PincodeOfficeStatus] [varchar](100) NULL,
  [TalukaAlt_Key] [int] NULL,
  [PincodeTaluka] [varchar](100) NULL,
  [DistrictAlt_Key] [smallint] NULL,
  [PincodeDistrict] [varchar](100) NULL,
  [StateAlt_Key] [smallint] NULL,
  [PincodeState] [varchar](100) NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [RecordStatus] [char](1) NULL
)
ON [PRIMARY]
GO