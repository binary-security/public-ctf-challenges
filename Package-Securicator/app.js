const http = require('http');
const validator = require('./package-validator.js')
const fs = require('fs');

const hostname = '0.0.0.0';
const port = 80;

const server = http.createServer(async function (req, res) {
    if (req.url == '/') {
        try {
            const data = fs.readFileSync('./index.html', 'utf8');
            res.statusCode = 200;
            res.setHeader('Content-Type', 'text/html');
            res.end(data);
          } catch (err) {
            console.error(err);
        }          
        ;
    } else if (req.url == '/package-validator') {
        const buffers = [];
        var npmAudit = '';

        for await (const chunk of req) {
            buffers.push(chunk);
        }

        // get package name from parameter
        const package = new URLSearchParams(Buffer.concat(buffers).toString()).get('package');

        [returnText, valid] = await validator.validatePackage(package);
        
        if (valid === 'true') {
            var auditText = await validator.packageSecurityCheck(package)
            npmAudit = `<h2>Security check</h2><p>${auditText}</p>`;
        }

        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/html');
        
        res.end(`<!DOCTYPE html>
        <html lang="en">
        <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
                <title>NPM Package Security Check</title>
            </head>
            <body>
                <header>
                    <h1>NPM Package Security Check</h1>
                </header>
                <h2>Status</h2>
                <p>${returnText}</p>
                ${npmAudit}<br />
                <button onclick="history.back()">Go Back</button>
            </body>
        </html>`);

        npmAudit = ''
    } else {
        res.statusCode = 404;
        res.setHeader('Content-Type', 'text/html');
        res.end(`<html><body>Not found</body></html>`);
    }
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});