import { verify } from 'jsonwebtoken';
import { publicKey } from '../config/keys';

const verifyToken = (req, token, res, tokenName) => {
    try {
        const decoded = verify(token, publicKey, {
            algorithms: ['RS256'],
        });

        const { user } = decoded;

        req.user = user;

    } catch (err) {
        // I wasn't able to verify the token as it was invalid
        // clear the token
        res.clearCookie(tokenName);

        // now send a response
        return res.status(401).json({
            message: 'Error, token not valid',
        });
    }
};

const get_cookies = (all_cookies) => {
    var cookies = {};
    for (var j = 0; j < all_cookies.length; j++) {
        var cookie_string = all_cookies[j].split(';');
        var cookiename = cookie_string[0].split('=')[0]
        cookies[cookiename] = cookie_string[0].split('=')[1];
    }
    return cookies
};

export { verifyToken, get_cookies };