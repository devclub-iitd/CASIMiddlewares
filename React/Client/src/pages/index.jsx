import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { Redirect } from 'react-router-dom';

import { connect } from 'react-redux';
import authUser from '../actions/auth';

import Loading from '../components/loading';

import classes from '../styles/index.module.css';

const Index = (props) => {
    const { authUserAction, loading, redirect } = props;

    useEffect(() => {
        authUserAction();
    }, [authUserAction]);

    if (loading) {
        return <Loading />;
    }
    if (redirect) {
        return <Redirect to="/home" />;
    }
    return (
        <div className={classes.rootContainer}>
            <h1>Oops! It seems like you are not logged in :(</h1>
            <a href="http://localhost:5000/user/login?serviceURL=http://localhost:5000">
                <div className={classes.loginBtn}>
                    Login with <b>CASI</b>
                </div>
            </a>
        </div>
    );
};

Index.propTypes = {
    authUserAction: PropTypes.func.isRequired,
    loading: PropTypes.bool.isRequired,
    redirect: PropTypes.bool.isRequired,
};

const mapStateToProps = (state) => {
    const { auth } = state;
    const { loading, loggedin } = auth;
    let redirect = false;
    if (loggedin) {
        redirect = true;
    }
    return {
        loading,
        redirect,
    };
};

export default connect(mapStateToProps, { authUserAction: authUser })(Index);
