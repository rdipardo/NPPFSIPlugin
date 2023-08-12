unit Constants;

// =============================================================================
// Unit: Constants
// Description: Defines constants and resource strings.
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

const

  FSI_PLUGIN_NAME = 'F# Interactive';
  FSI_PLUGIN_WND_TITLE = 'FSI';
  FSI_PLUGIN_MENU_TITLES: array[0..4] of WideString = (
    'Load FSI',
    'Send Text',
    '-',
    'Options',
    'About'
  );
  FSI_PLUGIN_EDITOR_CLEAR_MENU = 'Clear';
  FSI_PLUGIN_EDITOR_COPY_MENU = 'Copy';
  FSI_PLUGIN_EDITOR_CANCELEVAL_MENU = 'Cancel Evaluation';
  FSI_PLUGIN_START_FAILE_MSG = 'Failed to start FSI. Please make sure F# is installed and the' +
                               ' FSI binary path configuration is set properly';

type TFsiCmdID = (

  /// <summary>
  /// ID of function that invokes the FSI plugin.
  /// </summary>
  FSI_INVOKE_CMD_ID = 0,

  /// <summary>
  /// ID of the functions that sends text to the FSI plugin.
  /// </summary>
  FSI_SEND_TEXT_CMD_ID,

  /// <summary>
  /// ID of a separator menu item.
  /// </summary>
  FSI_SEP_1_CMD_ID,

  /// <summary>
  /// ID of function that invokes the configuration dialog.
  /// </summary>
  FSI_CONFIG_CMD_ID,

  /// <summary>
  /// ID of function that invokes the about dialog.
  /// </summary>
  FSI_ABOUT_CMD_ID
);

const

  /// <summary>
  /// Number of public functions exposed by FSI.
  /// </summary>
  FSI_PLUGIN_FUNC_COUNT = Ord(High(TFsiCmdID)) + 1;

  /// <summary>
  /// Name of dll containing the plugin
  /// </summary>
  FSI_PLUGIN_MODULE_FILENAME = 'NPPFSIPlugin.dll';

  /// <summary>
  /// Default number of spaces used when converting tabs to spaces.
  /// </summary>
  DEFAULT_TAB_LENGTH = 4;

  /// <summary>
  /// Name!
  /// </summary>
  FSI_PLUGIN_AUTHOR = 'Prapin Peethambaran';
  FSI_PLUGIN_MAINTAINER = 'Robert Di Pardo';

  /// <summary>
  /// App url
  /// </summary>
  FSI_PLUGIN_URL = 'https://github.com/rdipardo/NPPFSIPlugin';

  // config file related
  CONFIG_FSI_SECTION_NAME = 'FSI';
  CONFIG_FSI_SECTION_USE_DOTNET_FSI = 'USE_DOTNET_FSI';
  CONFIG_FSI_SECTION_BINARY_KEY_NAME = 'BINARY';
  CONFIG_FSI_SECTION_BINARYARGS_KEY_NAME = 'BINARY_ARGS';
  CONFIG_FSIEDITOR_SECTION_NAME = 'FSI_EDITOR';
  CONFIG_FSIEDITOR_SECTION_TABTOSPACES_KEY_NAME = 'CONVERT_TABS_TO_SPACES';
  CONFIG_FSIEDITOR_SECTION_TABLENGTH_KEY_NAME = 'TAB_LENGTH';
  CONFIG_FSIEDITOR_ECHO_NPP_TEXT_KEY_NAME = 'ECHO_NPP_TEXT';


implementation

end.
