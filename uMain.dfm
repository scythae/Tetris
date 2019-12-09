object frMain: TfrMain
  Left = 0
  Top = 0
  AlphaBlend = True
  BorderStyle = bsNone
  Caption = 'Tetris'
  ClientHeight = 317
  ClientWidth = 256
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseWheel = FormMouseWheel
  OnPaint = FormPaint
  DesignSize = (
    256
    317)
  PixelsPerInch = 96
  TextHeight = 13
  object pScore: TPanel
    Left = 165
    Top = 0
    Width = 91
    Height = 25
    Anchors = []
    Caption = '0'
    ParentBackground = False
    ParentColor = True
    TabOrder = 1
    OnClick = OnMenuButtonClick
  end
  object pMenu: TPanel
    Left = 159
    Top = 168
    Width = 97
    Height = 149
    Anchors = []
    BevelOuter = bvNone
    TabOrder = 0
    TabStop = True
    object btnResume: TButton
      Left = 0
      Top = -1
      Width = 97
      Height = 25
      Align = alBottom
      Caption = 'Resume'
      TabOrder = 0
      TabStop = False
      OnClick = OnMenuButtonClick
    end
    object btnExit: TButton
      Left = 0
      Top = 124
      Width = 97
      Height = 25
      Align = alBottom
      Caption = 'Exit'
      TabOrder = 5
      TabStop = False
      OnClick = OnMenuButtonClick
    end
    object btnMod2: TButton
      Left = 0
      Top = 49
      Width = 97
      Height = 25
      Align = alBottom
      Caption = 'Snake'
      TabOrder = 2
      TabStop = False
      OnClick = OnMenuButtonClick
    end
    object btnMod1: TButton
      Left = 0
      Top = 24
      Width = 97
      Height = 25
      Align = alBottom
      Caption = 'Tetris'
      TabOrder = 1
      TabStop = False
      OnClick = OnMenuButtonClick
    end
    object btnAbout: TButton
      Left = 0
      Top = 99
      Width = 97
      Height = 25
      Align = alBottom
      Caption = 'About'
      TabOrder = 4
      TabStop = False
      OnClick = OnMenuButtonClick
    end
    object btnMod3: TButton
      Left = 0
      Top = 74
      Width = 97
      Height = 25
      Align = alBottom
      Caption = 'Racer'
      TabOrder = 3
      TabStop = False
      OnClick = OnMenuButtonClick
    end
  end
  object pInfo: TPanel
    Left = 22
    Top = 32
    Width = 54
    Height = 25
    Alignment = taLeftJustify
    Anchors = [akLeft, akTop, akRight]
    BorderWidth = 5
    ParentBackground = False
    ParentColor = True
    TabOrder = 2
    VerticalAlignment = taAlignTop
    Visible = False
    OnClick = OnMenuButtonClick
    object labelInfo: TLabel
      Left = 6
      Top = 6
      Width = 42
      Height = 13
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption = 'labelInfo'
      Layout = tlCenter
      WordWrap = True
      OnMouseDown = labelInfoMouseDown
    end
  end
  object tRecalc: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tRecalcTimer
    Left = 64
    Top = 216
  end
end
