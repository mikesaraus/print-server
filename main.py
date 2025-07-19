#!/usr/bin/env python3
import os
import sys

# Always run from the script's directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))

from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, unquote
from mimetypes import guess_type
from argparse import ArgumentParser
from email import policy, message_from_bytes

UPLOADS_ROOT = Path('uploads').resolve()
UPLOADS_ROOT.mkdir(exist_ok=True)

icons = {
    'arrow_up': '''
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-up" viewBox="0 0 16 16">
  <path fill-rule="evenodd" d="M8 15a.5.5 0 0 0 .5-.5V2.707l3.146 3.147a.5.5 0 0 0 .708-.708l-4-4a.5.5 0 0 0-.708 0l-4 4a.5.5 0 1 0 .708.708L7.5 2.707V14.5a.5.5 0 0 0 .5.5z"/>
</svg>
''',

    'folder': '''
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-folder" viewBox="0 0 16 16">
  <path d="M.54 3.87.5 3a2 2 0 0 1 2-2h3.672a2 2 0 0 1 1.414.586l.828.828A2 2 0 0 0 9.828 3h3.982a2 2 0 0 1 1.992 2.181l-.637 7A2 2 0 0 1 13.174 14H2.826a2 2 0 0 1-1.991-1.819l-.637-7a1.99 1.99 0 0 1 .342-1.31zM2.19 4a1 1 0 0 0-.996 1.09l.637 7a1 1 0 0 0 .995.91h10.348a1 1 0 0 0 .995-.91l.637-7A1 1 0 0 0 13.81 4H2.19zm4.69-1.707A1 1 0 0 0 6.172 2H2.5a1 1 0 0 0-1 .981l.006.139C1.72 3.042 1.95 3 2.19 3h5.396l-.707-.707z"/>
</svg>
''',

    'file-earmark-fill': '''
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-file-earmark-fill" viewBox="0 0 16 16">
  <path d="M4 0h5.293A1 1 0 0 1 10 .293L13.707 4a1 1 0 0 1 .293.707V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2zm5.5 1.5v2a1 1 0 0 0 1 1h2l-3-3z"/>
</svg>
''',
}

# Read HTML template from file
with open('index.html', 'r', encoding='utf-8') as f:
    html_template = f.read()

class PrintHTTPServer(BaseHTTPRequestHandler):
    def get_path_from_request(self):
        urlparse_result = urlparse(self.path)
        requested = Path(unquote(urlparse_result.path).lstrip('/'))
        target = UPLOADS_ROOT / requested
        try:
            # Prevent directory traversal outside uploads
            target.relative_to(UPLOADS_ROOT)
            return target
        except ValueError:
            return UPLOADS_ROOT


    def load_html(self, path, uploaded_filenames=[]):
        out_html = html_template.replace(
            '$upload_result_html',
            '<p style="text-align: center"><span style="font-weight: bold">{}</span> file(s) have been uploaded.</p>'.format(len(uploaded_filenames)) if uploaded_filenames else ''
        )
        file_list_html = []
        
        # Only show "Go up" if not at uploads root
        if path != UPLOADS_ROOT:
            file_list_html.append(
                '<li><a class="go-up-entry" href="..">{} Go up</a></li>'.format(icons["arrow_up"])
            )
            
        for file in sorted(path.iterdir()):
            icon, trailing_path, html_class = None, None, None
            if (file.is_dir()):
                icon = icons['folder']
                trailing_path = '/'
                html_class = 'directory-entry'
            else:
                icon = icons['file-earmark-fill']
                trailing_path = ''
                html_class = 'file-entry'
            file_list_html.append(
                '<li><a class="{}" href="/{}{}"><span>{} {}</span></a></li>'.format(
                    html_class, 
                    file.relative_to(UPLOADS_ROOT), 
                    trailing_path, 
                    icon, 
                    file.name
                )
            )
        if not len(file_list_html):
            file_list_html.append(
                '<li>No uploaded files found.</li>'
            )
        relative_path = path.relative_to(UPLOADS_ROOT)
        display_path = '/' if str(relative_path) == '.' else '/{}'.format(relative_path)
        return out_html.replace('$path', display_path).replace('$file_list_html', ''.join(file_list_html))

    def serve_static_file(self, file_path, content_type=None):
        if not Path(file_path).exists():
            self.send_response(404)
            self.end_headers()
            return False
        
        # Auto-detect content type if not provided
        if content_type is None:
            mime_type = guess_type(file_path)
            content_type = mime_type[0] if mime_type[0] else 'application/octet-stream'
        
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.end_headers()
        self.wfile.write(Path(file_path).read_bytes())
        return True

    def do_GET(self):
        path = self.get_path_from_request()

        # Handle static files with automatic content type detection
        static_files = {
            '/style.css': 'style.css',
            '/script.js': 'script.js', 
            '/print.svg': 'print.svg'
        }
        
        if self.path in static_files:
            if self.serve_static_file(static_files[self.path]):
                return
        
        if path.is_file():
            mime_type = guess_type(path.name)
            self.send_response(200)
            self.send_header('Content-Type', '{}; charset={}'.format(mime_type[0], mime_type[1]))
            self.end_headers()
            self.wfile.write(path.read_bytes())
        elif path.is_dir():
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(self.load_html(path).encode('utf-8'))
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write('<h1>Not found</h1>'.encode('utf-8'))


    def do_POST(self):
        path = self.get_path_from_request()
        request_length = int(self.headers['Content-Length'])
        raw_email_message = b''
        for k, v in self.headers.items():
            raw_email_message += '{}: {}\r\n'.format(k, v).encode('ascii')
        raw_email_message += b'\r\n' + self.rfile.read(request_length)
        email_message = message_from_bytes(raw_email_message, policy=policy.strict)
        filenames = []
        paper_size = None
        
        # First pass: find the paper-size field
        for part in email_message.walk():
            if part.get_content_disposition() == 'form-data':
                name = part.get_param('name', header='Content-Disposition')
                if name == 'paper-size':
                    paper_size = part.get_content()
                    break
        
        # Second pass: process files with paper-size prefix if available
        for part in email_message.walk():
            filename = part.get_filename()
            if filename != None:
                if paper_size:
                    name, ext = filename.rsplit('.', 1) if '.' in filename else (filename, '')
                    new_filename = "{}-{}.{}".format(paper_size, name, ext) if ext else "{}-{}".format(paper_size, name)
                else:
                    new_filename = filename
                
                target_path = Path(path / new_filename)
                target_path.write_bytes(part.get_content())
                filenames.append(new_filename)
        self.send_response(201)
        self.send_header('Content-Type', 'text/html')
        self.end_headers()
        self.wfile.write(self.load_html(path, uploaded_filenames=filenames).encode('utf-8'))


def run_server(
        address, port,
        server_class = HTTPServer,
        handler_class = PrintHTTPServer,
    ):
    server_address = (address, port)
    httpd = server_class(server_address, handler_class)
    print('Running HTTP file server on {}:{}'.format(address, port))
    httpd.serve_forever()

if __name__ == '__main__':
    parser = ArgumentParser(description='A simple HTTP file server that supports uploading from the browser')
    parser.add_argument('-b', '--bind', type=str, metavar='ADDRESS', help='bind to address', default='0.0.0.0')
    parser.add_argument('port', type=int, nargs='?', help='bind to port', default=8000)
    args = parser.parse_args()
    run_server(address=args.bind, port=args.port)
