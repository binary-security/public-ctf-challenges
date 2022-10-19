var npa = require('npm-package-arg');

const axios = require('axios');
const { promisify } = require('util');
const fs = require('fs')
const path = require('path')
const os = require('os')

const exec = promisify(require('child_process').exec);
const mkdtemp = promisify(require('fs').mkdtemp);


module.exports = {
    validatePackage: async function (package) {
        
        try {
            // verify package name with npa
            const parsed = npa(package);
        } catch (error) {
            console.log('Error parsing package name');
            console.log(error);
            return ['Wrong package name format', 'false'];
        }
        
        // check if package exists in the CDN
        packageExists = await validatePackageExists(package);
        if (packageExists) {
            return ['The package exists in the CDN', 'true'];
        } else {
            return ['The package does not exist in the CDN', 'false'];
        } 
    },

    packageSecurityCheck: async function (package) {
        
        try {
            var tmp_folder = await mkdtemp(path.join(os.tmpdir(), 'package-')); 
        } catch (error) {
            return 'ERROR:';
        }
           
        try {
            var installText = await exec(`cd ${tmp_folder} && npm install ${package}`);
        } catch (error) {
            return `ERROR: Security check of package could not be performed<pre>${error.stdout}${error.stderr}</pre>`;
        }
        console.log(installText);
        var auditText;
        
        // Run npm audit to check if package is vulnerable
        try {
            auditText = await exec(`cd ${tmp_folder} && npm audit`);
            auditText = auditText['stdout'];
        } catch (error) {
            auditText = error.stdout;
        }
        
        try {
            await exec(`rm -rf ${tmp_folder}`);
        } catch (error) {
            console.log(error);
        }
        
        if (auditText.includes('found 0 vulnerabilities')) {
            return `Package is secure<pre>${auditText}</pre>`
        } else {
            return `WARNING: Package is insecure<pre>${auditText}</pre>`
        }
    }
  };

async function validatePackageExists(package) {
    console.log(`Sending request to cdn.jsdelivr.net to determine if package ${package} exists`);
    var packageExists = false;
    try {
        await axios
        .get(`https://cdn.jsdelivr.net/npm/${package}`)
        .then(res => {
            console.log(`statusCode: ${res.status}`);
            if (res.status === 200) {
                packageExists = true;
            } else {
                packageExists = false;
            }
        })
        .catch(error => {
            console.error(error);
        });   
    } catch (error) {
        console.log('Error requesting package')
        console.error(error);
        packageExists = false;
    }
    return packageExists;
};