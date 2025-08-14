#!/usr/bin/python

import http.server
import ssl
import subprocess
import os


cert_file="/opt/utkarai/utkarai_cert.pem"
key_file="/opt/utkarai/utkarai_key.pem"
script_path="/opt/utkarai/utkarai_helper"

# Define the request handler
class SimpleHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):

    def do_redirect(self):
        client_ip = self.client_address[0]
        # Redirect to the client's IP address
        self.send_response(302)
        self.send_header("Location", f"http://{client_ip}")
        self.end_headers()


    def do_GET(self):
        if self.path == '/button':
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"""
                <html>
                <body>
                    <h1>Press the Button</h1>
                    <form action="/execute" method="post">
                        <button type="submit">Execute Script</button>
                    </form>
                </body>
                </html>
            """)
        else:
            self.do_redirect()

    def do_POST(self):
        if self.path == '/execute':
            # Execute the shell script
            try:
                result = subprocess.run([script_path], check=True, text=True, capture_output=True)
                output = result.stdout.encode()  # Capture the output of the script
                self.send_response(200)
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(b"<h1>Script Executed Successfully</h1>")
                #self.wfile.write(b"<pre>" + output + b"</pre>")
                print(output)
            except subprocess.CalledProcessError as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b"<h1>Error Executing Script</h1>")
                self.wfile.write(b"<pre>" + e.stderr.encode() + b"</pre>")
        else:
            self.do_redirect()

httpd = http.server.HTTPServer(('', 8443), SimpleHTTPRequestHandler)

# Create an SSL context
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile=cert_file, keyfile=key_file)

# Wrap the server's socket with SSL
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print("Serving on https://0.0.0.0:8443")
httpd.serve_forever()
