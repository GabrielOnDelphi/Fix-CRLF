UNIT MainForm;

{ Replaces solitary CR characters with "normal" Windows enter (CRLF)
  Replaces solitary LF characters with "normal" Windows enter (CRLF)
}

INTERFACE

USES
  Winapi.Windows, Winapi.messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ExtCtrls, cFindInFile, Vcl.Mask, Vcl.Menus, Vcl.CheckLst, System.ImageList, Vcl.ImgList, ccCore,
  InternetLabel;

TYPE
  TfrmMain = class(TForm)
    btnStart      : TButton;
    btnFilters: TButton;
    chkAutoFix    : TCheckBox;
    chkBackup     : TCheckBox;
    Copyfilename1 : TMenuItem;
    edtFilter     : TLabeledEdit;
    edtPath       : TLabeledEdit;
    ImageList1    : TImageList;
    Label1        : TLabel;
    lblCurFile    : TLabel;
    lbxResults    : TListBox;
    mmoView       : TMemo;
    open1         : TMenuItem;
    Panel1        : TPanel;
    Panel2        : TPanel;
    pnlFiles      : TPanel;
    pnlView       : TPanel;
    PopupMenu     : TPopupMenu;
    Splitter      : TSplitter;
    urlBioniX     : TInternetLabel;
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate   (Sender: TObject);
    procedure FormDestroy  (Sender: TObject);
    procedure lbxResultsDblClick(Sender: TObject);
    procedure Copyfilename1Click(Sender: TObject);
    procedure btnFiltersClick   (Sender: TObject);
  private
    FilterCount: Integer;
    function GetSelectedSearch: TSearchResult;
    procedure FreeResults;
    procedure LateInitialize(VAR message: TMessage); message MSG_LateInitialize;
  end;

VAR
  frmMain: TfrmMain;

IMPLEMENTATION  {$R *.dfm}

USES
   ccIO, ccAppData,
   cmINIFileQuick,
   cmSystem,
   ccIniFileVCL,
   cvIniFile;



procedure TfrmMain.FormCreate(Sender: TObject);
begin
  PostMessage(Self.Handle, MSG_LateInitialize, 0, 0);         { This will call LateInitialize }
end;


procedure TfrmMain.LateInitialize;
begin
  LoadForm(Self);
  AppData.Initializing:= FALSE;
  Label1.Visible:= AppData.RunningFirstTime;
end;


procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  SaveForm(Self);
  FreeResults;
  FreeAndNil(AppData);
end;


procedure TfrmMain.FreeResults;
begin
 for VAR i:= 0 to lbxResults.Items.Count -1 do
    FreeAndNil(lbxResults.Items.Objects[i]);          { Release list and owned objects }
 lbxResults.Clear;
end;





procedure TfrmMain.btnStartClick(Sender: TObject);
var
   CurrFile: string;
   FileList: TStringList;
   sInput, sOutput: string;
begin
  FreeResults;
  mmoView.Clear;
  pnlView.Visible:= True;

  FileList:= ListFilesOf(edtPath.Text, edtFilter.Text, True, True);
  TRY
    if chkAutoFix.Checked
    then mmoView.Lines.Add('Broken enters fixed in: ')
    else mmoView.Lines.Add('Broken enters found in: ');

    for CurrFile in FileList do
     begin
       Caption:= CurrFile;
       Refresh;

       sInput:= StringFromFile(CurrFile);
       if (ccIO.IsDfm(CurrFile))
       AND (sInput.Length > 0)
       AND (sInput[1] = char($FF)) then
        begin
          mmoView.Lines.Add('Binary DFM skipped: '+ CurrFile);
          Continue;
        end;

       sOutput:= ReplaceLonellyLF(sInput, CRLF);    //0a #10 LF
       sOutput:= ReplaceLonellyCR(sOutput, CRLF);
       if sOutput <> sInput then
        begin
          if chkAutoFix.Checked then
           begin
            if chkBackup.Checked
            then ccIO.BackupFileIncrement(CurrFile, ccIO.GetTempFolder+ 'FixEnter Backup');
            StringToFile(CurrFile, sOutput, woOverwrite, FALSE);
           end;
          mmoView.Lines.Add(CurrFile);
        end;
     end;
  FINALLY
    FreeAndNil(FileList);
  END;

 Caption:= 'Done.';
end;


{ Returns the object selected by the user }
function TfrmMain.GetSelectedSearch: TSearchResult;
begin
 Result:= lbxResults.Items.Objects[lbxResults.ItemIndex] as TSearchResult;
end;



procedure TfrmMain.lbxResultsDblClick(Sender: TObject);
begin
 lblCurFile.Caption:= GetSelectedSearch.FileName;
 mmoView.Lines.LoadFromFile(GetSelectedSearch.FileName);

 //Scroll to first found pos
 var CurLine:= GetSelectedSearch.Positions[0];
 SendMessage(mmoView.Handle, EM_LINESCROLL, 0, CurLine);
end;


procedure TfrmMain.btnFiltersClick(Sender: TObject);
begin
 Inc(FilterCount);
 case FilterCount of
   1: edtFilter.Text:= '*.pas;';
   2: edtFilter.Text:= '*.pas;*.dfm';
   3: edtFilter.Text:= '*.pas;*.dfm;*.dpr;*.dpk;*.dproj;*.inc;';
   4: edtFilter.Text:= '*.txt';
 end;

 if FilterCount >= 4
 then FilterCount:= 0;
end;


procedure TfrmMain.Copyfilename1Click(Sender: TObject);
begin
 StringToClipboard(GetSelectedSearch.FileName);
end;


end.
