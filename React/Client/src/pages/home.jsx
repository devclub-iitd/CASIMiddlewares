/* eslint-disable jsx-a11y/click-events-have-key-events */
/* eslint-disable jsx-a11y/no-static-element-interactions */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { Redirect } from 'react-router-dom';

import { connect } from 'react-redux';
import { getUserProfile, logoutUser } from '../actions/profile';

import Loading from '../components/loading';

import classes from '../styles/home.module.css';

const Home = (props) => {
    const {
        getUserProfileAction,
        loading,
        redirect,
        user,
        logoutUserAction,
    } = props;

    useEffect(() => {
        getUserProfileAction();
    }, [getUserProfileAction]);
    if (loading) {
        return <Loading />;
    }
    if (redirect) {
        return <Redirect to="/" />;
    }
    const { firstname, username, email } = user;
    return (
        <div>
            <div className={classes.rootContainer}>
                <div className={classes.center}>
                    <div className={classes.pageTitle}>Profile</div>
                    <div className={classes.miniLine} />
                    <div className={classes.greeting}>
                        Hello, {firstname} =&gt; {username}
                    </div>
                    <div className={classes.email}>Your email is : {email}</div>
                    <div className={classes.welcome}>
                        Welcome to the Test server!
                    </div>
                    <p>
                        <a href="/notes">Click here</a> to manage and view your
                        notes
                    </p>
                    <div
                        className={classes.logoutBtn}
                        onClick={logoutUserAction}
                    >
                        <a href="/logout">Log Out</a>
                    </div>
                </div>
            </div>
            <div className={classes.navBar}>
                <div className={classes.navTitle}>
                    <h3>Devclub Client</h3>
                </div>
            </div>
        </div>
    );
};

Home.propTypes = {
    getUserProfileAction: PropTypes.func.isRequired,
    logoutUserAction: PropTypes.func.isRequired,
    redirect: PropTypes.bool.isRequired,
    loading: PropTypes.bool.isRequired,
    user: PropTypes.oneOfType([PropTypes.object]).isRequired,
};

const mapStateToProps = (state) => {
    const { auth, profile } = state;
    const { loggedin } = auth;
    const { user, loading } = profile;
    let redirect = false;
    if (!loggedin || !user) {
        redirect = true;
    }
    return {
        loading,
        redirect,
        user,
    };
};

export default connect(mapStateToProps, {
    getUserProfileAction: getUserProfile,
    logoutUserAction: logoutUser,
})(Home);
