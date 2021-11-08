; https://github.com/TheArkive/Socket_ahk2
#Include <Socket_ahk2/_socket>

; NOTE: Remove this! (allow multiple instances)
#SingleInstance Off

; Keep running in background
Persistent

; ==========================================================
; ========================= Setup ==========================
; ==========================================================

; Create tray menu
tray := A_TrayMenu
tray.delete()
tray.add("Show &GUI", show_gui)
tray.add()
tray.add("&Exit", exit_app)
tray.default := "Show &GUI"
TraySetIcon("chat.ico")

; Create GUI
g := Gui("Resize", "Chatty")
g.Add("Text",,"Enter message && press Ctrl+Enter to send")
_msg := g.Add("Edit","vMsg Multi w400 h250")
g.Add("Button", "Default xp+100 y+m w80", "&Send").OnEvent("Click", send_clicked)
g.Add("Button", "w80 x+m", "&Cancel").OnEvent("Click", cancel_clicked)
g.OnEvent("Close", cancel_clicked)
g.OnEvent("Escape", cancel_clicked)

; Create sockets
server_sock := winsock("server", socket_callback, "IPV4")
client_sock := winsock("client", socket_callback, "IPV4")

; Try connecting to the other end
client_sock.Connect("localhost", 27015)

mode := "Client"

; ==========================================================
; ======================== Hotkeys =========================
; ==========================================================

; TODO: Choose a different hotkey
; F1::show_gui

HotIfWinActive "Chatty"
Hotkey("^Enter", send_clicked)
HotIf

; ==========================================================
; ======================= Functions ========================
; ==========================================================

start_server(*) {
    global mode
    server_sock.Bind("0.0.0.0",27015)
    server_sock.Listen()
    mode := "Server"
}

socket_callback(sock, event, error_code) {
    if (sock.name = "client" and error_code) {
        start_server()
        TrayTip("Now listening on 27015!", "Chatty")
        return
    }

    global client_sock, client_addr

    if (event = "accept") {
        sock.Accept(&client_addr,&client_sock)
        ; TrayTip("New connection" . sock.name, "Chatty")
    }

    else if (event = "read") {
        buf := sock.Recv()
        handle_msg(StrGet(buf,"UTF-8"))
    }

    ; else {
    ;     MsgBox(sock.name . "`n" . event . "`n" . error_code, "Chatty")
    ; }
}

handle_msg(msg) {
    if(RegExMatch(msg, "^(https?://|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$")) {
        TrayTip("Opening received URL in browser", "Chatty")
        Run(msg)
    }
    else {
        TrayTip("Copied received msg to clipboard", "Chatty")
        A_Clipboard := msg
    }
}

show_gui(*) {
    global mode
    g.Title := "Chatty - " . mode
    g.Show("AutoSize Center")
}

send_clicked(*) {
    msg := _msg.Value
    _msg.Value := ""
    g.Hide()

    buf := Buffer(StrPut(msg, "UTF-8"),0)
    StrPut(msg, buf, "UTF-8")

    client_sock.Send(buf)
}

cancel_clicked(*) {
    _msg.Value := ""
    g.Hide()
}

exit_app(*) {
    ExitApp()
}
