// middleware function to use to interact with auth server
const axios = require('axios');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

// SSO Url for refreshing tokens that are about to expire
const SSO_Refresh_URL = 'https://auth.devclub.in/auth/refresh-token';
const SSO_Login_URL = 'https://auth.devclub.in/user/login?serviceURL=';

// Client url, this string should be equal to the exact base URL of the client
const clientURL = 'http://localhost:5000';

const accessTokenName = 'token'; // The default JWT token name
const refreshTokenName = 'rememberme'; // Name for remember me style tokens

const publicKey = fs.readFileSync(path.resolve(__dirname, './public.pem')); // Public Key path

// Max time remaining for token expiry, after which a refresh request will be sent to the SSO for refreshing the token
const maxTTL = 2 * 60; // 5 minutes

// Url for handling redirects, if none is provided than the user will automatically be redirected
// to the SSO Login Page
const redirectURL = '/';
// Array of public paths, these paths will be available without logging in and even for users that do not have sufficient permisisons
const publicPaths = ['^/public.*','^/asset.*','^/$'];

const UnauthorizedHandler = (req,res) => {
    return res.status(401).send("Alas You are out of scope! Go get some more permissions dude");
}

const ROLES = {
    '^/admin.*': ['admin']
}

const defaultRoles = ['external_user'];

const auth = async (req, res, next) => {
    // Extract tokens from cookies
    const token = req.cookies[accessTokenName];
    const refreshToken = req.cookies[refreshTokenName];

    try {
        let decoded;
        if (!token) {
            if (!refreshToken) {
                throw jwt.JsonWebTokenError;
            }
            decoded = await jwt.verify(refreshToken, publicKey, {
                algorithms: ['RS256']
            });
            
            // Send a refresh request to the SSO Server if the time remaining is less than maxTTL
            const response = await axios.post(SSO_Refresh_URL, { rememberme: refreshToken })
            res.setHeader('set-cookie',response.headers['set-cookie'])
            

        }else{
            decoded = await jwt.verify(token, publicKey, {
                algorithms: ['RS256']
            });
            const tokenAgeRemaining = decoded.exp - Math.floor(Date.now() / 1000);
            if (tokenAgeRemaining <= maxTTL) {
                console.log("refreshing token, since it is about to expire!")
                const response = await axios.post(SSO_Refresh_URL, { token })
                res.setHeader('set-cookie', response.headers['set-cookie'])
            }
        }
        if(isAuthorized(req,decoded.user)){
            req.user = decoded.user;
            next();
        }
        else return UnauthorizedHandler(req,res);
    } catch (error) {
        req.user = null;
        res.clearCookie(accessTokenName);
        res.clearCookie(refreshTokenName);
        // If the requested URL is a public path, proceed without any checks
        if (publicPaths.find(pathRegex => {return new RegExp(pathRegex).test(req.originalUrl)}) !== undefined) {
            next();
        } else {
            if (redirectURL != null) res.redirect(redirectURL);
            else res.redirect(SSO_Login_URL + clientURL + req.originalUrl);
        }
    }
    
};

const isAuthorized = (req,user) => {
    if (publicPaths.find(pathRegex => {return new RegExp(pathRegex).test(req.url)}) !== undefined) return true;
    const match = Object.keys(ROLES).find(pathRegex => { return new RegExp(pathRegex).test(req.url) })
    if(match){
        for (const index in ROLES[match]) {
            if (!user.roles.includes(ROLES[match][index])) return false;
        }
        return true;
    }
    
    for (const index in defaultRoles) {
        if (!user.roles.includes(defaultRoles[index])) return false;
    }
    return true;
}

module.exports = auth;
