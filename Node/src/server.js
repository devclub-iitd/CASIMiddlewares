const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const auth = require('./middleware/auth');

const notes = require('./routes/notes.js');

const port = 5000;
const app = express();

require('dotenv').config({ path: `${__dirname}/../.env` });
// extract Database URL from the environment variables
const db_url = process.env.DB_URL;

mongoose
    .connect(db_url, {
        useNewUrlParser: true,
        useCreateIndex: true,
        useFindAndModify: false,
        useUnifiedTopology: true,
    })
    .then(() => {
        console.log('Connected to the database...');
    })
    .catch((err) => {
        console.log(err);
    });

app.use(cors());
app.use(cookieParser());
app.use(bodyParser.urlencoded({ extended: true }));

app.set('view engine', 'ejs');
app.set('views', `${__dirname}/views`);
app.use(express.static(`${__dirname}/public`));

app.use(auth);

app.get('/', (req, res) => {
    const { user } = req;
    if (typeof user === 'undefined' || !user) {
        res.render('index');
    } else {
        res.redirect('/home');
    }
});

app.get('/home', (req, res) => {
    //we must have the user in req.user by now
    const user = req.user;
    res.render('home', { user });
});

app.use('/notes', notes);

app.get('/logout', (req, res) => {
    res.clearCookie('token');
    res.clearCookie('rememberme');
    res.redirect('/');
});

app.listen(port, () => {
    console.log(`Test server up and running on port:${port}`);
});
