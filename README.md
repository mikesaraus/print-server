# Python Print Server

A simple HTTP file server with web-based file upload capabilities, designed for easy document sharing and printing workflows. Upload files through a modern web interface and organize them with paper size prefixes.

## Description

A lightweight Python HTTP server that provides a clean web interface for uploading and organizing files. Perfect for small offices, home networks, or temporary file sharing needs. Features automatic file naming with paper size prefixes, directory browsing, and can be installed as a system service for continuous operation.

## Features

- **Web-based file upload**: Drag and drop or select multiple files through a clean web interface
- **Paper size selection**: Choose paper size (A4, Letter, Legal, etc.) and files are automatically prefixed
- **File organization**: Browse uploaded files in a directory structure
- **Multiple file formats**: Supports PDF, images (PNG, JPG, WebP, etc.), Office documents, and text files
- **Systemd service**: Can be installed as a system service for automatic startup
- **Auto-cleanup**: Optional cron job to automatically clear uploaded files

## Screenshots

The server provides a clean web interface with:

- File upload area with drag-and-drop support
- Paper size selection radio buttons
- Directory browsing of uploaded files
- Responsive design that works on desktop and mobile

## Installation

### Quick Start

1. **Clone or download the project**:

   ```bash
   git clone https://github.com/mikesaraus/print-server.git
   cd print-server
   ```

2. **Run the server**:

   ```bash
   python3 main.py
   ```

3. **Access the web interface**:
   Open your browser and go to `http://localhost:8000`

### System Installation (Linux)

For production use, install as a systemd service:

```bash
# Make install script executable
chmod +x install.sh

# Run the installation script
sudo ./install.sh
```

This will:

- Create a systemd service that starts automatically on boot
- Set up a cron job to clear uploaded files on reboot
- Configure the server to run on port 8000

### Manual Installation

1. **Install dependencies** (Python 3.6+ required):

   ```bash
   # No external dependencies required - uses only Python standard library
   ```

2. **Create uploads directory**:

   ```bash
   mkdir uploads
   ```

3. **Run the server**:
   ```bash
   python3 main.py [port]
   ```

## Usage

### Basic Usage

1. **Start the server**:

   ```bash
   python3 main.py 8000
   ```

2. **Upload files**:

   - Open `http://localhost:8000` in your browser
   - Select paper size (optional)
   - Choose files to upload
   - Click "Upload"

3. **Browse files**:
   - View uploaded files in the directory listing
   - Click on files to download them
   - Navigate through subdirectories

### Command Line Options

```bash
python3 main.py [options] [port]

Options:
  -b, --bind ADDRESS    Bind to specific address (default: 0.0.0.0)
  port                  Port number (default: 8000)

Examples:
  python3 main.py                    # Run on 0.0.0.0:8000
  python3 main.py 9000              # Run on port 9000
  python3 main.py -b 127.0.0.1 8080 # Run on localhost:8080
```

### File Naming

When you select a paper size and upload files, the server automatically prefixes filenames:

- **Original**: `document.pdf`
- **With A4 selected**: `A4-document.pdf`
- **With Letter selected**: `Letter-document.pdf`

## Supported File Types

The server accepts these file formats:

- **Documents**: PDF, TXT, DOC, DOCX, PAGES
- **Images**: PNG, JPG, JPEG, WebP, GIF, BMP, TIFF, SVG
- **Presentations**: PPT, PPTX
- **Spreadsheets**: XLS, XLSX, NUMBERS

## Development

### Project Structure

- `main.py`: Core HTTP server implementation using Python's `http.server`
- `style.css`: Modern CSS with responsive design
- `script.js`: Client-side functionality for file handling
- `install.sh`: Automated installation script for Linux systems

### Key Components

1. **SimpleHTTPFileServerRequestHandler**: Main request handler class

   - `do_GET()`: Serves files and directory listings
   - `do_POST()`: Handles file uploads with paper size prefixing

2. **HTML Template**: Embedded HTML with dynamic content replacement
3. **File Processing**: Multipart form data parsing with email library

## Troubleshooting

### Common Issues

1. **Port already in use**:

   ```bash
   # Use a different port
   python3 main.py 9000
   ```

2. **Permission denied**:

   ```bash
   # Check uploads directory permissions
   chmod 755 uploads
   ```

3. **Service won't start**:

   ```bash
   # Check service status
   sudo systemctl status print-server

   # View logs
   sudo journalctl -u print-server
   ```
