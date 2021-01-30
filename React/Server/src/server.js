import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import auth from './routes/auth';
import lusca from 'lusca';
import profile from './routes/profile';

const app = express();

// app.use(cors());
app.use(cors({ credentials: true, origin: 'http://localhost:3000' }));
app.use(lusca.xframe('SAMEORIGIN'));
app.use(lusca.xssProtection(true));
app.use(cookieParser()); // pass a string inside function to encrypt cookies

// Root page
app.get('/', (req, res) => {
    res.send('Root page');
});


app.use('/auth', auth);
app.use('/profile', profile);

const port = 8000;

app.listen(port, () => {
    console.log(`Server listening on ${port}!`);
});