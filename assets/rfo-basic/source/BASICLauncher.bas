
FN.DEF RfoIcon$(p$)
  IF IS_IN(".B",p$) THEN p$+="_"
  p$+=".png"
  FILE.EXISTS fe, p$
  IF fe THEN FN.RTN p$ ELSE FN.RTN "pkgunknown.png"
FN.END

VER$ = "v1.1"
PORT=4349
DELAY=3000 %' in ms
DQ$ = CHR$(34)
LF$ = CHR$(10)

% Load the GW lib in dark mode
GW_COLOR$="black"
GW_SILENT_LOAD=1
INCLUDE "GW.bas"

% Make title bar elements
tit$ = GW_ADD_BAR_TITLE$("BASIC! Launcher " + VER$)
GW_USE_THEME_CUSTO_ONCE("notext icon=power")
lbt$ = GW_ADD_BAR_LBUTTON$(">BACK")
GW_USE_THEME_CUSTO_ONCE("notext icon=gear")
rbt$ = GW_ADD_BAR_RBUTTON$(">SETTINGS")
GW_USE_THEME_CUSTO_ONCE("notext icon=back")
bbt$ = GW_ADD_BAR_LBUTTON$(">BACK")
GW_USE_THEME_CUSTO_ONCE("notext icon=check")
cbt$ = GW_ADD_BAR_RBUTTON$(">OK")

% Make sure BASIC! source folder exists
FILE.EXISTS fe, "../source/"
IF !fe
  GW_USE_THEME_CUSTO_ONCE("color=b")
  pe = GW_NEW_PAGE()
  GW_ADD_TITLEBAR(pe, lbt$ + tit$)
  GW_ADD_TEXT(pe, "Error: BASIC! source folder not found on the system.")
  GW_ADD_TEXT(pe, "Press the Back key to exit.")
  GW_RENDER(pe)
  GW_WAIT_ACTION$()
  EXIT
ELSE
  FILE.ROOT path$
  path$ = LEFT$(path$, LEN(path$) - 5) + "/source/"
  PRINT "BASIC! source folder found on the system:"
  PRINT path$
ENDIF

% List of BASIC! variants supported:
ARRAY.LOAD pkgn$[], ~
  "RFO-BASIC! Reborn", ~
  "RFO-BASIC! Legacy", ~
  "OliBasic XXIV or previous", ~
  "OliBasic V3", ~
  "hBasic V1 or V2", ~
  "hBasic V3"
ARRAY.LOAD pkg$[], ~
  "com.rfo.Basic", ~      % Reborn
  "com.rfo.basic", ~      % Legacy
  "com.rfo.basicTest", ~  % Oli v1 v2
  "com.rfo.basicOli", ~   % Oli v3
  "com.rfo.basich", ~     % Humpty v1 v2
  "com.rfo.hbasic"        % Humpty v3
ARRAY.LENGTH npkg, pkg$[]
DIM pkg_installed[npkg]

% Dump variant icons (needed by GW)
MAKE_SURE_IS_ON_SD(pkg$[1]+"_.png")
FOR i=2 TO npkg
  MAKE_SURE_IS_ON_SD(pkg$[i]+".png")
NEXT
MAKE_SURE_IS_ON_SD("pkgunknown.png")

% Scan for variants on the system
FOR i=1 TO npkg
  pkg_installed[i] = PKGEXIST(pkg$[i])
  IF pkg_installed[i]
    IF ++nlauncher_pkg = 1 THEN PRINT "BASIC! variants found on the system:"
    PRINT "- " + pkg$[i]
  ENDIF
NEXT

% Special case: no variant currently installed
IF 0=nlauncher_pkg
  GW_USE_THEME_CUSTO_ONCE("color=b")
  pe = GW_NEW_PAGE()
  GW_ADD_TITLEBAR(pe, lbt$ + tit$)
  GW_ADD_TEXT(pe, "Error: no BASIC! variant currently installed on the system.")
  GW_ADD_TEXT(pe, "Press the Back key to exit.")
  GW_RENDER(pe)
  GW_WAIT_ACTION$()
  EXIT
ENDIF

% In case of multiple variants: is there a preference?
IF nlauncher_pkg=1
  FOR i=1 TO npkg
    IF pkg_installed[i]=1 THEN launcher_pkg$=pkg$[i]
  NEXT
ELSEIF nlauncher_pkg > 1
  FILE.EXISTS fe, "../launcher.pref"
  IF fe
    TEXT.OPEN r, fid, "../launcher.pref"
    TEXT.READLN fid, launcher_pkg$
    TEXT.CLOSE fid
  ENDIF
ENDIF

% Create Settings page
GW_USE_THEME_CUSTO_ONCE("color=b")
ps = GW_NEW_PAGE()
GW_ADD_TITLEBAR(ps, bbt$ + tit$ + cbt$)
GW_INJECT_HTML(ps, "<style>img{width:60px;height:60px}</style>")
GW_ADD_TEXT(ps, "Select the BASIC! variant to launch when receiving a file:")
FOR i=1 TO npkg
  GW_USE_THEME_CUSTO_ONCE("style='float:right'")
  GW_ADD_IMAGE(ps, RfoIcon$(pkg$[i]))
  IF launcher_pkg$=pkg$[i] THEN s$=">" ELSE s$="" % selected launcher
  GW_ADD_RADIO(ps, papa, s$+pkgn$[i]+"\n(<i>"+pkg$[i]+"</i>)")
  IF 0=papa THEN papa=GW_LAST_ID()
NEXT

% Create Main page
GW_USE_THEME_CUSTO_ONCE("color=b")
mp = GW_NEW_PAGE()
GW_ADD_TITLEBAR(mp, lbt$ + tit$ + rbt$)
GW_ADD_TEXT(mp, "Launcher ready to receive requests from computers on the LAN. " ~
              + "Press the Home key to put in background. Press the Back key to exit.")
GW_USE_THEME_CUSTO_ONCE("color=b align=center")
pgbar = GW_ADD_PROGRESSBAR(mp, "Waiting connection...")
tinfo = GW_ADD_TEXT(mp, "") % Received file name
GW_OPEN_COLLAPSIBLE(mp, "Log")
GW_USE_THEME_CUSTO_ONCE("style='font-family:monospace;color:lime'")
txlog = GW_ADD_TEXT(mp, log$) % History log
GW_CLOSE_COLLAPSIBLE(mp)

% End of page creation - Starting point
% First start: need to define a launcher
IF launcher_pkg$="" THEN GOTO Settings ELSE GOTO Main

%===================================================================
Settings:

% Show settings page
GW_RENDER(ps)

% Disable (gray out) the variants not installed on the system
FOR i=1 TO npkg
  IF !pkg_installed[i]
    GW_DISABLE(papa+2*(i-1))    % disable radio
    GW_DISABLE(papa+2*(i-1)-1)  % disable icon
  ENDIF
NEXT

% Handle user action
StgManage:
r$ = GW_WAIT_ACTION$()
IF r$="OK"
  FOR i=1 TO npkg
    IF GW_RADIO_SELECTED(papa+2*(i-1)) THEN launcher_pkg$=pkg$[i]
  NEXT
  IF ""=launcher_pkg$
    POPUP "You need to select a launcher"
  ELSE
    TEXT.OPEN w, fid, "../launcher.pref"
    TEXT.WRITELN fid, launcher_pkg$
    TEXT.CLOSE fid
    GOTO Main
  ENDIF
ENDIF
IF r$ = "BACK"
  IF ""=launcher_pkg$ THEN EXIT ELSE GOTO Main % goto main page
ENDIF
GOTO StgManage
%===================================================================

%===================================================================
Main:

% Show main page
GW_RENDER(mp)

% Check for connections and handle user action
AnswerBroadcast:

DO
  IF BACKGROUND()
    NOTIFY "BASIC! Launcher", "Running in background", "Running in background", 0
  ELSE
    r$ = GW_ACTION$()
    IF r$ = "BACK" THEN EXIT
    IF r$ = "SETTINGS" THEN GOTO Settings
  ENDIF
  UDP.CLIENT.STATUS flag
UNTIL flag

SOCKET.SERVER.CREATE PORT
SOCKET.SERVER.CONNECT 0

GOSUB WAIT_FOR_CLIENT_CONNECT

SOCKET.SERVER.READ.LINE clientVersion$
SOCKET.SERVER.WRITE.LINE VER$
IF clientVersion$ <> VER$
  nfo_displayed = 1
  nfo_time = CLOCK()
  e$  = "<span style='color:lightcoral'>"
  e$ += "Version of PC Launcher does not match "
  e$ += "("+clientVersion$+" Vs "+VER$+"). Aborting..."
  e$ += "</span>"
  GW_MODIFY(tinfo, "text", e$)
  log$=e$+"\n"+log$
  GW_MODIFY(txlog, "text", log$)
  SOCKET.SERVER.DISCONNECT
  SOCKET.SERVER.CLOSE
  GOTO AnswerBroadcast
END IF

GOSUB WAIT_FOR_CLIENT_CONNECT
SOCKET.SERVER.READ.LINE computerName$

GOSUB WAIT_FOR_CLIENT_CONNECT
SOCKET.SERVER.READ.LINE basFile$

GW_MODIFY(pgbar, "text", "Connection from "+computerName$)

e$ = "Transferring "+DQ$+basFile$+DQ$
FILE.EXISTS fe, "../source/" + basFile$
IF fe
  BYTE.OPEN r, fid, "../source/" + basFile$
  BYTE.COPY fid, "../source/" + LEFT$(basFile$, LEN(basFile$) - 3) + "bkp.bas"
  FILE.DELETE fe, "../source/" + basFile$
  e$ += " (existing file was backed up)"
END IF
GW_MODIFY(tinfo, "text", e$)

GOSUB WAIT_FOR_CLIENT_CONNECT
BYTE.OPEN w, fid, "../source/" + basFile$
SOCKET.SERVER.READ.FILE fid
BYTE.CLOSE fid

SOCKET.SERVER.DISCONNECT
SOCKET.SERVER.CLOSE

FOR i=1 TO 100
  GW_SET_PROGRESSBAR(pgbar, i)
NEXT

PAUSE 250
GW_MODIFY(tinfo, "text", "Launching "+DQ$+basFile$+DQ$)
e$  = "<span style='color:lime'>"
e$ += "Launched "+DQ$+basFile$+DQ$+" received from "+computerName$
e$ += "</span>"
log$=e$+"\n"+log$
GW_MODIFY(txlog, "text", log$)
PAUSE 250

PKGLAUNCH launcher_pkg$, path$+basFile$ % PKGLAUNCH "com.rfo.basic", "path/to/prog.bas"

GOSUB ResetNfo

GOTO AnswerBroadcast

%===================================================================

WAIT_FOR_CLIENT_CONNECT:
maxclock = CLOCK() + DELAY
DO
  GOSUB CheckBgnOrAction
  SOCKET.SERVER.STATUS st
UNTIL st = 3
maxclock = CLOCK() + DELAY
DO
  GOSUB CheckBgnOrAction
  SOCKET.SERVER.READ.READY flag
UNTIL flag
RETURN

%===================================================================

OnError:
CONSOLE.SAVE "../launcher.log"
POPUP "Fatal Error"
EXIT

%===================================================================

ResetNfo:
GW_MODIFY(tinfo, "text", "")
GW_SET_PROGRESSBAR(pgbar, 0)
GW_MODIFY(pgbar, "text", "Waiting connection...")
nfo_displayed = 0
RETURN

%===================================================================

CheckBgnOrAction:
IF BACKGROUND()
  NOTIFY "BASIC! Launcher", "Running in background", "Running in background", 0
ELSE
  r$ = GW_ACTION$()
  IF r$ = "BACK" THEN EXIT
  IF r$ = "SETTINGS"
    SOCKET.SERVER.CLOSE
    GOTO Settings
  ENDIF
ENDIF
IF nfo_displayed & CLOCK() > nfo_time+DELAY THEN GOSUB ResetNfo
IF CLOCK() > maxclock
  SOCKET.SERVER.CLOSE
  GOTO AnswerBroadcast
ENDIF
RETURN
