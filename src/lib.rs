use tauri::{State, Manager};
use std::sync::Mutex;
use std::net::TcpStream;

/// Estado compartido para la conexión del servidor
pub struct ServerConnection {
    pub stream: Option<TcpStream>,
    pub connected: bool,
}

impl ServerConnection {
    pub fn new() -> Self {
        Self {
            stream: None,
            connected: false,
        }
    }
}

#[tauri::command]
fn connect_server(state: State<Mutex<ServerConnection>>, host: String, port: u16) -> Result<String, String> {
    let addr = format!("{}:{}", host, port);
    match TcpStream::connect(&addr) {
        Ok(stream) => {
            let mut conn = state.inner().lock().unwrap();
            *conn = ServerConnection {
                stream: Some(stream),
                connected: true,
            };
            Ok(format!("Connected to {}", addr))
        }
        Err(e) => Err(format!("Error connecting to {}: {}", addr, e))
    }
}

#[tauri::command]
fn disconnect_server(state: State<Mutex<ServerConnection>>) -> Result<String, String> {
    let mut conn = state.inner().lock().unwrap();
    *conn = ServerConnection {
        stream: None,
        connected: false,
    };
    Ok("Disconnected from server".to_string())
}

#[tauri::command]
fn get_server_status(state: State<Mutex<ServerConnection>>) -> String {
    let conn = state.inner().lock().unwrap();
    if conn.connected { "Connected".to_string() } else { "Disconnected".to_string() }
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            connect_server,
            disconnect_server,
            get_server_status
        ])
        .setup(|app| {
            app.manage(Mutex::new(ServerConnection::new()));
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}