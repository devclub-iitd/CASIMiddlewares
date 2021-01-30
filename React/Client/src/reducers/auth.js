import { AUTH_SUCC, AUTH_FAIL, AUTH_ERR } from '../actions/types';

const initialState = {
    loading: true,
    loggedin: false,
};

export default function (state = initialState, action) {
    const { type } = action;

    switch (type) {
        case AUTH_ERR:
        case AUTH_FAIL: {
            return {
                loading: false,
                loggedin: false,
            };
        }
        case AUTH_SUCC: {
            return {
                loading: false,
                loggedin: true,
            };
        }
        default:
            return state;
    }
}
