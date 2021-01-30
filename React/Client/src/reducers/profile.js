import { PROFILE_SUCC, PROFILE_FAIL, PROFILE_ERR } from '../actions/types';

const initialState = {
    loading: true,
    user: null,
};

export default function (state = initialState, action) {
    const { type, payload } = action;

    switch (type) {
        case PROFILE_ERR:
        case PROFILE_FAIL: {
            return {
                ...state,
                loading: false,
            };
        }
        case PROFILE_SUCC: {
            return {
                loading: false,
                user: payload.user,
            };
        }
        default:
            return state;
    }
}
