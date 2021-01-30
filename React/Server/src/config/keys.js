const fs = require('fs');
const path = require('path');

export const publicKey = fs.readFileSync(
    path.resolve(__dirname, './public.pem')
);