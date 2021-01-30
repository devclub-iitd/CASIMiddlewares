// middleware function to use to interact with auth server
import axios from 'axios';
import { verifyToken, get_cookies } from '../utils/utils';

const auth = async (req, res, next) => {

    try {
        const { token, rememberme } = req.cookies;

        if (token) {
            // verify token here
            verifyToken(req, token, res, 'token');
            next();
        }
        else if (rememberme) {

            verifyToken(req, rememberme, res, 'rememberme');

            const config = {
                headers: {
                    'Content-Type': 'application/json',
                },
            };

            const body = JSON.stringify({ rememberme });

            // Now send request to auth server to refresh the tokens
            const payload = await axios.post('http://localhost:5000/auth/refresh-token', body, config);
            const { data } = payload;

            req.user = data.user;

            // we also recieve cookies in set-cookie header
            // so set these cookies now
            const { headers } = payload;
            const cookies = get_cookies(headers['set-cookie']);

            res.cookie('token', cookies['token'], {
                maxAge: 60 * 20 * 1000, // in milli seconds
                secure: false, // set to true if your using https
                httpOnly: true,
                sameSite: 'lax',
            });

            res.cookie('rememberme', cookies['rememberme'], {
                maxAge: 60 * 60 * 24 * 2 * 1000, // in milli seconds
                secure: false, // set to true if your using https
                httpOnly: true,
                sameSite: 'lax',
            });

            next();
        }
        else return res.status(401).json({
            message: 'no tokens present'
        })

    } catch (err) {
        console.log(err);
        return res.status(401).json({
            message: 'tokens not valid'
        })
    }
}

export { auth };