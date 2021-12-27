unit FSIWrapper;

// =============================================================================
// Unit: FSIWrapper
// Description: FSI wrapper class source.
//
// Copyright 2010 Prapin Peethambaran
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// =============================================================================

interface

uses
  // standard units 
  Classes, ComCtrls, Controls, Types, Messages, Menus,
  // windows pipes wrapper 
  Pipes,
  // configuration manager
  Config;

type

  /// Implements a wrapper for the F-Sharp Interactive(FSI) so that it can be hosted inside an 
  /// external application. 
  /// 
  TFSIViewer = class
  private
    _config: TConfiguration;
    _editor: TRichEdit;
    _pipedConsole: TPipeConsole;
    _editableAreaStartCoord: TPoint;
    _editableAreaStartPos: Integer;
    _defEditorWndProc: TWndMethod;
    _onSendText: TNotifyEvent;
    _onResultOutput: TNotifyEvent;
    _onErrorOutput: TNotifyEvent;
  private

    /// <summary>
    /// Create an instance of FSI and also the pipes needed to interact with it.
    /// </summary>
    procedure createFSI;

    /// <summary>
    /// Create a richedit control instance that will be used to interface with FSI.
    /// </summary>
    procedure createEditor;

    /// <summary>
    /// Create menu for controlling some editor functions.
    /// </summary>
    procedure createContextMenu;

    /// <summary>
    /// Store postion of editor caret.
    /// </summary>
    procedure updateEditableAreaStart;

    /// <summary>
    /// Based on the editor's caret position determine if the user is allowed to make changes
    /// directly to the editor.
    /// </summary>
    function isEditorCaretInAValidPos: Boolean;

    /// <summary>
    /// Modify richedit's windowproc to handle tab key presses.
    /// </summary>
    procedure editorWndProc(var Message: TMessage);
  private

    /// <summary>
    /// When there is output available from FSI, redirect it to the editor control.
    /// </summary>
    procedure doOnPipeOutput(sender: TObject; stream: TStream);

    /// <summary>
    /// When there is error output available from FSI, redirect it to the editor control.
    /// </summary>
    procedure doOnPipeError(sender: TObject; stream: TStream);

    /// <summary>
    /// Handle key down and
    /// 1. Control the area in the editor where typing is allowed.
    /// 2. When Return key is pressed: send text to FSI
    /// 3. Conver tabs to spaces, if necessary.
    /// </summary>
    procedure doOnEditorKeyDown(sender: TObject; var Key: Word; Shift: TShiftState);

    /// <summary>
    /// Handle invalid keys.
    /// </summary>
    procedure doOnEditorKeyPress(sender: TObject; var Key: Char);

    /// <summary>
    /// Delete contenst of editor.
    /// </summary>
    procedure doOnEditorClearContextMenuClick(sender: TObject);
    
    /// <summary>
    /// Copy text to the clipboard
    /// </summary>
    procedure doOnEditorCopyContextMenuClick(sender: TObject);    

    /// <summary>
    /// Check for non-empty text selection and enable "Copy" menu item if true
    /// </summary>
    procedure doOnContextMenuPopup(sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  public

    /// <summary>
    /// Start FSI.
    /// </summary>
    function Start: Boolean;

    /// <summary>
    /// Stop FSI.
    /// </summary>
    procedure Stop;

    /// <summary>
    /// Send text to FSI.
    /// </summary>
    procedure SendText(const text: String; addDelimiter, appendEditor: Boolean);

    /// <summary>
    /// Add text to editor.
    /// </summary>
    procedure AddToEditor(const text: String);
  public
    /// <summary>
    /// Gets a readonly instance of the config manager.
    /// </summary>
    property Config: TConfiguration read _config;

    /// <summary>
    /// Get the instance of the editor that interfaces with FSI.
    /// </summary>
    property Editor: TRichEdit read _editor;

    /// <summary>
    /// Event raised when text is sent to FSI.
    /// </summary>
    property OnSendText: TNotifyEvent read _onSendText write _onSendText;

    /// <summary>
    /// Event reaised when there is output availabe from FSI.
    /// </summary>
    property OnResultOutput: TNotifyEvent read _onResultOutput write _onResultOutput;

    /// <summary>
    /// Event raised when an error message is generated by FSI.
    /// </summary>
    property OnErrorOutput: TNotifyEvent read _onErrorOutput write _onErrorOutput;
  end;

implementation

uses
  // standard units 
  Windows, StrUtils, StdCtrls, Graphics, SysUtils,
  // plugin units
  Constants;

{$REGION 'Constructor & Destructor' }

constructor TFSIViewer.Create;
begin
  createEditor;
  createContextMenu;
  createFSI;
end;

destructor TFSIViewer.Destroy;
begin
  Stop;

  if Assigned(_pipedConsole) then
    FreeAndNil(_pipedConsole);
  if Assigned(_editor) then
    FreeAndNil(_editor);
  if Assigned(_config) then
    FreeAndNil(_config);

  inherited;
end;

{$ENDREGION}

{$REGION 'Public methods'}

function TFSIViewer.Start: Boolean;
begin
  _editor.Enabled := _pipedConsole.Start(_config.FSIPath, _config.FSIArgs);
  Result := _editor.Enabled;
end;

procedure TFSIViewer.Stop;
begin
  if (_pipedConsole.Running) then
    _pipedConsole.Stop(0);
end;

procedure TFSIViewer.SendText(const text: String; addDelimiter, appendEditor: Boolean);
var
  finalText, lastChars: String;
begin
  if ((Length(text) > 0) and (_pipedConsole.Running)) then
  begin
    if (addDelimiter) then
    begin
      // the delimiter is assumed to be ";;"

      lastChars := RightStr(text, 2);

      if (lastChars = ';;') then
        finalText := text
      else if ((Length(lastChars) > 1) and (lastChars[2] = ';')) then
        finalText := text + ';'
      else
        finalText := text + ';;';

      finalText := finalText + #13#10;
    end
    else
    begin
      finalText := text;
    end;

    if (_config.ConvertTabsToSpacesInFSIEditor) then
    begin
      finalText := StringReplace(finalText, #9, DupeString(' ', _config.TabLength), [rfReplaceAll]);
    end;

    if (appendEditor) then
    begin
      AddToEditor(finalText);
    end;

    if (Length(finalText) > 0) then
    begin
      _pipedConsole.Write(finalText[1], SizeOf(Char) * Length(finalText));
    end;

    if Assigned(_onSendText) then
    begin
      _onSendText(self);
    end;
  end;
end;

procedure TFSIViewer.AddToEditor(const text: String);
begin
  _editor.SelStart := _editor.GetTextLen;
  _editor.SelText := text;
end;

{$ENDREGION}

{$REGION 'Private methods'}

procedure TFSIViewer.createEditor;
begin
  _config := TConfiguration.Create;
  _editor := TRichEdit.Create(Nil);
  _editor.Width := 10;
  _editor.Height := 10;
  _editor.ScrollBars := ssBoth;
  _editor.OnKeyDown := doOnEditorKeyDown;
  _editor.OnKeyPress := doOnEditorKeyPress;
  _defEditorWndProc := _editor.WindowProc;
  _editor.WindowProc := editorWndProc;
end;

procedure TFSIViewer.createFSI;
begin
  _pipedConsole := TPipeConsole.Create(Nil);
  _pipedConsole.OnOutput := doOnPipeOutput;
  _pipedConsole.OnError := doOnPipeError;
end;

procedure TFSIViewer.createContextMenu;
var
  ctxMenu: TPopupMenu;
  menu: TMenuItem;
  menuCopy: TMenuItem;
begin
  ctxMenu := TPopupMenu.Create(_editor);

  menu := TMenuItem.Create(ctxMenu);
  menu.Caption := FSI_PLUGIN_EDITOR_CLEAR_MENU;
  menu.OnClick := doOnEditorClearContextMenuClick;
  ctxMenu.Items.Add(menu);

  menuCopy := TMenuItem.Create(ctxMenu);
  menuCopy.Caption := FSI_PLUGIN_EDITOR_COPY_MENU;
  menuCopy.OnClick := doOnEditorCopyContextMenuClick;
  ctxMenu.Items.Add(menuCopy);  

//  menu := TMenuItem.Create(ctxMenu);
//  menu.Caption := FSI_PLUGIN_EDITOR_CANCELEVAL_MENU;
//  menu.OnClick := doOnEditorCancelEvalContextMenuClick;
//  ctxMenu.Items.Add(menu);
  ctxMenu.OnPopup := doOnContextMenuPopup;
  _editor.PopupMenu := ctxMenu;
end;

procedure TFSIViewer.updateEditableAreaStart;
begin
  _editor.SelStart := _editor.GetTextLen;
  _editableAreaStartCoord := _editor.CaretPos;
  _editableAreaStartPos := _editor.SelStart;
end;

function TFSIViewer.isEditorCaretInAValidPos: Boolean;
begin
  Result := (_editor.CaretPos.Y >= _editableAreaStartCoord.Y) and
    (((_editor.CaretPos.Y = _editableAreaStartCoord.Y) and (_editor.CaretPos.X >= _editableAreaStartCoord.X)) or
      (_editor.CaretPos.Y > _editableAreaStartCoord.Y));
end;

procedure TFSIViewer.editorWndProc(var Message: TMessage);
var
  doDefProc: Boolean;
begin
  doDefProc := true;

  if (Message.Msg = WM_GETDLGCODE) then
  begin
    Message.Result := Message.Result or DLGC_WANTTAB;
  end
  else if (Message.Msg = WM_KEYDOWN) then
  begin
    doDefProc := (TWMKey(Message).CharCode <> VK_TAB);
  end;

  if (doDefProc) then
    _defEditorWndProc(Message);
end;

{$ENDREGION}

{$REGION 'Event handlers'}

procedure TFSIViewer.doOnPipeOutput(sender: TObject; stream: TStream);
var
  strStream: TStringStream;
begin
  strStream := TStringStream.Create;
  try
    strStream.CopyFrom(stream, 0);
    _editor.SelStart := _editor.GetTextLen;
    _editor.SelAttributes.Color := clBlack;
    _editor.SelText := strStream.DataString;
    updateEditableAreaStart;
    _editor.Perform(WM_VSCROLL, MakeWParam(SB_BOTTOM, 0), 0);

    if Assigned(_onResultOutput) then
      _onResultOutput(self);
  finally
    strStream.Free;
  end;
end;

procedure TFSIViewer.doOnPipeError(sender: TObject; stream: TStream);
var
  strStream: TStringStream;
begin
  strStream := TStringStream.Create;
  try
    strStream.CopyFrom(stream, 0);
    _editor.SelStart := _editor.GetTextLen;
    _editor.SelAttributes.Color := clRed;
    _editor.SelText := strStream.DataString;
    updateEditableAreaStart;
    _editor.Perform(WM_VSCROLL, MakeWParam(SB_BOTTOM, 0), 0);

    if Assigned(_onErrorOutput) then
      _onErrorOutput(self);
  finally
    strStream.Free;
  end;
end;

procedure TFSIViewer.doOnEditorKeyDown(sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  newText: string;
  editorCaretInAValidPos: Boolean;
begin
  // the caret should not be at a place where the data was generated by FSI
  editorCaretInAValidPos := (_editor.CaretPos.Y >= _editableAreaStartCoord.Y) and
    (((_editor.CaretPos.Y = _editableAreaStartCoord.Y) and (_editor.CaretPos.X >= _editableAreaStartCoord.X)) or
      (_editor.CaretPos.Y > _editableAreaStartCoord.Y));

  if (editorCaretInAValidPos) then
  begin
    if (Key = VK_RETURN) then
    begin
      _editor.SelStart := _editableAreaStartPos;
      _editor.SelLength := _editor.GetTextLen - _editableAreaStartPos;
      newText := _editor.SelText;
      updateEditableAreaStart;
      newText := newText + #13#10;
      SendText(newText, false, false);
    end
    else if (Key = VK_UP) then
    begin
      if (_editor.CaretPos.Y = _editableAreaStartCoord.Y) then
        Key := 0;
    end
    else if (Key = VK_LEFT) then
    begin
      if ((_editor.CaretPos.Y = _editableAreaStartCoord.Y) and
          (_editor.CaretPos.X <= _editableAreaStartCoord.X)) then
        Key := 0;
    end
    else if (Key = VK_BACK) or (Key = VK_DELETE) then
    begin
      if (not editorCaretInAValidPos) or
        (_editor.CaretPos.X = _editableAreaStartCoord.X) then
        Key := 0;
    end
    else if (Key = VK_TAB) then
    begin
      if (_config.ConvertTabsToSpacesInFSIEditor) then
      begin
        _editor.SelStart := _editor.GetTextLen;
        _editor.SelText := DupeString(' ', _config.TabLength);
      end;
    end;
  end
  else
    Key := 0;
end;

procedure TFSIViewer.doOnEditorKeyPress(sender: TObject; var Key: Char);
begin
  if (not isEditorCaretInAValidPos) then
    Key := #0;
end;

procedure TFSIViewer.doOnEditorClearContextMenuClick(sender: TObject);
begin
  if (_editor.Lines.Count > 0) then
  begin
    // todo: its assumed here that editor lines start with ">"; this should be chnaged in next
    // version.
    if LeftStr(_editor.Lines[_editor.Lines.Count - 1], 1) = '>' then
    begin
      _editor.Clear;
      AddToEditor('> ');
    end
    else
      _editor.Clear;

    updateEditableAreaStart;
  end;
end;

procedure TFSIViewer.doOnEditorCopyContextMenuClick(sender: TObject);
begin
  _editor.CopyToClipboard;
end;

procedure TFSIViewer.doOnContextMenuPopup(sender: TObject);
var
  ctxMenu: TPopupMenu;
  menuCopy: TMenuItem;
begin
  ctxMenu := _editor.PopupMenu;
  menuCopy := ctxMenu.Items.Find(FSI_PLUGIN_EDITOR_COPY_MENU);
  if Assigned(menuCopy) then begin
    menuCopy.Enabled := (_editor.SelLength > 0);
  end;
end;

{$ENDREGION}

end.
