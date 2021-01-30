import axios from '../utility/axios';
import { AUTH_SUCC, AUTH_FAIL, AUTH_ERR } from './types';

const authUser = () => async (dispatch) => {
    try {
        const res = await axios({
            type: 'GET',
            url: '/auth/check',
            withCredentials: true,
        });
        const { success } = res.data;
        if (success) {
            dispatch({
                type: AUTH_SUCC,
            });
        } else {
            dispatch({
                type: AUTH_FAIL,
            });
        }
    } catch (err) {
        dispatch({
            type: AUTH_ERR,
        });
        // if (typeof err.response !== 'undefined' && err.response) {
        //     const error = err.response.data;
        //     const { message } = error;
        //     // eslint-disable-next-line no-alert
        //     alert(message);
        // }
    }
};

export default authUser;
