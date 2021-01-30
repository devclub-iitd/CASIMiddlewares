import React from 'react';
import { BrowserRouter as Router, Switch, Route } from 'react-router-dom';

import Index from './pages/index';
import Home from './pages/home';
import Notes from './pages/notes';

const App = () => {
    return (
        <Router>
            <div className="root">
                <Switch>
                    <Route exact path="/" component={Index} />
                    <Route exact path="/home" component={Home} />
                    <Route exact path="/notes" component={Notes} />
                </Switch>
            </div>
        </Router>
    );
};

export default App;
