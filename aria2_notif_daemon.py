import asyncio
import websockets
import json
import subprocess

async def notify_hyprland(title, message):
    subprocess.run(["notify-send", title, message])

async def handle_message(message):
    data = json.loads(message)
    
    # Обработка успешного завершения загрузки
    if "method" in data and data["method"] in ("aria2.onDownloadComplete", "aria2.onBtDownloadComplete"):
        download_info = data["params"][0]
        gid = download_info["gid"]

        async with websockets.connect('ws://localhost:6800/jsonrpc') as websocket:
            await websocket.send(json.dumps({
                "jsonrpc": "2.0",
                "id": "qwer",
                "method": "aria2.tellStatus",
                "params": [gid]
            }))
            response = await websocket.recv()
            status_info = json.loads(response)["result"]
            
            if 'bittorrent' in status_info and 'info' in status_info['bittorrent']:
                name = status_info['bittorrent']['info']['name']
            else:
                name = status_info['files'][0]['path'].split('/')[-1]
            
            title = "Aria2 Daemon"
            message = f"{name} has been downloaded successfully."
            await notify_hyprland(title, message)
    
    # Обработка ошибок
    elif "method" in data and data["method"] == "aria2.onDownloadError":
        error_info = data["params"][0]
        gid = error_info["gid"]
        error_message = error_info.get("errorMessage", "Unknown error")

        title = "Aria2 Error"
        message = f"Download {gid} failed: {error_message}"
        await notify_hyprland(title, message)

async def listen_to_aria2():
    async with websockets.connect('ws://localhost:6800/jsonrpc') as websocket:
        await websocket.send(json.dumps({
            "jsonrpc": "2.0",
            "method": "aria2.onDownloadComplete"
        }))
        await websocket.send(json.dumps({
            "jsonrpc": "2.0",
            "method": "aria2.onBtDownloadComplete"
        }))
        await websocket.send(json.dumps({
            "jsonrpc": "2.0",
            "method": "aria2.onDownloadError"
        }))
        while True:
            message = await websocket.recv()
            await handle_message(message)

if __name__ == "__main__":
    asyncio.run(listen_to_aria2())
